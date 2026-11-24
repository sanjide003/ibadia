import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../data/adhkar_data.dart';
import '../models/adhkar_tasbih_model.dart';
import '../providers/islamic_features_providers.dart';
import '../providers/quran_providers.dart';
import '../services/export_service.dart';
import '../widgets/focused_index_scaffold.dart';
import '../widgets/tv_mode_widgets.dart';
import 'settings_screen.dart';

class AdhkarDuasView extends ConsumerStatefulWidget {
  const AdhkarDuasView({super.key});

  @override
  ConsumerState<AdhkarDuasView> createState() => _AdhkarDuasViewState();
}

class _AdhkarDuasViewState extends ConsumerState<AdhkarDuasView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _activeSource = 'quran'; // 'quran' | 'hadith'
  String _hadithFilter = 'all'; // 'all' | 'morning' | 'evening' | 'after_salah' | 'daily_duas' | 'favorites'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static String _categoryLabel(String cat, AppStrings t) {
    switch (cat) {
      case 'morning':
        return t.morningAdhkar;
      case 'evening':
        return t.eveningAdhkar;
      case 'after_salah':
        return t.afterSalahAdhkar;
      default:
        return t.dailyDuasCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adhkarState = ref.watch(adhkarProvider);
    final t = ref.watch(stringsProvider);
    final appLang = ref.watch(settingsProvider.select((s) => s.appLanguage));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia =
        ref.watch(settingsProvider.select((s) => s.themeMode == 'sepia'));

    final Color cardBg = isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white);
    final Color cardBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6));

    final tvMode = ref.watch(settingsProvider.select((s) => s.tvModeEnabled));
    final Color accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: tvMode,
      normalMaxWidth: 880,
      minPad: 14.0,
    );

    final listLang = contentLangFor(appLang);
    final listStrings = AppStrings(listLang);
    final q = _query.trim().toLowerCase();

    final sourceEntries = AdhkarCatalog.entries
        .where((e) => e.source == _activeSource)
        .toList();

    final visibleEntries = <AdhkarEntry>[
      for (final entry in sourceEntries)
        if ((_activeSource == 'quran' ||
                _hadithFilter == 'all' ||
                (_hadithFilter == 'favorites' &&
                    adhkarState.favoriteIds.contains(entry.id)) ||
                entry.category == _hadithFilter) &&
            (q.isEmpty ||
                entry.titleEn.toLowerCase().contains(q) ||
                entry.titleMl.toLowerCase().contains(q) ||
                entry.reference.toLowerCase().contains(q) ||
                _categoryLabel(entry.category, listStrings)
                    .toLowerCase()
                    .contains(q) ||
                _categoryLabel(entry.category, t).toLowerCase().contains(q) ||
                entry.arabic.contains(_query.trim())))
          entry,
    ];

    final hadithFilters = <(String key, String label)>[
      ('all', t.allAdhkarLabel),
      ('morning', t.morningAdhkar),
      ('evening', t.eveningAdhkar),
      ('after_salah', t.afterSalahAdhkar),
      ('daily_duas', t.dailyDuasCategory),
      ('favorites', t.favoritesOnlyLabel),
    ];

    return Directionality(
      textDirection: t.textDirection,
      child: Column(
        children: [
          // Top 2 Sub-Tabs: From the Quran | From the Hadith
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF141A17)
                    : (isSepia
                        ? const Color(0xFFF3EBD8)
                        : const Color(0xFFE7F0EC)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SourceSubTabButton(
                      icon: Icons.menu_book_rounded,
                      label: t.quranAdhkarTab,
                      selected: _activeSource == 'quran',
                      accentColor: AppBranding.primaryEmerald,
                      isDark: isDark,
                      onTap: () => setState(() => _activeSource = 'quran'),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _SourceSubTabButton(
                      icon: Icons.auto_stories_rounded,
                      label: t.hadithAdhkarTab,
                      selected: _activeSource == 'hadith',
                      accentColor: AppBranding.primaryEmerald,
                      isDark: isDark,
                      onTap: () => setState(() => _activeSource = 'hadith'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 6),
            child: FeatureIndexSearchBar(
              controller: _searchCtrl,
              query: _query,
              onChanged: (v) => setState(() => _query = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              hintText: t.searchItemsHint,
              clearTooltip: t.clearSearchLabel,
              cardBg: cardBg,
              cardBorder: cardBorder,
            ),
          ),

          // Hadith Category Filter Chips (only on From Hadith sub-tab)
          if (_activeSource == 'hadith')
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(hPad, 2, hPad, 6),
                scrollDirection: Axis.horizontal,
                itemCount: hadithFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, idx) {
                  final (key, label) = hadithFilters[idx];
                  final selected = _hadithFilter == key;
                  return ChoiceChip(
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _hadithFilter = key),
                  );
                },
              ),
            ),

          Expanded(
            child: visibleEntries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 40,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t.noMatchingItems,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 28),
                    itemCount: visibleEntries.length,
                    itemBuilder: (ctx, pos) {
                      final entry = visibleEntries[pos];
                      final count = adhkarState.countFor(entry.id);
                      final completed = count >= entry.targetCount;
                      final isFav = adhkarState.favoriteIds.contains(entry.id);
                      final catLabel = entry.source == 'quran'
                          ? listStrings.quranAdhkarTab
                          : _categoryLabel(entry.category, listStrings);

                      return FeatureIndexTile(
                        indexNumber: pos + 1,
                        title: entry.titleFor(listLang),
                        subtitleMeta: '$catLabel · ${entry.reference}',
                        trailingLabel:
                            '${isFav ? "★ " : ""}$count/${entry.targetCount}',
                        isHighlighted: completed,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        accentColor: accentColor,
                        onTap: () {
                          Navigator.of(ctx).push<void>(
                            MaterialPageRoute(
                              builder: (_) => FocusedDetailPage(
                                initialIndex: pos,
                                itemCount: visibleEntries.length,
                                settingsScope: SettingsScope.all,
                                titleBuilder: (idx, _, hLang) =>
                                    visibleEntries[idx].titleFor(hLang),
                                itemBuilder: (_, idx, __, hLang, expLang) {
                                  final item = visibleEntries[idx];
                                  return _AdhkarFocusedDetailBody(
                                    entry: item,
                                    categoryLabel: item.source == 'quran'
                                        ? AppStrings(hLang).quranAdhkarTab
                                        : _categoryLabel(
                                            item.category,
                                            AppStrings(hLang),
                                          ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SourceSubTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SourceSubTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? accentColor : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? Colors.white
                        : (isDark ? Colors.white70 : cs.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdhkarFocusedDetailBody extends ConsumerWidget {
  final AdhkarEntry entry;
  final String categoryLabel;

  const _AdhkarFocusedDetailBody({
    required this.entry,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adhkarState = ref.watch(adhkarProvider);
    final notifier = ref.read(adhkarProvider.notifier);
    final t = ref.watch(stringsProvider);
    final appLang = ref.watch(settingsProvider.select((s) => s.appLanguage));
    final expLang = explanationLangFor(appLang);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia =
        ref.watch(settingsProvider.select((s) => s.themeMode == 'sepia'));

    final Color cardBg = isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white);
    final Color cardBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6));

    final (settingsArabicSize, settingsTransSize) = ref.watch(
      settingsProvider.select(
        (s) => (s.arabicFontSize, s.translationFontSize),
      ),
    );
    final double arabicPx = settingsArabicSize;
    final double meaningPx = settingsTransSize;

    final int count = adhkarState.countFor(entry.id);
    final bool isFavorite = adhkarState.favoriteIds.contains(entry.id);
    final bool completed = count >= entry.targetCount;
    final double progress = entry.targetCount > 0
        ? (count / entry.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        color:
            completed ? cs.primaryContainer.withValues(alpha: 0.25) : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              completed ? cs.primary.withValues(alpha: 0.55) : cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final completedNow = await notifier.incrementEntry(entry);
            if (completedNow) {
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.selectionClick();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tier 1: Full-width Title & Reference
                Text(
                  entry.titleFor(contentLangFor(appLang)),
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$categoryLabel · ${entry.reference}',
                  style: TextStyle(
                    fontSize: 12.2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                // Tier 2: Action Row (Share, Copy, Favorite, Reset)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _AdhkarActionChip(
                      icon: Icons.share_rounded,
                      label: t.share,
                      color: cs.primary,
                      borderColor: cardBorder,
                      onTap: () {
                        final shareBody =
                            '${entry.titleFor(contentLangFor(appLang))}\n\n${entry.arabic}\n\n${entry.translationFor(expLang)}\n(${entry.reference})';
                        ExportService.shareText(
                          shareBody,
                          subject: entry.titleFor(contentLangFor(appLang)),
                        );
                      },
                    ),
                    _AdhkarActionChip(
                      icon: Icons.copy_rounded,
                      label: t.copyLabel,
                      color: cs.onSurfaceVariant,
                      borderColor: cardBorder,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                '${entry.arabic}\n\n${entry.translationFor(expLang)}\n(${entry.reference})',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(t.copiedNameNotice),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    _AdhkarActionChip(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      label: t.favoritesOnlyLabel,
                      color: isFavorite ? cs.error : cs.onSurfaceVariant,
                      borderColor: cardBorder,
                      onTap: () => notifier.toggleFavorite(entry.id),
                    ),
                    if (count > 0)
                      _AdhkarActionChip(
                        icon: Icons.refresh_rounded,
                        label: t.resetCycleLabel,
                        color: cs.onSurfaceVariant,
                        borderColor: cardBorder,
                        onTap: () => notifier.resetEntry(entry.id),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF101915)
                        : (isSepia
                            ? const Color(0xFFF6EFE0)
                            : const Color(0xFFF1F7F4)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: NoTextScaling(
                      child: Text(
                        entry.arabic,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri(
                          fontSize: arabicPx,
                          height: 1.9,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                NoTextScaling(
                  child: Text(
                    entry.translationFor(expLang),
                    style: TextStyle(
                      fontSize: meaningPx,
                      height: 1.6,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              cs.outlineVariant.withValues(alpha: 0.35),
                          color: completed
                              ? AppBranding.primaryEmerald
                              : cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppBranding.primaryEmerald
                            : cs.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (completed) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            '$count / ${entry.targetCount}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: completed ? Colors.white : cs.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DigitalTasbihView extends ConsumerWidget {
  const DigitalTasbihView({super.key});

  void _handleTap(WidgetRef ref, TasbihState tasbihState) {
    final hitTarget = ref.read(tasbihProvider.notifier).tap();
    if (tasbihState.vibrateOnTap) {
      if (hitTarget) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _showTargetSheet(
    BuildContext context,
    WidgetRef ref,
    TasbihState tasbihState,
    AppStrings t,
  ) async {
    const options = [33, 99, 100, 1000, 0];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.targetLabel,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final target in options)
                    ChoiceChip(
                      label: Text(
                        target == 0 ? t.unlimitedLabel : '$target',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      selected: tasbihState.activeTarget == target,
                      onSelected: (_) {
                        ref.read(tasbihProvider.notifier).setTarget(target);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _addCustomMenuValue = '__add_custom_dhikr__';
  static final RegExp _arabicScriptRe = RegExp(r'[\u0600-\u06FF]');

  Future<void> _showAddCustomDialog(
    BuildContext context,
    WidgetRef ref,
    AppStrings t,
  ) async {
    final dhikrCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '33');

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final currentVal = int.tryParse(countCtrl.text.trim()) ?? 0;
          return AlertDialog(
            title: Text(t.addCustomDhikr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: dhikrCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t.customDhikrName,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: countCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: t.customDhikrTargetLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final tgt in const [33, 99, 100, 0])
                        ChoiceChip(
                          label: Text(tgt == 0 ? t.unlimitedLabel : '$tgt'),
                          selected: currentVal == tgt,
                          onSelected: (_) {
                            setDialogState(() {
                              countCtrl.text = '$tgt';
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.cancelLabel),
              ),
              FilledButton(
                onPressed: () {
                  final text = dhikrCtrl.text.trim();
                  if (text.isEmpty) return;
                  final target = int.tryParse(countCtrl.text.trim()) ?? 33;
                  ref.read(tasbihProvider.notifier).addCustomPreset(
                        title: text,
                        arabic: text,
                        defaultTarget: target < 0 ? 0 : target,
                      );
                  Navigator.pop(ctx);
                },
                child: Text(t.applyLabel),
              ),
            ],
          );
        },
      ),
    );
    Future.delayed(const Duration(milliseconds: 350), () {
      dhikrCtrl.dispose();
      countCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasbih = ref.watch(tasbihProvider);
    final notifier = ref.read(tasbihProvider.notifier);
    final t = ref.watch(stringsProvider);
    final appLang = ref.watch(settingsProvider.select((s) => s.appLanguage));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = ref.watch(settingsProvider.select((s) => s.themeMode == 'sepia'));

    final Color cardBg = isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white);
    final Color cardBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6));

    final (tvMode, settingsArabicSize) = ref.watch(
      settingsProvider.select(
        (s) => (s.tvModeEnabled, s.arabicFontSize),
      ),
    );
    final double tasbihArabicPx = math.max(30.0, settingsArabicSize);
    final preset = tasbih.activePreset;
    final cycle = tasbih.activeCycleCount;
    final target = tasbih.activeTarget;
    final progress = target > 0 ? (cycle / target).clamp(0.0, 1.0) : 0.0;
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: tvMode,
      normalMaxWidth: 860,
      minPad: 14.0,
    );

    final listLang = contentLangFor(appLang);
    final presetTitle = preset.titleFor(listLang).trim();
    final presetArabic = preset.arabic.trim();
    final bool hasDistinctSubtitle =
        presetTitle.isNotEmpty && presetTitle != presetArabic;
    final bool mainTextIsArabic = _arabicScriptRe.hasMatch(presetArabic);

    return Directionality(
      textDirection: t.textDirection,
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: tasbih.tapAnywhere ? () => _handleTap(ref, tasbih) : null,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(0.0, viewportConstraints.maxHeight - 32),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. TOP SECTION: Dropdown + Controls + Quick Stats (away from thumb tap zone)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: t.selectDhikrLabel,
                                    isDense: true,
                                    filled: true,
                                    fillColor: cardBg,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: cardBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: cardBorder),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: preset.id,
                                      isExpanded: true,
                                      borderRadius: BorderRadius.circular(14),
                                      icon: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: cs.primary,
                                      ),
                                      items: [
                                        for (final p in tasbih.allPresets)
                                          DropdownMenuItem<String>(
                                            value: p.id,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    p.titleFor(listLang),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                if (p
                                                        .titleFor(listLang)
                                                        .trim() !=
                                                    p.arabic.trim()) ...[
                                                  const SizedBox(width: 8),
                                                  ConstrainedBox(
                                                    constraints:
                                                        const BoxConstraints(
                                                      maxWidth: 130,
                                                    ),
                                                    child: Text(
                                                      p.arabic,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      style: GoogleFonts.amiri(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: cs.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        DropdownMenuItem<String>(
                                          value: _addCustomMenuValue,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .add_circle_outline_rounded,
                                                size: 19,
                                                color: cs.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  t.addCustomDhikr,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w800,
                                                    color: cs.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val == null) return;
                                        if (val == _addCustomMenuValue) {
                                          _showAddCustomDialog(
                                              context, ref, t);
                                          return;
                                        }
                                        notifier.selectPreset(val);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (preset.isCustom) ...[
                                const SizedBox(width: 8),
                                IconButton.outlined(
                                  tooltip: t.deleteCustomLabel,
                                  onPressed: () =>
                                      notifier.deleteCustomPreset(preset.id),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: cs.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Controls Card moved to TOP
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Icon(
                                    Icons.touch_app_rounded,
                                    color: cs.primary,
                                  ),
                                  title: Text(
                                    t.tapAnywhereLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    t.tapAnywhereHint,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  value: tasbih.tapAnywhere,
                                  onChanged: (_) =>
                                      notifier.toggleTapAnywhere(),
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  secondary: Icon(
                                    Icons.vibration_rounded,
                                    color: cs.primary,
                                  ),
                                  title: Text(
                                    t.vibrateOnTapLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: tasbih.vibrateOnTap,
                                  onChanged: (_) =>
                                      notifier.toggleVibrateOnTap(),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _showTargetSheet(
                                              context, ref, tasbih, t),
                                          icon: const Icon(
                                            Icons.flag_rounded,
                                            size: 18,
                                          ),
                                          label: Text(
                                            '${t.targetLabel}: ${target == 0 ? t.unlimitedLabel : target}',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: notifier.resetCycle,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            size: 18,
                                          ),
                                          label: Text(t.resetCycleLabel),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Quick metrics row
                          Row(
                            children: [
                              Expanded(
                                child: _TasbihStatTile(
                                  label: t.todayTotalLabel,
                                  value: '${tasbih.todayTotal}',
                                  cs: cs,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _TasbihStatTile(
                                  label: t.lifetimeTotalLabel,
                                  value: '${tasbih.activeLifetimeCount}',
                                  cs: cs,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _showTargetSheet(
                                      context, ref, tasbih, t),
                                  child: _TasbihStatTile(
                                    label: t.targetLabel,
                                    value: target == 0
                                        ? t.unlimitedLabel
                                        : '$target',
                                    cs: cs,
                                    highlight: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. BOTTOM SECTION: Thumb-friendly Tap Counter Zone
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          Directionality(
                            textDirection: mainTextIsArabic
                                ? TextDirection.rtl
                                : t.textDirection,
                            child: NoTextScaling(
                              child: Text(
                                presetArabic,
                                textAlign: TextAlign.center,
                                style: mainTextIsArabic
                                    ? GoogleFonts.amiri(
                                        fontSize: tasbihArabicPx,
                                        fontWeight: FontWeight.w700,
                                        height: 1.45,
                                        color: cs.primary,
                                      )
                                    : TextStyle(
                                        fontSize:
                                            math.max(22.0, tasbihArabicPx * 0.8),
                                        fontWeight: FontWeight.w800,
                                        height: 1.35,
                                        color: cs.primary,
                                      ),
                              ),
                            ),
                          ),
                          if (hasDistinctSubtitle) ...[
                            const SizedBox(height: 4),
                            Text(
                              presetTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Interactive Circular Counter Orb (Bottom thumb zone)
                          GestureDetector(
                            onTap: () => _handleTap(ref, tasbih),
                            child: SizedBox(
                              width: 214,
                              height: 214,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 208,
                                    height: 208,
                                    child: CircularProgressIndicator(
                                      value: target > 0 ? progress : 1.0,
                                      strokeWidth: 10,
                                      backgroundColor: cs.outlineVariant
                                          .withValues(alpha: 0.3),
                                      color: target > 0 && cycle == target
                                          ? AppBranding.accentGold
                                          : cs.primary,
                                    ),
                                  ),
                                  Container(
                                    width: 178,
                                    height: 178,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          cs.primary.withValues(alpha: 0.14),
                                          cs.primaryContainer
                                              .withValues(alpha: 0.5),
                                        ],
                                      ),
                                      border: Border.all(
                                        color:
                                            cs.primary.withValues(alpha: 0.35),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: NoTextScaling(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$cycle',
                                            style: TextStyle(
                                              fontSize: 52,
                                              fontWeight: FontWeight.w900,
                                              color: cs.primary,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            target == 0
                                                ? t.unlimitedLabel
                                                : '/ $target',
                                            style: TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t.tapToCount,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
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
        },
      ),
    );
  }
}

class _TasbihStatTile extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;

  const _TasbihStatTile({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? cs.primaryContainer.withValues(alpha: 0.65)
            : cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: highlight ? cs.primary : cs.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdhkarActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _AdhkarActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
