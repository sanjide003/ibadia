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
import '../providers/quran_providers.dart';
import '../services/storage_service.dart';
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

class SurahReaderScreen extends ConsumerStatefulWidget {
  final int initialSurahNumber;
  final int? initialAyahNumber;

  const SurahReaderScreen({
    super.key,
    required this.initialSurahNumber,
    this.initialAyahNumber,
  });

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final Key _centerKey = const ValueKey<String>('reader_center_sliver');

  /// Forward list: [initialSurah, initial+1, initial+2, ...] (scrolls down)
  final List<SurahDetail> _forwardSurahs = [];

  /// Backward list: [initial-1, initial-2, ...] (scrolls up from end of prev Surah)
  final List<SurahDetail> _backwardSurahs = [];

  /// Cached block lists recomputed only when Surahs or readingMode change
  List<_ReaderBlock> _forwardBlocks = const [];
  List<_ReaderBlock> _backwardBlocks = const [];
  String _cachedBlockMode = '';

  /// GlobalKeys on Surah header banners ONLY — used for flicker-free header detection
  final Map<int, GlobalKey> _headerKeys = {};
  final GlobalKey _targetAyahKey = GlobalKey();

  /// Isolated AppBar header notifier so Surah transitions never rebuild the scroll view
  final ValueNotifier<SurahSummary?> _headerSummaryNotifier =
      ValueNotifier<SurahSummary?>(null);

  /// Isolated auto-scroll active state so toggling Play/Pause never rebuilds Quran text
  final ValueNotifier<bool> _isAutoScrollingNotifier = ValueNotifier<bool>(false);

  bool _isInitialLoading = true;
  bool _isLoadingNext = false;
  bool _isLoadingPrev = false;
  String? _errorText;
  String _loadedTransKey = '';

