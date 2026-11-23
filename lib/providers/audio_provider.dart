import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/api_config.dart';
import '../models/surah_model.dart';
import 'quran_providers.dart';

class QuranAudioState {
  final bool isVisible;
  final int? surahNumber;
  final int? ayahNumber;
  final int? globalAyahNumber;
  final SurahSummary? summary;
  final bool isPlaying;
  final bool isBuffering;
  final bool repeatAyah;
  final String? errorMessage;
  final Duration position;
  final Duration duration;

  const QuranAudioState({
    this.isVisible = false,
    this.surahNumber,
    this.ayahNumber,
    this.globalAyahNumber,
    this.summary,
    this.isPlaying = false,
    this.isBuffering = false,
    this.repeatAyah = false,
    this.errorMessage,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  QuranAudioState copyWith({
    bool? isVisible,
    int? surahNumber,
    int? ayahNumber,
    int? globalAyahNumber,
    SurahSummary? summary,
    bool? isPlaying,
    bool? isBuffering,
    bool? repeatAyah,
    String? errorMessage,
    bool clearError = false,
    Duration? position,
    Duration? duration,
  }) {
    return QuranAudioState(
      isVisible: isVisible ?? this.isVisible,
      surahNumber: surahNumber ?? this.surahNumber,
      ayahNumber: ayahNumber ?? this.ayahNumber,
      globalAyahNumber: globalAyahNumber ?? this.globalAyahNumber,
      summary: summary ?? this.summary,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      repeatAyah: repeatAyah ?? this.repeatAyah,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  final Ref _ref;
  final AudioPlayer _player = AudioPlayer();
  final Map<int, SurahDetail> _loadedSurahs = {};

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  int _playbackSerial = 0;

  QuranAudioNotifier(this._ref) : super(const QuranAudioState()) {
    _bindListeners();
  }

  void _bindListeners() {
    _playerStateSub = _player.onPlayerStateChanged.listen((playerState) {
      if (!mounted) return;
      state = state.copyWith(
        isPlaying: playerState == PlayerState.playing,
        isBuffering: false,
      );
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (!mounted) return;
      state = state.copyWith(position: pos);
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (!mounted) return;
      state = state.copyWith(duration: dur);
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      unawaited(_handleTrackCompleted());
    });
  }

  void registerLoadedSurahs(List<SurahDetail> surahs) {
    for (final s in surahs) {
      _loadedSurahs[s.summary.number] = s;
    }
  }

  Future<void> playOrToggleAyah({
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
    SurahSummary? summary,
  }) async {
    final isSameAyah = state.isVisible &&
        state.surahNumber == surahNumber &&
        state.ayahNumber == ayahNumber;

    if (isSameAyah) {
      await togglePlayPause();
      return;
    }

    await _startAyahPlayback(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
      summary: summary ?? _loadedSurahs[surahNumber]?.summary,
    );
  }

  Future<void> _startAyahPlayback({
    required int surahNumber,
    required int ayahNumber,
    required int globalAyahNumber,
    SurahSummary? summary,
  }) async {
    final serial = ++_playbackSerial;
    final reciterId = _ref.read(settingsProvider).reciterId;
    final reciter = ApiConfig.reciterById(reciterId);

    state = state.copyWith(
      isVisible: true,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      globalAyahNumber: globalAyahNumber,
      summary: summary ?? _loadedSurahs[surahNumber]?.summary,
      isPlaying: false,
      isBuffering: true,
      clearError: true,
      position: Duration.zero,
      duration: Duration.zero,
    );

    final primaryUrl = reciter.alQuranCloudUrl(globalAyahNumber);
    final fallbackUrl = reciter.everyAyahUrl(surahNumber, ayahNumber);

    try {
      await _player.stop();
      if (serial != _playbackSerial || !mounted) return;
      await _player.play(UrlSource(primaryUrl));
      if (serial != _playbackSerial || !mounted) return;
      state = state.copyWith(isPlaying: true, isBuffering: false);
    } catch (_) {
      try {
        if (serial != _playbackSerial || !mounted) return;
        await _player.stop();
        await _player.play(UrlSource(fallbackUrl));
        if (serial != _playbackSerial || !mounted) return;
        state = state.copyWith(isPlaying: true, isBuffering: false);
      } catch (_) {
        if (serial != _playbackSerial || !mounted) return;
        final err = _ref.read(stringsProvider).audioLoadError;
        state = state.copyWith(
          isPlaying: false,
          isBuffering: false,
          errorMessage: err,
        );
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (!state.isVisible) return;
    if (state.isPlaying) {
      try {
        await _player.pause();
        if (mounted) {
          state = state.copyWith(isPlaying: false, isBuffering: false);
        }
      } catch (_) {}
      return;
    }

    if (state.errorMessage != null &&
        state.surahNumber != null &&
        state.ayahNumber != null &&
        state.globalAyahNumber != null) {
      await _startAyahPlayback(
        surahNumber: state.surahNumber!,
        ayahNumber: state.ayahNumber!,
        globalAyahNumber: state.globalAyahNumber!,
        summary: state.summary,
      );
      return;
    }

    try {
      await _player.resume();
      if (mounted) {
        state = state.copyWith(
          isPlaying: true,
          isBuffering: false,
          clearError: true,
        );
      }
    } catch (_) {
      if (state.surahNumber != null &&
          state.ayahNumber != null &&
          state.globalAyahNumber != null) {
        await _startAyahPlayback(
          surahNumber: state.surahNumber!,
          ayahNumber: state.ayahNumber!,
          globalAyahNumber: state.globalAyahNumber!,
          summary: state.summary,
        );
      }
    }
  }

  Future<void> _handleTrackCompleted() async {
    if (!state.isVisible) return;
    if (state.repeatAyah &&
        state.surahNumber != null &&
        state.ayahNumber != null &&
        state.globalAyahNumber != null) {
      await _startAyahPlayback(
        surahNumber: state.surahNumber!,
        ayahNumber: state.ayahNumber!,
        globalAyahNumber: state.globalAyahNumber!,
        summary: state.summary,
      );
      return;
    }
    await playNextAyah(fromAutoAdvance: true);
  }

  Future<SurahDetail?> _resolveSurahDetail(int surahNumber) async {
    final cached = _loadedSurahs[surahNumber];
    if (cached != null) return cached;
    try {
      final settings = _ref.read(settingsProvider);
      final fetched = await _ref.read(apiServiceProvider).fetchSurahDetail(
            surahNumber: surahNumber,
            requiredTranslations: settings.showTranslation
                ? settings.selectedTranslations
                : const [],
          );
      _loadedSurahs[surahNumber] = fetched;
      return fetched;
    } catch (_) {
      return null;
    }
  }

  Future<void> playNextAyah({bool fromAutoAdvance = false}) async {
    final sNo = state.surahNumber;
    final aNo = state.ayahNumber;
    if (sNo == null || aNo == null) return;

    final currentSurah = await _resolveSurahDetail(sNo);
    if (currentSurah != null) {
      final idx = currentSurah.ayahs.indexWhere((a) => a.numberInSurah == aNo);
      if (idx >= 0 && idx + 1 < currentSurah.ayahs.length) {
        final next = currentSurah.ayahs[idx + 1];
        await _startAyahPlayback(
          surahNumber: sNo,
          ayahNumber: next.numberInSurah,
          globalAyahNumber: next.globalNumber,
          summary: currentSurah.summary,
        );
        return;
      }
    }

    if (sNo < 114) {
      final nextSurah = await _resolveSurahDetail(sNo + 1);
      if (nextSurah != null && nextSurah.ayahs.isNotEmpty) {
        final first = nextSurah.ayahs.first;
        await _startAyahPlayback(
          surahNumber: nextSurah.summary.number,
          ayahNumber: first.numberInSurah,
          globalAyahNumber: first.globalNumber,
          summary: nextSurah.summary,
        );
        return;
      }
    }

    if (fromAutoAdvance && mounted) {
      state = state.copyWith(
        isPlaying: false,
        isBuffering: false,
        position: Duration.zero,
      );
    }
  }

  Future<void> playPreviousAyah() async {
    final sNo = state.surahNumber;
    final aNo = state.ayahNumber;
    if (sNo == null || aNo == null) return;

    final currentSurah = await _resolveSurahDetail(sNo);
    if (currentSurah != null) {
      final idx = currentSurah.ayahs.indexWhere((a) => a.numberInSurah == aNo);
      if (idx > 0) {
        final prev = currentSurah.ayahs[idx - 1];
        await _startAyahPlayback(
          surahNumber: sNo,
          ayahNumber: prev.numberInSurah,
          globalAyahNumber: prev.globalNumber,
          summary: currentSurah.summary,
        );
        return;
      }
    }

    if (sNo > 1) {
      final prevSurah = await _resolveSurahDetail(sNo - 1);
      if (prevSurah != null && prevSurah.ayahs.isNotEmpty) {
        final last = prevSurah.ayahs.last;
        await _startAyahPlayback(
          surahNumber: prevSurah.summary.number,
          ayahNumber: last.numberInSurah,
          globalAyahNumber: last.globalNumber,
          summary: prevSurah.summary,
        );
      }
    }
  }

  void toggleRepeatAyah() {
    state = state.copyWith(repeatAyah: !state.repeatAyah);
  }

  Future<void> onReciterChanged(String reciterId) async {
    if (!state.isVisible ||
        state.surahNumber == null ||
        state.ayahNumber == null ||
        state.globalAyahNumber == null) {
      return;
    }
    await _startAyahPlayback(
      surahNumber: state.surahNumber!,
      ayahNumber: state.ayahNumber!,
      globalAyahNumber: state.globalAyahNumber!,
      summary: state.summary,
    );
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (_) {}
  }

  Future<void> stopAndClose() async {
    _playbackSerial++;
    try {
      await _player.stop();
    } catch (_) {}
    if (mounted) {
      state = const QuranAudioState();
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }
}

final quranAudioProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>(
  (ref) => QuranAudioNotifier(ref),
);
