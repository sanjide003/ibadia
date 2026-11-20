import 'dart:async';
import 'package:flutter/material.dart';
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

class SurahReaderScreen extends ConsumerStatefulWidget {
  final int initialSurahNumber;

  const SurahReaderScreen({super.key, required this.initialSurahNumber});

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  final Key _centerKey = const ValueKey<String>('reader_center_sliver');

  /// Forward list: [initialSurah, initial+1, initial+2, ...] (scrolls down)
  final List<SurahDetail> _forwardSurahs = [];

  /// Backward list: [initial-1, initial-2, ...] (scrolls up from end of prev Surah)
  final List<SurahDetail> _backwardSurahs = [];

  /// GlobalKeys on Surah header banners ONLY — used for flicker-free header detection
  final Map<int, GlobalKey> _headerKeys = {};

  bool _isInitialLoading = true;
  bool _isLoadingNext = false;
  bool _isLoadingPrev = false;
  String? _errorText;
  SurahSummary? _activeHeaderSummary;

  String _loadedTransKey = '';

  // Auto-scroll state
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  DateTime _lastHeaderCheck = DateTime.fromMillisecondsSinceEpoch(0);

  // Normalized 0.0..1.0 position while dragging (guaranteed visible in BOTH portrait & landscape)
  double? _dragRelX;
  double? _dragRelY;