  // Vsync-synchronized auto-scroll state
  late final Ticker _autoScrollTicker;
  Duration _lastTickElapsed = Duration.zero;
  DateTime _lastHeaderCheck = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _autoScrollTicker = createTicker(_onAutoScrollTick);
    _scrollController.addListener(_onScroll);
    _loadInitialSurah();
  }

  @override
  void dispose() {
    _autoScrollTicker.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerSummaryNotifier.dispose();
    _isAutoScrollingNotifier.dispose();
    super.dispose();
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

  bool _isTargetAyahBlock(_ReaderBlock block, int targetAyah) {
    if (block.type == 'mushaf_page' && block.segments != null) {
      for (final seg in block.segments!) {
        if (seg.detail.summary.number != widget.initialSurahNumber) continue;
        for (final idx in seg.ayahIndices) {
          if (seg.detail.ayahs[idx].numberInSurah == targetAyah) {
            return true;
          }
        }
      }
    } else if (block.type == 'verse_row' && block.ayahIndex != null) {
      if (block.detail.summary.number == widget.initialSurahNumber &&
          block.detail.ayahs[block.ayahIndex!].numberInSurah == targetAyah) {
        return true;
      }
    }
    return false;
  }

  Future<void> _scrollToInitialAyah(int targetAyah) async {
    if (!mounted || !_scrollController.hasClients || _forwardBlocks.isEmpty) {
      return;
    }
    final targetIndex = _forwardBlocks.indexWhere(
      (b) => _isTargetAyahBlock(b, targetAyah),
    );
    if (targetIndex <= 0) return;

    final maxExt = _scrollController.position.maxScrollExtent;
    final approx =
        ((targetIndex / _forwardBlocks.length) * maxExt).clamp(0.0, maxExt);
    _scrollController.jumpTo(approx);

    for (int attempt = 0; attempt < 4; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final ctx = _targetAyahKey.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.04,
          duration: Duration.zero,
        );
        return;
      }
      if (!_scrollController.hasClients) return;
      final curMax = _scrollController.position.maxScrollExtent;
      final nextApprox =
          ((targetIndex / _forwardBlocks.length) * curMax).clamp(0.0, curMax);
      _scrollController.jumpTo(nextApprox);
    }
  }

  Future<void> _loadInitialSurah() async {
    setState(() {
      _isInitialLoading = true;
      _errorText = null;
    });
    try {
      final settings = ref.read(settingsProvider);
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

      if (widget.initialAyahNumber != null && widget.initialAyahNumber! > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToInitialAyah(widget.initialAyahNumber!);
        });
      } else if (prepended.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final targetCtx =
              _headerKeys[widget.initialSurahNumber]?.currentContext;
          if (targetCtx != null && mounted) {
            Scrollable.ensureVisible(
              targetCtx,
              alignment: 0.04,
              duration: Duration.zero,
            );
          }
        });
      }

      ref.read(lastReadProvider.notifier).setPosition(
            LastReadPosition(
              surahNumber: detail.summary.number,
              surahName: detail.summary.englishName,
              surahArabicName: detail.summary.nameArabic,
              ayahNumber: widget.initialAyahNumber ?? 1,
            ),
          );

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPrev = false);
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

    // Throttled, flicker-free header detection (runs at most once every 150ms)
    final now = DateTime.now();
    if (now.difference(_lastHeaderCheck).inMilliseconds >= 150) {
      _lastHeaderCheck = now;
      _syncActiveHeaderFromViewport();
    }
  }

  void _syncActiveHeaderFromViewport() {
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
      final summary = byNum[resolvedNum]!;
      _headerSummaryNotifier.value = summary;
      ref.read(lastReadProvider.notifier).setPosition(
            LastReadPosition(
              surahNumber: summary.number,
              surahName: summary.englishName,
              surahArabicName: summary.nameArabic,
              ayahNumber: 1,
            ),
          );
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
    if (_autoScrollTicker.isActive) {
      _autoScrollTicker.stop();
    }
    if (_isAutoScrollingNotifier.value) {
      _isAutoScrollingNotifier.value = false;
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
            final settings = modalRef.watch(settingsProvider);
            final notifier = modalRef.read(settingsProvider.notifier);
            final t = modalRef.watch(stringsProvider);
            final cs = Theme.of(context).colorScheme;
            const presets = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0];

            return SafeArea(
              child: Directionality(
                textDirection: t.textDirection,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Auto-Scroll Speed + Play/Pause
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${t.autoScrollSpeed}: ${settings.autoScrollSpeed.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _isAutoScrollingNotifier,
                            builder: (_, isScrolling, __) {
                              return FilledButton.tonalIcon(
                                icon: Icon(
                                  isScrolling
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                label: Text(isScrolling ? t.pause : t.play),
                                onPressed: () {
                                  _toggleAutoScroll();
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: () {
                              final next = (settings.autoScrollSpeed - 0.5)
                                  .clamp(0.5, 4.0);
                              notifier.update(
                                settings.copyWith(autoScrollSpeed: next),
                              );
                            },
                          ),
                          Expanded(
                            child: Slider(
                              min: 0.5,
                              max: 4.0,
                              divisions: 7,
                              value: settings.autoScrollSpeed,
                              onChanged: (v) => notifier.update(
                                settings.copyWith(autoScrollSpeed: v),
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () {
                              final next = (settings.autoScrollSpeed + 0.5)
                                  .clamp(0.5, 4.0);
                              notifier.update(
                                settings.copyWith(autoScrollSpeed: next),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: presets.map((spd) {
                          final selected =
                              (settings.autoScrollSpeed - spd).abs() < 0.05;
                          return ChoiceChip(
                            label: Text('${spd.toStringAsFixed(1)}x'),
                            selected: selected,
                            onSelected: (_) => notifier.update(
                              settings.copyWith(autoScrollSpeed: spd),
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 26),

                      // 2. Arabic Font Size (+/- buttons & Slider)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.arabicFontSize,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${settings.arabicFontSize.round()}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: () {
                              final next = (settings.arabicFontSize - 1.0)
                                  .clamp(20.0, 44.0);
                              notifier.update(
                                settings.copyWith(arabicFontSize: next),
                              );
                            },
                          ),
                          Expanded(
                            child: Slider(
                              min: 20,
                              max: 44,
                              divisions: 24,
                              value: settings.arabicFontSize.clamp(20.0, 44.0),
                              onChanged: (v) => notifier.update(
                                settings.copyWith(arabicFontSize: v),
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () {
                              final next = (settings.arabicFontSize + 1.0)
                                  .clamp(20.0, 44.0);
                              notifier.update(
                                settings.copyWith(arabicFontSize: next),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 3. Translation Font Size (+/- buttons & Slider)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.translationFontSize,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${settings.translationFontSize.round()}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            icon: const Icon(Icons.remove_rounded),
                            onPressed: () {
                              final next = (settings.translationFontSize - 1.0)
                                  .clamp(13.0, 24.0);
                              notifier.update(
                                settings.copyWith(translationFontSize: next),
                              );
                            },
                          ),
                          Expanded(
                            child: Slider(
                              min: 13,
                              max: 24,
                              divisions: 11,
                              value: settings.translationFontSize
                                  .clamp(13.0, 24.0),
                              onChanged: (v) => notifier.update(
                                settings.copyWith(translationFontSize: v),
                              ),
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add_rounded),
                            onPressed: () {
                              final next = (settings.translationFontSize + 1.0)
                                  .clamp(13.0, 24.0);
                              notifier.update(
                                settings.copyWith(translationFontSize: next),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
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
      _rebuildBlockCaches(readingMode);
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

    return Directionality(
      textDirection: t.textDirection,
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
                CustomScrollView(
                  controller: _scrollController,
                  center: _centerKey,
                  slivers: [
                    // UPWARD SLIVER: Previous Surahs (ends directly above current Surah)
                    if (_backwardBlocks.isNotEmpty)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: readerHPad),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => RepaintBoundary(
                              child: _renderBlock(
                                _backwardBlocks[index],
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
                            final isTarget = widget.initialAyahNumber != null &&
                                widget.initialAyahNumber! > 1 &&
                                _isTargetAyahBlock(
                                    block, widget.initialAyahNumber!);
                            return RepaintBoundary(
                              key: isTarget ? _targetAyahKey : null,
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

              // Isolated 1:1 Instant Draggable Floating Auto-Scroll & Quick Control Button
              _DraggableAutoScrollFab(
                isAutoScrollingListenable: _isAutoScrollingNotifier,
                onTap: _toggleAutoScroll,
                onLongPress: _showQuickControlSheet,
              ),
            ],
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
              if (segments[sIdx].startsHere)
                _buildSurahHeader(
                  segments[sIdx].detail.summary,
                  segments[sIdx].detail.ayahs[segments[sIdx].ayahIndices.first].juz,
                  bookmarks,
                  t,
                  cs,
                  styles,
                  isFirst: sIdx == 0,
                  includeBismillah: true,
                ),
              if (!segments[sIdx].startsHere && sIdx == 0)
                const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text.rich(
                  TextSpan(
                    style: styles.arabicBase,
                    children: [
                      for (final i in segments[sIdx].ayahIndices) ...[
                        TextSpan(
                          text: segments[sIdx].detail.ayahs[i].arabicText,
                        ),
                        TextSpan(
                          text: ApiConfig.ayahEndMarker(
                            segments[sIdx].detail.ayahs[i].numberInSurah,
                          ),
                          style: styles.arabicMarker,
                        ),
                      ],
                    ],
                  ),
                  textAlign: TextAlign.justify,
                ),
              ),
              if (showTranslation) ...[
                const Divider(height: 22),
                for (final i in segments[sIdx].ayahIndices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: selectedTranslations.map((code) {
                        final txt =
                            segments[sIdx].detail.translationAt(code, i);
                        if (txt.isEmpty) return const SizedBox.shrink();
                        final isAr = code == 'ar';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Directionality(
                            textDirection:
                                isAr ? TextDirection.rtl : TextDirection.ltr,
                            child: Text(
                              '(${segments[sIdx].detail.ayahs[i].numberInSurah}) $txt',
                              textAlign:
                                  isAr ? TextAlign.right : TextAlign.left,
                              style: styles.forTranslation(code),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
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
    final ayahKey = '${detail.summary.number}:${ayah.numberInSurah}';
    final isBookmarked = bookmarks.contains(ayahKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                        text: ApiConfig.ayahEndMarker(ayah.numberInSurah),
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
                        textAlign: isAr ? TextAlign.right : TextAlign.left,
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
                      color: isBookmarked ? cs.primary : cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      ref.read(bookmarksProvider.notifier).toggle(ayahKey);
                      ref.read(lastReadProvider.notifier).setPosition(
                            LastReadPosition(
                              surahNumber: detail.summary.number,
                              surahName: detail.summary.englishName,
                              surahArabicName: detail.summary.nameArabic,
                              ayahNumber: ayah.numberInSurah,
                            ),
                          );
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
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      final buffer = StringBuffer(
                        '${ayah.arabicText}${ApiConfig.ayahEndMarker(ayah.numberInSurah)}',
                      );
                      if (showTranslation) {
                        for (final code in selectedTranslations) {
                          final txt = detail.translationAt(code, ayahIndex);
                          if (txt.isNotEmpty) {
                            buffer.write('\n\n$txt');
                          }
                        }
                      }
                      Clipboard.setData(ClipboardData(text: buffer.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(t.copiedAyah),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
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
                                    '${speed.toStringAsFixed(1)}x',
                                    style: TextStyle(
                                      fontSize: 10,
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar: Juz badge + Surah # + Whole-Surah Bookmark icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
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
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
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
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                  Material(
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
                ],
              ),

              const SizedBox(height: 6),

              // Calligraphic Arabic Surah Title flanked by traditional rosettes
              Row(
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

              const SizedBox(height: 3),

              // English Name & Total Ayahs Count
              Text(
                '${summary.englishName}  •  ${summary.numberOfAyahs} ${strings.ayahsLabel}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.88),
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

