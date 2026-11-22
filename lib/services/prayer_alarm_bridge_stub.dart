import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import 'prayer_alarm_bridge_types.dart';
import 'storage_service.dart';

/// Web / fallback Prayer Alarm bridge using `audioplayers` cleanly.
class PrayerAlarmBridge {
  PrayerAlarmBridge._();

  static final PrayerAlarmBridge instance = PrayerAlarmBridge._();

  AudioPlayer? _player;
  String? _chimeDataUri;
  StreamSubscription<void>? _completeSub;

  bool get isNativeAndroid => false;

  void setOnAlarmRingingHandler(
    void Function(NativeRingingAlarm alarm)? handler,
  ) {
    // Web uses foreground 1s ticker in PrayerAlarmNotifier.
  }

  AudioPlayer? _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    try {
      final p = AudioPlayer();
      _completeSub = p.onPlayerComplete.listen((_) {}, onError: (_) {});
      _player = p;
      return p;
    } catch (_) {
      return null;
    }
  }

  String _getChimeUri() {
    return _chimeDataUri ??= Uri.dataFromBytes(
      buildSoftChimeWavBytes(),
      mimeType: 'audio/wav',
    ).toString();
  }

  Future<String?> ensureAdhanCached(AlarmSoundOption option) async =>
      option.remoteUrl;

  Future<bool> requestAlarmPermissions() async => true;

  Future<void> syncNativeSchedule({
    required List<ComputedPrayerSlot> slots,
    required AppSettings settings,
    required AppStrings strings,
    required DateTime referenceDay,
  }) async {
    // Web relies on foreground polling while tab is active.
  }

  Future<void> previewSound(
    AppSettings settings, {
    VoidCallback? onFinished,
  }) async {
    await _playWithSettings(settings, loop: false, onFinished: onFinished);
  }

  Future<void> startRingingLoopSound(AppSettings settings) async {
    await _playWithSettings(settings, loop: true);
  }

  Future<void> _playWithSettings(
    AppSettings settings, {
    required bool loop,
    VoidCallback? onFinished,
  }) async {
    final player = _ensurePlayer();
    if (player == null) return;
    try {
      await _completeSub?.cancel();
      _completeSub = player.onPlayerComplete.listen(
        (_) => onFinished?.call(),
        onError: (_) {},
      );
      await player.stop();
      await player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await player.setVolume(settings.alarmVolume.clamp(0.1, 1.0));

      final opt = AlAdhanCatalog.soundById(settings.alarmSoundType);
      final sourceUrl = opt.remoteUrl ?? _getChimeUri();
      await player.play(UrlSource(sourceUrl));
    } catch (_) {
      // Fallback to built-in chime if remote Adhan fails / CORS restricted
      try {
        await player.setReleaseMode(
          loop ? ReleaseMode.loop : ReleaseMode.release,
        );
        await player.setVolume(settings.alarmVolume.clamp(0.1, 1.0));
        await player.play(UrlSource(_getChimeUri()));
      } catch (_) {
        onFinished?.call();
      }
    }
  }

  Future<void> stopSound() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dismissNativeAlarm({
    String? dateKey,
    String? prayerKey,
  }) async {
    await stopSound();
  }

  Future<NativeRingingAlarm?> getActiveRingingAlarm() async => null;

  Future<List<String>> getNativeDismissedKeys(String dateKey) async =>
      const [];
}

typedef VoidCallback = void Function();
