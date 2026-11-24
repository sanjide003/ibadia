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
import '../widgets/tv_mode_widgets.dart';

class AdhkarDuasView extends ConsumerWidget {
  const AdhkarDuasView({super.key});

  String _categoryLabel(String cat, AppStrings t) {
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

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'morning':
        return Icons.wb_sunny_rounded;
      case 'evening':
        return Icons.nights_stay_rounded;
      case 'after_salah':
        return Icons.mosque_rounded;
      default:
        return Icons.menu_book_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adhkarState = ref.watch(adhkarProvider);
    final notifier = ref.read(adhkarProvider.notifier);
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

    final items = AdhkarCatalog.entries.where((entry) {
      if (adhkarState.favoritesOnly) {
        return adhkarState.favoriteIds.contains(entry.id);
      }
      return entry.category == adhkarState.selectedCategory;
    }).toList();

    final categoryItems = AdhkarCatalog.entries
        .where((e) => e.category == adhkarState.selectedCategory)
        .toList();
    final completedCount = categoryItems
        .where((e) => adhkarState.countFor(e.id) >= e.targetCount)
        .length;
    final totalInCat = categoryItems.length;
    final catProgress = totalInCat == 0 ? 0.0 : completedCount / totalInCat;

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
    final double uiScale = tvMode ? tvScale.clamp(1.0, 1.6) : 1.0;
    final double arabicPx =
        tvMode ? math.max(22.0 * tvScale, settingsArabicSize) : 22.0;
    final double meaningPx =
        tvMode ? math.max(13.5 * tvScale, settingsTransSize) : 13.5;

    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: tvMode,
      normalMaxWidth: 860,
      minPad: 14.0,
    );

    return Directionality(
      textDirection: t.textDirection,
      child: ListView(
        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
        children: [
          // Header banner + progress
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.actionAdhkar,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            t.hisnulMuslimNote,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!adhkarState.favoritesOnly && totalInCat > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$completedCount / $totalInCat',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!adhkarState.favoritesOnly && totalInCat > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: catProgress,
                      minHeight: 6,
                      backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: () =>
                          notifier.resetCategory(adhkarState.selectedCategory),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(t.resetTodayProgress),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category selector + Favorites filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final cat in AdhkarCatalog.categoryKeys) ...[
                  ChoiceChip(
                    avatar: Icon(
                      _categoryIcon(cat),
                      size: 16,
                      color: !adhkarState.favoritesOnly &&
                              adhkarState.selectedCategory == cat
                          ? cs.onPrimary
                          : cs.primary,
                    ),
                    label: Text(_categoryLabel(cat, t)),
                    selected: !adhkarState.favoritesOnly &&
                        adhkarState.selectedCategory == cat,
                    onSelected: (_) => notifier.selectCategory(cat),
                  ),
                  const SizedBox(width: 8),
                ],
                FilterChip(
                  avatar: Icon(
                    adhkarState.favoritesOnly
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: adhkarState.favoritesOnly ? cs.error : cs.primary,
                  ),
                  label: Text(
                    '${t.favoritesOnlyLabel} (${adhkarState.favoriteIds.length})',
                  ),
                  selected: adhkarState.favoritesOnly,
                  onSelected: (_) => notifier.toggleFavoritesOnly(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_outline_rounded,
                    size: 40,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t.favoritesOnlyLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.hisnulMuslimNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            for (final entry in items)
              _AdhkarCard(
                entry: entry,
                count: adhkarState.countFor(entry.id),
                isFavorite: adhkarState.favoriteIds.contains(entry.id),
                appLang: appLang,
                strings: t,
                cs: cs,
                cardBg: cardBg,
                cardBorder: cardBorder,
                arabicFontSize: arabicPx,
                meaningFontSize: meaningPx,
                uiScale: uiScale,
                onTapCount: () async {
                  final completedNow = await notifier.incrementEntry(entry);
                  if (completedNow) {
                    HapticFeedback.mediumImpact();
                  } else {
                    HapticFeedback.selectionClick();
                  }
                },
                onReset: () => notifier.resetEntry(entry.id),
                onToggleFav: () => notifier.toggleFavorite(entry.id),
                onCopy: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: '${entry.arabic}\n\n${entry.translationFor(appLang)}\n(${entry.reference})',
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
        ],
      ),
    );
  }
}

class _AdhkarCard extends StatelessWidget {
  final AdhkarEntry entry;
  final int count;
  final bool isFavorite;
  final String appLang;
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final double arabicFontSize;
  final double meaningFontSize;
  final double uiScale;
  final VoidCallback onTapCount;
  final VoidCallback onReset;
  final VoidCallback onToggleFav;
  final VoidCallback onCopy;

  const _AdhkarCard({
    required this.entry,
    required this.count,
    required this.isFavorite,
    required this.appLang,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    this.arabicFontSize = 22.0,
    this.meaningFontSize = 13.5,
    this.uiScale = 1.0,
    required this.onTapCount,
    required this.onReset,
    required this.onToggleFav,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final completed = count >= entry.targetCount;
    final progress = entry.targetCount > 0
        ? (count / entry.targetCount).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: completed ? cs.primaryContainer.withValues(alpha: 0.25) : cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed ? cs.primary.withValues(alpha: 0.55) : cardBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTapCount,
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                              fontSize: 15 * uiScale,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.reference,
                            style: TextStyle(
                              fontSize: 11.5 * uiScale,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: strings.favoritesOnlyLabel,
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavorite ? cs.error : cs.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: onToggleFav,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.copy_rounded,
                        color: cs.onSurfaceVariant,
                        size: 18,
                      ),
                      onPressed: onCopy,
                    ),
                    if (count > 0)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: strings.resetCycleLabel,
                        icon: Icon(
                          Icons.refresh_rounded,
                          color: cs.onSurfaceVariant,
                          size: 19,
                        ),
                        onPressed: onReset,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    entry.arabic,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(
                      fontSize: arabicFontSize,
                      height: 1.85,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  entry.translationFor(appLang),
                  style: TextStyle(
                    fontSize: meaningFontSize,
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
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
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppBranding.primaryEmerald
                            : cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (completed) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 15,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '$count / ${entry.targetCount}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: completed ? Colors.white : cs.primary,
                              fontFeatures: const [FontFeature.tabularFigures()],
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
