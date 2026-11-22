import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/api_config.dart';
import '../core/l10n/app_strings.dart';
import '../models/surah_model.dart';
import '../providers/audio_provider.dart';
import '../providers/quran_providers.dart';
import '../services/storage_service.dart';
import '../widgets/audio_player_bar.dart';
import '../widgets/quick_reader_controls.dart';
import 'settings_screen.dart';

class _MushafPageSegment {
  final SurahDetail detail;
  final bool startsHere;
  final List<int> ayahIndices;

  const _MushafPageSegment({
    required this.detail,
    required this.startsHere,
    required this.ayahIndices,
  });
}

class _ReaderBlock {
  final String type; // 'surah_header' | 'mushaf_page' | 'verse_row'
  final SurahDetail detail;
  final int? pageNumber;
  final int? juzNumber;
  final List<_MushafPageSegment>? segments;
  final int? ayahIndex;

  const _ReaderBlock({
    required this.type,
    required this.detail,
    this.pageNumber,
    this.juzNumber,
    this.segments,
    this.ayahIndex,
  });
}

class _ReaderTextStyles {
  final TextStyle surahTitle;
  final TextStyle bismillah;
  final TextStyle arabicBase;
  final TextStyle arabicMarker;
  final TextStyle mlTranslation;
  final TextStyle arTafsir;
  final TextStyle enTranslation;

  const _ReaderTextStyles({
    required this.surahTitle,
    required this.bismillah,
    required this.arabicBase,
    required this.arabicMarker,
    required this.mlTranslation,
    required this.arTafsir,
    required this.enTranslation,
  });

  TextStyle forTranslation(String code) {
    if (code == 'ml') return mlTranslation;
    if (code == 'ar') return arTafsir;
    return enTranslation;
  }
}

class _MountedBlockInfo {
  final String id;
  final _ReaderBlock block;
  final bool isForward;
  final int listIndex;
  final BuildContext context;

  const _MountedBlockInfo({
    required this.id,
    required this.block,
    required this.isForward,
    required this.listIndex,
    required this.context,
  });
}

class _MountedSegmentInfo {
  final int pageNumber;
  final int surahNumber;
  final _MushafPageSegment segment;
  final BuildContext context;

  const _MountedSegmentInfo({
    required this.pageNumber,
    required this.surahNumber,
    required this.segment,
    required this.context,
  });
}

class _MountedAyahInfo {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  final BuildContext context;

  const _MountedAyahInfo({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
    required this.context,
  });
}

class _CapturedReadingPosition {
  final SurahSummary summary;
  final int ayahNumber;
  final int? pageNumber;
  final double anchorOffsetPx;
  final String readingMode;

  const _CapturedReadingPosition({
    required this.summary,
    required this.ayahNumber,
    this.pageNumber,
    required this.anchorOffsetPx,
    required this.readingMode,
  });
}

class SurahReaderScreen extends ConsumerStatefulWidget {
  final int initialSurahNumber;
  final int? initialAyahNumber;
  final double? initialAnchorOffsetPx;
  final String? initialSavedReadingMode;

  const SurahReaderScreen({
    super.key,
    required this.initialSurahNumber,
    this.initialAyahNumber,
    this.initialAnchorOffsetPx,
    this.initialSavedReadingMode,
  });

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final Key _centerKey = const ValueKey<String>('reader_center_sliver');
  GlobalKey? _scrollViewKeyBacking;
  GlobalKey get _scrollViewKey => _scrollViewKeyBacking ??= GlobalKey();

  /// Forward list: [initialSurah, initial+1, initial+2, ...] (scrolls down)
  final List<SurahDetail> _forwardSurahs = [];

  /// Backward list: [initial-1, initial-2, ...] (scrolls up from end of prev Surah)
  final List<SurahDetail> _backwardSurahs = [];

  /// Cached block lists recomputed only when Surahs or readingMode change
  List<_ReaderBlock> _forwardBlocks = const [];
  List<_ReaderBlock> _backwardBlocks = const [];
  String _cachedBlockMode = '';

  /// Mounted block, segment, and ayah trackers for zero-overhead exact viewport measurement
  Map<String, _MountedBlockInfo>? _mountedBlocksBacking;
  Map<String, _MountedSegmentInfo>? _mountedSegmentsBacking;
  Map<String, _MountedAyahInfo>? _mountedAyahsBacking;
  Map<String, _MountedBlockInfo> get _mountedBlocks =>
      _mountedBlocksBacking ??= {};
  Map<String, _MountedSegmentInfo> get _mountedSegments =>
      _mountedSegmentsBacking ??= {};
  Map<String, _MountedAyahInfo> get _mountedAyahs =>
      _mountedAyahsBacking ??= {};
  Map<String, BuildContext>? _playingAyahAnchorsBacking;
  Map<String, BuildContext> get _playingAyahAnchors =>
      _playingAyahAnchorsBacking ??= {};
  Map<String, BuildContext>? _playingAyahStartAnchorsBacking;
  Map<String, BuildContext> get _playingAyahStartAnchors =>
      _playingAyahStartAnchorsBacking ??= {};
  final Map<int, GlobalKey> _headerKeys = {};

  /// Isolated AppBar header notifier so Surah transitions never rebuild the scroll view
  final ValueNotifier<SurahSummary?> _headerSummaryNotifier =
      ValueNotifier<SurahSummary?>(null);

  /// Isolated auto-scroll active state so toggling Play/Pause never rebuilds Quran text
  final ValueNotifier<bool> _isAutoScrollingNotifier = ValueNotifier<bool>(false);

  bool _isInitialLoading = true;
  bool _isLoadingNext = false;
  bool _isLoadingPrev = false;
  bool? _isRestoringPositionBacking;
  bool get _isRestoringPosition => _isRestoringPositionBacking ?? false;
  set _isRestoringPosition(bool v) => _isRestoringPositionBacking = v;

  bool? _isPoppingToHomeBacking;
  bool get _isPoppingToHome => _isPoppingToHomeBacking ?? false;
  set _isPoppingToHome(bool v) => _isPoppingToHomeBacking = v;

  String? _errorText;
  String _loadedTransKey = '';

  // Vsync-synchronized auto-scroll state
  late final Ticker _autoScrollTicker;
  late final QuranAudioNotifier _audioNotifier;
  Duration _lastTickElapsed = Duration.zero;
  DateTime _lastHeaderCheck = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _saveDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioNotifier = ref.read(quranAudioProvider.notifier);
    _autoScrollTicker = createTicker(_onAutoScrollTick);
    _scrollController.addListener(_onScroll);
    _loadInitialSurah();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveDebounceTimer?.cancel();
    _autoScrollTicker.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerSummaryNotifier.dispose();
    _isAutoScrollingNotifier.dispose();
    Future.microtask(() {
      if (_audioNotifier.mounted) {
        _audioNotifier.stopAndClose();
      }
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _persistCurrentReadingPosition(markReaderActive: !_isPoppingToHome);
    }
  }

  List<String> _requiredTranslations(AppSettings s) {
    if (!s.showTranslation) return const [];
    return s.selectedTranslations;
  }

  void _rebuildBlockCaches(String readingMode) {
    _cachedBlockMode = readingMode;
    if (readingMode == 'mushaf') {
      _forwardBlocks = _buildUnifiedMushafBlocks(_forwardSurahs);
      _backwardBlocks =
          _buildUnifiedMushafBlocks(_backwardSurahs.reversed.toList())
              .reversed
              .toList();
      return;
    }

    final fwd = <_ReaderBlock>[];
    for (final s in _forwardSurahs) {
      fwd.addAll(_blocksForVerseSurah(s));
    }
    final bwd = <_ReaderBlock>[];
    for (final s in _backwardSurahs) {
      final normalOrder = _blocksForVerseSurah(s);
      bwd.addAll(normalOrder.reversed);
    }
    _forwardBlocks = fwd;
    _backwardBlocks = bwd;
  }

  List<_ReaderBlock> _buildUnifiedMushafBlocks(List<SurahDetail> surahs) {
    if (surahs.isEmpty) return const [];

    final blocks = <_ReaderBlock>[];
    int? activePage;
    int activeJuz = 1;
    List<_MushafPageSegment> activeSegments = [];

    void flushPage(SurahDetail refDetail) {
      if (activePage == null || activeSegments.isEmpty) return;
      blocks.add(
        _ReaderBlock(
          type: 'mushaf_page',
          detail: refDetail,
          pageNumber: activePage,
          juzNumber: activeJuz,
          segments: List<_MushafPageSegment>.from(activeSegments),
        ),
      );
      activeSegments = [];
    }

    for (final s in surahs) {
      int? segPage;
      List<int> segIndices = [];

      void commitSegment() {
        if (segPage == null || segIndices.isEmpty) return;
        if (activePage != null && activePage != segPage) {
          flushPage(s);
        }
        if (activePage != segPage) {
          activePage = segPage;
          activeJuz = s.ayahs[segIndices.first].juz;
        }
        activeSegments.add(
          _MushafPageSegment(
            detail: s,
            startsHere: segIndices.first == 0,
            ayahIndices: List<int>.from(segIndices),
          ),
        );
        segIndices = [];
      }

      for (int i = 0; i < s.ayahs.length; i++) {
        final p = s.ayahs[i].page;
        if (segPage == null) {
          segPage = p;
          segIndices = [i];
        } else if (p == segPage) {
          segIndices.add(i);
        } else {
          commitSegment();
          segPage = p;
          segIndices = [i];
        }
      }
      commitSegment();
    }

    if (surahs.isNotEmpty) {
      flushPage(surahs.last);
    }
    return blocks;
  }

