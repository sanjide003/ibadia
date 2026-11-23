import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import 'storage_service.dart';

class NativeLaunchAction {
  final int? openSurah;
  final bool openPrayerTab;

  const NativeLaunchAction({
    this.openSurah,
    this.openPrayerTab = false,
  });
}

class NativeRingingAlarm {
  final String prayerKey;
  final String title;
  final String timeLabel;
  final String dateKey;

  const NativeRingingAlarm({
    required this.prayerKey,
    required this.title,
    required this.timeLabel,
    required this.dateKey,
  });
}

class PrayerAlarmBridge {
  PrayerAlarmBridge._() {
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_handleNativeCall);
    }
  }

  static final PrayerAlarmBridge instance = PrayerAlarmBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.ibadia/prayer_alarm');

  final AudioPlayer _fallbackPlayer = AudioPlayer();
  void Function(int surahNo)? _onOpenSurah;
  VoidCallback? _onOpenPrayerTab;
  void Function(NativeRingingAlarm info)? _onAlarmRinging;
  VoidCallback? _onPreviewFinished;
  Timer? _previewDoneTimer;
  StreamSubscription<void>? _fallbackCompleteSub;

  bool get isNativeAndroid => Platform.isAndroid;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onLaunchAction') {
      final raw = call.arguments;
      if (raw is Map) {
        final surah = (raw['openSurah'] as num?)?.toInt();
        final openPrayer = raw['openPrayerTab'] == true;
        if (openPrayer) {
          _onOpenPrayerTab?.call();
        } else if (surah != null && surah > 0) {
          _onOpenSurah?.call(surah);
        }
      }
    } else if (call.method == 'onAlarmRinging') {
      final raw = call.arguments;
      if (raw is Map) {
        final info = NativeRingingAlarm(
          prayerKey: (raw['prayerKey'] ?? '').toString(),
          title: (raw['title'] ?? '').toString(),
          timeLabel: (raw['timeLabel'] ?? '').toString(),
          dateKey: (raw['dateKey'] ?? '').toString(),
        );
        _onAlarmRinging?.call(info);
      }
    }
    return null;
  }

  void setOnOpenSurahHandler(void Function(int surahNo)? handler) {
    _onOpenSurah = handler;
  }

  void setOnOpenPrayerTabHandler(VoidCallback? handler) {
    _onOpenPrayerTab = handler;
  }

  void setOnAlarmRingingHandler(
    void Function(NativeRingingAlarm info)? handler,
  ) {
    _onAlarmRinging = handler;
  }

  Future<NativeLaunchAction?> getInitialLaunchAction() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getInitialLaunchAction',
      );
      if (raw == null) return null;
      return NativeLaunchAction(
        openSurah: (raw['openSurah'] as num?)?.toInt(),
        openPrayerTab: raw['openPrayerTab'] == true,
      );
    } catch (_) {
      return null;
    }
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

  Future<List<String>> getNativeDismissedKeys(String dateKey) async {
    if (!Platform.isAndroid) return const [];
    try {
      final raw = await _channel.invokeListMethod<dynamic>(
        'getDismissedKeysForDate',
        {'dateKey': dateKey},
      );
      return (raw ?? const []).map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<NativeRingingAlarm?> getActiveRingingAlarm() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getActiveRingingAlarm',
      );
      if (raw == null) return null;
      final key = (raw['prayerKey'] ?? '').toString();
      if (key.isEmpty) return null;
      return NativeRingingAlarm(
        prayerKey: key,
        title: (raw['title'] ?? key).toString(),
        timeLabel: (raw['timeLabel'] ?? '').toString(),
        dateKey: (raw['dateKey'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> isDndPolicyAccessGranted() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('isDndPolicyAccessGranted');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openDndPolicySettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openDndPolicySettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return ok ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('openExactAlarmSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAutoSilentActiveNow() async {
    if (!Platform.isAndroid) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('getAutoSilentStatus');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> restoreNormalRingerNow() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('restoreNormalRingerNow');
    } catch (_) {}
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

  Future<String?> _ensureCachedSoundFile(String soundType) async {
    if (!Platform.isAndroid || soundType == 'alarm_tone') return null;
    final option = ApiConfig.alarmSoundById(soundType);
    final url = option.remoteUrl;
    if (url == null || url.isEmpty) return null;

    try {
      final dirPath = await _channel.invokeMethod<String>('getAdhanCacheDir');
      if (dirPath == null || dirPath.isEmpty) return null;
      final file = File('$dirPath/${option.id}.mp3');
      if (await file.exists() && await file.length() > 1024) {
        return file.path;
      }
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode >= 200 &&
          res.statusCode < 300 &&
          res.bodyBytes.length > 1024) {
        await file.writeAsBytes(res.bodyBytes, flush: true);
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  Future<void> syncNativeSchedule({
    required List<ComputedPrayerSlot> slots,
    required AppSettings settings,
    required AppStrings strings,
    required DateTime referenceDay,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final soundFilePath = await _ensureCachedSoundFile(settings.alarmSoundType);
      final alarms = <Map<String, dynamic>>[];

      for (final slot in slots) {
        if (!slot.isAlarmActive || slot.alarmTime == null) continue;
        final label = strings.prayerName(slot.prayerKey);
        final timeStr = DailyPrayerData.format12Hour(slot.adhanTime);
        alarms.add({
          'prayerKey': slot.prayerKey,
          'title': '$label • ${strings.prayerReminderRinging}',
          'subtitle': '${strings.adhanLabel} $timeStr',
          'timeLabel': DailyPrayerData.format12Hour(slot.alarmTime!),
          'triggerAtMillis': slot.alarmTime!.millisecondsSinceEpoch,
        });
      }

      await _channel.invokeMethod<bool>('schedulePrayerAlarms', {
        'alarms': alarms,
        'soundType': settings.alarmSoundType,
        'soundFilePath': soundFilePath,
        'volume': settings.alarmVolume.clamp(0.1, 1.0),
        'vibrate': settings.alarmVibrate,
      });
    } catch (_) {}
  }

  Future<void> syncAutoSilentWindows({
    required List<ComputedPrayerSlot> slots,
    required AppSettings settings,
    required AppStrings strings,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final durationMins = settings.autoSilentDurationMinutes.clamp(5, 60);
      final windows = <Map<String, dynamic>>[];
      for (final slot in slots) {
        if (!settings.isAutoSilentEnabledFor(slot.prayerKey)) continue;
        final startDt = slot.iqamahTime;
        final endDt = startDt.add(Duration(minutes: durationMins));
        final pName = strings.prayerName(slot.prayerKey);
        windows.add({
          'prayerKey': slot.prayerKey,
          'prayerName': pName,
          'startMillis': startDt.millisecondsSinceEpoch,
          'endMillis': endDt.millisecondsSinceEpoch,
          'durationMinutes': durationMins,
          'notifTitle': '${strings.dndActiveNowBanner} ($pName)',
          'restoreBtn': strings.restoreSoundNowBtn,
        });
      }

      await _channel.invokeMethod<bool>('schedulePrayerDndWindows', {
        'enabled': settings.autoSilentEnabled,
        'windows': windows,
      });
    } catch (_) {}
  }

  Future<void> dismissNativeAlarm({
    required String dateKey,
    String? prayerKey,
  }) async {
    await stopSound();
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('dismissActiveAlarm', {
        'dateKey': dateKey,
        'prayerKey': prayerKey,
      });
    } catch (_) {}
  }

  Future<void> startRingingLoopSound(AppSettings settings) async {
    if (Platform.isAndroid) return;
    final option = ApiConfig.alarmSoundById(settings.alarmSoundType);
    final url = option.remoteUrl;
    if (url == null || url.isEmpty) return;
    try {
      await _fallbackPlayer.stop();
      await _fallbackPlayer.setReleaseMode(ReleaseMode.loop);
      await _fallbackPlayer.setVolume(settings.alarmVolume.clamp(0.1, 1.0));
      await _fallbackPlayer.play(UrlSource(url));
    } catch (_) {}
  }

  Future<void> previewSound(
    AppSettings settings, {
    VoidCallback? onFinished,
  }) async {
    await stopSound();
    _onPreviewFinished = onFinished;

    if (Platform.isAndroid) {
      try {
        final soundFilePath =
            await _ensureCachedSoundFile(settings.alarmSoundType);
        await _channel.invokeMethod<bool>('previewAlarmSound', {
          'soundType': settings.alarmSoundType,
          'soundFilePath': soundFilePath,
          'volume': settings.alarmVolume.clamp(0.1, 1.0),
          'vibrate': settings.alarmVibrate,
        });
        _previewDoneTimer = Timer(const Duration(seconds: 12), () {
          final cb = _onPreviewFinished;
          _onPreviewFinished = null;
          cb?.call();
        });
        return;
      } catch (_) {}
    }

    final option = ApiConfig.alarmSoundById(settings.alarmSoundType);
    final url = option.remoteUrl ??
        ApiConfig.alarmSoundById('adhan_alafasy').remoteUrl;
    if (url == null || url.isEmpty) {
      final cb = _onPreviewFinished;
      _onPreviewFinished = null;
      cb?.call();
      return;
    }

    try {
      _fallbackCompleteSub?.cancel();
      _fallbackCompleteSub = _fallbackPlayer.onPlayerComplete.listen((_) {
        final cb = _onPreviewFinished;
        _onPreviewFinished = null;
        cb?.call();
      });
      await _fallbackPlayer.setReleaseMode(ReleaseMode.stop);
      await _fallbackPlayer.setVolume(settings.alarmVolume.clamp(0.1, 1.0));
      await _fallbackPlayer.play(UrlSource(url));
    } catch (_) {
      final cb = _onPreviewFinished;
      _onPreviewFinished = null;
      cb?.call();
    }
  }

  Future<void> stopSound() async {
    _previewDoneTimer?.cancel();
    _previewDoneTimer = null;
    _onPreviewFinished = null;
    await _fallbackCompleteSub?.cancel();
    _fallbackCompleteSub = null;
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<bool>('stopAlarmSound');
      } catch (_) {}
    }
    try {
      await _fallbackPlayer.stop();
    } catch (_) {}
  }
}
