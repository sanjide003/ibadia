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

    final (tvMode, tvScale) = ref.watch(
      settingsProvider.select((s) => (s.tvModeEnabled, s.tvFontScale)),
    );
    final double uiScale = tvMode ? tvScale.clamp(1.0, 1.5) : 1.0;
    final Color accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: tvMode,
      normalMaxWidth: 880,
      minPad: 14.0,
    );

    const allEntries = AdhkarCatalog.entries;
    final q = _query.trim().toLowerCase();
    final filteredIndices = <int>[
      for (int i = 0; i < allEntries.length; i++)
        if (q.isEmpty ||
            allEntries[i].titleEn.toLowerCase().contains(q) ||
            allEntries[i].titleMl.toLowerCase().contains(q) ||
            allEntries[i].reference.toLowerCase().contains(q) ||
            _categoryLabel(allEntries[i].category, t)
                .toLowerCase()
                .contains(q) ||
            allEntries[i].arabic.contains(_query.trim()))
          i,
    ];

    return Directionality(
      textDirection: t.textDirection,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
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
              uiScale: uiScale,
            ),
          ),
          Expanded(
            child: filteredIndices.isEmpty
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
                              fontSize: 14.5 * uiScale.clamp(1.0, 1.3),
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
                    itemCount: filteredIndices.length,
                    itemBuilder: (ctx, pos) {
                      final fullIdx = filteredIndices[pos];
                      final entry = allEntries[fullIdx];
                      final count = adhkarState.countFor(entry.id);
                      final completed = count >= entry.targetCount;
                      final isFav = adhkarState.favoriteIds.contains(entry.id);
                      final catLabel = _categoryLabel(entry.category, t);

                      return FeatureIndexTile(
                        indexNumber: fullIdx + 1,
                        title: entry.titleFor(appLang),
                        subtitleMeta: '$catLabel · ${entry.reference}',
                        trailingLabel:
                            '${isFav ? "★ " : ""}$count/${entry.targetCount}',
                        isHighlighted: completed,
                        cardBg: cardBg,
                        cardBorder: cardBorder,
                        accentColor: accentColor,
                        uiScale: uiScale,
                        onTap: () {
                          Navigator.of(ctx).push<void>(
                            MaterialPageRoute(
                              builder: (_) => FocusedDetailPage(
                                initialIndex: fullIdx,
                                itemCount: allEntries.length,
                                settingsScope: SettingsScope.all,
                                titleBuilder: (idx, strings, _) =>
                                    allEntries[idx].titleFor(strings.lang),
                                itemBuilder: (_, idx, strings, __, expLang) {
                                  final item = allEntries[idx];
                                  return _AdhkarFocusedDetailBody(
                                    entry: item,
                                    categoryLabel:
                                        _categoryLabel(item.category, strings),
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

    final (tvMode, tvScale, settingsArabicSize, settingsTransSize) = ref.watch(
      settingsProvider.select(
        (s) => (
          s.tvModeEnabled,
          s.tvFontScale,
          s.arabicFontSize,
          s.translationFontSize,
        ),
      ),
    );
    final double uiScale = tvMode ? tvScale.clamp(1.0, 1.55) : 1.0;
    final double arabicPx =
        tvMode ? math.max(24.0 * tvScale, settingsArabicSize) : 24.0;
    final double meaningPx =
        tvMode ? math.max(14.0 * tvScale, settingsTransSize) : 14.0;

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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.titleFor(appLang),
                            style: TextStyle(
                              fontSize: 16.5 * uiScale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$categoryLabel · ${entry.reference}',
                            style: TextStyle(
                              fontSize: 12 * uiScale,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: t.favoritesOnlyLabel,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? cs.error : cs.onSurfaceVariant,
                        size: 21,
                      ),
                      onPressed: () => notifier.toggleFavorite(entry.id),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: t.copiedTextNotice,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: cs.onSurfaceVariant,
                        size: 19,
                      ),
                      onPressed: () {
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
                    if (count > 0)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: t.resetCycleLabel,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () => notifier.resetEntry(entry.id),
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
                const SizedBox(height: 12),
                Text(
                  entry.translationFor(expLang),
                  style: TextStyle(
                    fontSize: meaningPx,
                    height: 1.6,
                    color: cs.onSurfaceVariant,
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
                              fontSize: 13.5 * uiScale,
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

  Future<void> _showAddCustomDialog(
    BuildContext context,
    WidgetRef ref,
    AppStrings t,
  ) async {
    final nameCtrl = TextEditingController();
    final arabicCtrl = TextEditingController();
    int chosenTarget = 33;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(t.addCustomDhikr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: t.customDhikrName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: arabicCtrl,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  labelText: t.customDhikrArabic,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: [
                  for (final tgt in const [33, 99, 100, 0])
                    ChoiceChip(
                      label: Text(tgt == 0 ? t.unlimitedLabel : '$tgt'),
                      selected: chosenTarget == tgt,
                      onSelected: (_) => setDialogState(() => chosenTarget = tgt),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t.cancelLabel),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                ref.read(tasbihProvider.notifier).addCustomPreset(
                      title: nameCtrl.text.trim(),
                      arabic: arabicCtrl.text.trim(),
                      defaultTarget: chosenTarget,
                    );
                Navigator.pop(ctx);
              },
              child: Text(t.applyLabel),
            ),
          ],
        ),
      ),
    );
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

    final (tvMode, tvScale, settingsArabicSize) = ref.watch(
      settingsProvider.select(
        (s) => (s.tvModeEnabled, s.tvFontScale, s.arabicFontSize),
      ),
    );
    final double uiScale = tvMode ? tvScale.clamp(1.0, 1.55) : 1.0;
    final double tasbihArabicPx =
        tvMode ? math.max(30.0 * tvScale, settingsArabicSize) : 30.0;
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

    return Directionality(
      textDirection: t.textDirection,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: tasbih.tapAnywhere ? () => _handleTap(ref, tasbih) : null,
        child: ListView(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
          children: [
            // Preset selector row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in tasbih.allPresets) ...[
                    InputChip(
                      selected: p.id == tasbih.selectedId,
                      label: Text(p.titleFor(appLang)),
                      onPressed: () => notifier.selectPreset(p.id),
                      onDeleted: p.isCustom
                          ? () => notifier.deleteCustomPreset(p.id)
                          : null,
                      deleteButtonTooltipMessage: t.deleteCustomLabel,
                    ),
                    const SizedBox(width: 8),
                  ],
                  ActionChip(
                    avatar: const Icon(Icons.add_rounded, size: 17),
                    label: Text(t.addCustomDhikr),
                    onPressed: () => _showAddCustomDialog(context, ref, t),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Active Dhikr display card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      preset.arabic,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: tasbihArabicPx,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preset.titleFor(appLang),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16 * uiScale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Interactive Circular Counter Orb
                  GestureDetector(
                    onTap: () => _handleTap(ref, tasbih),
                    child: SizedBox(
                      width: 210,
                      height: 210,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 204,
                            height: 204,
                            child: CircularProgressIndicator(
                              value: target > 0 ? progress : 1.0,
                              strokeWidth: 10,
                              backgroundColor:
                                  cs.outlineVariant.withValues(alpha: 0.3),
                              color: target > 0 && cycle == target
                                  ? AppBranding.accentGold
                                  : cs.primary,
                            ),
                          ),
                          Container(
                            width: 174,
                            height: 174,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  cs.primary.withValues(alpha: 0.14),
                                  cs.primaryContainer.withValues(alpha: 0.5),
                                ],
                              ),
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$cycle',
                                  style: TextStyle(
                                    fontSize: 50,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.tapToCount,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                          onTap: () => _showTargetSheet(context, ref, tasbih, t),
                          child: _TasbihStatTile(
                            label: t.targetLabel,
                            value: target == 0 ? t.unlimitedLabel : '$target',
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
            const SizedBox(height: 12),

            // Controls Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.touch_app_rounded, color: cs.primary),
                    title: Text(
                      t.tapAnywhereLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      t.tapAnywhereHint,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: tasbih.tapAnywhere,
                    onChanged: (_) => notifier.toggleTapAnywhere(),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(Icons.vibration_rounded, color: cs.primary),
                    title: Text(
                      t.vibrateOnTapLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    value: tasbih.vibrateOnTap,
                    onChanged: (_) => notifier.toggleVibrateOnTap(),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showTargetSheet(context, ref, tasbih, t),
                            icon: const Icon(Icons.flag_rounded, size: 18),
                            label: Text(t.targetLabel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: notifier.resetCycle,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(t.resetCycleLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
