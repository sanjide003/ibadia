import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';
import '../models/surah_model.dart';
import '../services/audio_cache_service.dart';
import 'quran_providers.dart';

class QuranAudioState {
  final bool isVisible;
  final bool isPlaying;
  final bool isBuffering;
  final bool isLoopingAyah;
  final int? surahNumber;
  final String surahName;
  final String surahArabicName;
  final int? ayahNumber;
  final int? globalAyahNumber;
  final String reciterId;
  final Duration position;
  final Duration duration;
  final String? errorKey;

  const QuranAudioState({
    this.isVisible = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLoopingAyah = false,
    this.surahNumber,
    this.surahName = '',
    this.surahArabicName = '',
    this.ayahNumber,
    this.globalAyahNumber,
    this.reciterId = ApiConfig.defaultReciterId,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorKey,
  });

  bool isTargetAyah(int surah, int ayah) =>
      isVisible && surahNumber == surah && ayahNumber == ayah;

  bool get canGoPrev =>
      surahNumber != null &&
      ayahNumber != null &&
      (surahNumber! > 1 || ayahNumber! > 1 || position.inMilliseconds > 500);

  bool get canGoNext =>
      surahNumber != null &&
      ayahNumber != null &&
      !(surahNumber == 114 && ayahNumber == 6);

  QuranAudioState copyWith({
    bool? isVisible,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLoopingAyah,
    int? surahNumber,
    String? surahName,
    String? surahArabicName,
    int? ayahNumber,
    int? globalAyahNumber,
    String? reciterId,
    Duration? position,
    Duration? duration,
    String? errorKey,
    bool clearError = false,
  }) {
    return QuranAudioState(
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLoopingAyah: isLoopingAyah ?? this.isLoopingAyah,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      surahArabicName: surahArabicName ?? this.surahArabicName,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      globalAyahNumber: globalAyahNumber ?? this.globalAyahNumber,
      reciterId: reciterId ?? this.reciterId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }
}

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _cache = AudioCacheService.instance;
  final Map<int, SurahDetail> _loadedSurahs = {};

  int _opToken = 0;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<void>? _completeSub;

  QuranAudioNotifier(this._ref)
      : super(
          QuranAudioState(
            reciterId: _ref.read(settingsProvider).reciterId,
          ),
        ) {
    _bindPlayerStreams();
  }

