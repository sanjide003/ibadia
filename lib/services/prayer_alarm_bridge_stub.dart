import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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
  PrayerAlarmBridge._();

  static final PrayerAlarmBridge instance = PrayerAlarmBridge._();

  final AudioPlayer _player = AudioPlayer();
  VoidCallback? _onPreviewFinished;
  StreamSubscription<void>? _completeSub;

  bool get isNativeAndroid => false;

  void setOnOpenSurahHandler(void Function(int surahNo)? handler) {}

  void setOnOpenPrayerTabHandler(VoidCallback? handler) {}

  void setOnAlarmRingingHandler(void Function(NativeRingingAlarm info)? handler) {}

  Future<NativeLaunchAction?> getInitialLaunchAction() async => null;

  Future<bool> requestAlarmPermissions() async => true;

  Future<List<String>> getNativeDismissedKeys(String dateKey) async => const [];

  Future<NativeRingingAlarm?> getActiveRingingAlarm() async => null;

  Future<bool> isDndPolicyAccessGranted() async => false;

  Future<bool> openDndPolicySettings() async => false;

  Future<bool> canScheduleExactAlarms() async => true;

  Future<bool> openExactAlarmSettings() async => false;

  Future<bool> isAutoSilentActiveNow() async => false;

  Future<void> restoreNormalRingerNow() async {}

  Future<void> syncKahfReminders({
    required AppSettings settings,
    required AppStrings strings,
  }) async {}

  Future<void> testKahfNotification({required AppStrings strings}) async {}

  Future<void> syncNativeSchedule({
    required List<ComputedPrayerSlot> slots,
    required AppSettings settings,
    required AppStrings strings,
    required DateTime referenceDay,
  }) async {}

  Future<void> syncAutoSilentWindows({
    required List<ComputedPrayerSlot> slots,
    required AppSettings settings,
    required AppStrings strings,
  }) async {}

  Future<void> dismissNativeAlarm({
    required String dateKey,
    String? prayerKey,
  }) async {
    await stopSound();
  }

  Future<void> startRingingLoopSound(AppSettings settings) async {
    final option = ApiConfig.alarmSoundById(settings.alarmSoundType);
    final url = option.remoteUrl;
    if (url == null || url.isEmpty) return;
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(settings.alarmVolume.clamp(0.1, 1.0));
      await _player.play(UrlSource(url));
    } catch (_) {}
  }

  Future<void> previewSound(
    AppSettings settings, {
    VoidCallback? onFinished,
  }) async {
    await stopSound();
    _onPreviewFinished = onFinished;
    final option = ApiConfig.alarmSoundById(settings.alarmSoundType);
    final url = option.remoteUrl ??
        ApiConfig.alarmSoundById('adhan_alafasy').remoteUrl;
    if (url == null || url.isEmpty) {
      onFinished?.call();
      return;
    }
    try {
      _completeSub?.cancel();
      _completeSub = _player.onPlayerComplete.listen((_) {
        final cb = _onPreviewFinished;
        _onPreviewFinished = null;
        cb?.call();
      });
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setVolume(settings.alarmVolume.clamp(0.1, 1.0));
      await _player.play(UrlSource(url));
    } catch (_) {
      final cb = _onPreviewFinished;
      _onPreviewFinished = null;
      cb?.call();
    }
  }

  Future<void> stopSound() async {
    _onPreviewFinished = null;
    await _completeSub?.cancel();
    _completeSub = null;
    try {
      await _player.stop();
    } catch (_) {}
  }
}
