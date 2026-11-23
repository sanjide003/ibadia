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
import '../services/storage_service.dart';

({Color cardBg, Color cardBorder, Color headerBg}) _themePalette(
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

// ---------------------------------------------------------------------------
// 3. OFFLINE DAILY DUAS & ADHKAR VIEW (Hisnul Muslim)
// ---------------------------------------------------------------------------
class AdhkarDuasView extends ConsumerWidget {
  const AdhkarDuasView({super.key});

  String _categoryLabel(String key, AppStrings t) {
    switch (key) {
      case 'morning':
        return t.morningAdhkar;
      case 'evening':
        return t.eveningAdhkar;
      case 'after_salah':
        return t.afterSalahAdhkar;
      case 'daily_duas':
        return t.dailyDuasCategory;
      default:
        return key;
    }
  }

  IconData _categoryIcon(String key) {
    switch (key) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'evening':
        return Icons.nights_stay_outlined;
      case 'after_salah':
        return Icons.mosque_outlined;
      case 'daily_duas':
        return Icons.menu_book_outlined;
      default:
        return Icons.star_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adhkar = ref.watch(adhkarProvider);
    final notifier = ref.read(adhkarProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final palette = _themePalette(context, settings);
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 860) / 2);

    final List<AdhkarEntry> visibleEntries = adhkar.favoritesOnly
        ? AdhkarCatalog.entries
            .where((e) => adhkar.favoriteIds.contains(e.id))
            .toList()
        : AdhkarCatalog.entries
            .where((e) => e.category == adhkar.selectedCategory)
            .toList();

    final completedCount = visibleEntries
        .where((e) => adhkar.countFor(e.id) >= e.targetCount)
        .length;

    return Column(
      children: [
        // Top Category Selector & Favorites / Reset bar
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 10),
          decoration: BoxDecoration(
            color: palette.cardBg,
            border: Border(bottom: BorderSide(color: palette.cardBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...AdhkarCatalog.categoryKeys.map((key) {
                      final active =
                          !adhkar.favoritesOnly && adhkar.selectedCategory == key;
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            _categoryIcon(key),
                            size: 16,
                            color: active ? cs.onPrimary : cs.primary,
                          ),
                          label: Text(
                            _categoryLabel(key, t),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: active ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                          selected: active,
                          selectedColor: cs.primary,
                          showCheckmark: false,
                          onSelected: (_) => notifier.selectCategory(key),
                        ),
                      );
                    }),
                    ChoiceChip(
                      avatar: Icon(
                        adhkar.favoritesOnly
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 16,
                        color: adhkar.favoritesOnly
                            ? cs.onPrimary
                            : AppBranding.accentGold,
                      ),
                      label: Text(
                        t.favoritesOnlyLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color:
                              adhkar.favoritesOnly ? cs.onPrimary : cs.onSurface,
                        ),
                      ),
                      selected: adhkar.favoritesOnly,
                      selectedColor: cs.primary,
                      showCheckmark: false,
                      onSelected: (_) => notifier.toggleFavoritesOnly(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.hisnulMuslimNote,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (!adhkar.favoritesOnly && visibleEntries.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$completedCount/${visibleEntries.length}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (completedCount > 0 ||
                        visibleEntries
                            .any((e) => adhkar.countFor(e.id) > 0)) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(44, 38),
                        ),
                        onPressed: () =>
                            notifier.resetCategory(adhkar.selectedCategory),
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: Text(
                          t.resetTodayProgress,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),

        // Adhkar Cards List
        Expanded(
          child: visibleEntries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_outline_rounded,
                          size: 46,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.noFavoriteAdhkar,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
                  itemCount: visibleEntries.length,
                  itemBuilder: (context, idx) {
                    final entry = visibleEntries[idx];
                    final count = adhkar.countFor(entry.id);
                    final done = count >= entry.targetCount;
                    final isFav = adhkar.favoriteIds.contains(entry.id);
                    final progress = (count / entry.targetCount).clamp(0.0, 1.0);

                    return RepaintBoundary(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: done
                              ? cs.primaryContainer.withValues(alpha: 0.34)
                              : palette.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: done
                                ? cs.primary.withValues(alpha: 0.55)
                                : palette.cardBorder,
                            width: done ? 1.4 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              if (done) return;
                              final justDone =
                                  await notifier.incrementEntry(entry);
                              if (justDone) {
                                HapticFeedback.mediumImpact();
                              } else {
                                HapticFeedback.selectionClick();
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    10,
                                    12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Title & Actions Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.titleFor(settings.appLanguage),
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                                color: done
                                                    ? cs.primary
                                                    : cs.onSurface,
                                              ),
                                            ),
                                          ),
                                          if (count > 0)
                                            IconButton(
                                              tooltip: t.resetCycleLabel,
                                              constraints: const BoxConstraints(
                                                minWidth: 44,
                                                minHeight: 44,
                                              ),
                                              onPressed: () =>
                                                  notifier.resetEntry(entry.id),
                                              icon: Icon(
                                                Icons.refresh_rounded,
                                                size: 19,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          IconButton(
                                            tooltip: t.favoritesOnlyLabel,
                                            constraints: const BoxConstraints(
                                              minWidth: 44,
                                              minHeight: 44,
                                            ),
                                            onPressed: () =>
                                                notifier.toggleFavorite(entry.id),
                                            icon: Icon(
                                              isFav
                                                  ? Icons.star_rounded
                                                  : Icons.star_outline_rounded,
                                              size: 21,
                                              color: isFav
                                                  ? AppBranding.accentGold
                                                  : cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Arabic Text
                                      Text(
                                        entry.arabic,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        style: GoogleFonts.amiri(
                                          fontSize: 22.5,
                                          height: 1.75,
                                          fontWeight: FontWeight.w700,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 10),

                                      // Translation (English or Malayalam based on App Language)
                                      if (settings.appLanguage != 'ar') ...[
                                        Text(
                                          entry.translationFor(
                                            settings.appLanguage,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            height: 1.5,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                      ],

                                      // Clean Unboxed Metadata & Counter Row
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${entry.reference}  ·  ${entry.targetCount}x',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          if (done)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  size: 17,
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  t.completedLabel,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: cs.primary,
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            Text(
                                              '$count / ${entry.targetCount}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: cs.primary,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 4,
                                  backgroundColor: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    done ? cs.primary : AppBranding.accentGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. DIGITAL TASBIH COUNTER VIEW (Haptic Circular Counter & Custom Dhikr)
// ---------------------------------------------------------------------------
class DigitalTasbihView extends ConsumerStatefulWidget {
  const DigitalTasbihView({super.key});

  @override
  ConsumerState<DigitalTasbihView> createState() => _DigitalTasbihViewState();
}

class _DigitalTasbihViewState extends ConsumerState<DigitalTasbihView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _onTapCounter() async {
    _pulseCtrl.forward(from: 0.0).then((_) {
      if (mounted) _pulseCtrl.reverse();
    });
    final stateBefore = ref.read(tasbihProvider);
    final hitTarget = ref.read(tasbihProvider.notifier).tap();
    if (stateBefore.vibrateOnTap) {
      if (hitTarget) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
  }

  Future<void> _openAddCustomDialog(AppStrings t) async {
    final nameCtrl = TextEditingController();
    final arabicCtrl = TextEditingController();
    int selectedTarget = 33;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Directionality(
              textDirection: t.textDirection,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  24 + MediaQuery.viewInsetsOf(sheetCtx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      t.addCustomDhikr,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: t.customDhikrName,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: arabicCtrl,
                      textDirection: TextDirection.rtl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: t.customDhikrArabic,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t.targetLabel,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      segments: [
                        const ButtonSegment(value: 33, label: Text('33')),
                        const ButtonSegment(value: 99, label: Text('99')),
                        const ButtonSegment(value: 100, label: Text('100')),
                        ButtonSegment(value: 0, label: Text(t.unlimitedLabel)),
                      ],
                      selected: {selectedTarget},
                      onSelectionChanged: (s) =>
                          setSheetState(() => selectedTarget = s.first),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(t.cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              if (nameCtrl.text.trim().isEmpty) return;
                              ref
                                  .read(tasbihProvider.notifier)
                                  .addCustomPreset(
                                    title: nameCtrl.text,
                                    arabic: arabicCtrl.text,
                                    defaultTarget: selectedTarget,
                                  );
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(t.applyLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    arabicCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasbih = ref.watch(tasbihProvider);
    final notifier = ref.read(tasbihProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final palette = _themePalette(context, settings);

    final activePreset = tasbih.activePreset;
    final target = tasbih.activeTarget;
    final cycleCount = tasbih.activeCycleCount;
    final double ringProgress = target > 0
        ? (cycleCount / target).clamp(0.0, 1.0)
        : ((cycleCount % 33) / 33.0);
    final bool cycleDone = target > 0 && cycleCount >= target;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hPad = math.max(16.0, (constraints.maxWidth - 680) / 2);
        final isCompactHeight = constraints.maxHeight < 520;

        final topDock = Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Dhikr Selector + Add/Delete Custom Dhikr
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        filled: true,
                        fillColor: palette.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: palette.cardBorder),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activePreset.id,
                          isExpanded: true,
                          borderRadius: BorderRadius.circular(14),
                          items: tasbih.allPresets.map((p) {
                            return DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                p.titleFor(settings.appLanguage),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) notifier.selectPreset(id);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openAddCustomDialog(t),
                      child: Tooltip(
                        message: t.addCustomDhikr,
                        child: const Icon(Icons.add_rounded, size: 22),
                      ),
                    ),
                  ),
                  if (activePreset.isCustom) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: IconButton.outlined(
                        onPressed: () =>
                            notifier.deleteCustomPreset(activePreset.id),
                        tooltip: t.deleteCustomLabel,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: cs.error,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 10),

              // 2. Target Selector (33 / 99 / 100 / Free)
              SegmentedButton<int>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                segments: [
                  const ButtonSegment(value: 33, label: Text('33')),
                  const ButtonSegment(value: 99, label: Text('99')),
                  const ButtonSegment(value: 100, label: Text('100')),
                  ButtonSegment(
                    value: 0,
                    label: Text(
                      t.unlimitedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                selected: {
                  const [33, 99, 100, 0].contains(target) ? target : 0,
                },
                onSelectionChanged: (sel) => notifier.setTarget(sel.first),
              ),

              const SizedBox(height: 10),

              // 3. Stats + Tap Anywhere Toggle + Vibrate + Reset Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      '${t.todayTotalLabel}: ${tasbih.todayTotal}  ·  ${t.lifetimeTotalLabel}: ${tasbih.activeLifetimeCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: tasbih.tapAnywhere
                              ? cs.primary
                              : cs.surfaceContainerHighest
                                  .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: notifier.toggleTapAnywhere,
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.touch_app_rounded,
                                    size: 16,
                                    color: tasbih.tapAnywhere
                                        ? cs.onPrimary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    t.tapAnywhereLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: tasbih.tapAnywhere
                                          ? cs.onPrimary
                                          : cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          tooltip: t.vibrateOnTapLabel,
                          visualDensity: VisualDensity.compact,
                          constraints:
                              const BoxConstraints(minWidth: 38, minHeight: 38),
                          onPressed: notifier.toggleVibrateOnTap,
                          icon: Icon(
                            tasbih.vibrateOnTap
                                ? Icons.vibration_rounded
                                : Icons.smartphone_rounded,
                            size: 20,
                            color: tasbih.vibrateOnTap
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        IconButton(
                          tooltip: t.resetCycleLabel,
                          visualDensity: VisualDensity.compact,
                          constraints:
                              const BoxConstraints(minWidth: 38, minHeight: 38),
                          onPressed:
                              cycleCount > 0 ? notifier.resetCycle : null,
                          icon: Icon(
                            Icons.restart_alt_rounded,
                            size: 20,
                            color: cycleCount > 0
                                ? cs.error
                                : cs.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        Widget buildCircleZone(double availableHeight) {
          final double circleSize = isCompactHeight
              ? 204.0
              : (availableHeight - 138.0).clamp(178.0, 222.0);
          final double countFont = circleSize < 195 ? 48 : 56;
          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Middle: Selected Dhikr Card
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        activePreset.arabic,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.38,
                          color: cs.primary,
                        ),
                      ),
                      if (settings.appLanguage != 'ar') ...[
                        const SizedBox(height: 2),
                        Text(
                          activePreset.titleFor(settings.appLanguage),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                if (isCompactHeight)
                  const SizedBox(height: 14)
                else
                  const Spacer(),

                // Bottom: Ergonomic Thumb-Zone Counter Circle
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      final scale = 1.0 - (_pulseCtrl.value * 0.045);
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Semantics(
                      button: true,
                      label:
                          '${activePreset.titleFor(settings.appLanguage)} $cycleCount',
                      child: GestureDetector(
                        onTap: _onTapCounter,
                        child: SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: CustomPaint(
                            painter: _TasbihRingPainter(
                              progress: ringProgress,
                              trackColor: palette.cardBorder,
                              progressColor: cycleDone
                                  ? AppBranding.accentGold
                                  : cs.primary,
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    palette.headerBg,
                                    AppBranding.darkEmerald,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        palette.headerBg.withValues(alpha: 0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$cycleCount',
                                    style: TextStyle(
                                      fontSize: countFont,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.05,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    target > 0
                                        ? '/ $target'
                                        : t.unlimitedLabel,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: cycleDone
                                          ? AppBranding.accentGold
                                          : Colors.white
                                              .withValues(alpha: 0.82),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    child: Text(
                                      t.tapToCount,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.white
                                            .withValues(alpha: 0.72),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                if (!isCompactHeight) const SizedBox(height: 4),
              ],
            ),
          );
        }

        Widget buildTapAnywhereZone() {
          return Padding(
            padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 16),
            child: Semantics(
              button: true,
              label:
                  '${activePreset.titleFor(settings.appLanguage)} $cycleCount',
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: Ink(
                  width: double.infinity,
                  height: isCompactHeight ? 280 : double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.headerBg,
                        AppBranding.darkEmerald,
                      ],
                    ),
                    border: Border.all(
                      color: cycleDone
                          ? AppBranding.accentGold
                          : cs.primary.withValues(alpha: 0.45),
                      width: cycleDone ? 2.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.headerBg.withValues(alpha: 0.24),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: _onTapCounter,
                    splashColor: Colors.white.withValues(alpha: 0.16),
                    highlightColor: Colors.white.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top inside Tap Box: Arabic Dhikr + localized title
                          Column(
                            children: [
                              Text(
                                activePreset.arabic,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.amiri(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                  color: Colors.white,
                                ),
                              ),
                              if (settings.appLanguage != 'ar') ...[
                                const SizedBox(height: 2),
                                Text(
                                  activePreset.titleFor(settings.appLanguage),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.78),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Center-Lower: Giant Counter + Target + Progress Bar
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              final scale = 1.0 - (_pulseCtrl.value * 0.04);
                              return Transform.scale(scale: scale, child: child);
                            },
                            child: Column(
                              children: [
                                Text(
                                  '$cycleCount',
                                  style: const TextStyle(
                                    fontSize: 70,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  target > 0 ? '/ $target' : t.unlimitedLabel,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: cycleDone
                                        ? AppBranding.accentGold
                                        : Colors.white.withValues(alpha: 0.85),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: 220,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: ringProgress,
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.16),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        cycleDone
                                            ? AppBranding.accentGold
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Bottom Prompt inside Thumb Zone
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 17,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  t.tapAnywhereHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.82),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final lowerContent = LayoutBuilder(
          builder: (context, lowerConstraints) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey<bool>(tasbih.tapAnywhere),
                child: tasbih.tapAnywhere
                    ? buildTapAnywhereZone()
                    : buildCircleZone(
                        isCompactHeight ? 360.0 : lowerConstraints.maxHeight,
                      ),
              ),
            );
          },
        );

        if (isCompactHeight) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                topDock,
                lowerContent,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            topDock,
            Expanded(child: lowerContent),
          ],
        );
      },
    );
  }
}

class _TasbihRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _TasbihRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 5;
    const strokeWidth = 6.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_TasbihRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