  void _bindPlayerStreams() {
    _durationSub = _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      state = state.copyWith(duration: d);
    });

    _positionSub = _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      final clamped =
          state.duration > Duration.zero && p > state.duration
              ? state.duration
              : p;
      state = state.copyWith(position: clamped);
    });

    _stateSub = _player.onPlayerStateChanged.listen((ps) {
      if (!mounted) return;
      if (ps == PlayerState.playing) {
        state = state.copyWith(isPlaying: true, isBuffering: false);
      } else if (ps == PlayerState.paused) {
        state = state.copyWith(isPlaying: false, isBuffering: false);
      } else if (ps == PlayerState.stopped) {
        state = state.copyWith(isPlaying: false, isBuffering: false);
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted || !state.isVisible) return;
      _handleTrackCompleted(_opToken);
    });
  }

  @override
  void dispose() {
    _opToken++;
    _durationSub?.cancel();
    _positionSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void registerLoadedSurahs(Iterable<SurahDetail> surahs) {
    for (final s in surahs) {
      _loadedSurahs[s.summary.number] = s;
    }
  }

  Future<SurahDetail?> _getSurahDetail(int surahNumber) async {
    final existing = _loadedSurahs[surahNumber];
    if (existing != null) return existing;
    try {
      final fetched = await _ref.read(apiServiceProvider).fetchSurahDetail(
            surahNumber: surahNumber,
            requiredTranslations: const [],
          );
      _loadedSurahs[surahNumber] = fetched;
      return fetched;
    } catch (_) {
      return null;
    }
  }

  Future<void> playOrToggleAyah({
    required int surahNumber,
    required int ayahNumber,
    int? globalAyahNumber,
    SurahSummary? summary,
  }) async {
    if (state.isTargetAyah(surahNumber, ayahNumber) && state.errorKey == null) {
      await togglePlayPause();
      return;
    }
    await playAyah(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
      summary: summary,
    );
  }

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    int? globalAyahNumber,
    SurahSummary? summary,
    String? overrideReciterId,
    bool autoPlay = true,
  }) async {
    final token = ++_opToken;
    final reciterId =
        overrideReciterId ?? _ref.read(settingsProvider).reciterId;
    final reciter = ApiConfig.reciterById(reciterId);

    SurahDetail? detail = _loadedSurahs[surahNumber];
    if (detail == null && (globalAyahNumber == null || summary == null)) {
      detail = await _getSurahDetail(surahNumber);
      if (!mounted || token != _opToken) return;
    }

    final resolvedSummary = summary ?? detail?.summary;
    int? resolvedGlobal = globalAyahNumber;
    if (resolvedGlobal == null && detail != null) {
      for (final a in detail.ayahs) {
        if (a.numberInSurah == ayahNumber) {
          resolvedGlobal = a.globalNumber;
          break;
        }
      }
    }

    state = state.copyWith(
      isVisible: true,
      isPlaying: false,
      isBuffering: autoPlay,
      surahNumber: surahNumber,
      surahName: resolvedSummary?.englishName ?? state.surahName,
      surahArabicName: resolvedSummary?.nameArabic ?? state.surahArabicName,
      ayahNumber: ayahNumber,
      globalAyahNumber: resolvedGlobal,
      reciterId: reciter.id,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    );

    try {
      await _player.stop();
    } catch (_) {}
    if (!mounted || token != _opToken) return;

    if (resolvedGlobal == null || resolvedGlobal <= 0) {
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorKey: 'audio_load_error',
      );
      return;
    }

    final source = await _cache.resolvePlayableSource(
      reciter: reciter,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: resolvedGlobal,
    );
    if (!mounted || token != _opToken) return;

    if (source == null) {
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorKey: 'audio_load_error',
      );
      return;
    }

    if (!autoPlay) {
      try {
        await _player.setSource(source);
      } catch (_) {}
      if (!mounted || token != _opToken) return;
      state = state.copyWith(isBuffering: false, isPlaying: false);
      return;
    }

    bool started = false;
    try {
      await _player.play(source);
      started = true;
    } catch (_) {
      if (!mounted || token != _opToken) return;
      try {
        final fallback = _cache.fallbackUrlSource(
          reciter: reciter,
          surahNumber: surahNumber,
          ayahNumber: ayahNumber,
        );
        await _player.play(fallback);
        started = true;
      } catch (_) {
        started = false;
      }
    }

    if (!mounted || token != _opToken) return;
    if (!started) {
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorKey: 'audio_load_error',
      );
      return;
    }

    state = state.copyWith(
      isBuffering: false,
      isPlaying: true,
      clearError: true,
    );

    // Preload ONLY the next 1 Ayah so transitions stay seamless without wasting data.
    unawaited(
      _prefetchNextAyah(
        token: token,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        reciter: reciter,
      ),
    );
  }

  Future<void> _prefetchNextAyah({
    required int token,
    required int surahNumber,
    required int ayahNumber,
    required QuranReciter reciter,
  }) async {
    if (!mounted || token != _opToken) return;
    final detail = await _getSurahDetail(surahNumber);
    if (!mounted || token != _opToken || detail == null) return;

    int? nextSurah;
    int? nextAyah;
    int? nextGlobal;

    if (ayahNumber < detail.ayahs.length) {
      nextSurah = surahNumber;
      nextAyah = ayahNumber + 1;
      for (final a in detail.ayahs) {
        if (a.numberInSurah == nextAyah) {
          nextGlobal = a.globalNumber;
          break;
        }
      }
    } else if (surahNumber < 114) {
      final nextDetail = await _getSurahDetail(surahNumber + 1);
      if (!mounted || token != _opToken || nextDetail == null) return;
      if (nextDetail.ayahs.isNotEmpty) {
        nextSurah = surahNumber + 1;
        nextAyah = nextDetail.ayahs.first.numberInSurah;
        nextGlobal = nextDetail.ayahs.first.globalNumber;
      }
    }

    if (nextSurah != null && nextAyah != null && nextGlobal != null) {
      await _cache.prefetchAyah(
        reciter: reciter,
        surahNumber: nextSurah,
        ayahNumber: nextAyah,
        globalAyahNumber: nextGlobal,
      );
    }
  }

  void toggleLoopAyah() {
    state = state.copyWith(isLoopingAyah: !state.isLoopingAyah);
  }

  Future<void> _handleTrackCompleted(int token) async {
    if (!mounted || token != _opToken) return;
    final curSurah = state.surahNumber;
    final curAyah = state.ayahNumber;
    if (curSurah == null || curAyah == null) return;

    if (state.isLoopingAyah) {
      await playAyah(
        surahNumber: curSurah,
        ayahNumber: curAyah,
        globalAyahNumber: state.globalAyahNumber,
        autoPlay: true,
      );
      return;
    }

    if (curSurah >= 114) {
      final detail = await _getSurahDetail(114);
      if (!mounted || token != _opToken) return;
      final lastAyah = detail?.ayahs.length ?? 6;
      if (curAyah >= lastAyah) {
        state = state.copyWith(
          isPlaying: false,
          isBuffering: false,
          position: state.duration,
        );
        return;
      }
    }

    await nextAyah();
  }

  Future<void> togglePlayPause() async {
    if (!state.isVisible ||
        state.surahNumber == null ||
        state.ayahNumber == null) {
      return;
    }

    if (state.errorKey != null) {
      await playAyah(
        surahNumber: state.surahNumber!,
        ayahNumber: state.ayahNumber!,
        globalAyahNumber: state.globalAyahNumber,
      );
      return;
    }

    if (state.isBuffering) return;

    if (state.isPlaying) {
      await _player.pause();
      if (mounted) {
        state = state.copyWith(isPlaying: false);
      }
      return;
    }

    // If track finished at the end (e.g. end of Surah 114), replay cleanly from start.
    if (state.duration > Duration.zero &&
        state.position >= state.duration - const Duration(milliseconds: 150)) {
      await playAyah(
        surahNumber: state.surahNumber!,
        ayahNumber: state.ayahNumber!,
        globalAyahNumber: state.globalAyahNumber,
      );
      return;
    }

    try {
      await _player.resume();
      if (mounted) {
        state = state.copyWith(isPlaying: true);
      }
    } catch (_) {
      await playAyah(
        surahNumber: state.surahNumber!,
        ayahNumber: state.ayahNumber!,
        globalAyahNumber: state.globalAyahNumber,
      );
    }
  }

  Future<void> seekTo(Duration target) async {
    if (!state.isVisible) return;
    final maxDur = state.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (maxDur > Duration.zero && target > maxDur ? maxDur : target);
    state = state.copyWith(position: clamped);
    try {
      await _player.seek(clamped);
    } catch (_) {}
  }

  Future<void> nextAyah() async {
    final curSurah = state.surahNumber;
    final curAyah = state.ayahNumber;
    if (curSurah == null || curAyah == null) return;

    final detail = await _getSurahDetail(curSurah);
    if (!mounted) return;
    final total = detail?.ayahs.length ?? 0;

    if (total > 0 && curAyah < total) {
      await playAyah(
        surahNumber: curSurah,
        ayahNumber: curAyah + 1,
        summary: detail?.summary,
      );
      return;
    }

    if (curSurah < 114) {
      await playAyah(
        surahNumber: curSurah + 1,
        ayahNumber: 1,
      );
    }
  }

  Future<void> prevAyah() async {
    final curSurah = state.surahNumber;
    final curAyah = state.ayahNumber;
    if (curSurah == null || curAyah == null) return;

    if (curAyah > 1) {
      await playAyah(
        surahNumber: curSurah,
        ayahNumber: curAyah - 1,
        summary: _loadedSurahs[curSurah]?.summary,
      );
      return;
    }

    if (curSurah > 1) {
      final prevDetail = await _getSurahDetail(curSurah - 1);
      if (!mounted) return;
      if (prevDetail != null && prevDetail.ayahs.isNotEmpty) {
        await playAyah(
          surahNumber: curSurah - 1,
          ayahNumber: prevDetail.ayahs.last.numberInSurah,
          globalAyahNumber: prevDetail.ayahs.last.globalNumber,
          summary: prevDetail.summary,
        );
      }
      return;
    }

    await seekTo(Duration.zero);
  }

  Future<void> onReciterChanged(String newReciterId) async {
    if (state.reciterId == newReciterId) return;
    if (!state.isVisible ||
        state.surahNumber == null ||
        state.ayahNumber == null) {
      state = state.copyWith(reciterId: newReciterId);
      return;
    }
    final shouldAutoPlay = state.isPlaying || state.isBuffering;
    await playAyah(
      surahNumber: state.surahNumber!,
      ayahNumber: state.ayahNumber!,
      globalAyahNumber: state.globalAyahNumber,
      overrideReciterId: newReciterId,
      autoPlay: shouldAutoPlay,
    );
  }

  Future<void> stopAndClose() async {
    _opToken++;
    try {
      await _player.stop();
    } catch (_) {}
    if (!mounted) return;
    state = QuranAudioState(reciterId: state.reciterId);
  }
}

final quranAudioProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>((ref) {
  return QuranAudioNotifier(ref);
});
