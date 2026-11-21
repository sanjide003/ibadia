import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/api_config.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastRead = ref.watch(lastReadProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            t.appTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
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
        body: _tabIndex == 0
            ? Column(
                children: [
                  if (lastRead != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openSurah(context, lastRead.surahNumber),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                color: colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.lastRead,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.8),
                                      ),
                                    ),
                                    Text(
                                      '${settings.appLanguage == 'ar' && lastRead.surahArabicName.isNotEmpty ? lastRead.surahArabicName : lastRead.surahName} — ${t.ayahLabel} ${lastRead.ayahNumber}',
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 15,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Single-line horizontal swipeable Important Surahs bar
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: ApiConfig.featuredSurahs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final item = ApiConfig.featuredSurahs[idx];
                        final surahNo = item['number'] as int;
                        final label =
                            (item[settings.appLanguage] ?? item['en']) as String;
                        return ActionChip(
                          avatar: CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            radius: 10,
                            child: Text(
                              '$surahNo',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          label: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () => _openSurah(context, surahNo),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: t.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(
                        () => _searchQuery = val.trim().toLowerCase(),
                      ),
                    ),
                  ),

                  Expanded(
                    child: surahsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.wifi_off_rounded, size: 42),
                              const SizedBox(height: 12),
                              Text(
                                t.loadError,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () =>
                                    ref.invalidate(surahListProvider),
                                child: Text(t.retry),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (surahs) {
                        final filtered = surahs.where((s) {
                          if (_searchQuery.isEmpty) return true;
                          return s.englishName
                                  .toLowerCase()
                                  .contains(_searchQuery) ||
                              s.nameArabic.contains(_searchQuery) ||
                              s.number.toString() == _searchQuery;
                        }).toList();

                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final surah = filtered[index];
                            return RepaintBoundary(
                              child: _SurahTile(
                                key: ValueKey(surah.number),
                                surah: surah,
                                strings: t,
                                onTap: () => _openSurah(context, surah.number),
                              ),
                            );
                          },
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
                    onOpenSurah: (surahNo) => _openSurah(context, surahNo),
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

  void _openSurah(BuildContext context, int surahNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(initialSurahNumber: surahNumber),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final SurahSummary surah;
  final AppStrings strings;
  final VoidCallback onTap;

  const _SurahTile({
    super.key,
    required this.surah,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        child: Text(
          '${surah.number}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      title: Text(
        strings.lang == 'ar' ? surah.nameArabic : surah.englishName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${strings.revelationLabel(surah.revelationType)} • ${surah.numberOfAyahs} ${strings.ayahsLabel}',
        style: const TextStyle(fontSize: 12.5),
      ),
      trailing: Text(
        surah.nameArabic,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiri(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _BookmarksTab extends StatelessWidget {
  final List<String> bookmarks;
  final List<SurahSummary> surahs;
  final AppStrings strings;
  final ValueChanged<int> onOpenSurah;

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
          onTap: () => onOpenSurah(surahNo),
        );
      },
    );
  }
}
