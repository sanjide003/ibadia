import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/api_config.dart';
import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/surah_model.dart';
import '../providers/quran_providers.dart';
import 'export_screen.dart';
import 'settings_screen.dart';
import 'surah_reader_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _quranTabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _quranTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _quranTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastRead = ref.watch(lastReadProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';

    final Color headerBg =
        isDark ? AppBranding.darkEmerald : AppBranding.headerEmerald;
    final Color canvasBg = isDark
        ? const Color(0xFF0A0D0C)
        : (isSepia ? const Color(0xFFFBF6E9) : const Color(0xFFF3F6F4));
    final Color cardBg = isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white);
    final Color cardBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6));

    final String appBarTitle = _tabIndex == 0
        ? t.appTitle
        : (_tabIndex == 1 ? t.bookmarksTab : t.exportTab);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: canvasBg,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: headerBg,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: _tabIndex == 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        AppBranding.logoAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      appBarTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  appBarTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
          actions: [
            Builder(
              builder: (drawerCtx) => IconButton(
                tooltip: t.settings,
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(drawerCtx).openEndDrawer(),
              ),
            ),
          ],
          bottom: _tabIndex == 0
              ? TabBar(
                  controller: _quranTabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  tabs: [
                    Tab(text: t.surahTabLabel),
                    Tab(text: t.juzTabLabel),
                  ],
                )
              : null,
        ),
        endDrawer: const CompactSettingsDrawer(),
        body: _tabIndex == 0
            ? Stack(
                children: [
                  TabBarView(
                    controller: _quranTabController,
                    children: [
                      // 1. Surah Tab View
                      _SurahTabView(
                        surahsAsync: surahsAsync,
                        lastRead: lastRead,
                        appLanguage: settings.appLanguage,
                        strings: t,
                        cs: cs,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        onRetry: () => ref.invalidate(surahListProvider),
                        onOpenSurah: (surahNo, {int? ayahNo}) =>
                            _openSurah(context, surahNo, initialAyah: ayahNo),
                      ),

                      // 2. Juz Tab View
                      _JuzTabView(
                        strings: t,
                        cs: cs,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        onOpenJuz: (juz) => _openSurah(
                          context,
                          juz.startSurah,
                          initialAyah: juz.startAyah,
                        ),
                      ),
                    ],
                  ),

                  // Floating Search Surah Pill
                  PositionedDirectional(
                    end: 16,
                    bottom: 16,
                    child: FloatingActionButton.extended(
                      heroTag: 'search_surah_pill',
                      backgroundColor: headerBg,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      icon: const Icon(Icons.search_rounded),
                      label: Text(
                        t.searchSurah,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        final list = surahsAsync.valueOrNull;
                        if (list == null || list.isEmpty) return;
                        _showSurahSearchSheet(
                          context: context,
                          surahs: list,
                          strings: t,
                          cs: cs,
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                        );
                      },
                    ),
                  ),
                ],
              )
            : _tabIndex == 1
                ? _BookmarksTab(
                    bookmarks: bookmarks,
                    surahs: surahsAsync.valueOrNull ?? const [],
                    strings: t,
                    onOpenSurah: (surahNo, {int? ayahNo}) =>
                        _openSurah(context, surahNo, initialAyah: ayahNo),
                  )
                : const ExportScreen(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (i) => setState(() => _tabIndex = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              selectedIcon: const Icon(Icons.auto_stories_rounded),
              label: t.surahsTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.bookmark_border_rounded),
              selectedIcon: const Icon(Icons.bookmark_rounded),
              label: t.bookmarksTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.file_download_outlined),
              selectedIcon: const Icon(Icons.file_download_rounded),
              label: t.exportTab,
            ),
          ],
        ),
      ),
    );
  }

  void _openSurah(BuildContext context, int surahNumber, {int? initialAyah}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          initialSurahNumber: surahNumber,
          initialAyahNumber: initialAyah,
        ),
      ),
    );
  }

  void _showSurahSearchSheet({
    required BuildContext context,
    required List<SurahSummary> surahs,
    required AppStrings strings,
    required ColorScheme cs,
    required Color cardBg,
    required Color cardBorder,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final filtered = surahs.where((s) {
              if (query.isEmpty) return true;
              return s.englishName.toLowerCase().contains(query) ||
                  s.nameArabic.contains(query) ||
                  s.number.toString() == query;
            }).toList();

            return Directionality(
              textDirection: strings.textDirection,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.78,
                minChildSize: 0.5,
                maxChildSize: 0.94,
                builder: (_, scrollCtrl) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: strings.searchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) => setSheetState(
                            () => query = v.trim().toLowerCase(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) {
                            final surah = filtered[idx];
                            return _SurahCardTile(
                              key: ValueKey('search_${surah.number}'),
                              surah: surah,
                              strings: strings,
                              cs: cs,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              onTap: () {
                                Navigator.pop(ctx);
                                _openSurah(context, surah.number);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SurahTabView extends StatelessWidget {
  final AsyncValue<List<SurahSummary>> surahsAsync;
  final dynamic lastRead;
  final String appLanguage;
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onRetry;
  final void Function(int surahNo, {int? ayahNo}) onOpenSurah;

  const _SurahTabView({
    required this.surahsAsync,
    required this.lastRead,
    required this.appLanguage,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    required this.onRetry,
    required this.onOpenSurah,
  });

  @override
  Widget build(BuildContext context) {
    return surahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 42),
              const SizedBox(height: 12),
              Text(strings.loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text(strings.retry)),
            ],
          ),
        ),
      ),
      data: (surahs) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
          itemCount: surahs.length + 2,
          itemBuilder: (context, index) {
            // Item 0: Optional Last Read resume banner
            if (index == 0) {
              if (lastRead == null) return const SizedBox.shrink();
              final surahLabel = appLanguage == 'ar' &&
                      (lastRead.surahArabicName as String).isNotEmpty
                  ? lastRead.surahArabicName
                  : lastRead.surahName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onOpenSurah(
                      lastRead.surahNumber as int,
                      ayahNo: lastRead.ayahNumber as int,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: cs.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.lastRead,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '$surahLabel — ${strings.ayahLabel} ${lastRead.ayahNumber}',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: cs.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Item 1: Commonly Recited Calligraphy Card Section
            if (index == 1) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.commonlyRecited,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 98,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ApiConfig.featuredSurahs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, idx) {
                          final item = ApiConfig.featuredSurahs[idx];
                          final surahNo = item['number'] as int;
                          final label =
                              (item[appLanguage] ?? item['en']) as String;
                          final arabicCalligraphy = item['ar'] as String;

                          return Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onOpenSurah(surahNo),
                              child: Container(
                                width: 104,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      arabicCalligraphy,
                                      textDirection: TextDirection.rtl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.amiri(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            // Items 2..115: 114 Surah Cards
            final surah = surahs[index - 2];
            return RepaintBoundary(
              child: _SurahCardTile(
                key: ValueKey(surah.number),
                surah: surah,
                strings: strings,
                cs: cs,
                cardBg: cardBg,
                cardBorder: cardBorder,
                onTap: () => onOpenSurah(surah.number),
              ),
            );
          },
        );
      },
    );
  }
}

class _JuzTabView extends StatelessWidget {
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final ValueChanged<JuzInfo> onOpenJuz;

  const _JuzTabView({
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    required this.onOpenJuz,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 92),
      itemCount: ApiConfig.juzCatalog.length,
      itemBuilder: (context, index) {
        final juz = ApiConfig.juzCatalog[index];
        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onOpenJuz(juz),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Leading solid emerald circle with Arabic-Indic Juz numeral
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ApiConfig.toArabicNumber(juz.number),
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Middle Arabic Juz title + Opening cue
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              juz.arabicName,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            Text(
                              juz.openingCue,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 14.5,
                                color: cs.onSurfaceVariant,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Trailing starting Mushaf Page badge
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${juz.startPage}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurahCardTile extends StatelessWidget {
  final SurahSummary surah;
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  const _SurahCardTile({
    super.key,
    required this.surah,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _IslamicStarNumberBadge(
                  numberText: ApiConfig.toArabicNumber(surah.number),
                  color: cs.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.lang == 'ar'
                            ? surah.nameArabic
                            : surah.englishName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${strings.revelationLabel(surah.revelationType)} • ${surah.numberOfAyahs} ${strings.ayahsLabel}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 8-pointed Rub el Hizb Islamic star outline with centered Arabic-Indic Surah numeral.
class _IslamicStarNumberBadge extends StatelessWidget {
  final String numberText;
  final Color color;

  const _IslamicStarNumberBadge({
    required this.numberText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: CustomPaint(
        painter: _RubElHizbPainter(color: color),
        child: Center(
          child: Text(
            numberText,
            style: GoogleFonts.amiri(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RubElHizbPainter extends CustomPainter {
  final Color color;

  const _RubElHizbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final side = size.width * 0.62;
    final half = side / 2;

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Rect.fromCenter(center: Offset.zero, width: side, height: side);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawRect(rect, stroke);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(rect, stroke);
    canvas.restore();

    // Inner subtle circle accent
    canvas.drawCircle(
      center,
      half * 0.88,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RubElHizbPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _BookmarksTab extends StatelessWidget {
  final List<String> bookmarks;
  final List<SurahSummary> surahs;
  final AppStrings strings;
  final void Function(int surahNo, {int? ayahNo}) onOpenSurah;

  const _BookmarksTab({
    required this.bookmarks,
    required this.surahs,
    required this.strings,
    required this.onOpenSurah,
  });

  SurahSummary? _findSurah(int surahNo) {
    for (final s in surahs) {
      if (s.number == surahNo) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return Center(child: Text(strings.noBookmarks));
    }
    final cs = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = bookmarks[index];
        final isFullSurah = key.startsWith('surah:');
        if (isFullSurah) {
          final surahNo = int.tryParse(key.substring(6)) ?? 1;
          final summary = _findSurah(surahNo);
          final title = summary == null
              ? '${strings.surahLabel} $surahNo'
              : (strings.lang == 'ar'
                  ? '${summary.number}. ${summary.nameArabic}'
                  : '${summary.number}. ${summary.englishName}');

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: const Icon(Icons.menu_book_rounded, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    strings.fullSurahBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: summary != null
                ? Text(
                    '${summary.numberOfAyahs} ${strings.ayahsLabel} • ${summary.nameArabic}',
                    style: const TextStyle(fontSize: 12.5),
                  )
                : null,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onOpenSurah(surahNo),
          );
        }

        final parts = key.split(':');
        final surahNo = int.tryParse(parts.first) ?? 1;
        final ayahNo = parts.length > 1 ? parts[1] : '1';
        final summary = _findSurah(surahNo);
        final surahTitle = summary == null
            ? '${strings.surahLabel} $surahNo'
            : (strings.lang == 'ar'
                ? summary.nameArabic
                : '${summary.number}. ${summary.englishName}');

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest,
            foregroundColor: cs.primary,
            child: const Icon(Icons.bookmark_rounded, size: 20),
          ),
          title: Text(
            '$surahTitle — ${strings.ayahLabel} $ayahNo',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onOpenSurah(
            surahNo,
            ayahNo: int.tryParse(ayahNo),
          ),
        );
      },
    );
  }
}