  String _blockId(_ReaderBlock block) {
    if (block.type == 'surah_header') {
      return 'h_${block.detail.summary.number}';
    }
    if (block.type == 'mushaf_page') {
      final firstSeg = block.segments!.first;
      return 'p_${block.pageNumber}_${firstSeg.detail.summary.number}_${firstSeg.ayahIndices.first}';
    }
    final ayah = block.detail.ayahs[block.ayahIndex!];
    return 'v_${block.detail.summary.number}_${ayah.numberInSurah}';
  }

  bool _isTargetAyahBlock(_ReaderBlock block, int targetSurah, int targetAyah) {
    if (block.type == 'mushaf_page' && block.segments != null) {
      for (final seg in block.segments!) {
        if (seg.detail.summary.number != targetSurah) continue;
        for (final idx in seg.ayahIndices) {
          if (seg.detail.ayahs[idx].numberInSurah == targetAyah) {
            return true;
          }
        }
      }
    } else if (block.type == 'verse_row' && block.ayahIndex != null) {
      if (block.detail.summary.number == targetSurah &&
          block.detail.ayahs[block.ayahIndex!].numberInSurah == targetAyah) {
        return true;
      }
    }
    return false;
  }

  Future<void> _restoreInitialTargetPosition({
    required int targetSurah,
    required int targetAyah,
    required double? anchorOffsetPx,
    required String? savedReadingMode,
  }) async {
    if (!mounted || !_scrollController.hasClients || _forwardBlocks.isEmpty) {
      return;
    }

    final currentMode = ref.read(settingsProvider).readingMode;
    final bool canUseExactPixelDelta = anchorOffsetPx != null &&
        (savedReadingMode == null || savedReadingMode == currentMode);

    int targetIndex = -1;
    if (targetAyah == 1 && anchorOffsetPx == null) {
      targetIndex = _forwardBlocks.indexWhere(
        (b) => b.type == 'surah_header' && b.detail.summary.number == targetSurah,
      );
    }
    if (targetIndex < 0) {
      targetIndex = _forwardBlocks.indexWhere(
        (b) => _isTargetAyahBlock(b, targetSurah, targetAyah),
      );
    }
    if (targetIndex < 0) return;

    final targetId = _blockId(_forwardBlocks[targetIndex]);
    _isRestoringPosition = true;

    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !_scrollController.hasClients) return;

      // Guided convergence until the exact target block is mounted in the viewport
      if (!_mountedBlocks.containsKey(targetId) && targetIndex > 0) {
        final pos = _scrollController.position;
        final initialApprox =
            ((targetIndex / _forwardBlocks.length) * pos.maxScrollExtent)
                .clamp(pos.minScrollExtent, pos.maxScrollExtent);
        _scrollController.jumpTo(initialApprox);

        for (int attempt = 0; attempt < 10; attempt++) {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || !_scrollController.hasClients) return;
          if (_mountedBlocks.containsKey(targetId)) break;

          final viewportBox =
              _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
          final viewportH =
              (viewportBox != null && viewportBox.hasSize) ? viewportBox.size.height : 600.0;

          int? minMountedIdx;
          int? maxMountedIdx;
          double totalHeight = 0.0;
          int count = 0;

          for (final info in _mountedBlocks.values) {
            if (!info.isForward) continue;
            if (minMountedIdx == null || info.listIndex < minMountedIdx) {
              minMountedIdx = info.listIndex;
            }
            if (maxMountedIdx == null || info.listIndex > maxMountedIdx) {
              maxMountedIdx = info.listIndex;
            }
            if (!info.context.mounted) continue;
            final box = info.context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              totalHeight += box.size.height;
              count++;
            }
          }

          final avgH = count > 0 ? (totalHeight / count) : 140.0;
          final curPos = _scrollController.position;
          double nextOffset = curPos.pixels;

          if (maxMountedIdx != null && targetIndex > maxMountedIdx) {
            final deltaBlocks = targetIndex - maxMountedIdx;
            final step = math.max(viewportH * 0.65, deltaBlocks * avgH);
            nextOffset = curPos.pixels + step;
          } else if (minMountedIdx != null && targetIndex < minMountedIdx) {
            final deltaBlocks = minMountedIdx - targetIndex;
            final step = math.max(viewportH * 0.65, deltaBlocks * avgH);
            nextOffset = curPos.pixels - step;
          } else {
            nextOffset =
                (targetIndex / _forwardBlocks.length) * curPos.maxScrollExtent;
          }

