import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import 'prayer_alarm_bridge_types.dart';
import 'storage_service.dart';

/// Native Android Prayer Alarm bridge (`com.quranapp.malayalam/prayer_alarm`)
/// with offline Adhan audio caching and non-Android IO desktop fallback.
class PrayerAlarmBridge {
  PrayerAlarmBridge._() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_onMethodCall);
    }
  }

  static final PrayerAlarmBridge instance = PrayerAlarmBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.quranapp.malayalam/prayer_alarm');

  static const int _minValidAudioBytes = 2048;

  void Function(NativeRingingAlarm alarm)? _ringingHandler;
  void Function(int surahNumber)? _openSurahHandler;
  void Function()? _openPrayerTabHandler;
  AudioPlayer? _fallbackPlayer;
  StreamSubscription<void>? _completeSub;
  final Map<String, Future<String?>> _inFlightDownloads = {};

  bool get isNativeAndroid => Platform.isAndroid;

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'onAlarmRinging' && call.arguments is Map) {
      final info = NativeRingingAlarm.fromMap(
        call.arguments as Map<dynamic, dynamic>,
      );
      if (info.prayerKey.isNotEmpty) {
        _ringingHandler?.call(info);
      }
    } else if (call.method == 'onLaunchAction' && call.arguments is Map) {
      final map = call.arguments as Map<dynamic, dynamic>;
      final surah = (map['openSurah'] as num?)?.toInt();
      final openPrayer = map['openPrayerTab'] == true;
      if (surah != null && surah > 0) {
        _openSurahHandler?.call(surah);
      } else if (openPrayer) {
        _openPrayerTabHandler?.call();
      }
    }
    return null;
  }

  void setOnAlarmRingingHandler(
    void Function(NativeRingingAlarm alarm)? handler,
  ) {
    _ringingHandler = handler;
  }

  void setOnOpenSurahHandler(void Function(int surahNumber)? handler) {
    _openSurahHandler = handler;
  }

  void setOnOpenPrayerTabHandler(void Function()? handler) {
    _openPrayerTabHandler = handler;
  }

  Future<String?> _getAdhanCacheDir() async {
    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<String>('getAdhanCacheDir');
      } catch (_) {}
    }
    final dir = Directory('${Directory.systemTemp.path}/alquran_adhans_v1');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String?> ensureAdhanCached(AlarmSoundOption option) async {
    final url = option.remoteUrl;
    if (url == null || url.isEmpty) return null;

    final dirPath = await _getAdhanCacheDir();
    if (dirPath == null || dirPath.isEmpty) return null;

    final safeId = option.id.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final targetFile = File('$dirPath/$safeId.mp3');
    if (await targetFile.exists()) {
      final size = await targetFile.length();
      if (size >= _minValidAudioBytes) {
        return targetFile.path;
      }
      try {
        await targetFile.delete();
      } catch (_) {}
    }

    final existing = _inFlightDownloads[option.id];
    if (existing != null) return existing;

    final future = _downloadAdhanFile(url, targetFile);
    _inFlightDownloads[option.id] = future;
    try {
      return await future;
    } finally {
      _inFlightDownloads.remove(option.id);
    }
  }

  Future<String?> _downloadAdhanFile(String url, File targetFile) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 200 && res.bodyBytes.length >= _minValidAudioBytes) {
        final tmp = File('${targetFile.path}.tmp');
        await tmp.writeAsBytes(res.bodyBytes, flush: true);
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tmp.rename(targetFile.path);
        return targetFile.path;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> requestAlarmPermissions() async {
    if (!Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('requestAlarmPermissions');
      return ok ?? true;
    } catch (_) {
      return false;
    }
  }

  String _prayerNameFor(String key, AppStrings t) {
    switch (key) {
      case 'fajr':
        return t.fajrName;
      case 'dhuhr':
        return t.dhuhrName;
      case 'asr':
        return t.asrName;
      case 'maghrib':
        return t.maghribName;
      case 'isha':
        return t.ishaName;
      default:
        return key;
    }
  }

  Future<void> syncNativeSchedule({
    required List<ComputedPrayerSlot> slots,
    required AppSettings settings,
    required AppStrings strings,
    required DateTime referenceDay,
  }) async {
    if (!Platform.isAndroid) return;

    final soundOpt = AlAdhanCatalog.soundById(settings.alarmSoundType);
    String? soundFilePath;
    if (soundOpt.remoteUrl != null) {
      // Download/cache offline Adhan file so alarm rings reliably offline
      soundFilePath = await ensureAdhanCached(soundOpt);
    }

    final List<Map<String, dynamic>> alarmsPayload = [];
    if (settings.prayerAlarmMasterEnabled) {
      for (final slot in slots) {
        if (!slot.prayerAlarmEnabled || slot.alarmTime == null) continue;
        final prayerLabel = _prayerNameFor(slot.prayerKey, strings);
        final timeLabel = DailyPrayerData.format12Hour(slot.alarmTime!);
        final adhanLabel = DailyPrayerData.format12Hour(slot.adhanTime);
        final iqamahLabel = DailyPrayerData.format12Hour(slot.iqamahTime);
        alarmsPayload.add({
          'prayerKey': slot.prayerKey,
          'title': '$prayerLabel • ${strings.prayerReminderRinging}',
          'subtitle':
              '${strings.adhanLabel}: $adhanLabel  |  ${strings.iqamahLabel}: $iqamahLabel',
          'timeLabel': timeLabel,
          'triggerAtMillis': slot.alarmTime!.millisecondsSinceEpoch,
        });
      }
    }

    try {
      await _channel.invokeMethod<bool>('schedulePrayerAlarms', {
        'alarms': alarmsPayload,
        'soundType': settings.alarmSoundType,
        'soundFilePath': soundFilePath,
        'volume': settings.alarmVolume.clamp(0.1, 1.0),
        'vibrate': settings.alarmVibrate,
      });
    } catch (_) {}
  }

  Future<void> previewSound(
    AppSettings settings, {
    void Function()? onFinished,
  }) async {
    final soundOpt = AlAdhanCatalog.soundById(settings.alarmSoundType);
    String? localPath;
    if (soundOpt.remoteUrl != null) {
      localPath = await ensureAdhanCached(soundOpt);
    }

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('previewAlarmSound', {
          'soundType': settings.alarmSoundType,
          'soundFilePath': localPath,
          'volume': settings.alarmVolume.clamp(0.1, 1.0),
          'vibrate': settings.alarmVibrate,
        });
        return;
      } catch (_) {}
    }

    await _playFallbackAudio(settings, localPath, loop: false, onFinished: onFinished);
  }

  Future<void> startRingingLoopSound(AppSettings settings) async {
    // On Android native BroadcastReceiver already starts MediaPlayer + Vibrator.
    if (Platform.isAndroid) return;
    final soundOpt = AlAdhanCatalog.soundById(settings.alarmSoundType);
    String? localPath;
    if (soundOpt.remoteUrl != null) {
      localPath = await ensureAdhanCached(soundOpt);
    }
    await _playFallbackAudio(settings, localPath, loop: true);
  }

  Future<void> _playFallbackAudio(
    AppSettings settings,
    String? localPath, {
    required bool loop,
    void Function()? onFinished,
  }) async {
    try {
      final p = _fallbackPlayer ??= AudioPlayer();
      await _completeSub?.cancel();
      _completeSub = p.onPlayerComplete.listen(
        (_) => onFinished?.call(),
        onError: (_) {},
      );
      await p.stop();
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await p.setVolume(settings.alarmVolume.clamp(0.1, 1.0));
      if (localPath != null) {
        await p.play(DeviceFileSource(localPath));
      } else {
        final uri = Uri.dataFromBytes(
          buildSoftChimeWavBytes(),
          mimeType: 'audio/wav',
        ).toString();
        await p.play(UrlSource(uri));
      }
    } catch (_) {
      onFinished?.call();
    }
  }

  Future<void> stopSound() async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('stopAlarmSound');
      } catch (_) {}
    }
    try {
      await _fallbackPlayer?.stop();
    } catch (_) {}
  }

  Future<void> dismissNativeAlarm({
    String? dateKey,
    String? prayerKey,
  }) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('dismissActiveAlarm', {
          if (dateKey != null) 'dateKey': dateKey,
          if (prayerKey != null) 'prayerKey': prayerKey,
        });
      } catch (_) {}
    }
    await stopSound();
  }

  Future<NativeRingingAlarm?> getActiveRingingAlarm() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getActiveRingingAlarm',
      );
      if (raw == null) return null;
      final alarm = NativeRingingAlarm.fromMap(raw);
      return alarm.prayerKey.isEmpty ? null : alarm;
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> getNativeDismissedKeys(String dateKey) async {
    if (!Platform.isAndroid) return const [];
    try {
      final list = await _channel.invokeListMethod<String>(
        'getDismissedKeysForDate',
        {'dateKey': dateKey},
      );
      return list ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> syncKahfReminders({
    required AppSettings settings,
    required AppStrings strings,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('scheduleKahfReminders', {
        'thuEnabled': settings.kahfThursdayEnabled,
        'friEnabled': settings.kahfFridayEnabled,
        'thuHour': settings.kahfThuHour,
        'thuMinute': settings.kahfThuMinute,
        'friHour': settings.kahfFriHour,
        'friMinute': settings.kahfFriMinute,
        'title': strings.kahfNotifTitle,
        'body': strings.kahfNotifBody,
      });
    } catch (_) {}
  }

  Future<void> testKahfNotification({required AppStrings strings}) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('testKahfNotification', {
        'title': strings.kahfNotifTitle,
        'body': strings.kahfNotifBody,
      });
    } catch (_) {}
  }

  Future<({int? openSurah, bool openPrayerTab})?>
      getInitialLaunchAction() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getInitialLaunchAction',
      );
      if (raw == null) return null;
      final surah = (raw['openSurah'] as num?)?.toInt();
      final openPrayer = raw['openPrayerTab'] == true;
      if ((surah == null || surah <= 0) && !openPrayer) return null;
      return (openSurah: surah, openPrayerTab: openPrayer);
    } catch (_) {
      return null;
    }
  }
}
