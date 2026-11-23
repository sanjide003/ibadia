import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IbadahAudioState {
  final String? activeAudioPath;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final int missingAssetTick;
  final String? lastMissingAssetPath;

  const IbadahAudioState({
    this.activeAudioPath,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.missingAssetTick = 0,
    this.lastMissingAssetPath,
  });

  IbadahAudioState copyWith({
    String? activeAudioPath,
    bool clearActivePath = false,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    int? missingAssetTick,
    String? lastMissingAssetPath,
  }) {
    return IbadahAudioState(
      activeAudioPath:
          clearActivePath ? null : (activeAudioPath ?? this.activeAudioPath),
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      missingAssetTick: missingAssetTick ?? this.missingAssetTick,
      lastMissingAssetPath: lastMissingAssetPath ?? this.lastMissingAssetPath,
    );
  }

  static String formatDuration(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final mins = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

/// Shared singleton audio controller for all Ibadah & Salah offline audio clips.
/// Ensures only one clip plays at a time and handles missing assets gracefully.
class IbadahAudioController extends StateNotifier<IbadahAudioState> {
  static final IbadahAudioController instance = IbadahAudioController._internal();

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<void>? _completeSub;
  int _playEpoch = 0;

  IbadahAudioController._internal() : super(const IbadahAudioState()) {
    _stateSub = _player.onPlayerStateChanged.listen((playerState) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: playerState == PlayerState.playing,
        isLoading: false,
      );
    });
    _posSub = _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });
    _durSub = _player.onDurationChanged.listen((dur) {
      if (!mounted) return;
      state = state.copyWith(duration: dur);
    });
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: false,
        isLoading: false,
        position: state.duration,
      );
    });
  }

  String _toAssetSourcePath(String assetPath) {
    final normalized = assetPath.trim();
    if (normalized.startsWith('assets/')) {
      return normalized.substring(7);
    }
    return normalized;
  }

  Future<void> playOrToggle(String assetPath) async {
    final normalized = assetPath.trim();
    if (normalized.isEmpty) {
      _emitMissingAsset(assetPath);
      return;
    }

    if (state.activeAudioPath == normalized) {
      if (state.isLoading) return;
      if (state.isPlaying) {
        try {
          await _player.pause();
        } catch (_) {}
        return;
      }
      if (state.duration > Duration.zero &&
          state.position < state.duration &&
          state.position > Duration.zero) {
        try {
          await _player.resume();
          return;
        } catch (_) {
          // Fall through to fresh playback if resume fails.
        }
      }
    }

    await _playFresh(normalized);
  }

  Future<void> _playFresh(String assetPath) async {
    final epoch = ++_playEpoch;
    try {
      await _player.stop();
    } catch (_) {}

    state = state.copyWith(
      activeAudioPath: assetPath,
      isPlaying: false,
      isLoading: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    try {
      // Pre-check bundle presence so missing local files fail cleanly without crashing on Android or Web.
      await rootBundle.load(assetPath);
      if (epoch != _playEpoch || !mounted) return;

      final sourcePath = _toAssetSourcePath(assetPath);
      await _player.play(AssetSource(sourcePath));
      if (epoch != _playEpoch || !mounted) return;
      state = state.copyWith(isLoading: false);
    } catch (_) {
      if (epoch != _playEpoch || !mounted) return;
      _emitMissingAsset(assetPath);
    }
  }

  void _emitMissingAsset(String assetPath) {
    state = state.copyWith(
      clearActivePath: true,
      isPlaying: false,
      isLoading: false,
      position: Duration.zero,
      duration: Duration.zero,
      missingAssetTick: state.missingAssetTick + 1,
      lastMissingAssetPath: assetPath,
    );
  }

  Future<void> seekTo(Duration position) async {
    if (state.activeAudioPath == null) return;
    try {
      final maxDur = state.duration;
      final clamped = position < Duration.zero
          ? Duration.zero
          : (maxDur > Duration.zero && position > maxDur ? maxDur : position);
      await _player.seek(clamped);
      if (mounted) {
        state = state.copyWith(position: clamped);
      }
    } catch (_) {}
  }

  Future<void> stop() async {
    ++_playEpoch;
    try {
      await _player.stop();
    } catch (_) {}
    if (!mounted) return;
    state = state.copyWith(
      clearActivePath: true,
      isPlaying: false,
      isLoading: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  /// Safe to invoke synchronously inside State.dispose().
  void stopOnDispose() {
    ++_playEpoch;
    unawaited(_player.stop().catchError((_) {}));
    Future<void>.microtask(() {
      if (!mounted) return;
      state = state.copyWith(
        clearActivePath: true,
        isPlaying: false,
        isLoading: false,
        position: Duration.zero,
        duration: Duration.zero,
      );
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}

final ibadahAudioProvider =
    StateNotifierProvider<IbadahAudioController, IbadahAudioState>((ref) {
  return IbadahAudioController.instance;
});
