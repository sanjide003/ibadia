import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../data/adhkar_data.dart';
import '../data/asmaul_husna_data.dart';
import '../models/adhkar_tasbih_model.dart';
import '../models/islamic_features_model.dart';
import '../models/recent_activity_model.dart';
import '../models/surah_model.dart';
import '../providers/islamic_features_providers.dart';
import '../providers/quran_providers.dart';
import '../services/storage_service.dart';
import '../widgets/tajweed_widgets.dart';
import '../widgets/tv_mode_widgets.dart';
import '../widgets/web_pwa_widgets.dart';
import 'asmaul_husna_view.dart';
import 'features_views.dart';

class _DashboardQuickAction {
  final String id;
  final IconData icon;
  final Color accent;
  final String titleEn;
  final String titleMl;
  final String titleAr;
  final String subtitleEn;
  final String subtitleMl;
  final String subtitleAr;
  final List<String> keywords;
  final VoidCallback onTap;

  const _DashboardQuickAction({
    required this.id,
    required this.icon,
    required this.accent,
    required this.titleEn,
    required this.titleMl,
    required this.titleAr,
    required this.subtitleEn,
    required this.subtitleMl,
    required this.subtitleAr,
    required this.keywords,
    required this.onTap,
  });

  String titleFor(String lang) {
    if (lang == 'ml') return titleMl;
    if (lang == 'ar') return titleAr;
    return titleEn;
  }

  String subtitleFor(String lang) {
    if (lang == 'ml') return subtitleMl;
    if (lang == 'ar') return subtitleAr;
    return subtitleEn;
  }
}

class DashboardView extends ConsumerStatefulWidget {
  final void Function(int tabIndex, {int? subTab}) onNavigateTab;
  final Future<void> Function(String featureId) onOpenFeature;
  final void Function(
    int surahNo, {
    int? ayahNo,
    double? anchorOffsetPx,
    String? savedReadingMode,
  }) onOpenSurah;

