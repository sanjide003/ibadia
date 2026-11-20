import 'dart:async';
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

class _ReaderBlock {
  final String type; // 'surah_header' | 'mushaf_page' | 'verse_row'
  final SurahDetail detail;
  final int? pageNumber;
  final List<int>? ayahIndices;
  final int? ayahIndex;

  const _ReaderBlock({
    required this.type,
    required this.detail,
    this.pageNumber,
    this.ayahIndices,
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

  const SurahReaderScreen({super.key, required this.initialSurahNumber});

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
    final fwd = <_ReaderBlock>[];
    for (final s in _forwardSurahs) {
      fwd.addAll(_blocksForSurah(s, readingMode));
    }
    final bwd = <_ReaderBlock>[];
    for (final s in _backwardSurahs) {
      final normalOrder = _blocksForSurah(s, readingMode);
      bwd.addAll(normalOrder.reversed);
    }
    _forwardBlocks = fwd;
    _backwardBlocks = bwd;
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

      final detail = await ref.read(apiServiceProvider).fetchSurahDetail(
            surahNumber: widget.initialSurahNumber,
            requiredTranslations: reqTrans,
          );
      if (!mounted) return;
      setState(() {
        _forwardSurahs
          ..clear()
          ..add(detail);
        _backwardSurahs.clear();
        _headerKeys[detail.summary.number] = GlobalKey();
        _headerSummaryNotifier.value = detail.summary;
        _rebuildBlockCaches(settings.readingMode);
        _isInitialLoading = false;
      });

      ref.read(lastReadProvider.notifier).setPosition(
            LastReadPosition(
              surahNumber: detail.summary.number,
              surahName: detail.summary.englishName,
              surahArabicName: detail.summary.nameArabic,
              ayahNumber: 1,
            ),
          );

      // Quietly pre-load previous Surah so scrolling UP works immediately
      if (widget.initialSurahNumber > 1) {
        _loadPrevSurahIfNeeded();
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

  List<_ReaderBlock> _blocksForSurah(SurahDetail detail, String readingMode) {
    final blocks = <_ReaderBlock>[
      _ReaderBlock(type: 'surah_header', detail: detail),
    ];
    if (readingMode == 'mushaf') {
      int? currentPage;
      List<int> currentIndices = [];
      for (int i = 0; i < detail.ayahs.length; i++) {
        final p = detail.ayahs[i].page;
        if (currentPage == null) {
          currentPage = p;
          currentIndices = [i];
        } else if (p == currentPage) {
          currentIndices.add(i);
        } else {
          blocks.add(
            _ReaderBlock(
              type: 'mushaf_page',
              detail: detail,
              pageNumber: currentPage,
              ayahIndices: List<int>.from(currentIndices),
            ),
          );
          currentPage = p;
          currentIndices = [i];
        }
      }
      if (currentPage != null && currentIndices.isNotEmpty) {
        blocks.add(
          _ReaderBlock(
            type: 'mushaf_page',
            detail: detail,
            pageNumber: currentPage,
            ayahIndices: currentIndices,
          ),
        );
      }
    } else {
      for (int i = 0; i < detail.ayahs.length; i++) {
        blocks.add(
          _ReaderBlock(
            type: 'verse_row',
            detail: detail,
            ayahIndex: i,
          ),
        );
      }
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
            IconButton(
              tooltip: t.settings,
              icon: const Icon(Icons.settings_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
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
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => RepaintBoundary(
                            child: _renderBlock(
                              _forwardBlocks[index],
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
      return _buildSurahHeader(
        block.detail.summary,
        t,
        cs,
        styles,
        isFirst: isFirst,
      );
    }
    if (block.type == 'mushaf_page') {
      return _buildMushafPageBlock(
        detail: block.detail,
        pageNumber: block.pageNumber!,
        indices: block.ayahIndices!,
        showTranslation: showTranslation,
        selectedTranslations: selectedTranslations,
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
    AppStrings t,
    ColorScheme cs,
    _ReaderTextStyles styles, {
    required bool isFirst,
  }) {
    final showBismillah = summary.number != 1 && summary.number != 9;
    return Column(
      key: _headerKeys[summary.number],
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: isFirst ? 2 : 24, bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.primary.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Text(
                summary.nameArabic,
                textDirection: TextDirection.rtl,
                style: styles.surahTitle,
              ),
              const SizedBox(height: 2),
              Text(
                '${summary.englishName} • ${summary.numberOfAyahs} ${t.ayahsLabel}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        if (showBismillah)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
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
    required SurahDetail detail,
    required int pageNumber,
    required List<int> indices,
    required bool showTranslation,
    required List<String> selectedTranslations,
    required AppStrings t,
    required ColorScheme cs,
    required Color scaffoldBg,
    required _ReaderTextStyles styles,
  }) {
    final firstAyah = detail.ayahs[indices.first];
    final spans = <InlineSpan>[];

    for (final i in indices) {
      final ayah = detail.ayahs[i];
      spans.add(TextSpan(text: ayah.arabicText));
      spans.add(
        TextSpan(
          text: ApiConfig.ayahEndMarker(ayah.numberInSurah),
          style: styles.arabicMarker,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                style: styles.arabicBase,
                children: spans,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          if (showTranslation) ...[
            const Divider(height: 24),
            ...indices.map((i) {
              final ayah = detail.ayahs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: selectedTranslations.map((code) {
                    final txt = detail.translationAt(code, i);
                    if (txt.isEmpty) return const SizedBox.shrink();
                    final isAr = code == 'ar';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Directionality(
                        textDirection:
                            isAr ? TextDirection.rtl : TextDirection.ltr,
                        child: Text(
                          '(${ayah.numberInSurah}) $txt',
                          textAlign: isAr ? TextAlign.right : TextAlign.left,
                          style: styles.forTranslation(code),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${t.juzLabel} ${firstAyah.juz}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${t.pageLabel} $pageNumber',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                onPressed: () {
                  final key =
                      '${detail.summary.number}:${firstAyah.numberInSurah}';
                  ref.read(bookmarksProvider.notifier).toggle(key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t.bookmarkSaved),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
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