          final clamped =
              nextOffset.clamp(curPos.minScrollExtent, curPos.maxScrollExtent);
          if ((clamped - curPos.pixels).abs() < 1.0) break;
          _scrollController.jumpTo(clamped);
        }
      }

      // Apply exact pixel delta relative to the viewport top
      for (int refine = 0; refine < 2; refine++) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted || !_scrollController.hasClients) return;

        final viewportBox =
            _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
        final targetInfo = _mountedBlocks[targetId];
        if (viewportBox == null || !viewportBox.hasSize || targetInfo == null) {
          break;
        }
        if (!targetInfo.context.mounted) break;
        final targetBox = targetInfo.context.findRenderObject() as RenderBox?;
        if (targetBox == null || !targetBox.hasSize || !targetBox.attached) {
          break;
        }

        final viewportTopY = viewportBox.localToGlobal(Offset.zero).dy;
        final blockTopRel =
            targetBox.localToGlobal(Offset.zero).dy - viewportTopY;

        final double desiredDelta =
            canUseExactPixelDelta ? anchorOffsetPx : -10.0;
        final double error = blockTopRel + desiredDelta;
        if (error.abs() <= 1.0) break;

        final curPos = _scrollController.position;
        final desiredOffset = (curPos.pixels + error)
            .clamp(curPos.minScrollExtent, curPos.maxScrollExtent);
        if ((desiredOffset - curPos.pixels).abs() < 0.5) break;
        _scrollController.jumpTo(desiredOffset);
      }

      if (mounted) {
        _syncActiveHeaderFromViewport();
        _persistCurrentReadingPosition(markReaderActive: true);
      }
    } finally {
      _isRestoringPosition = false;
    }
  }

  Future<void> _loadInitialSurah() async {
    setState(() {
      _isInitialLoading = true;
      _errorText = null;
    });
    try {
      final settings =
          await ref.read(settingsProvider.notifier).ensureLoaded();
      final reqTrans = _requiredTranslations(settings);
      _loadedTransKey = reqTrans.join(',');
      final api = ref.read(apiServiceProvider);

      final detail = await api.fetchSurahDetail(
        surahNumber: widget.initialSurahNumber,
        requiredTranslations: reqTrans,
      );

      // Complete the Mushaf page if preceding short Surah(s) share the same starting page
      final prepended = <SurahDetail>[];
      final initialBackward = <SurahDetail>[];
      if (detail.ayahs.isNotEmpty && widget.initialSurahNumber > 1) {
        final anchorPage = detail.ayahs.first.page;
        int prevNum = widget.initialSurahNumber - 1;
        while (prevNum >= 1 && prepended.length < 4) {
          try {
            final prevDetail = await api.fetchSurahDetail(
              surahNumber: prevNum,
              requiredTranslations: reqTrans,
            );
            if (prevDetail.ayahs.isNotEmpty &&
                prevDetail.ayahs.last.page == anchorPage) {
              prepended.insert(0, prevDetail);
              prevNum--;
            } else {
              initialBackward.add(prevDetail);
              break;
            }
          } catch (_) {
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _forwardSurahs
          ..clear()
          ..addAll(prepended)
          ..add(detail);
        _backwardSurahs
          ..clear()
          ..addAll(initialBackward);
        for (final s in _forwardSurahs) {
          _headerKeys[s.summary.number] = GlobalKey();
        }
        for (final s in _backwardSurahs) {
          _headerKeys[s.summary.number] = GlobalKey();
        }
        _headerSummaryNotifier.value = detail.summary;
        _rebuildBlockCaches(settings.readingMode);
        _isInitialLoading = false;
      });
      _audioNotifier.registerLoadedSurahs([..._backwardSurahs, ..._forwardSurahs]);

      final int targetAyah = widget.initialAyahNumber ?? 1;
      final bool hasExplicitTarget = targetAyah > 1 ||
          widget.initialAnchorOffsetPx != null ||
          prepended.isNotEmpty;

      if (hasExplicitTarget) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _restoreInitialTargetPosition(
            targetSurah: widget.initialSurahNumber,
            targetAyah: targetAyah,
            anchorOffsetPx: widget.initialAnchorOffsetPx,
            savedReadingMode: widget.initialSavedReadingMode,
          );
        });
      } else {
        final initialPage =
            detail.ayahs.isNotEmpty ? detail.ayahs.first.page : null;
        final initialPos = LastReadPosition(
          surahNumber: detail.summary.number,
          surahName: detail.summary.englishName,
          surahArabicName: detail.summary.nameArabic,
          ayahNumber: targetAyah,
          pageNumber: initialPage,
          anchorOffsetPx: 0.0,
          readingMode: settings.readingMode,
        );
        ref.read(lastReadProvider.notifier).setPosition(initialPos);
        ref.read(appResumeProvider.notifier).setReaderActive(
              surahNumber: detail.summary.number,
              ayahNumber: targetAyah,
              pageNumber: initialPage,
              anchorOffsetPx: 0.0,
              readingMode: settings.readingMode,
            );
      }

      // Quietly pre-warm next Surah in cache for seamless forward scroll
      if (widget.initialSurahNumber < 114) {
        _loadNextSurahIfNeeded();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString();
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _reloadLoadedSurahsForTranslations(AppSettings settings) async {
    if (_forwardSurahs.isEmpty) return;
    final reqTrans = _requiredTranslations(settings);
    final newKey = reqTrans.join(',');
    if (newKey == _loadedTransKey) return;
    _loadedTransKey = newKey;

    try {
      final fwdNums = _forwardSurahs.map((s) => s.summary.number).toList();
      final bwdNums = _backwardSurahs.map((s) => s.summary.number).toList();

      final updatedFwd = await Future.wait(
        fwdNums.map(
          (n) => ref.read(apiServiceProvider).fetchSurahDetail(
                surahNumber: n,
                requiredTranslations: reqTrans,
              ),
        ),
      );
      final updatedBwd = await Future.wait(
        bwdNums.map(
          (n) => ref.read(apiServiceProvider).fetchSurahDetail(
                surahNumber: n,
                requiredTranslations: reqTrans,
              ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _forwardSurahs
          ..clear()
          ..addAll(updatedFwd);
        _backwardSurahs
          ..clear()
          ..addAll(updatedBwd);
        _rebuildBlockCaches(settings.readingMode);
      });
    } catch (_) {
      // Keep existing Surahs if offline
    }
  }

  Future<void> _loadNextSurahIfNeeded() async {
    if (_isLoadingNext || _forwardSurahs.isEmpty) return;
    final nextNumber = _forwardSurahs.last.summary.number + 1;
    if (nextNumber > 114) return;

    setState(() => _isLoadingNext = true);
    try {
      final settings = ref.read(settingsProvider);
      final nextDetail = await ref.read(apiServiceProvider).fetchSurahDetail(
            surahNumber: nextNumber,
            requiredTranslations: _requiredTranslations(settings),
          );
      if (!mounted) return;
      setState(() {
        _forwardSurahs.add(nextDetail);
        _headerKeys[nextDetail.summary.number] = GlobalKey();
        _rebuildBlockCaches(settings.readingMode);
        _isLoadingNext = false;
      });
      _audioNotifier.registerLoadedSurahs([nextDetail]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingNext = false);
    }
  }

  Future<void> _loadPrevSurahIfNeeded() async {
    if (_isLoadingPrev || _forwardSurahs.isEmpty) return;
    final earliestLoaded = _backwardSurahs.isNotEmpty
        ? _backwardSurahs.last.summary.number
        : _forwardSurahs.first.summary.number;
    final prevNumber = earliestLoaded - 1;
    if (prevNumber < 1) return;

    setState(() => _isLoadingPrev = true);
    try {
      final settings = ref.read(settingsProvider);
      final prevDetail = await ref.read(apiServiceProvider).fetchSurahDetail(
            surahNumber: prevNumber,
            requiredTranslations: _requiredTranslations(settings),
          );
      if (!mounted) return;
      setState(() {
        _backwardSurahs.add(prevDetail);
        _headerKeys[prevDetail.summary.number] = GlobalKey();
        _rebuildBlockCaches(settings.readingMode);
        _isLoadingPrev = false;
      });
      _audioNotifier.registerLoadedSurahs([prevDetail]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrev = false);
    }
  }

  Future<void> _syncViewportToPlayingAyah(int surahNo, int ayahNo) async {
    if (!mounted || _isInitialLoading || _forwardSurahs.isEmpty) return;

    while (mounted &&
        _forwardSurahs.isNotEmpty &&
        surahNo > _forwardSurahs.last.summary.number &&
        _forwardSurahs.last.summary.number < 114) {
      final prevLast = _forwardSurahs.last.summary.number;
      await _loadNextSurahIfNeeded();
      if (!mounted || _forwardSurahs.last.summary.number <= prevLast) break;
    }

    int earliestLoaded = _backwardSurahs.isNotEmpty
        ? _backwardSurahs.last.summary.number
        : _forwardSurahs.first.summary.number;
    while (mounted && surahNo < earliestLoaded && earliestLoaded > 1) {
      await _loadPrevSurahIfNeeded();
      if (!mounted) return;
      final nextEarliest = _backwardSurahs.isNotEmpty
          ? _backwardSurahs.last.summary.number
          : _forwardSurahs.first.summary.number;
      if (nextEarliest >= earliestLoaded) break;
      earliestLoaded = nextEarliest;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;

    final anchorKey = '${surahNo}_$ayahNo';
    final viewportBox =
        _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize || !viewportBox.attached) {
      return;
    }

    final viewportTopY = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportH = viewportBox.size.height;
    const double safeTopPad = 18.0;

    final startCtx =
        _playingAyahStartAnchors[anchorKey] ?? _playingAyahAnchors[anchorKey];
    final endCtx = _playingAyahAnchors[anchorKey] ?? startCtx;

    if (startCtx != null && startCtx.mounted) {
      final startBox = startCtx.findRenderObject() as RenderBox?;
      final endBox = (endCtx != null && endCtx.mounted)
          ? endCtx.findRenderObject() as RenderBox?
          : null;
      if (startBox != null && startBox.hasSize && startBox.attached) {
        final startTopRel =
            startBox.localToGlobal(Offset.zero).dy - viewportTopY;
        final endBottomRel = (endBox != null && endBox.hasSize && endBox.attached)
            ? (endBox.localToGlobal(Offset.zero).dy +
                endBox.size.height -
                viewportTopY)
            : (startTopRel + startBox.size.height);

        final double ayahHeight = math.max(0.0, endBottomRel - startTopRel);
        final bool fitsCompletely =
            startTopRel >= safeTopPad && endBottomRel <= viewportH - 20.0;
        final bool tallAyahPinnedCleanly =
            ayahHeight > (viewportH - 44.0) &&
            startTopRel >= safeTopPad &&
            startTopRel <= 48.0;

        if (fitsCompletely || tallAyahPinnedCleanly) {
          return;
        }

        final double targetStartY = ayahHeight > viewportH * 0.65
            ? safeTopPad
            : math.max(safeTopPad, math.min(44.0, viewportH * 0.08));
        final desiredOffset =
            (_scrollController.offset + (startTopRel - targetStartY)).clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );
        if ((desiredOffset - _scrollController.offset).abs() > 1.0) {
          await _scrollController.animateTo(
            desiredOffset,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
        return;
      }
    }

    // Off-screen target: converge cleanly to the block in forward list, then refine.
    await _restoreInitialTargetPosition(
      targetSurah: surahNo,
      targetAyah: ayahNo,
      anchorOffsetPx: null,
      savedReadingMode: null,
    );
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !_scrollController.hasClients) return;
    final postViewportBox =
        _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (postViewportBox == null ||
        !postViewportBox.hasSize ||
        !postViewportBox.attached) {
      return;
    }
    final postViewportTopY = postViewportBox.localToGlobal(Offset.zero).dy;
    final postViewportH = postViewportBox.size.height;
    final postStartCtx =
        _playingAyahStartAnchors[anchorKey] ?? _playingAyahAnchors[anchorKey];
    final postEndCtx = _playingAyahAnchors[anchorKey] ?? postStartCtx;
    if (postStartCtx != null && postStartCtx.mounted) {
      final startBox = postStartCtx.findRenderObject() as RenderBox?;
      final endBox = (postEndCtx != null && postEndCtx.mounted)
          ? postEndCtx.findRenderObject() as RenderBox?
          : null;
      if (startBox != null && startBox.hasSize && startBox.attached) {
        final startTopRel =
            startBox.localToGlobal(Offset.zero).dy - postViewportTopY;
        final endBottomRel = (endBox != null && endBox.hasSize && endBox.attached)
            ? (endBox.localToGlobal(Offset.zero).dy +
                endBox.size.height -
                postViewportTopY)
            : (startTopRel + startBox.size.height);
        final double ayahHeight = math.max(0.0, endBottomRel - startTopRel);
        if (startTopRel < safeTopPad || endBottomRel > postViewportH - 20.0) {
          final double targetStartY = ayahHeight > postViewportH * 0.65
              ? safeTopPad
              : math.max(safeTopPad, math.min(44.0, postViewportH * 0.08));
          final desiredOffset =
              (_scrollController.offset + (startTopRel - targetStartY)).clamp(
            _scrollController.position.minScrollExtent,
            _scrollController.position.maxScrollExtent,
          );
          _scrollController.jumpTo(desiredOffset);
        }
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    // Trigger next Surah when scrolling near bottom
    if (pos.pixels >= pos.maxScrollExtent - 750) {
      _loadNextSurahIfNeeded();
    }
    // Trigger previous Surah when scrolling near top
    if (pos.pixels <= pos.minScrollExtent + 750) {
      _loadPrevSurahIfNeeded();
    }

    if (_isRestoringPosition) return;

    // Throttled, flicker-free header detection (runs at most once every 120ms)
    final now = DateTime.now();
    if (now.difference(_lastHeaderCheck).inMilliseconds >= 120) {
      _lastHeaderCheck = now;
      _syncActiveHeaderFromViewport();
    }

    // Debounced persistence while continuously scrolling
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && !_isRestoringPosition) {
        _persistCurrentReadingPosition(markReaderActive: !_isPoppingToHome);
      }
    });
  }

  _CapturedReadingPosition? _captureVisibleReadingPosition() {
    final viewportBox =
        _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null || !viewportBox.hasSize || !viewportBox.attached) {
      return null;
    }

    final viewportTopY = viewportBox.localToGlobal(Offset.zero).dy;
    final viewportH = viewportBox.size.height;
    const double readingLineY = 14.0;

    _MountedBlockInfo? spanningBlock;
    double spanningTop = double.negativeInfinity;
    _MountedBlockInfo? nextBelowBlock;
    double nextBelowTop = double.infinity;
    _MountedBlockInfo? fallbackVisible;
    double fallbackDist = double.infinity;

    for (final info in _mountedBlocks.values) {
      final box = info.context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) continue;
      final topY = box.localToGlobal(Offset.zero).dy - viewportTopY;
      final bottomY = topY + box.size.height;

      if (topY <= readingLineY && bottomY > readingLineY) {
        if (topY > spanningTop) {
          spanningTop = topY;
          spanningBlock = info;
        }
      } else if (topY > readingLineY && topY < viewportH) {
        if (topY < nextBelowTop) {
          nextBelowTop = topY;
          nextBelowBlock = info;
        }
      }

      if (bottomY > 0 && topY < viewportH) {
        final dist = (topY - readingLineY).abs();
        if (dist < fallbackDist) {
          fallbackDist = dist;
          fallbackVisible = info;
        }
      }
    }

    final chosen = spanningBlock ?? nextBelowBlock ?? fallbackVisible;
    if (chosen == null) return null;

    final chosenBox = chosen.context.findRenderObject() as RenderBox?;
    if (chosenBox == null || !chosenBox.hasSize || !chosenBox.attached) {
      return null;
    }
    final chosenTopY = chosenBox.localToGlobal(Offset.zero).dy - viewportTopY;
    final currentMode = ref.read(settingsProvider).readingMode;

    if (chosen.block.type == 'surah_header') {
      final surah = chosen.block.detail;
      final firstPage =
          surah.ayahs.isNotEmpty ? surah.ayahs.first.page : null;
      // Measure relative to Ayah 1 verse_row when mounted so header scroll offset restores identically
      double anchorOffsetPx = math.max(0.0, -chosenTopY);
      final verse1Info = _mountedBlocks['v_${surah.summary.number}_1'];
      if (verse1Info != null) {
        final v1Box = verse1Info.context.findRenderObject() as RenderBox?;
        if (v1Box != null && v1Box.hasSize && v1Box.attached) {
          final v1TopY = v1Box.localToGlobal(Offset.zero).dy - viewportTopY;
          anchorOffsetPx = -v1TopY;
        }
      }
      return _CapturedReadingPosition(
        summary: surah.summary,
        ayahNumber: 1,
        pageNumber: firstPage,
        anchorOffsetPx: anchorOffsetPx,
        readingMode: currentMode,
      );
    }

    if (chosen.block.type == 'verse_row') {
      final detail = chosen.block.detail;
      final ayah = detail.ayahs[chosen.block.ayahIndex!];
      return _CapturedReadingPosition(
        summary: detail.summary,
        ayahNumber: ayah.numberInSurah,
        pageNumber: ayah.page,
        anchorOffsetPx: math.max(0.0, -chosenTopY),
        readingMode: currentMode,
      );
    }

    // mushaf_page block
    final pageNum = chosen.block.pageNumber ?? 1;
    final segments = chosen.block.segments ?? const [];
    if (segments.isEmpty) return null;

    // Resolve which Surah segment on this Mushaf page is at readingLineY
    _MountedSegmentInfo? activeSegInfo;
    double activeSegTop = double.negativeInfinity;
    _MountedSegmentInfo? nextSegBelow;
    double nextSegBelowTop = double.infinity;

    for (final segInfo in _mountedSegments.values) {
      if (segInfo.pageNumber != pageNum) continue;
      final sBox = segInfo.context.findRenderObject() as RenderBox?;
      if (sBox == null || !sBox.hasSize || !sBox.attached) continue;
      final sTop = sBox.localToGlobal(Offset.zero).dy - viewportTopY;
      final sBottom = sTop + sBox.size.height;
      if (sTop <= readingLineY && sBottom > readingLineY) {
        if (sTop > activeSegTop) {
          activeSegTop = sTop;
          activeSegInfo = segInfo;
        }
      } else if (sTop > readingLineY && sTop < viewportH) {
        if (sTop < nextSegBelowTop) {
          nextSegBelowTop = sTop;
          nextSegBelow = segInfo;
        }
      }
    }

    final resolvedSeg =
        (activeSegInfo ?? nextSegBelow)?.segment ?? segments.first;
    final surahDetail = resolvedSeg.detail;
    int resolvedAyah = resolvedSeg.ayahIndices.isNotEmpty
        ? surahDetail.ayahs[resolvedSeg.ayahIndices.first].numberInSurah
        : 1;

    // 1. Check mounted translation Ayah rows for exact Ayah visibility when translations are shown
    _MountedAyahInfo? activeAyahInfo;
    double activeAyahTop = double.negativeInfinity;
    _MountedAyahInfo? nextAyahBelow;
    double nextAyahBelowTop = double.infinity;

    for (final ayahInfo in _mountedAyahs.values) {
      if (ayahInfo.pageNumber != pageNum ||
          ayahInfo.surahNumber != surahDetail.summary.number) {
        continue;
      }
      final aBox = ayahInfo.context.findRenderObject() as RenderBox?;
      if (aBox == null || !aBox.hasSize || !aBox.attached) continue;
      final aTop = aBox.localToGlobal(Offset.zero).dy - viewportTopY;
      final aBottom = aTop + aBox.size.height;
      if (aTop <= readingLineY && aBottom > readingLineY) {
        if (aTop > activeAyahTop) {
          activeAyahTop = aTop;
          activeAyahInfo = ayahInfo;
        }
      } else if (aTop > readingLineY && aTop < viewportH) {
        if (aTop < nextAyahBelowTop) {
          nextAyahBelowTop = aTop;
          nextAyahBelow = ayahInfo;
        }
      }
    }

    if (activeAyahInfo != null) {
      resolvedAyah = activeAyahInfo.ayahNumber;
    } else if (nextAyahBelow != null && activeSegInfo == null) {
      resolvedAyah = nextAyahBelow.ayahNumber;
    } else if (resolvedSeg.ayahIndices.length > 1) {
      // 2. Proportional ayah estimate across the segment when Arabic-only Mushaf is scrolled
      final segCtx = (activeSegInfo ?? nextSegBelow)?.context;
      final segBox = segCtx?.findRenderObject() as RenderBox?;
      final refTop = (segBox != null && segBox.hasSize)
          ? (segBox.localToGlobal(Offset.zero).dy - viewportTopY)
          : chosenTopY;
      final refH = (segBox != null && segBox.hasSize)
          ? segBox.size.height
          : chosenBox.size.height;
      if (refH > 0 && readingLineY > refTop) {
        final frac = ((readingLineY - refTop) / refH).clamp(0.0, 0.999);
        final pickIdx = (frac * resolvedSeg.ayahIndices.length)
            .floor()
            .clamp(0, resolvedSeg.ayahIndices.length - 1);
        resolvedAyah =
            surahDetail.ayahs[resolvedSeg.ayahIndices[pickIdx]].numberInSurah;
      }
    }

    return _CapturedReadingPosition(
      summary: surahDetail.summary,
      ayahNumber: resolvedAyah,
      pageNumber: pageNum,
      anchorOffsetPx: math.max(0.0, -chosenTopY),
      readingMode: currentMode,
    );
  }

  void _syncActiveHeaderFromViewport() {
    final captured = _captureVisibleReadingPosition();
    if (captured != null) {
      if (captured.summary.number != _headerSummaryNotifier.value?.number) {
        _headerSummaryNotifier.value = captured.summary;
      }
      return;
    }

    // Fallback to banner keys if no tracked block is mounted yet
    final allLoaded = <SurahDetail>[
      ..._backwardSurahs.reversed,
      ..._forwardSurahs,
    ];
    if (allLoaded.isEmpty) return;

    final Map<int, SurahSummary> byNum = {
      for (final s in allLoaded) s.summary.number: s.summary,
    };

    const double thresholdY = 150.0;
    int? highestAbove;
    int? lowestBelow;

    for (final s in allLoaded) {
      final num = s.summary.number;
      final ctx = _headerKeys[num]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= thresholdY) {
        if (highestAbove == null || num > highestAbove) {
          highestAbove = num;
        }
      } else {
        if (lowestBelow == null || num < lowestBelow) {
          lowestBelow = num;
        }
      }
    }

    int? resolvedNum;
    if (highestAbove != null) {
      resolvedNum = highestAbove;
    } else if (lowestBelow != null && byNum.containsKey(lowestBelow - 1)) {
      resolvedNum = lowestBelow - 1;
    }

    if (resolvedNum != null &&
        resolvedNum != _headerSummaryNotifier.value?.number) {
      _headerSummaryNotifier.value = byNum[resolvedNum]!;
    }
  }

  void _persistCurrentReadingPosition({required bool markReaderActive}) {
    if (_isInitialLoading || _forwardSurahs.isEmpty) return;
    final captured = _captureVisibleReadingPosition();
    if (captured == null) return;

    if (captured.summary.number != _headerSummaryNotifier.value?.number) {
      _headerSummaryNotifier.value = captured.summary;
    }

    ref.read(lastReadProvider.notifier).setPosition(
          LastReadPosition(
            surahNumber: captured.summary.number,
            surahName: captured.summary.englishName,
            surahArabicName: captured.summary.nameArabic,
            ayahNumber: captured.ayahNumber,
            pageNumber: captured.pageNumber,
            anchorOffsetPx: captured.anchorOffsetPx,
            readingMode: captured.readingMode,
          ),
        );

    if (markReaderActive) {
      ref.read(appResumeProvider.notifier).setReaderActive(
            surahNumber: captured.summary.number,
            ayahNumber: captured.ayahNumber,
            pageNumber: captured.pageNumber,
            anchorOffsetPx: captured.anchorOffsetPx,
            readingMode: captured.readingMode,
          );
    } else {
      ref.read(appResumeProvider.notifier).markReturnedHome();
    }
  }

  void _onAutoScrollTick(Duration elapsed) {
    if (!mounted || !_scrollController.hasClients) return;
    final dtMs =
        ((elapsed - _lastTickElapsed).inMicroseconds / 1000.0).clamp(0.0, 50.0);
    _lastTickElapsed = elapsed;
    if (dtMs <= 0) return;

    final speed = ref.read(settingsProvider).autoScrollSpeed;
    final step = (dtMs / 20.0) * speed * 0.9;
    final maxExt = _scrollController.position.maxScrollExtent;
    final nextOffset = _scrollController.offset + step;

    if (nextOffset >= maxExt - 650) {
      _loadNextSurahIfNeeded();
    }
    if (nextOffset >= maxExt) {
      if (_forwardSurahs.isNotEmpty &&
          _forwardSurahs.last.summary.number >= 114) {
        _stopAutoScroll();
      }
    } else {
      _scrollController.jumpTo(nextOffset);
    }
  }

  void _stopAutoScroll() {
    final wasScrolling =
        _autoScrollTicker.isActive || _isAutoScrollingNotifier.value;
    if (_autoScrollTicker.isActive) {
      _autoScrollTicker.stop();
    }
    if (_isAutoScrollingNotifier.value) {
      _isAutoScrollingNotifier.value = false;
    }
    if (wasScrolling && mounted && !_isRestoringPosition && !_isPoppingToHome) {
      _saveDebounceTimer?.cancel();
      _persistCurrentReadingPosition(markReaderActive: true);
    }
  }

  void _toggleAutoScroll() {
    if (_isAutoScrollingNotifier.value) {
      _stopAutoScroll();
      return;
    }
    _lastTickElapsed = Duration.zero;
    _isAutoScrollingNotifier.value = true;
    if (!_autoScrollTicker.isActive) {
      _autoScrollTicker.start();
    }
  }

  /// Long-press quick control modal: Auto-Scroll Speed + Arabic & Translation Font Sizes
  void _showQuickControlSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, modalRef, _) {
            final t = modalRef.watch(stringsProvider);
            return SafeArea(
              child: Directionality(
                textDirection: t.textDirection,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: QuickReaderControls(
                    compact: false,
                    isAutoScrollingListenable: _isAutoScrollingNotifier,
                    onToggleAutoScroll: () {
                      _toggleAutoScroll();
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_ReaderBlock> _blocksForVerseSurah(SurahDetail detail) {
    final blocks = <_ReaderBlock>[
      _ReaderBlock(type: 'surah_header', detail: detail),
    ];
    for (int i = 0; i < detail.ayahs.length; i++) {
      blocks.add(
        _ReaderBlock(
          type: 'verse_row',
          detail: detail,
          ayahIndex: i,
        ),
      );
    }
    return blocks;
  }

  @override
  Widget build(BuildContext context) {
    // Watch ONLY settings that affect the Quran text/layout — never autoScrollSpeed or fabRelX/Y!
    final readingMode =
        ref.watch(settingsProvider.select((s) => s.readingMode));
    final arabicFontSize =
        ref.watch(settingsProvider.select((s) => s.arabicFontSize));
    final translationFontSize =
        ref.watch(settingsProvider.select((s) => s.translationFontSize));
    final showTranslation =
        ref.watch(settingsProvider.select((s) => s.showTranslation));
    final selectedTranslations =
        ref.watch(settingsProvider.select((s) => s.selectedTranslations));
    final appLanguage =
        ref.watch(settingsProvider.select((s) => s.appLanguage));

    final bookmarks = ref.watch(bookmarksProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final bodyTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    final double readerHPad =
        math.max(14.0, (MediaQuery.sizeOf(context).width - 820) / 2);

    if (readingMode != _cachedBlockMode && _forwardSurahs.isNotEmpty) {
      final bool modeChangedWhileOpen = _cachedBlockMode.isNotEmpty;
      _rebuildBlockCaches(readingMode);
      if (modeChangedWhileOpen && !_isInitialLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isRestoringPosition && !_isPoppingToHome) {
            _persistCurrentReadingPosition(markReaderActive: true);
          }
        });
      }
    }

    // Lazy-fetch translation editions if toggled in Settings
    final desiredKey =
        (showTranslation ? selectedTranslations : const <String>[]).join(',');
    if (!_isInitialLoading && desiredKey != _loadedTransKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadLoadedSurahsForTranslations(ref.read(settingsProvider));
      });
    }

    // Pre-compute text styles once per build so large Surahs render rapidly
    final styles = _ReaderTextStyles(
      surahTitle: GoogleFonts.amiri(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: cs.onPrimaryContainer,
      ),
      bismillah: GoogleFonts.amiri(
        fontSize: arabicFontSize + 1,
        fontWeight: FontWeight.w700,
        color: cs.primary,
      ),
      arabicBase: GoogleFonts.amiri(
        fontSize: arabicFontSize,
        height: 2.15,
        color: bodyTextColor,
      ),
      arabicMarker: GoogleFonts.amiri(
        fontSize: arabicFontSize * 0.84,
        fontWeight: FontWeight.w700,
        color: cs.primary,
      ),
      mlTranslation: GoogleFonts.notoSansMalayalam(
        fontSize: translationFontSize,
        height: 1.7,
      ),
      arTafsir: GoogleFonts.amiri(
        fontSize: translationFontSize + 3,
        height: 1.8,
      ),
      enTranslation: TextStyle(
        fontSize: translationFontSize,
        height: 1.6,
      ),
    );

    ref.listen<(bool, int?, int?)>(
      quranAudioProvider.select((s) => (s.isVisible, s.surahNumber, s.ayahNumber)),
      (prev, next) {
        if (!next.$1 || next.$2 == null || next.$3 == null) return;
        if (prev != null &&
            prev.$1 == next.$1 &&
            prev.$2 == next.$2 &&
            prev.$3 == next.$3) {
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _syncViewportToPlayingAyah(next.$2!, next.$3!);
        });
      },
    );

    return Directionality(
      textDirection: t.textDirection,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _isPoppingToHome = true;
            _saveDebounceTimer?.cancel();
            _stopAutoScroll();
            _persistCurrentReadingPosition(markReaderActive: false);
            _audioNotifier.stopAndClose();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: ValueListenableBuilder<SurahSummary?>(
              valueListenable: _headerSummaryNotifier,
              builder: (_, activeSummary, __) {
                String headerTitle = '${t.surahLabel} ${widget.initialSurahNumber}';
                if (activeSummary != null) {
                  headerTitle = appLanguage == 'ar'
                      ? activeSummary.nameArabic
                      : '${activeSummary.number}. ${activeSummary.englishName}';
                }
                return Text(
                  headerTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                );
              },
            ),
            actions: [
              Builder(
                builder: (drawerCtx) => IconButton(
                  tooltip: t.settings,
                  icon: const Icon(Icons.settings_rounded),
                  onPressed: () => Scaffold.of(drawerCtx).openEndDrawer(),
                ),
              ),
            ],
          ),
          endDrawer: const CompactSettingsDrawer(),
          body: SafeArea(
            child: Column(
              children: [
                const ReaderAudioPlayerBar(),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                if (_isInitialLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorText != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(t.loadError, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _loadInitialSurah,
                            child: Text(t.retry),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (_) {
                      if (!_isRestoringPosition && !_isPoppingToHome) {
                        _saveDebounceTimer?.cancel();
                        _persistCurrentReadingPosition(markReaderActive: true);
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      key: _scrollViewKey,
                      controller: _scrollController,
                      center: _centerKey,
                      slivers: [
                        // UPWARD SLIVER: Previous Surahs (ends directly above current Surah)
                        if (_backwardBlocks.isNotEmpty)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: readerHPad),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final block = _backwardBlocks[index];
                                  final bId = _blockId(block);
                                  return RepaintBoundary(
                                    child: _BlockMountTracker(
                                      blockId: bId,
                                      onMount: (ctx) {
                                        _mountedBlocks[bId] = _MountedBlockInfo(
                                          id: bId,
                                          block: block,
                                          isForward: false,
                                          listIndex: index,
                                          context: ctx,
                                        );
                                      },
                                      onUnmount: (ctx) {
                                        if (_mountedBlocks[bId]?.context == ctx) {
                                          _mountedBlocks.remove(bId);
                                        }
                                      },
                                      child: _renderBlock(
                                        block,
                                        showTranslation: showTranslation,
                                        selectedTranslations: selectedTranslations,
                                        bookmarks: bookmarks,
                                        t: t,
                                        cs: cs,
                                        scaffoldBg: scaffoldBg,
                                        styles: styles,
                                        isFirst: false,
                                      ),
                                    ),
                                  );
                                },
                                childCount: _backwardBlocks.length,
                              ),
                            ),
                          ),
                        if (_isLoadingPrev)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 8),
                                    Text(t.loadingPrevSurah),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // CENTER + DOWNWARD SLIVER: Initial Surah -> Next Surahs
                        SliverPadding(
                          key: _centerKey,
                          padding: EdgeInsets.fromLTRB(
                              readerHPad, 10, readerHPad, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final block = _forwardBlocks[index];
                                final bId = _blockId(block);
                                return RepaintBoundary(
                                  child: _BlockMountTracker(
                                    blockId: bId,
                                    onMount: (ctx) {
                                      _mountedBlocks[bId] = _MountedBlockInfo(
                                        id: bId,
                                        block: block,
                                        isForward: true,
                                        listIndex: index,
                                        context: ctx,
                                      );
                                    },
                                    onUnmount: (ctx) {
                                      if (_mountedBlocks[bId]?.context == ctx) {
                                        _mountedBlocks.remove(bId);
                                      }
                                    },
                                    child: _renderBlock(
                                      block,
                                      showTranslation: showTranslation,
                                      selectedTranslations: selectedTranslations,
                                      bookmarks: bookmarks,
                                      t: t,
                                      cs: cs,
                                      scaffoldBg: scaffoldBg,
                                      styles: styles,
                                      isFirst: index == 0,
                                    ),
                                  ),
                                );
                              },
                              childCount: _forwardBlocks.length,
                            ),
                          ),
                        ),
                        if (_isLoadingNext)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 8),
                                    Text(t.loadingNextSurah),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                // Isolated 1:1 Instant Draggable Floating Auto-Scroll & Quick Control Button
                _DraggableAutoScrollFab(
                  isAutoScrollingListenable: _isAutoScrollingNotifier,
                  onTap: _toggleAutoScroll,
                  onLongPress: _showQuickControlSheet,
                ),
              ],
            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderBlock(
    _ReaderBlock block, {
    required bool showTranslation,
    required List<String> selectedTranslations,
    required List<String> bookmarks,
    required AppStrings t,
    required ColorScheme cs,
    required Color scaffoldBg,
    required _ReaderTextStyles styles,
    required bool isFirst,
  }) {
    if (block.type == 'surah_header') {
      final juzNum =
          block.detail.ayahs.isNotEmpty ? block.detail.ayahs.first.juz : 1;
      return _buildSurahHeader(
        block.detail.summary,
        juzNum,
        bookmarks,
        t,
        cs,
        styles,
        isFirst: isFirst,
        includeBismillah: true,
      );
    }
    if (block.type == 'mushaf_page') {
      return _buildMushafPageBlock(
        pageNumber: block.pageNumber!,
        juzNumber: block.juzNumber ?? 1,
        segments: block.segments!,
        showTranslation: showTranslation,
        selectedTranslations: selectedTranslations,
        bookmarks: bookmarks,
        t: t,
        cs: cs,
        scaffoldBg: scaffoldBg,
        styles: styles,
      );
    }
    return _buildVerseRow(
      detail: block.detail,
      ayahIndex: block.ayahIndex!,
      showTranslation: showTranslation,
      selectedTranslations: selectedTranslations,
      bookmarks: bookmarks,
      t: t,
      cs: cs,
      styles: styles,
    );
  }

  Widget _buildSurahHeader(
    SurahSummary summary,
    int juzNumber,
    List<String> bookmarks,
    AppStrings t,
    ColorScheme cs,
    _ReaderTextStyles styles, {
    required bool isFirst,
    required bool includeBismillah,
  }) {
    final showBismillah =
        includeBismillah && summary.number != 1 && summary.number != 9;
    final surahKey = 'surah:${summary.number}';
    final isBookmarked = bookmarks.contains(surahKey);

    return Column(
      key: _headerKeys[summary.number],
      children: [
        _SurahOrnamentalBanner(
          summary: summary,
          juzNumber: juzNumber,
          isBookmarked: isBookmarked,
          strings: t,
          cs: cs,
          titleStyle: styles.surahTitle,
          topMargin: isFirst ? 2 : 8,
          onToggleBookmark: () {
            ref.read(bookmarksProvider.notifier).toggle(surahKey);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isBookmarked ? t.bookmarkRemoved : t.bookmarkSaved,
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
        if (showBismillah)
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            child: Text(
              'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: styles.bismillah,
            ),
          ),
      ],
    );
  }

  Widget _buildMushafPageBlock({
    required int pageNumber,
    required int juzNumber,
    required List<_MushafPageSegment> segments,
    required bool showTranslation,
    required List<String> selectedTranslations,
    required List<String> bookmarks,
    required AppStrings t,
    required ColorScheme cs,
    required Color scaffoldBg,
    required _ReaderTextStyles styles,
  }) {
    const goldColor = Color(0xFFB48A3E);

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goldColor.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.primary.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int sIdx = 0; sIdx < segments.length; sIdx++) ...[
              if (sIdx > 0) const SizedBox(height: 16),
              _BlockMountTracker(
                blockId:
                    'seg_${pageNumber}_${segments[sIdx].detail.summary.number}_${segments[sIdx].ayahIndices.first}',
                onMount: (ctx) {
                  final seg = segments[sIdx];
                  final key =
                      'seg_${pageNumber}_${seg.detail.summary.number}_${seg.ayahIndices.first}';
                  _mountedSegments[key] = _MountedSegmentInfo(
                    pageNumber: pageNumber,
                    surahNumber: seg.detail.summary.number,
                    segment: seg,
                    context: ctx,
                  );
                },
                onUnmount: (ctx) {
                  final seg = segments[sIdx];
                  final key =
                      'seg_${pageNumber}_${seg.detail.summary.number}_${seg.ayahIndices.first}';
                  if (_mountedSegments[key]?.context == ctx) {
                    _mountedSegments.remove(key);
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (segments[sIdx].startsHere)
                      _buildSurahHeader(
                        segments[sIdx].detail.summary,
                        segments[sIdx]
                            .detail
                            .ayahs[segments[sIdx].ayahIndices.first]
                            .juz,
                        bookmarks,
                        t,
                        cs,
                        styles,
                        isFirst: sIdx == 0,
                        includeBismillah: true,
                      ),
                    if (!segments[sIdx].startsHere && sIdx == 0)
                      const SizedBox(height: 2),
                    _MushafSegmentBody(
                      pageNumber: pageNumber,
                      segment: segments[sIdx],
                      showTranslation: showTranslation,
                      selectedTranslations: selectedTranslations,
                      t: t,
                      cs: cs,
                      styles: styles,
                      onRegisterStartAnchor: (key, ctx) =>
                          _playingAyahStartAnchors[key] = ctx,
                      onUnregisterStartAnchor: (key, ctx) {
                        if (_playingAyahStartAnchors[key] == ctx) {
                          _playingAyahStartAnchors.remove(key);
                        }
                      },
                      onRegisterAnchor: (key, ctx) =>
                          _playingAyahAnchors[key] = ctx,
                      onUnregisterAnchor: (key, ctx) {
                        if (_playingAyahAnchors[key] == ctx) {
                          _playingAyahAnchors.remove(key);
                        }
                      },
                      onRegisterMountedAyah: (key, info) =>
                          _mountedAyahs[key] = info,
                      onUnregisterMountedAyah: (key, ctx) {
                        if (_mountedAyahs[key]?.context == ctx) {
                          _mountedAyahs.remove(key);
                        }
                      },
                      onTogglePlay: (surahNo, ayahNo, globalAyah, summary) {
                        _audioNotifier.playOrToggleAyah(
                          surahNumber: surahNo,
                          ayahNumber: ayahNo,
                          globalAyahNumber: globalAyah,
                          summary: summary,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            // Single bottom Mushaf page footer centered inside the page frame
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: goldColor.withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: goldColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    segments.any((s) => s.startsHere)
                        ? '${t.pageLabel} $pageNumber'
                        : '${t.pageLabel} $pageNumber  •  ${t.juzLabel} $juzNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: goldColor.withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseRow({
    required SurahDetail detail,
    required int ayahIndex,
    required bool showTranslation,
    required List<String> selectedTranslations,
    required List<String> bookmarks,
    required AppStrings t,
    required ColorScheme cs,
    required _ReaderTextStyles styles,
  }) {
    final ayah = detail.ayahs[ayahIndex];
    final surahNo = detail.summary.number;
    final ayahNo = ayah.numberInSurah;
    final ayahKey = '$surahNo:$ayahNo';
    final anchorKey = '${surahNo}_$ayahNo';
    final isBookmarked = bookmarks.contains(ayahKey);

    return _BlockMountTracker(
      blockId: 'verse_audio_$anchorKey',
      onMount: (ctx) {
        _playingAyahAnchors[anchorKey] = ctx;
        _playingAyahStartAnchors[anchorKey] = ctx;
      },
      onUnmount: (ctx) {
        if (_playingAyahAnchors[anchorKey] == ctx) {
          _playingAyahAnchors.remove(anchorKey);
        }
        if (_playingAyahStartAnchors[anchorKey] == ctx) {
          _playingAyahStartAnchors.remove(anchorKey);
        }
      },
      child: Consumer(
        builder: (context, audioRef, _) {
          final activeAudio = audioRef.watch(
            quranAudioProvider.select(
              (s) => s.isVisible &&
                      s.surahNumber == surahNo &&
                      s.ayahNumber == ayahNo
                  ? (s.isPlaying, s.isBuffering)
                  : null,
            ),
          );
          final isTarget = activeAudio != null;
          final isPlayingThis = activeAudio?.$1 ?? false;
          final isBufferingThis = activeAudio?.$2 ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isTarget
                      ? cs.primaryContainer.withValues(alpha: 0.34)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text.rich(
                        TextSpan(
                          style: styles.arabicBase,
                          children: [
                            TextSpan(text: ayah.arabicText),
                            TextSpan(
                              text: ApiConfig.ayahEndMarker(ayahNo),
                              style: styles.arabicMarker,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    if (showTranslation)
                      ...selectedTranslations.map((code) {
                        final text = detail.translationAt(code, ayahIndex);
                        if (text.isEmpty) return const SizedBox.shrink();
                        final isAr = code == 'ar';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Directionality(
                            textDirection:
                                isAr ? TextDirection.rtl : TextDirection.ltr,
                            child: Text(
                              text,
                              textAlign:
                                  isAr ? TextAlign.right : TextAlign.left,
                              style: styles.forTranslation(code),
                            ),
                          ),
                        );
                      }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 19,
                            color: isBookmarked
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                          onPressed: () {
                            ref.read(bookmarksProvider.notifier).toggle(ayahKey);
                            final captured = _captureVisibleReadingPosition();
                            final currentMode =
                                ref.read(settingsProvider).readingMode;
                            ref.read(lastReadProvider.notifier).setPosition(
                                  LastReadPosition(
                                    surahNumber: surahNo,
                                    surahName: detail.summary.englishName,
                                    surahArabicName: detail.summary.nameArabic,
                                    ayahNumber: ayahNo,
                                    pageNumber: ayah.page,
                                    anchorOffsetPx: captured?.summary.number ==
                                                surahNo &&
                                            captured?.ayahNumber == ayahNo
                                        ? captured!.anchorOffsetPx
                                        : 0.0,
                                    readingMode: currentMode,
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isBookmarked
                                      ? t.bookmarkRemoved
                                      : t.bookmarkSaved,
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.copy_rounded,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () {
                            final buffer = StringBuffer(
                              '${ayah.arabicText}${ApiConfig.ayahEndMarker(ayahNo)}',
                            );
                            if (showTranslation) {
                              for (final code in selectedTranslations) {
                                final txt = detail.translationAt(code, ayahIndex);
                                if (txt.isNotEmpty) {
                                  buffer.write('\n\n$txt');
                                }
                              }
                            }
                            Clipboard.setData(
                              ClipboardData(text: buffer.toString()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.copiedAyah),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          tooltip: isPlayingThis ? t.pauseAyah : t.playAyah,
                          visualDensity: VisualDensity.compact,
                          icon: isBufferingThis
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.primary,
                                  ),
                                )
                              : Icon(
                                  isPlayingThis
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_outline_rounded,
                                  size: 22,
                                  color: isTarget
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                ),
                          onPressed: () => _audioNotifier.playOrToggleAyah(
                            surahNumber: surahNo,
                            ayahNumber: ayahNo,
                            globalAyahNumber: ayah.globalNumber,
                            summary: detail.summary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}

class _MushafSegmentBody extends ConsumerWidget {
  final int pageNumber;
  final _MushafPageSegment segment;
  final bool showTranslation;
  final List<String> selectedTranslations;
  final AppStrings t;
  final ColorScheme cs;
  final _ReaderTextStyles styles;
  final void Function(String key, BuildContext ctx) onRegisterStartAnchor;
  final void Function(String key, BuildContext ctx) onUnregisterStartAnchor;
  final void Function(String key, BuildContext ctx) onRegisterAnchor;
  final void Function(String key, BuildContext ctx) onUnregisterAnchor;
  final void Function(String key, _MountedAyahInfo info) onRegisterMountedAyah;
  final void Function(String key, BuildContext ctx) onUnregisterMountedAyah;
  final void Function(
    int surahNumber,
    int ayahNumber,
    int globalAyahNumber,
    SurahSummary summary,
  ) onTogglePlay;

  const _MushafSegmentBody({
    required this.pageNumber,
    required this.segment,
    required this.showTranslation,
    required this.selectedTranslations,
    required this.t,
    required this.cs,
    required this.styles,
    required this.onRegisterStartAnchor,
    required this.onUnregisterStartAnchor,
    required this.onRegisterAnchor,
    required this.onUnregisterAnchor,
    required this.onRegisterMountedAyah,
    required this.onUnregisterMountedAyah,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahNo = segment.detail.summary.number;
    final activeAudio = ref.watch(
      quranAudioProvider.select(
        (s) => s.isVisible && s.surahNumber == surahNo
            ? (s.ayahNumber, s.isPlaying, s.isBuffering)
            : null,
      ),
    );

    final highlightBg = cs.primaryContainer.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text.rich(
            TextSpan(
              style: styles.arabicBase,
              children: [
                for (final i in segment.ayahIndices) ...[
                  () {
                    final ayahNo = segment.detail.ayahs[i].numberInSurah;
                    final anchorKey = '${surahNo}_$ayahNo';
                    return WidgetSpan(
                      alignment: PlaceholderAlignment.top,
                      child: _BlockMountTracker(
                        blockId: 'mushaf_start_$anchorKey',
                        onMount: (ctx) => onRegisterStartAnchor(anchorKey, ctx),
                        onUnmount: (ctx) =>
                            onUnregisterStartAnchor(anchorKey, ctx),
                        child: const SizedBox(width: 0, height: 2),
                      ),
                    );
                  }(),
                  () {
                    final ayah = segment.detail.ayahs[i];
                    final isTarget =
                        activeAudio != null && activeAudio.$1 == ayah.numberInSurah;
                    return TextSpan(
                      text: ayah.arabicText,
                      style: isTarget
                          ? styles.arabicBase.copyWith(backgroundColor: highlightBg)
                          : null,
                    );
                  }(),
                  () {
                    final ayah = segment.detail.ayahs[i];
                    final isTarget =
                        activeAudio != null && activeAudio.$1 == ayah.numberInSurah;
                    return TextSpan(
                      text: ApiConfig.ayahEndMarker(ayah.numberInSurah).trimRight(),
                      style: isTarget
                          ? styles.arabicMarker.copyWith(backgroundColor: highlightBg)
                          : styles.arabicMarker,
                    );
                  }(),
                  () {
                    final ayah = segment.detail.ayahs[i];
                    final ayahNo = ayah.numberInSurah;
                    final isTarget =
                        activeAudio != null && activeAudio.$1 == ayahNo;
                    final isPlayingThis = isTarget && activeAudio.$2;
                    final isBufferingThis = isTarget && activeAudio.$3;
                    final anchorKey = '${surahNo}_$ayahNo';

                    return WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _BlockMountTracker(
                        blockId: 'mushaf_anchor_$anchorKey',
                        onMount: (ctx) => onRegisterAnchor(anchorKey, ctx),
                        onUnmount: (ctx) => onUnregisterAnchor(anchorKey, ctx),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: 3,
                            end: 2,
                          ),
                          child: _InlineAyahAudioChip(
                            isTarget: isTarget,
                            isPlaying: isPlayingThis,
                            isBuffering: isBufferingThis,
                            tooltip: isPlayingThis ? t.pauseAyah : t.playAyah,
                            cs: cs,
                            onTap: () => onTogglePlay(
                              surahNo,
                              ayahNo,
                              ayah.globalNumber,
                              segment.detail.summary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }(),
                  const TextSpan(text: ' '),
                ],
              ],
            ),
            textAlign: TextAlign.justify,
          ),
        ),
        if (showTranslation) ...[
          const Divider(height: 22),
          for (final i in segment.ayahIndices)
            () {
              final ayahNo = segment.detail.ayahs[i].numberInSurah;
              final isTarget = activeAudio != null && activeAudio.$1 == ayahNo;
              final mountedKey = 'ayah_${pageNumber}_${surahNo}_$ayahNo';
              return _BlockMountTracker(
                blockId: mountedKey,
                onMount: (ctx) {
                  onRegisterMountedAyah(
                    mountedKey,
                    _MountedAyahInfo(
                      surahNumber: surahNo,
                      ayahNumber: ayahNo,
                      pageNumber: pageNumber,
                      context: ctx,
                    ),
                  );
                },
                onUnmount: (ctx) => onUnregisterMountedAyah(mountedKey, ctx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: isTarget
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isTarget
                        ? cs.primaryContainer.withValues(alpha: 0.30)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: selectedTranslations.map((code) {
                      final txt = segment.detail.translationAt(code, i);
                      if (txt.isEmpty) return const SizedBox.shrink();
                      final isAr = code == 'ar';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Directionality(
                          textDirection:
                              isAr ? TextDirection.rtl : TextDirection.ltr,
                          child: Text(
                            '($ayahNo) $txt',
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            style: styles.forTranslation(code),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }(),
        ],
      ],
    );
  }
}

class _InlineAyahAudioChip extends StatelessWidget {
  final bool isTarget;
  final bool isPlaying;
  final bool isBuffering;
  final String tooltip;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _InlineAyahAudioChip({
    required this.isTarget,
    required this.isPlaying,
    required this.isBuffering,
    required this.tooltip,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isTarget ? cs.primary : cs.primary.withValues(alpha: 0.10),
        shape: CircleBorder(
          side: BorderSide(
            color: isTarget
                ? cs.primary
                : cs.primary.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Center(
              child: isBuffering
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: cs.onPrimary,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 15,
                      color: isTarget ? cs.onPrimary : cs.primary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Isolated floating button that tracks pointer movement 1:1 via ValueNotifier
/// without rebuilding the underlying Quran reader slivers on every frame.
class _DraggableAutoScrollFab extends ConsumerStatefulWidget {
  final ValueNotifier<bool> isAutoScrollingListenable;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _DraggableAutoScrollFab({
    required this.isAutoScrollingListenable,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  ConsumerState<_DraggableAutoScrollFab> createState() =>
      _DraggableAutoScrollFabState();
}

class _DraggableAutoScrollFabState
    extends ConsumerState<_DraggableAutoScrollFab> {
  static const double _fabSize = 58.0;
  static const double _margin = 12.0;
  static const double _dragThresholdPx = 5.0;
  static const Duration _longPressDelay = Duration(milliseconds: 420);

  final ValueNotifier<Offset?> _dragRelNotifier = ValueNotifier<Offset?>(null);

  Offset _fallbackRel = const Offset(1.0, 1.0);
  int? _activePointer;
  Offset? _downGlobalPos;
  Offset? _lastGlobalPos;
  bool _isDragging = false;
  bool _longPressFired = false;
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _dragRelNotifier.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
    _downGlobalPos = event.position;
    _lastGlobalPos = event.position;
    _isDragging = false;
    _longPressFired = false;
    _longPressTimer?.cancel();
    _longPressTimer = Timer(_longPressDelay, () {
      if (!mounted || _activePointer == null || _isDragging) return;
      _longPressFired = true;
      HapticFeedback.mediumImpact();
      widget.onLongPress();
    });
  }

  void _handlePointerMove(
    PointerMoveEvent event,
    double availW,
    double availH,
  ) {
    if (event.pointer != _activePointer ||
        _downGlobalPos == null ||
        _lastGlobalPos == null) {
      return;
    }

    if (!_isDragging) {
      final totalDist = (event.position - _downGlobalPos!).distance;
      if (totalDist <= _dragThresholdPx) return;
      _isDragging = true;
      _longPressTimer?.cancel();
      _longPressTimer = null;

      // Apply full displacement from pointer-down so the button catches up 1:1 immediately
      final initialDelta = event.position - _downGlobalPos!;
      _lastGlobalPos = event.position;
      _updateRelPos(initialDelta, availW, availH);
      return;
    }

    final delta = event.position - _lastGlobalPos!;
    _lastGlobalPos = event.position;
    _updateRelPos(delta, availW, availH);
  }

  void _updateRelPos(
    Offset delta,
    double availW,
    double availH,
  ) {
    final currentRel = _dragRelNotifier.value ?? _fallbackRel;
    final leftPx = _margin + currentRel.dx * availW + delta.dx;
    final topPx = _margin + currentRel.dy * availH + delta.dy;
    final nextRelX = ((leftPx - _margin) / availW).clamp(0.0, 1.0);
    final nextRelY = ((topPx - _margin) / availH).clamp(0.0, 1.0);
    _dragRelNotifier.value = Offset(nextRelX, nextRelY);
  }

  void _finishPointer(int pointer, {required bool cancelled}) {
    if (pointer != _activePointer) return;
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _activePointer = null;

    final wasDragging = _isDragging;
    final wasLongPress = _longPressFired;
    _isDragging = false;
    _longPressFired = false;
    _downGlobalPos = null;
    _lastGlobalPos = null;

    if (wasDragging) {
      final pos = _dragRelNotifier.value;
      if (pos != null) {
        final s = ref.read(settingsProvider);
        ref.read(settingsProvider.notifier).update(
              s.copyWith(fabRelX: pos.dx, fabRelY: pos.dy),
            );
      }
    } else if (!cancelled && !wasLongPress) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedRelX = ref.watch(settingsProvider.select((s) => s.fabRelX));
    final savedRelY = ref.watch(settingsProvider.select((s) => s.fabRelY));
    final speed =
        ref.watch(settingsProvider.select((s) => s.autoScrollSpeed));
    final cs = Theme.of(context).colorScheme;

    _fallbackRel = Offset(
      (savedRelX ?? 1.0).clamp(0.0, 1.0),
      (savedRelY ?? 1.0).clamp(0.0, 1.0),
    );

    // Clear transient drag value if user reset position in Settings
    if (!_isDragging && savedRelX == null && savedRelY == null) {
      _dragRelNotifier.value = null;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW =
            (constraints.maxWidth - _fabSize - _margin * 2).clamp(1.0, 4000.0);
        final availH =
            (constraints.maxHeight - _fabSize - _margin * 2).clamp(1.0, 4000.0);

        return ValueListenableBuilder<Offset?>(
          valueListenable: _dragRelNotifier,
          builder: (_, dragRel, __) {
            final rel = dragRel ?? _fallbackRel;
            final leftPx = _margin + rel.dx * availW;
            final topPx = _margin + rel.dy * availH;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: leftPx,
                  top: topPx,
                  child: RepaintBoundary(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: _handlePointerDown,
                      onPointerMove: (e) =>
                          _handlePointerMove(e, availW, availH),
                      onPointerUp: (e) =>
                          _finishPointer(e.pointer, cancelled: false),
                      onPointerCancel: (e) =>
                          _finishPointer(e.pointer, cancelled: true),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: widget.isAutoScrollingListenable,
                        builder: (_, isAutoScrolling, __) {
                          return Material(
                            elevation: 6,
                            shape: const CircleBorder(),
                            color: isAutoScrolling
                                ? cs.primary
                                : cs.primaryContainer,
                            child: SizedBox(
                              width: _fabSize,
                              height: _fabSize,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isAutoScrolling
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 25,
                                    color: isAutoScrolling
                                        ? cs.onPrimary
                                        : cs.onPrimaryContainer,
                                  ),
                                  Text(
                                    formatAutoScrollSpeed(speed),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: isAutoScrolling
                                          ? cs.onPrimary
                                          : cs.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SurahOrnamentalBanner extends StatelessWidget {
  final SurahSummary summary;
  final int juzNumber;
  final bool isBookmarked;
  final AppStrings strings;
  final ColorScheme cs;
  final TextStyle titleStyle;
  final double topMargin;
  final VoidCallback onToggleBookmark;

  const _SurahOrnamentalBanner({
    required this.summary,
    required this.juzNumber,
    required this.isBookmarked,
    required this.strings,
    required this.cs,
    required this.titleStyle,
    required this.topMargin,
    required this.onToggleBookmark,
  });

  static const Color _gold = Color(0xFFB48A3E);

  @override
  Widget build(BuildContext context) {
    final badgeBg = cs.surface.withValues(alpha: 0.72);
    final badgeTextColor = cs.onPrimaryContainer;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: topMargin, bottom: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primaryContainer,
            cs.primaryContainer.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CustomPaint(
        painter: _MushafCalligraphyFramePainter(
          primaryColor: cs.primary,
          goldColor: _gold,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calligraphic Arabic Surah Title strictly centered, with bookmark button in top-end corner
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '۞',
                          style: TextStyle(
                            fontSize: 16,
                            color: _gold.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            summary.nameArabic,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: titleStyle.copyWith(
                              fontSize: 29,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '۞',
                          style: TextStyle(
                            fontSize: 16,
                            color: _gold.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PositionedDirectional(
                    top: 0,
                    end: 0,
                    child: Material(
                      color: isBookmarked ? cs.primary : badgeBg,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onToggleBookmark,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_add_outlined,
                            size: 18,
                            color: isBookmarked ? cs.onPrimary : cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Single bottom line: Juz (left) • English Name & Ayahs count (center) • Surah # (right)
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '${strings.juzLabel} $juzNumber',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${summary.englishName}  •  ${summary.numberOfAyahs} ${strings.ayahsLabel}',
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  cs.onPrimaryContainer.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${strings.surahLabel} ${summary.number}',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MushafCalligraphyFramePainter extends CustomPainter {
  final Color primaryColor;
  final Color goldColor;

  const _MushafCalligraphyFramePainter({
    required this.primaryColor,
    required this.goldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Offset.zero & size;
    final outerRRect =
        RRect.fromRectAndRadius(outerRect.deflate(1.0), const Radius.circular(13));
    final innerRRect =
        RRect.fromRectAndRadius(outerRect.deflate(5.0), const Radius.circular(10));

    final outerPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final innerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(outerRRect, outerPaint);
    canvas.drawRRect(innerRRect, innerPaint);

    // Draw corner ornamental diamonds and subtle arabesque arcs
    final accentFill = Paint()
      ..color = goldColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final corners = [
      const Offset(9, 9),
      Offset(size.width - 9, 9),
      Offset(9, size.height - 9),
      Offset(size.width - 9, size.height - 9),
    ];

    for (final c in corners) {
      final diamond = Path()
        ..moveTo(c.dx, c.dy - 3.5)
        ..lineTo(c.dx + 3.5, c.dy)
        ..lineTo(c.dx, c.dy + 3.5)
        ..lineTo(c.dx - 3.5, c.dy)
        ..close();
      canvas.drawPath(diamond, accentFill);
    }

    // Left and right mid-point scalloped brackets
    final midY = size.height / 2;
    final leftBracket = Path()
      ..moveTo(5, midY - 14)
      ..quadraticBezierTo(13, midY, 5, midY + 14);
    final rightBracket = Path()
      ..moveTo(size.width - 5, midY - 14)
      ..quadraticBezierTo(size.width - 13, midY, size.width - 5, midY + 14);

    canvas.drawPath(leftBracket, outerPaint);
    canvas.drawPath(rightBracket, outerPaint);
  }

  @override
  bool shouldRepaint(covariant _MushafCalligraphyFramePainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.goldColor != goldColor;
  }
}

class _BlockMountTracker extends StatefulWidget {
  final String blockId;
  final ValueChanged<BuildContext> onMount;
  final ValueChanged<BuildContext> onUnmount;
  final Widget child;

  const _BlockMountTracker({
    required this.blockId,
    required this.onMount,
    required this.onUnmount,
    required this.child,
  });

  @override
  State<_BlockMountTracker> createState() => _BlockMountTrackerState();
}

class _BlockMountTrackerState extends State<_BlockMountTracker> {
  @override
  void initState() {
    super.initState();
    widget.onMount(context);
  }

  @override
  void didUpdateWidget(covariant _BlockMountTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blockId != widget.blockId) {
      oldWidget.onUnmount(context);
    }
    widget.onMount(context);
  }

  @override
  void dispose() {
    widget.onUnmount(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