  const DashboardView({
    super.key,
    required this.onNavigateTab,
    required this.onOpenFeature,
    required this.onOpenSurah,
  });

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  ({Color cardBg, Color cardBorder, Color headerBg}) _palette(
    BuildContext context,
    AppSettings settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';
    return (
      headerBg: isDark ? AppBranding.darkEmerald : AppBranding.headerEmerald,
      cardBg: isDark
          ? const Color(0xFF141A17)
          : (isSepia ? const Color(0xFFFFFDF7) : Colors.white),
      cardBorder: isDark
          ? const Color(0xFF23302A)
          : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6)),
    );
  }

  void _recordSimpleActivity({
    required String id,
    required RecentActivityType type,
    required String titleEn,
    required String titleMl,
    required String titleAr,
    required String subtitleEn,
    required String subtitleMl,
    required String subtitleAr,
    int? featureSubTab,
    int? quranSubTab,
  }) {
    ref.read(recentActivityProvider.notifier).record(
          RecentActivityEntry(
            id: id,
            type: type,
            titleEn: titleEn,
            titleMl: titleMl,
            titleAr: titleAr,
            subtitleEn: subtitleEn,
            subtitleMl: subtitleMl,
            subtitleAr: subtitleAr,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            featureSubTab: featureSubTab,
            quranSubTab: quranSubTab,
          ),
        );
  }

  void _openTajweedGuide(AppStrings t) {
    _recordSimpleActivity(
      id: 'tool:tajweed',
      type: RecentActivityType.tajweed,
      titleEn: 'Tajweed Guide',
      titleMl: 'തജ്‌വീദ് നിയമം',
      titleAr: 'أحكام التجويد',
      subtitleEn: 'Color Rules & Examples',
      subtitleMl: 'കളർ കോഡ് & നിയമങ്ങൾ',
      subtitleAr: 'دليل ألوان التجويد',
    );
    showTajweedLegendSheet(context, strings: t);
  }

  void _openAutoSilent(AppStrings t) {
    _recordSimpleActivity(
      id: 'tool:auto_silent',
      type: RecentActivityType.autoSilent,
      titleEn: 'Auto-Silent (DND)',
      titleMl: 'ഓട്ടോ സൈലന്റ് (DND)',
      titleAr: 'الصامت التلقائي',
      subtitleEn: 'Prayer Quiet Mode',
      subtitleMl: 'നിസ്കാര സൈലന്റ് മോഡ്',
      subtitleAr: 'صامت وقت الصلاة',
      featureSubTab: 0,
    );
    showAutoSilentSheet(context, t);
  }

  void _handleRecentTap(RecentActivityEntry entry, AppStrings t, String lang) {
    ref.read(recentActivityProvider.notifier).record(
          RecentActivityEntry(
            id: entry.id,
            type: entry.type,
            titleEn: entry.titleEn,
            titleMl: entry.titleMl,
            titleAr: entry.titleAr,
            subtitleEn: entry.subtitleEn,
            subtitleMl: entry.subtitleMl,
            subtitleAr: entry.subtitleAr,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            surahNumber: entry.surahNumber,
            ayahNumber: entry.ayahNumber,
            featureSubTab: entry.featureSubTab,
            quranSubTab: entry.quranSubTab,
            asmaIndex: entry.asmaIndex,
          ),
        );

    switch (entry.type) {
      case RecentActivityType.surah:
      case RecentActivityType.juz:
      case RecentActivityType.bookmark:
        if (entry.surahNumber != null && entry.surahNumber! > 0) {
          widget.onOpenSurah(entry.surahNumber!, ayahNo: entry.ayahNumber);
        } else {
          widget.onNavigateTab(1, subTab: entry.quranSubTab ?? 0);
        }
        break;
      case RecentActivityType.prayer:
        widget.onOpenFeature('prayer_times');
        break;
      case RecentActivityType.hijri:
        widget.onOpenFeature('hijri_calendar');
        break;
      case RecentActivityType.adhkar:
        widget.onOpenFeature('adhkar');
        break;
      case RecentActivityType.counter:
        widget.onOpenFeature('tasbih');
        break;
      case RecentActivityType.asmaulHusna:
        widget.onOpenFeature('names_99');
        if (entry.asmaIndex != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final currentSettings = ref.read(settingsProvider);
            showAsmaulHusnaDetailSheet(
              context,
              initialIndex: entry.asmaIndex!,
              strings: t,
              appLanguage: lang,
              arabicFontSize: currentSettings.arabicFontSize,
              translationFontSize: currentSettings.translationFontSize,
            );
          });
        }
        break;
      case RecentActivityType.tajweed:
        showTajweedLegendSheet(context, strings: t);
        break;
      case RecentActivityType.autoSilent:
        showAutoSilentSheet(context, t);
        break;
      case RecentActivityType.ibadah:
        final featureId = entry.id.startsWith('tool:ibadah_')
            ? entry.id.substring(5)
            : 'ibadah_salah';
        widget.onOpenFeature(featureId);
        break;
      case RecentActivityType.exportPdf:
        widget.onOpenFeature('export');
        break;
      case RecentActivityType.settings:
        widget.onNavigateTab(2);
        break;
    }
  }

  IconData _iconForRecent(RecentActivityType type) {
    switch (type) {
      case RecentActivityType.surah:
        return Icons.menu_book_rounded;
      case RecentActivityType.juz:
        return Icons.grid_view_rounded;
      case RecentActivityType.prayer:
        return Icons.mosque_rounded;
      case RecentActivityType.hijri:
        return Icons.calendar_month_rounded;
      case RecentActivityType.adhkar:
        return Icons.auto_stories_rounded;
      case RecentActivityType.counter:
        return Icons.touch_app_rounded;
      case RecentActivityType.asmaulHusna:
        return Icons.auto_awesome_rounded;
      case RecentActivityType.tajweed:
        return Icons.palette_rounded;
      case RecentActivityType.autoSilent:
        return Icons.do_not_disturb_on_rounded;
      case RecentActivityType.ibadah:
        return Icons.menu_book_outlined;
      case RecentActivityType.bookmark:
        return Icons.bookmark_rounded;
      case RecentActivityType.exportPdf:
        return Icons.ios_share_rounded;
      case RecentActivityType.settings:
        return Icons.settings_rounded;
    }
  }

  void _showUniversalSearchSheet({
    required BuildContext context,
    required AppStrings strings,
    required AppSettings settings,
    required List<_DashboardQuickAction> allActions,
    required List<SurahSummary> surahs,
    required ({Color cardBg, Color cardBorder, Color headerBg}) palette,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        String rawQuery = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final cs = Theme.of(sheetCtx).colorScheme;
            final trimmedQuery = rawQuery.trim().toLowerCase();
            final bool isSearching = trimmedQuery.isNotEmpty;

            final List<_DashboardQuickAction> matchedActions = isSearching
                ? allActions.where((a) {
                    return a.titleEn.toLowerCase().contains(trimmedQuery) ||
                        a.titleMl.toLowerCase().contains(trimmedQuery) ||
                        a.titleAr.contains(rawQuery.trim()) ||
                        a.keywords
                            .any((k) => k.toLowerCase().contains(trimmedQuery));
                  }).toList()
                : allActions.take(6).toList();

            final List<SurahSummary> matchedSurahs = isSearching
                ? surahs
                    .where((s) =>
                        s.number.toString() == trimmedQuery ||
                        s.englishName.toLowerCase().contains(trimmedQuery) ||
                        s.nameArabic.contains(rawQuery.trim()))
                    .take(6)
                    .toList()
                : const [];

            final List<AsmaulHusnaItem> matchedNames = isSearching
                ? AsmaulHusnaCatalog.names
                    .where((n) =>
                        n.number.toString() == trimmedQuery ||
                        n.transliteration
                            .toLowerCase()
                            .contains(trimmedQuery) ||
                        n.englishMeaning
                            .toLowerCase()
                            .contains(trimmedQuery) ||
                        n.malayalamMeaning
                            .toLowerCase()
                            .contains(trimmedQuery) ||
                        n.arabicMeaning.contains(rawQuery.trim()) ||
                        n.arabic.contains(rawQuery.trim()))
                    .take(6)
                    .toList()
                : const [];

            final List<AdhkarEntry> matchedAdhkar = isSearching
                ? AdhkarCatalog.entries
                    .where((d) =>
                        d.titleEn.toLowerCase().contains(trimmedQuery) ||
                        d.titleMl.toLowerCase().contains(trimmedQuery) ||
                        d.arabic.contains(rawQuery.trim()))
                    .take(5)
                    .toList()
                : const [];

            final bool hasAnyMatch = matchedActions.isNotEmpty ||
                matchedSurahs.isNotEmpty ||
                matchedNames.isNotEmpty ||
                matchedAdhkar.isNotEmpty;

            return Directionality(
              textDirection: strings.textDirection,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.82,
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
                            hintText: strings.dashboardSearchHint,
                            prefixIcon:
                                const Icon(Icons.search_rounded, size: 21),
                            suffixIcon: rawQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: () =>
                                        setSheetState(() => rawQuery = ''),
                                    icon:
                                        const Icon(Icons.close_rounded, size: 19),
                                  )
                                : null,
                            isDense: true,
                            filled: true,
                            fillColor: palette.cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: palette.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: palette.cardBorder),
                            ),
                          ),
                          onChanged: (v) => setSheetState(() => rawQuery = v),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          children: [
                            if (!hasAnyMatch)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: palette.cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: palette.cardBorder),
                                ),
                                child: Text(
                                  strings.noSearchResults,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              )
                            else ...[
                              if (matchedActions.isNotEmpty) ...[
                                _SearchSectionHeader(
                                  label: strings.quickActionsTitle,
                                  cs: cs,
                                ),
                                ...matchedActions.map((a) => _SearchResultTile(
                                      icon: a.icon,
                                      accent: a.accent,
                                      title: a.titleFor(settings.appLanguage),
                                      subtitle:
                                          a.subtitleFor(settings.appLanguage),
                                      cardBg: palette.cardBg,
                                      cardBorder: palette.cardBorder,
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        a.onTap();
                                      },
                                    )),
                                const SizedBox(height: 10),
                              ],
                              if (matchedSurahs.isNotEmpty) ...[
                                _SearchSectionHeader(
                                  label: strings.surahTabLabel,
                                  cs: cs,
                                ),
                                ...matchedSurahs.map((s) => _SearchResultTile(
                                      icon: Icons.menu_book_rounded,
                                      accent: cs.primary,
                                      title: '${s.number}. ${s.englishName}',
                                      subtitle:
                                          '${s.nameArabic} · ${s.numberOfAyahs} ${strings.ayahsLabel}',
                                      cardBg: palette.cardBg,
                                      cardBorder: palette.cardBorder,
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        widget.onOpenSurah(s.number);
                                      },
                                    )),
                                const SizedBox(height: 10),
                              ],
                              if (matchedNames.isNotEmpty) ...[
                                _SearchSectionHeader(
                                  label: strings.actionNames99,
                                  cs: cs,
                                ),
                                ...matchedNames.map((n) => _SearchResultTile(
                                      icon: Icons.auto_awesome_rounded,
                                      accent: const Color(0xFF8E24AA),
                                      title:
                                          '${n.number}. ${n.transliteration} — ${n.arabic}',
                                      subtitle:
                                          '${n.malayalamMeaning} · ${n.arabicMeaning}',
                                      cardBg: palette.cardBg,
                                      cardBorder: palette.cardBorder,
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        ref
                                            .read(
                                                recentActivityProvider.notifier)
                                            .record(
                                              RecentActivityEntry(
                                                id: 'asma:${n.number}',
                                                type: RecentActivityType
                                                    .asmaulHusna,
                                                titleEn:
                                                    '${n.number}. ${n.transliteration}',
                                                titleMl:
                                                    '${n.number}. ${n.malayalamMeaning}',
                                                titleAr:
                                                    '${n.number}. ${n.arabic}',
                                                subtitleEn: n.englishMeaning,
                                                subtitleMl: n.transliteration,
                                                subtitleAr: n.arabicMeaning,
                                                timestampMs: DateTime.now()
                                                    .millisecondsSinceEpoch,
                                                featureSubTab: 4,
                                                asmaIndex: n.number - 1,
                                              ),
                                            );
                                        showAsmaulHusnaDetailSheet(
                                          context,
                                          initialIndex: n.number - 1,
                                          strings: strings,
                                          appLanguage: settings.appLanguage,
                                          arabicFontSize: settings.arabicFontSize,
                                          translationFontSize:
                                              settings.translationFontSize,
                                        );
                                      },
                                    )),
                                const SizedBox(height: 10),
                              ],
                              if (matchedAdhkar.isNotEmpty) ...[
                                _SearchSectionHeader(
                                  label: strings.actionAdhkar,
                                  cs: cs,
                                ),
                                ...matchedAdhkar.map((d) => _SearchResultTile(
                                      icon: Icons.auto_stories_rounded,
                                      accent: const Color(0xFF0B7A43),
                                      title: d.titleFor(
                                          contentLangFor(settings.appLanguage)),
                                      subtitle: d.reference,
                                      cardBg: palette.cardBg,
                                      cardBorder: palette.cardBorder,
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _recordSimpleActivity(
                                          id: 'tool:adhkar',
                                          type: RecentActivityType.adhkar,
                                          titleEn: d.titleEn,
                                          titleMl: d.titleMl,
                                          titleAr: d.titleEn,
                                          subtitleEn: d.reference,
                                          subtitleMl: d.reference,
                                          subtitleAr: d.reference,
                                          featureSubTab: 2,
                                        );
                                        widget.onOpenFeature('adhkar');
                                      },
                                    )),
                              ],
                            ],
                          ],
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final surahs = ref.watch(surahListProvider).valueOrNull ?? const [];
    final recent = ref.watch(recentActivityProvider);
    final lastRead = ref.watch(lastReadProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _palette(context, settings);
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: settings.tvModeEnabled,
      normalMaxWidth: 1040,
    );

    // Core 6 tools rendered right beneath the floating prayer hero card
    final topTools = <_DashboardQuickAction>[
      _DashboardQuickAction(
        id: 'read_quran',
        icon: Icons.menu_book_rounded,
        accent: cs.primary,
        titleEn: t.actionReadQuran,
        titleMl: t.actionReadQuran,
        titleAr: t.actionReadQuran,
        subtitleEn: '114 Surahs & Tajweed',
        subtitleMl: '114 സൂറത്തുകൾ & തജ്‌വീദ്',
        subtitleAr: '114 سورة بالتجويد',
        keywords: const ['quran', 'surah', 'read', 'ഖുർആൻ', 'സൂറത്ത്'],
        onTap: () => widget.onNavigateTab(1, subTab: 0),
      ),
      _DashboardQuickAction(
        id: 'prayer_times',
        icon: Icons.mosque_rounded,
        accent: const Color(0xFF0B7A43),
        titleEn: t.actionPrayer,
        titleMl: t.actionPrayer,
        titleAr: t.actionPrayer,
        subtitleEn: 'Adhan, Iqamah & Alarms',
        subtitleMl: 'ബാങ്ക്, ഇഖാമത്ത്, അലാറം',
        subtitleAr: 'الأذان والإقامة',
        keywords: const ['prayer', 'salah', 'adhan', 'നിസ്കാരം', 'ബാങ്ക്'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:prayer',
            type: RecentActivityType.prayer,
            titleEn: 'Prayer Times',
            titleMl: 'നിസ്കാര സമയം',
            titleAr: 'أوقات الصلاة',
            subtitleEn: settings.displayLocationLabel,
            subtitleMl: settings.displayLocationLabel,
            subtitleAr: settings.displayLocationLabel,
            featureSubTab: 0,
          );
          widget.onOpenFeature('prayer_times');
        },
      ),
      _DashboardQuickAction(
        id: 'hijri_calendar',
        icon: Icons.calendar_month_rounded,
        accent: const Color(0xFF1565C0),
        titleEn: t.actionHijri,
        titleMl: t.actionHijri,
        titleAr: t.actionHijri,
        subtitleEn: 'Islamic Calendar',
        subtitleMl: 'ഹിജ്‌രി കലണ്ടർ',
        subtitleAr: 'التقويم الهجري',
        keywords: const ['hijri', 'calendar', 'date', 'ഹിജ്‌രി', 'കലണ്ടർ'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:hijri',
            type: RecentActivityType.hijri,
            titleEn: 'Hijri Calendar',
            titleMl: 'ഹിജ്‌രി കലണ്ടർ',
            titleAr: 'التقويم الهجري',
            subtitleEn: 'Monthly Hijri Dates',
            subtitleMl: 'ഇസ്‌ലാമിക കലണ്ടർ',
            subtitleAr: 'التاريخ الهجري',
            featureSubTab: 1,
          );
          widget.onOpenFeature('hijri_calendar');
        },
      ),
      _DashboardQuickAction(
        id: 'daily_adhkar',
        icon: Icons.auto_stories_rounded,
        accent: const Color(0xFF00796B),
        titleEn: t.actionAdhkar,
        titleMl: t.actionAdhkar,
        titleAr: t.actionAdhkar,
        subtitleEn: 'Hisnul Muslim',
        subtitleMl: 'ദിനചര്യ ദുആകൾ',
        subtitleAr: 'حصن المسلم',
        keywords: const ['adhkar', 'dua', 'morning', 'evening', 'ദിക്ർ', 'ദുആ'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:adhkar',
            type: RecentActivityType.adhkar,
            titleEn: 'Daily Adhkar',
            titleMl: 'ദിക്ർ & ദുആ',
            titleAr: 'الأذكار اليومية',
            subtitleEn: 'Morning & Evening',
            subtitleMl: 'രാവിലെയും വൈകുന്നേരവും',
            subtitleAr: 'أذكار الصباح والمساء',
            featureSubTab: 2,
          );
          widget.onOpenFeature('adhkar');
        },
      ),
      _DashboardQuickAction(
        id: 'counter',
        icon: Icons.touch_app_rounded,
        accent: const Color(0xFF00838F),
        titleEn: t.actionCounter,
        titleMl: t.actionCounter,
        titleAr: t.actionCounter,
        subtitleEn: 'Digital Dhikr Counter',
        subtitleMl: 'ഡിജിറ്റൽ തസ്ബീഹ്',
        subtitleAr: 'مسبحة رقمية',
        keywords: const ['counter', 'tasbih', 'dhikr', 'കൗണ്ടർ', 'തസ്ബീഹ്'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:counter',
            type: RecentActivityType.counter,
            titleEn: 'Dhikr Counter',
            titleMl: 'കൗണ്ടർ',
            titleAr: 'عدّاد الأذكار',
            subtitleEn: 'Tap Counter',
            subtitleMl: 'കൗണ്ടർ',
            subtitleAr: 'تسبيح',
            featureSubTab: 3,
          );
          widget.onOpenFeature('tasbih');
        },
      ),
      _DashboardQuickAction(
        id: 'auto_silent',
        icon: Icons.do_not_disturb_on_rounded,
        accent: const Color(0xFFC62828),
        titleEn: t.actionAutoSilent,
        titleMl: t.actionAutoSilent,
        titleAr: t.actionAutoSilent,
        subtitleEn: '${settings.autoSilentDurationMinutes}m Silent Mode',
        subtitleMl: '${settings.autoSilentDurationMinutes}മി. സൈലന്റ്',
        subtitleAr: '${settings.autoSilentDurationMinutes} د صامت',
        keywords: const ['silent', 'dnd', 'mute', 'സൈലന്റ്', 'നിശബ്ദം'],
        onTap: () => _openAutoSilent(t),
      ),
    ];

    final ibadahActions = <_DashboardQuickAction>[
      _DashboardQuickAction(
        id: 'ibadah_niyyah',
        icon: Icons.record_voice_over_rounded,
        accent: const Color(0xFF047857),
        titleEn: t.actionNiyyah,
        titleMl: t.actionNiyyah,
        titleAr: t.actionNiyyah,
        subtitleEn: 'Fard & Sunnah Intentions',
        subtitleMl: 'ഫർള് & സുന്നത്ത് നിയ്യത്തുകൾ',
        subtitleAr: 'نيات الفرائض والنوافل',
        keywords: const [
          'niyyah',
          'intention',
          'fajr',
          'dhuhr',
          'asr',
          'maghrib',
          'isha',
          'witr',
          'taraweeh',
          'നിയ്യത്ത്',
        ],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:ibadah_niyyah',
            type: RecentActivityType.ibadah,
            titleEn: 'Niyyah',
            titleMl: 'നിയ്യത്ത്',
            titleAr: 'النية',
            subtitleEn: 'Fard & Sunnah Intentions',
            subtitleMl: 'ഫർള് & സുന്നത്ത് നിയ്യത്തുകൾ',
            subtitleAr: 'نيات الصلاة',
          );
          widget.onOpenFeature('ibadah_niyyah');
        },
      ),
      _DashboardQuickAction(
        id: 'ibadah_salah',
        icon: Icons.menu_book_outlined,
        accent: const Color(0xFF0F766E),
        titleEn: t.actionSalahGuide,
        titleMl: t.actionSalahGuide,
        titleAr: t.actionSalahGuide,
        subtitleEn: '7 Shart, 14 Arkan & 14 Steps',
        subtitleMl: '7 ശർത്വുകൾ, 14 ഫർളുകൾ & ക്രമം',
        subtitleAr: 'الشروط والأركان والصفة',
        keywords: const [
          'salah',
          'namaz',
          'shart',
          'arkan',
          'qunoot',
          'tashahhud',
          'fatihah',
          'നിസ്കാരം',
          'സ്വലാത്ത്',
          'അർക്കാൻ',
          'ശർത്ത്',
          'ഖുനൂത്ത്',
        ],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:ibadah_salah',
            type: RecentActivityType.ibadah,
            titleEn: 'Salah Guide',
            titleMl: 'സ്വലാത്ത് ഗൈഡ്',
            titleAr: 'دليل الصلاة',
            subtitleEn: 'Shafi\'i Step-by-Step Guide',
            subtitleMl: 'നിസ്കാരത്തിന്റെ പൂർണ്ണ ക്രമം',
            subtitleAr: 'صفة الصلاة الشافعية',
          );
          widget.onOpenFeature('ibadah_salah');
        },
      ),
      _DashboardQuickAction(
        id: 'ibadah_rawatib',
        icon: Icons.schedule_rounded,
        accent: const Color(0xFFB45309),
        titleEn: t.actionRawatibSurahs,
        titleMl: t.actionRawatibSurahs,
        titleAr: t.actionRawatibSurahs,
        subtitleEn: 'Sunnah Schedule & Surahs',
        subtitleMl: 'റവാതിബ് & ഉത്തമ സൂറത്തുകൾ',
        subtitleAr: 'السنن الرواتب والسور',
        keywords: const [
          'rawatib',
          'sunnah',
          'surah',
          'muakkadah',
          'റവാതിബ്',
          'സുന്നത്ത്',
          'സൂറത്ത്',
        ],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:ibadah_rawatib',
            type: RecentActivityType.ibadah,
            titleEn: 'Rawatib & Surahs',
            titleMl: 'റവാതിബും സൂറത്തുകളും',
            titleAr: 'الرواتب والسور',
            subtitleEn: 'Sunnah Prayers & Surahs',
            subtitleMl: 'സുന്നത്ത് നിസ്കാരങ്ങൾ',
            subtitleAr: 'الرواتب والسور المستحبة',
          );
          widget.onOpenFeature('ibadah_rawatib');
        },
      ),
      _DashboardQuickAction(
        id: 'ibadah_mayyith',
        icon: Icons.volunteer_activism_rounded,
        accent: const Color(0xFF475569),
        titleEn: t.actionMayyithGuide,
        titleMl: t.actionMayyithGuide,
        titleAr: t.actionMayyithGuide,
        subtitleEn: 'Ghusl, Kafan, 4 Takbirs & Burial',
        subtitleMl: 'മയ്യിത്ത് നിസ്കാരം & തൽഖീൻ',
        subtitleAr: 'الغسل والتكفين وصلاة الجنازة',
        keywords: const [
          'mayyith',
          'janazah',
          'funeral',
          'talqeen',
          'ghusl',
          'kafan',
          'മയ്യിത്ത്',
          'ജനാസ',
          'തൽഖീൻ',
        ],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:ibadah_mayyith',
            type: RecentActivityType.ibadah,
            titleEn: 'Mayyith Guide',
            titleMl: 'മയ്യിത്ത് ഗൈഡ്',
            titleAr: 'دليل الجنازة',
            subtitleEn: 'Janazah & Preparation',
            subtitleMl: 'മയ്യിത്ത് പരിപാലനവും നിസ്കാരവും',
            subtitleAr: 'أحكام الجنائز',
          );
          widget.onOpenFeature('ibadah_mayyith');
        },
      ),
    ];

    // Remaining 6 tools under Categories grid (balanced 3x2 layout)
    final categoryTools = <_DashboardQuickAction>[
      _DashboardQuickAction(
        id: 'juz_index',
        icon: Icons.grid_view_rounded,
        accent: const Color(0xFF00796B),
        titleEn: t.actionJuz,
        titleMl: t.actionJuz,
        titleAr: t.actionJuz,
        subtitleEn: '30 Juz Index',
        subtitleMl: '30 ജുസ്അ് പട്ടിക',
        subtitleAr: 'فهرس 30 جزء',
        keywords: const ['juz', 'para', 'ജുസ്അ്'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:juz',
            type: RecentActivityType.juz,
            titleEn: 'Juz Index',
            titleMl: 'ജുസ്അ് പട്ടിക',
            titleAr: 'الأجزاء',
            subtitleEn: '30 Juz Navigation',
            subtitleMl: 'ഖുർആൻ ജുസ്അ്',
            subtitleAr: '30 جزء',
            quranSubTab: 1,
          );
          widget.onNavigateTab(1, subTab: 1);
        },
      ),
      _DashboardQuickAction(
        id: 'bookmarks',
        icon: Icons.bookmark_rounded,
        accent: const Color(0xFFB45309),
        titleEn: t.actionBookmarks,
        titleMl: t.actionBookmarks,
        titleAr: t.actionBookmarks,
        subtitleEn: 'Saved Ayahs & Surahs',
        subtitleMl: 'സേവ് ചെയ്ത ആയത്തുകൾ',
        subtitleAr: 'الآيات المحفوظة',
        keywords: const ['bookmark', 'saved', 'ബുക്ക്‌മാർക്ക്'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:bookmarks',
            type: RecentActivityType.bookmark,
            titleEn: 'Bookmarks',
            titleMl: 'ബുക്ക്‌മാർക്ക്',
            titleAr: 'المحفوظات',
            subtitleEn: 'Saved Reading List',
            subtitleMl: 'സേവ് ചെയ്തവ',
            subtitleAr: 'قائمة الحفظ',
            quranSubTab: 2,
          );
          widget.onOpenFeature('bookmarks');
        },
      ),
      _DashboardQuickAction(
        id: 'names_99',
        icon: Icons.auto_awesome_rounded,
        accent: const Color(0xFF8E24AA),
        titleEn: t.actionNames99,
        titleMl: t.actionNames99,
        titleAr: t.actionNames99,
        subtitleEn: 'Asmaul Husna',
        subtitleMl: 'അസ്മാഉൽ ഹുസ്ന',
        subtitleAr: 'أسماء الله الحسنى',
        keywords: const ['99', 'names', 'allah', 'asma', 'നാമങ്ങൾ', 'അല്ലാഹു'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:names_99',
            type: RecentActivityType.asmaulHusna,
            titleEn: '99 Names of Allah',
            titleMl: 'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ',
            titleAr: 'أسماء الله الحسنى',
            subtitleEn: 'Arabic & Malayalam',
            subtitleMl: 'അസ്മാഉൽ ഹുസ്ന',
            subtitleAr: '99 اسماً',
            featureSubTab: 4,
          );
          widget.onOpenFeature('names_99');
        },
      ),
      _DashboardQuickAction(
        id: 'tajweed_guide',
        icon: Icons.palette_rounded,
        accent: const Color(0xFF558B2F),
        titleEn: t.actionTajweed,
        titleMl: t.actionTajweed,
        titleAr: t.actionTajweed,
        subtitleEn: 'Color Rules Key',
        subtitleMl: 'തജ്‌വീദ് കളർ കീ',
        subtitleAr: 'ألوان التجويد',
        keywords: const ['tajweed', 'ghunnah', 'qalqalah', 'തജ്‌വീദ്', 'നിയമം'],
        onTap: () => _openTajweedGuide(t),
      ),
      _DashboardQuickAction(
        id: 'export_pdf',
        icon: Icons.ios_share_rounded,
        accent: const Color(0xFF3949AB),
        titleEn: t.actionExport,
        titleMl: t.actionExport,
        titleAr: t.actionExport,
        subtitleEn: 'Print & Share PDF',
        subtitleMl: 'PDF & ടെക്സ്റ്റ്',
        subtitleAr: 'تصدير وطباعة',
        keywords: const ['export', 'pdf', 'share', 'print', 'എക്സ്പോർട്ട്'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:export',
            type: RecentActivityType.exportPdf,
            titleEn: 'Export PDF',
            titleMl: 'PDF എക്സ്പോർട്ട്',
            titleAr: 'تصدير PDF',
            subtitleEn: 'Surah / Juz Export',
            subtitleMl: 'പേജ് എക്സ്പോർട്ട്',
            subtitleAr: 'تصدير السور',
            quranSubTab: 3,
          );
          widget.onOpenFeature('export');
        },
      ),
      _DashboardQuickAction(
        id: 'settings',
        icon: Icons.settings_rounded,
        accent: const Color(0xFF546E7A),
        titleEn: t.actionSettings,
        titleMl: t.actionSettings,
        titleAr: t.actionSettings,
        subtitleEn: 'Theme, Audio & More',
        subtitleMl: 'തീം, ശബ്ദം, ഭാഷ',
        subtitleAr: 'التخصيص واللغة',
        keywords: const ['settings', 'theme', 'language', 'സെറ്റിംഗ്സ്'],
        onTap: () {
          _recordSimpleActivity(
            id: 'tool:settings',
            type: RecentActivityType.settings,
            titleEn: 'Settings',
            titleMl: 'സെറ്റിംഗ്സ്',
            titleAr: 'الإعدادات',
            subtitleEn: 'App Preferences',
            subtitleMl: 'ആപ്പ് ക്രമീകരണങ്ങൾ',
            subtitleAr: 'تفضيلات التطبيق',
          );
          widget.onNavigateTab(2);
        },
      ),
    ];

    final allActions = [...topTools, ...ibadahActions, ...categoryTools];

    // Daily Asmaul Husna index
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final dailyNameIdx = dayOfYear % AsmaulHusnaCatalog.names.length;
    final dailyName = AsmaulHusnaCatalog.names[dailyNameIdx];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 92),
          children: [
            // 1. Curved Emerald Header Backdrop + Floating White Prayer Card
            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 82,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.headerBg,
                          AppBranding.darkEmerald,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0),
                  child: _DashboardFloatingPrayerCard(
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onOpenPrayerTab: () => widget.onOpenFeature('prayer_times'),
                    onOpenAutoSilent: () => _openAutoSilent(t),
                  ),
                ),
              ],
            ),

            // Optional Continue Reading Shortcut
            if (lastRead != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Material(
                  color: cs.primaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => widget.onOpenSurah(
                      lastRead.surahNumber,
                      ayahNo: lastRead.ayahNumber,
                      anchorOffsetPx: lastRead.anchorOffsetPx,
                      savedReadingMode: lastRead.readingMode,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_fill_rounded,
                              color: cs.primary, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${t.lastRead}: ${settings.appLanguage == 'ar' && lastRead.surahArabicName.isNotEmpty ? lastRead.surahArabicName : lastRead.surahName} · ${t.ayahLabel} ${lastRead.ayahNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: cs.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // 2. Top 3-Column Icon Grid (6 Core Actions)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _DashboardActionGrid(
                actions: topTools,
                appLanguage: settings.appLanguage,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                cs: cs,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 18),

            // 3. Quick Access (Recent Activity)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.recentActivityTitle,
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (recent.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () =>
                          ref.read(recentActivityProvider.notifier).clearAll(),
                      child: Text(
                        t.clearHistoryLabel,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (recent.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 18, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.recentActivityEmpty,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Builder(
                builder: (ctx) {
                  final textScale = MediaQuery.textScalerOf(ctx)
                      .scale(1.0)
                      .clamp(0.85, 2.2);
                  final stripHeight =
                      (92.0 + math.max(0.0, textScale - 1.0) * 44.0)
                          .clamp(92.0, 154.0);
                  final cardWidth =
                      (168.0 * math.max(1.0, textScale * 0.72))
                          .clamp(168.0, 270.0);
                  return SizedBox(
                    height: stripHeight,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      scrollDirection: Axis.horizontal,
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, idx) {
                        final item = recent[idx];
                        final iconColor =
                            isDark ? AppBranding.accentGold : cs.primary;
                        return Material(
                          color: palette.cardBg,
                          borderRadius: BorderRadius.circular(15),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(15),
                            onTap: () =>
                                _handleRecentTap(item, t, settings.appLanguage),
                            child: Container(
                              width: cardWidth,
                              padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: palette.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.13),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      _iconForRecent(item.type),
                                      size: 16,
                                      color: iconColor,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item.timeAgoLabel(settings.appLanguage),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.titleFor(settings.appLanguage),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    item.subtitleFor(settings.appLanguage),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

            const SizedBox(height: 18),

            // 4A. Daily Highlight Card — Asmaul Husna (All 3 Languages)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _DailyAsmaulHusnaBanner(
                item: dailyName,
                headerBg: palette.headerBg,
                strings: t,
                onTap: () {
                  ref.read(recentActivityProvider.notifier).record(
                        RecentActivityEntry(
                          id: 'asma:${dailyName.number}',
                          type: RecentActivityType.asmaulHusna,
                          titleEn:
                              '${dailyName.number}. ${dailyName.transliteration}',
                          titleMl:
                              '${dailyName.number}. ${dailyName.malayalamMeaning}',
                          titleAr: '${dailyName.number}. ${dailyName.arabic}',
                          subtitleEn: dailyName.englishMeaning,
                          subtitleMl: dailyName.transliteration,
                          subtitleAr: dailyName.arabicMeaning,
                          timestampMs: DateTime.now().millisecondsSinceEpoch,
                          featureSubTab: 4,
                          asmaIndex: dailyNameIdx,
                        ),
                      );
                  showAsmaulHusnaDetailSheet(
                    context,
                    initialIndex: dailyNameIdx,
                    strings: t,
                    appLanguage: settings.appLanguage,
                    arabicFontSize: settings.arabicFontSize,
                    translationFontSize: settings.translationFontSize,
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 5. Other Features (4 Standalone Ibadah Modules + 6 Remaining Tools)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: Text(
                t.categoriesTitle,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _DashboardActionGrid(
                actions: ibadahActions,
                appLanguage: settings.appLanguage,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                cs: cs,
                isDark: isDark,
                crossAxisCount: 2,
                mainAxisExtent: 106,
                showSubtitle: true,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: _DashboardActionGrid(
                actions: categoryTools,
                appLanguage: settings.appLanguage,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                cs: cs,
                isDark: isDark,
              ),
            ),

            const SizedBox(height: 18),

            // 6. Dedicated App & Updates Card (Check Updates, Install PWA, Download Android APK, Share)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: HomeAppUpdatesCard(
                strings: t,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
              ),
            ),
          ],
        ),

        // Floating Search Button (Screenshot-inspired pinned bottom-end action)
        PositionedDirectional(
          end: hPad,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'dashboard_search_fab',
            backgroundColor: palette.headerBg,
            foregroundColor: Colors.white,
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tooltip: t.dashboardSearchHint,
            onPressed: () => _showUniversalSearchSheet(
              context: context,
              strings: t,
              settings: settings,
              allActions: allActions,
              surahs: surahs,
              palette: palette,
            ),
            child: const Icon(Icons.search_rounded, size: 26),
          ),
        ),
      ],
    );
  }
}

class _DashboardFloatingPrayerCard extends ConsumerStatefulWidget {
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onOpenPrayerTab;
  final VoidCallback onOpenAutoSilent;

  const _DashboardFloatingPrayerCard({
    required this.cardBg,
    required this.cardBorder,
    required this.onOpenPrayerTab,
    required this.onOpenAutoSilent,
  });

  @override
  ConsumerState<_DashboardFloatingPrayerCard> createState() =>
      _DashboardFloatingPrayerCardState();
}

class _DashboardFloatingPrayerCardState
    extends ConsumerState<_DashboardFloatingPrayerCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _prayerName(String key, AppStrings t) {
    switch (key) {
      case 'fajr':
        return t.fajrName;
      case 'dhuhr':
        return t.dhuhrName;
      case 'asr':
        return t.asrName;
      case 'maghrib':
        return t.maghribName;
      case 'isha':
        return t.ishaName;
      default:
        return key;
    }
  }

  String _formatCountdown(Duration diff) {
    final safe = diff.isNegative ? Duration.zero : diff;
    final h = safe.inHours.toString().padLeft(2, '0');
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerTimesProvider);
    final alarmState = ref.watch(prayerAlarmProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final data = prayerState.data;

    ({String name, DateTime time, double progress})? nextInfo;
    if (data != null) {
      final todayTimes = <({String key, DateTime time})>[
        for (final key in AlAdhanCatalog.fivePrayerKeys)
          (
            key: key,
            time: data.tunedTimeFor(key, settings.tuneFor(key), _now),
          ),
      ];
      int nextIdx = -1;
      for (int i = 0; i < todayTimes.length; i++) {
        if (todayTimes[i].time.isAfter(_now)) {
          nextIdx = i;
          break;
        }
      }

      DateTime prevTime;
      DateTime nextTime;
      String nextName;
      if (nextIdx >= 0) {
        nextName = _prayerName(todayTimes[nextIdx].key, t);
        nextTime = todayTimes[nextIdx].time;
        if (nextIdx > 0) {
          prevTime = todayTimes[nextIdx - 1].time;
        } else {
          final yesterday = _now.subtract(const Duration(days: 1));
          prevTime = data.tunedTimeFor(
            'isha',
            settings.prayerTuneIsha,
            yesterday,
          );
        }
      } else {
        final tomorrow = _now.add(const Duration(days: 1));
        nextName = t.fajrName;
        nextTime = data.tunedTimeFor('fajr', settings.prayerTuneFajr, tomorrow);
        prevTime = todayTimes.last.time;
      }

      final totalSecs = nextTime.difference(prevTime).inSeconds.clamp(1, 86400);
      final elapsedSecs = _now.difference(prevTime).inSeconds.clamp(0, totalSecs);
      nextInfo = (
        name: nextName,
        time: nextTime,
        progress: (elapsedSecs / totalSecs).clamp(0.04, 1.0),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onOpenPrayerTab,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (data != null)
                                Text(
                                  '${data.hijriDay} ${HijriMonthCatalog.monthName(data.hijriMonthNumber, contentLangFor(t.lang))}${t.lang == 'ar' ? '' : ' (${data.hijriMonthAr})'} ${data.hijriYear} ${t.hijriEraShort}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                  ),
                                )
                              else
                                Text(
                                  t.nextPrayerLabel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                nextInfo?.name ?? t.actionPrayer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: accentColor,
                                  height: 1.12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (nextInfo != null)
                          Text(
                            DailyPrayerData.format12Hour(
                              nextInfo.time,
                              am: t.amLabel,
                              pm: t.pmLabel,
                            ),
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              height: 1.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            settings.displayLocationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (nextInfo != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            t.remainingLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatCountdown(nextInfo.time.difference(_now)),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (alarmState.autoSilentActiveNow) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications_paused_rounded,
                                size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                t.dndActiveNowBanner,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => ref
                                  .read(prayerAlarmProvider.notifier)
                                  .restoreNormalRingerNow(),
                              child: Text(
                                t.restoreSoundNowBtn,
                                style: const TextStyle(fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (nextInfo != null)
                ClipRRect(
                  child: LinearProgressIndicator(
                    value: nextInfo.progress,
                    minHeight: 4,
                    backgroundColor:
                        cs.surfaceContainerHighest.withValues(alpha: 0.45),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardActionGrid extends StatelessWidget {
  final List<_DashboardQuickAction> actions;
  final String appLanguage;
  final Color cardBg;
  final Color cardBorder;
  final ColorScheme cs;
  final bool isDark;
  final int crossAxisCount;
  final double mainAxisExtent;
  final bool showSubtitle;

  const _DashboardActionGrid({
    required this.actions,
    required this.appLanguage,
    required this.cardBg,
    required this.cardBorder,
    required this.cs,
    required this.isDark,
    this.crossAxisCount = 3,
    this.mainAxisExtent = 102,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(0.85, 2.2);
    final double dynamicExtent = mainAxisExtent +
        math.max(0.0, textScale - 1.0) * (showSubtitle ? 52.0 : 48.0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
        mainAxisExtent: dynamicExtent,
      ),
      itemCount: actions.length,
      itemBuilder: (_, idx) {
        final action = actions[idx];
        final iconTint = isDark && action.accent == cs.primary
            ? AppBranding.accentGold
            : action.accent;
        return Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: action.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: showSubtitle ? 40 : 44,
                    height: showSubtitle ? 40 : 44,
                    decoration: BoxDecoration(
                      color: iconTint.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      action.icon,
                      size: showSubtitle ? 22 : 24,
                      color: iconTint,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    action.titleFor(appLanguage),
                    maxLines: showSubtitle ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w700,
                      height: 1.18,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      action.subtitleFor(appLanguage),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DailyAsmaulHusnaBanner extends StatelessWidget {
  final AsmaulHusnaItem item;
  final Color headerBg;
  final AppStrings strings;
  final VoidCallback onTap;

  const _DailyAsmaulHusnaBanner({
    required this.item,
    required this.headerBg,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            headerBg,
            AppBranding.darkEmerald,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: headerBg.withValues(alpha: 0.26),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppBranding.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      strings.dailyNameTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppBranding.accentGold.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppBranding.accentGold.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '${item.number} / 99',
                      style: const TextStyle(
                        color: AppBranding.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.transliteration,
                          style: const TextStyle(
                            color: AppBranding.accentGold,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (item.arabicMeaning.isNotEmpty) ...[
                          Text(
                            item.arabicMeaning,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: 15,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                        Text(
                          item.malayalamMeaning,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      item.arabic,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.viewMeaningBtn,
                      style: TextStyle(
                        color: AppBranding.accentGold.withValues(alpha: 0.96),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: AppBranding.accentGold.withValues(alpha: 0.96),
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
}


class _SearchSectionHeader extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _SearchSectionHeader({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accent),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 18),
          onTap: onTap,
        ),
      ),
    );
  }
}