  @override
  void initState() {
    super.initState();
    _loadInitialSurah();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _requiredTranslations(AppSettings s) {
    if (!s.showTranslation) return const [];
    return s.selectedTranslations;
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
        _activeHeaderSummary = detail.summary;
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
    if (pos.pixels >= pos.maxScrollExtent - 650) {
      _loadNextSurahIfNeeded();
    }
    // Trigger previous Surah when scrolling near top
    if (pos.pixels <= pos.minScrollExtent + 650) {
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
      // Scrolled up into the lower half of the previous Surah whose header is still above screen
      resolvedNum = lowestBelow - 1;
    }

    if (resolvedNum != null && resolvedNum != _activeHeaderSummary?.number) {
      final summary = byNum[resolvedNum]!;
      setState(() => _activeHeaderSummary = summary);
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

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _autoScrollTimer?.cancel();
      setState(() => _isAutoScrolling = false);
      return;
    }
    setState(() => _isAutoScrolling = true);
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final speed = ref.read(settingsProvider).autoScrollSpeed;
      final step = speed * 0.9;
      final maxExt = _scrollController.position.maxScrollExtent;
      final nextOffset = _scrollController.offset + step;
      if (nextOffset >= maxExt - 450) {
        _loadNextSurahIfNeeded();
      }
      if (nextOffset >= maxExt) {
        if (_forwardSurahs.isNotEmpty &&
            _forwardSurahs.last.summary.number >= 114) {
          _autoScrollTimer?.cancel();
          setState(() => _isAutoScrolling = false);
        }
      } else {
        _scrollController.jumpTo(nextOffset);
      }
    });
  }

  /// Long-press quick speed control modal right from the floating button
  void _showQuickSpeedSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, modalRef, _) {
            final settings = modalRef.watch(settingsProvider);
            final notifier = modalRef.read(settingsProvider.notifier);
            final t = modalRef.watch(stringsProvider);
            final presets = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0];

            return SafeArea(
              child: Directionality(
                textDirection: t.textDirection,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${t.autoScrollSpeed}: ${settings.autoScrollSpeed.toStringAsFixed(1)}x',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          FilledButton.tonalIcon(
                            icon: Icon(
                              _isAutoScrolling
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(_isAutoScrolling ? t.pause : t.play),
                            onPressed: () {
                              _toggleAutoScroll();
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
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
    final settings = ref.watch(settingsProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    // Lazy-fetch translation editions if toggled in Settings
    final desiredKey = _requiredTranslations(settings).join(',');
    if (!_isInitialLoading && desiredKey != _loadedTransKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reloadLoadedSurahsForTranslations(settings);
      });
    }

    String headerTitle = '${t.surahLabel} ${widget.initialSurahNumber}';
    if (_activeHeaderSummary != null) {
      headerTitle = settings.appLanguage == 'ar'
          ? _activeHeaderSummary!.nameArabic
          : '${_activeHeaderSummary!.number}. ${_activeHeaderSummary!.englishName}';
    }

    // Build forward blocks (initialSurah -> 114)
    final forwardBlocks = <_ReaderBlock>[];
    for (final s in _forwardSurahs) {
      forwardBlocks.addAll(_blocksForSurah(s, settings.readingMode));
    }

    // Build backward blocks (initialSurah - 1 -> 1) in reverse order so index 0
    // (the LAST page/ayah of previous Surah) sits immediately above initialSurah!
    final backwardBlocks = <_ReaderBlock>[];
    for (final s in _backwardSurahs) {
      final normalOrder = _blocksForSurah(s, settings.readingMode);
      backwardBlocks.addAll(normalOrder.reversed);
    }

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            headerTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              const double fabSize = 58.0;
              const double margin = 12.0;
              final double availW =
                  (constraints.maxWidth - fabSize - margin * 2)
                      .clamp(1.0, 4000.0);
              final double availH =
                  (constraints.maxHeight - fabSize - margin * 2)
                      .clamp(1.0, 4000.0);

              // Default bottom-right (1.0, 1.0) in normalized coordinates -> always visible in BOTH portrait & landscape!
              final double relX =
                  (_dragRelX ?? settings.fabRelX ?? 1.0).clamp(0.0, 1.0);
              final double relY =
                  (_dragRelY ?? settings.fabRelY ?? 1.0).clamp(0.0, 1.0);

              final double leftPx = margin + relX * availW;
              final double topPx = margin + relY * availH;

              return Stack(
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
                        if (backwardBlocks.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _renderBlock(
                                  backwardBlocks[index],
                                  settings,
                                  bookmarks,
                                  t,
                                  cs,
                                  isFirst: false,
                                ),
                                childCount: backwardBlocks.length,
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
                              (context, index) => _renderBlock(
                                forwardBlocks[index],
                                settings,
                                bookmarks,
                                t,
                                cs,
                                isFirst: index == 0,
                              ),
                              childCount: forwardBlocks.length,
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

                  // Draggable + Tap (Play/Pause) + Long-Press (Speed Control) Floating Button
                  // Always rendered inside SafeArea bounds in BOTH Portrait & Landscape!
                  Positioned(
                    left: leftPx,
                    top: topPx,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          final nextX =
                              ((leftPx + details.delta.dx - margin) / availW)
                                  .clamp(0.0, 1.0);
                          final nextY =
                              ((topPx + details.delta.dy - margin) / availH)
                                  .clamp(0.0, 1.0);
                          _dragRelX = nextX;
                          _dragRelY = nextY;
                        });
                      },
                      onPanEnd: (_) {
                        if (_dragRelX != null && _dragRelY != null) {
                          ref.read(settingsProvider.notifier).update(
                                settings.copyWith(
                                  fabRelX: _dragRelX,
                                  fabRelY: _dragRelY,
                                ),
                              );
                        }
                      },
                      onTap: _toggleAutoScroll,
                      onLongPress: _showQuickSpeedSheet,
                      child: Material(
                        elevation: 6,
                        shape: const CircleBorder(),
                        color:
                            _isAutoScrolling ? cs.primary : cs.primaryContainer,
                        child: SizedBox(
                          width: fabSize,
                          height: fabSize,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isAutoScrolling
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 25,
                                color: _isAutoScrolling
                                    ? cs.onPrimary
                                    : cs.onPrimaryContainer,
                              ),
                              Text(
                                '${settings.autoScrollSpeed.toStringAsFixed(1)}x',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _isAutoScrolling
                                      ? cs.onPrimary
                                      : cs.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _renderBlock(
    _ReaderBlock block,
    AppSettings settings,
    List<String> bookmarks,
    AppStrings t,
    ColorScheme cs, {
    required bool isFirst,
  }) {
    if (block.type == 'surah_header') {
      return _buildSurahHeader(
        block.detail.summary,
        settings,
        t,
        cs,
        isFirst: isFirst,
      );
    }
    if (block.type == 'mushaf_page') {
      return _buildMushafPageBlock(
        detail: block.detail,
        pageNumber: block.pageNumber!,
        indices: block.ayahIndices!,
        settings: settings,
        t: t,
        cs: cs,
      );
    }
    return _buildVerseRow(
      detail: block.detail,
      ayahIndex: block.ayahIndex!,
      settings: settings,
      bookmarks: bookmarks,
      t: t,
      cs: cs,
    );
  }

  Widget _buildSurahHeader(
    SurahSummary summary,
    AppSettings settings,
    AppStrings t,
    ColorScheme cs, {
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
                style: GoogleFonts.amiri(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer,
                ),
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
              style: GoogleFonts.amiri(
                fontSize: settings.arabicFontSize + 1,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMushafPageBlock({
    required SurahDetail detail,
    required int pageNumber,
    required List<int> indices,
    required AppSettings settings,
    required AppStrings t,
    required ColorScheme cs,
  }) {
    final firstAyah = detail.ayahs[indices.first];
    final spans = <InlineSpan>[];

    for (final i in indices) {
      final ayah = detail.ayahs[i];
      spans.add(TextSpan(text: ayah.arabicText));
      spans.add(
        TextSpan(
          text: ApiConfig.ayahEndMarker(ayah.numberInSurah),
          style: GoogleFonts.amiri(
            fontSize: settings.arabicFontSize * 0.84,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                style: GoogleFonts.amiri(
                  fontSize: settings.arabicFontSize,
                  height: 2.15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                children: spans,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
          if (settings.showTranslation) ...[
            const Divider(height: 24),
            ...indices.map((i) {
              final ayah = detail.ayahs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: settings.selectedTranslations.map((code) {
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
                          style: _translationStyle(code, settings),
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
    required AppSettings settings,
    required List<String> bookmarks,
    required AppStrings t,
    required ColorScheme cs,
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
                    style: GoogleFonts.amiri(
                      fontSize: settings.arabicFontSize,
                      height: 2.1,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    children: [
                      TextSpan(text: ayah.arabicText),
                      TextSpan(
                        text: ApiConfig.ayahEndMarker(ayah.numberInSurah),
                        style: GoogleFonts.amiri(
                          fontSize: settings.arabicFontSize * 0.85,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (settings.showTranslation)
                ...settings.selectedTranslations.map((code) {
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
                        style: _translationStyle(code, settings),
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
                      if (settings.showTranslation) {
                        for (final code in settings.selectedTranslations) {
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

  TextStyle _translationStyle(String code, AppSettings settings) {
    if (code == 'ml') {
      return GoogleFonts.notoSansMalayalam(
        fontSize: settings.translationFontSize,
        height: 1.7,
      );
    }
    if (code == 'ar') {
      return GoogleFonts.amiri(
        fontSize: settings.translationFontSize + 3,
        height: 1.8,
      );
    }
    return TextStyle(
      fontSize: settings.translationFontSize,
      height: 1.6,
    );
  }
}
