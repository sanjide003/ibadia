import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

class DashboardView extends ConsumerStatefulWidget {
  final void Function(int tabIndex, {int? subTab}) onNavigateTab;
  final void Function(
    int surahNo, {
    int? ayahNo,
    double? anchorOffsetPx,
    String? savedReadingMode,
  }) onOpenSurah;

  const DashboardView({
    super.key,
    required this.onNavigateTab,
    required this.onOpenSurah,
  });

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
    // Re-stamp recency when accessed again
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
        widget.onNavigateTab(2, subTab: 0);
        break;
      case RecentActivityType.hijri:
        widget.onNavigateTab(2, subTab: 1);
        break;
      case RecentActivityType.adhkar:
        widget.onNavigateTab(2, subTab: 2);
        break;
      case RecentActivityType.counter:
        widget.onNavigateTab(2, subTab: 3);
        break;
      case RecentActivityType.asmaulHusna:
        widget.onNavigateTab(2, subTab: 4);
        if (entry.asmaIndex != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            showAsmaulHusnaDetailSheet(
              context,
              initialIndex: entry.asmaIndex!,
              strings: t,
              appLanguage: lang,
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
      case RecentActivityType.exportPdf:
        widget.onNavigateTab(1, subTab: 3);
        break;
      case RecentActivityType.settings:
        widget.onNavigateTab(3);
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
      case RecentActivityType.bookmark:
        return Icons.bookmark_rounded;
      case RecentActivityType.exportPdf:
        return Icons.ios_share_rounded;
      case RecentActivityType.settings:
        return Icons.settings_rounded;
    }
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
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 1040) / 2);

    final quickActions = <_DashboardQuickAction>[
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
          widget.onNavigateTab(1, subTab: 2);
        },
      ),
      _DashboardQuickAction(
        id: 'prayer_times',
        icon: Icons.mosque_rounded,
        accent: cs.primary,
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
          widget.onNavigateTab(2, subTab: 0);
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
          widget.onNavigateTab(2, subTab: 1);
        },
      ),
      _DashboardQuickAction(
        id: 'auto_silent',
        icon: Icons.do_not_disturb_on_rounded,
        accent: const Color(0xFFC62828),
        titleEn: t.actionAutoSilent,
        titleMl: t.actionAutoSilent,
        titleAr: t.actionAutoSilent,
        subtitleEn: '${settings.autoSilentDurationMinutes}m DND',
        subtitleMl: '${settings.autoSilentDurationMinutes}മി. സൈലന്റ്',
        subtitleAr: '${settings.autoSilentDurationMinutes} د صامت',
        keywords: const ['silent', 'dnd', 'mute', 'സൈലന്റ്', 'നിശബ്ദം'],
        onTap: () => _openAutoSilent(t),
      ),
      _DashboardQuickAction(
        id: 'daily_adhkar',
        icon: Icons.auto_stories_rounded,
        accent: const Color(0xFF0B7A43),
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
          widget.onNavigateTab(2, subTab: 2);
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
            titleMl: 'തസ്ബീഹ് കൗണ്ടർ',
            titleAr: 'عدّاد الأذكار',
            subtitleEn: 'Tap Counter',
            subtitleMl: 'കൗണ്ടർ',
            subtitleAr: 'تسبيح',
            featureSubTab: 3,
          );
          widget.onNavigateTab(2, subTab: 3);
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
            subtitleEn: 'Malayalam & English',
            subtitleMl: 'അസ്മാഉൽ ഹുസ്ന',
            subtitleAr: '99 اسماً',
            featureSubTab: 4,
          );
          widget.onNavigateTab(2, subTab: 4);
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
          widget.onNavigateTab(1, subTab: 3);
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
          widget.onNavigateTab(3);
        },
      ),
    ];

    final trimmedQuery = _query.trim().toLowerCase();
    final bool isSearching = trimmedQuery.isNotEmpty;

    final List<_DashboardQuickAction> matchedActions = isSearching
        ? quickActions.where((a) {
            return a.titleEn.toLowerCase().contains(trimmedQuery) ||
                a.titleMl.toLowerCase().contains(trimmedQuery) ||
                a.titleAr.contains(_query.trim()) ||
                a.keywords.any((k) => k.toLowerCase().contains(trimmedQuery));
          }).toList()
        : const [];

    final List<SurahSummary> matchedSurahs = isSearching
        ? surahs
            .where((s) =>
                s.number.toString() == trimmedQuery ||
                s.englishName.toLowerCase().contains(trimmedQuery) ||
                s.nameArabic.contains(_query.trim()))
            .take(6)
            .toList()
        : const [];

    final List<AsmaulHusnaItem> matchedNames = isSearching
        ? AsmaulHusnaCatalog.names
            .where((n) =>
                n.number.toString() == trimmedQuery ||
                n.transliteration.toLowerCase().contains(trimmedQuery) ||
                n.englishMeaning.toLowerCase().contains(trimmedQuery) ||
                n.malayalamMeaning.toLowerCase().contains(trimmedQuery) ||
                n.arabic.contains(_query.trim()))
            .take(6)
            .toList()
        : const [];

    final List<AdhkarEntry> matchedAdhkar = isSearching
        ? AdhkarCatalog.entries
            .where((d) =>
                d.titleEn.toLowerCase().contains(trimmedQuery) ||
                d.titleMl.toLowerCase().contains(trimmedQuery) ||
                d.arabic.contains(_query.trim()))
            .take(5)
            .toList()
        : const [];

    final bool hasAnySearchMatch = matchedActions.isNotEmpty ||
        matchedSurahs.isNotEmpty ||
        matchedNames.isNotEmpty ||
        matchedAdhkar.isNotEmpty;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 28),
      children: [
        // 1. Live Prayer + Hijri + DND Hero Strip
        _DashboardHeroPrayerCard(
          headerBg: palette.headerBg,
          onOpenPrayerTab: () => widget.onNavigateTab(2, subTab: 0),
          onOpenAutoSilent: () => _openAutoSilent(t),
        ),

        const SizedBox(height: 12),

        // Optional compact Continue Reading shortcut if available
        if (lastRead != null) ...[
          Material(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const SizedBox(height: 12),
        ],

        // 2. Universal Search Box
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: t.dashboardSearchHint,
            prefixIcon: const Icon(Icons.search_rounded, size: 21),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close_rounded, size: 19),
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: palette.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: palette.cardBorder),
            ),
          ),
        ),

        if (isSearching) ...[
          const SizedBox(height: 14),
          if (!hasAnySearchMatch)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Text(
                t.noSearchResults,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          else ...[
            if (matchedActions.isNotEmpty) ...[
              _SearchSectionHeader(label: t.quickActionsTitle, cs: cs),
              ...matchedActions.map((a) => _SearchResultTile(
                    icon: a.icon,
                    accent: a.accent,
                    title: a.titleFor(settings.appLanguage),
                    subtitle: settings.appLanguage == 'ml'
                        ? a.subtitleMl
                        : (settings.appLanguage == 'ar'
                            ? a.subtitleAr
                            : a.subtitleEn),
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: a.onTap,
                  )),
              const SizedBox(height: 10),
            ],
            if (matchedSurahs.isNotEmpty) ...[
              _SearchSectionHeader(label: t.surahTabLabel, cs: cs),
              ...matchedSurahs.map((s) => _SearchResultTile(
                    icon: Icons.menu_book_rounded,
                    accent: cs.primary,
                    title: '${s.number}. ${s.englishName}',
                    subtitle:
                        '${s.nameArabic} · ${s.numberOfAyahs} ${t.ayahsLabel}',
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => widget.onOpenSurah(s.number),
                  )),
              const SizedBox(height: 10),
            ],
            if (matchedNames.isNotEmpty) ...[
              _SearchSectionHeader(label: t.actionNames99, cs: cs),
              ...matchedNames.map((n) => _SearchResultTile(
                    icon: Icons.auto_awesome_rounded,
                    accent: const Color(0xFF8E24AA),
                    title: '${n.number}. ${n.transliteration} — ${n.arabic}',
                    subtitle: '${n.malayalamMeaning} · ${n.englishMeaning}',
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () {
                      ref.read(recentActivityProvider.notifier).record(
                            RecentActivityEntry(
                              id: 'asma:${n.number}',
                              type: RecentActivityType.asmaulHusna,
                              titleEn: '${n.number}. ${n.transliteration}',
                              titleMl: '${n.number}. ${n.malayalamMeaning}',
                              titleAr: '${n.number}. ${n.arabic}',
                              subtitleEn: n.englishMeaning,
                              subtitleMl: n.transliteration,
                              subtitleAr: n.englishMeaning,
                              timestampMs:
                                  DateTime.now().millisecondsSinceEpoch,
                              featureSubTab: 4,
                              asmaIndex: n.number - 1,
                            ),
                          );
                      showAsmaulHusnaDetailSheet(
                        context,
                        initialIndex: n.number - 1,
                        strings: t,
                        appLanguage: settings.appLanguage,
                      );
                    },
                  )),
              const SizedBox(height: 10),
            ],
            if (matchedAdhkar.isNotEmpty) ...[
              _SearchSectionHeader(label: t.actionAdhkar, cs: cs),
              ...matchedAdhkar.map((d) => _SearchResultTile(
                    icon: Icons.auto_stories_rounded,
                    accent: const Color(0xFF0B7A43),
                    title: d.titleFor(settings.appLanguage),
                    subtitle: d.reference,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () {
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
                      widget.onNavigateTab(2, subTab: 2);
                    },
                  )),
            ],
          ],
        ] else ...[
          const SizedBox(height: 16),

          // 3. Recent Activity — Single Horizontally Swipeable Row (max 7)
          Row(
            children: [
              Expanded(
                child: Text(
                  t.recentActivityTitle,
                  style: TextStyle(
                    fontSize: 15.5,
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
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            )
          else
            SizedBox(
              height: 98,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, idx) {
                  final item = recent[idx];
                  final iconColor = isDark ? AppBranding.accentGold : cs.primary;
                  return Material(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(15),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () =>
                          _handleRecentTap(item, t, settings.appLanguage),
                      child: Container(
                        width: 168,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: palette.cardBorder),
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
            ),

          const SizedBox(height: 18),

          // 4. All Features & Tools — Strictly 3 Per Row
          Text(
            t.quickActionsTitle,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 102,
            ),
            itemCount: quickActions.length,
            itemBuilder: (_, idx) {
              final action = quickActions[idx];
              return Material(
                color: palette.cardBg,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: action.onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.cardBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: action.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            action.icon,
                            size: 21,
                            color: isDark && action.accent == cs.primary
                                ? AppBranding.accentGold
                                : action.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.titleFor(settings.appLanguage),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _DashboardHeroPrayerCard extends ConsumerStatefulWidget {
  final Color headerBg;
  final VoidCallback onOpenPrayerTab;
  final VoidCallback onOpenAutoSilent;

  const _DashboardHeroPrayerCard({
    required this.headerBg,
    required this.onOpenPrayerTab,
    required this.onOpenAutoSilent,
  });

  @override
  ConsumerState<_DashboardHeroPrayerCard> createState() =>
      _DashboardHeroPrayerCardState();
}

class _DashboardHeroPrayerCardState
    extends ConsumerState<_DashboardHeroPrayerCard> {
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
    final data = prayerState.data;

    ({String name, DateTime time})? nextInfo;
    if (data != null) {
      for (final key in AlAdhanCatalog.fivePrayerKeys) {
        final dt = data.tunedTimeFor(key, settings.tuneFor(key), _now);
        if (dt.isAfter(_now)) {
          nextInfo = (name: _prayerName(key, t), time: dt);
          break;
        }
      }
      if (nextInfo == null) {
        final tomorrow = _now.add(const Duration(days: 1));
        nextInfo = (
          name: t.fajrName,
          time: data.tunedTimeFor('fajr', settings.prayerTuneFajr, tomorrow),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onOpenPrayerTab,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                widget.headerBg,
                AppBranding.darkEmerald,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: widget.headerBg.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppBranding.accentGold,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      settings.displayLocationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onOpenAutoSilent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: alarmState.autoSilentActiveNow
                            ? AppBranding.accentGold
                            : Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            settings.autoSilentEnabled
                                ? Icons.do_not_disturb_on_rounded
                                : Icons.do_not_disturb_off_outlined,
                            size: 13,
                            color: alarmState.autoSilentActiveNow
                                ? AppBranding.darkEmerald
                                : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            alarmState.autoSilentActiveNow
                                ? 'DND ON'
                                : (settings.autoSilentEnabled
                                    ? '${settings.autoSilentDurationMinutes}m'
                                    : t.actionAutoSilent),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: alarmState.autoSilentActiveNow
                                  ? AppBranding.darkEmerald
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (data != null && nextInfo != null) ...[
                Text(
                  '${data.hijriDay} ${t.lang == 'ar' ? data.hijriMonthAr : data.hijriMonthEn} ${data.hijriYear} AH',
                  style: TextStyle(
                    color: AppBranding.accentGold.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.nextPrayerLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              '${nextInfo.name} · ${DailyPrayerData.format12Hour(nextInfo.time)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCountdown(nextInfo.time.difference(_now)),
                        style: const TextStyle(
                          color: AppBranding.accentGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  t.actionPrayer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (alarmState.autoSilentActiveNow) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.dndActiveNowBanner,
                        style: const TextStyle(
                          color: AppBranding.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        visualDensity: VisualDensity.compact,
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
              ],
            ],
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
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: cardBorder),
      ),
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
    );
  }
}
