import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../data/asmaul_husna_data.dart';
import '../models/recent_activity_model.dart';
import '../providers/quran_providers.dart';
import '../services/export_service.dart';
import '../services/storage_service.dart';
import '../widgets/tv_mode_widgets.dart';

String _stripArabicTashkeel(String input) {
  return input.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
}

void showAsmaulHusnaDetailSheet(
  BuildContext context, {
  required int initialIndex,
  required AppStrings strings,
  required String appLanguage,
  ValueChanged<AsmaulHusnaItem>? onNavigateName,
  double textScale = 1.0,
  double? arabicFontSize,
}) {
  final total = AsmaulHusnaCatalog.names.length;
  if (total == 0) return;
  int currentIdx = initialIndex.clamp(0, total - 1);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final item = AsmaulHusnaCatalog.names[currentIdx];
          final cs = Theme.of(sheetCtx).colorScheme;
          final isDark = Theme.of(sheetCtx).brightness == Brightness.dark;
          final accent = isDark ? AppBranding.accentGold : cs.primary;

          return Directionality(
            textDirection: strings.textDirection,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tier 1: Full-width Header (Number + Transliteration)
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item.number.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.transliteration,
                              style: const TextStyle(
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${item.number} / $total',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tier 2: Share & Copy Actions
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final shareText =
                              '${item.arabic} (${item.transliteration})\n${item.malayalamMeaning}\n${item.arabicMeaning}\n\n${item.reflectionMl}';
                          ExportService.shareText(
                            shareText,
                            subject: '${item.transliteration} (${item.arabic})',
                          );
                        },
                        icon: const Icon(Icons.share_rounded, size: 17),
                        label: Text(strings.share),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          final copyText =
                              '${item.arabic} (${item.transliteration})\n${item.malayalamMeaning}\n${item.arabicMeaning}\n\n${item.reflectionMl}';
                          Clipboard.setData(ClipboardData(text: copyText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.copiedNameNotice),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: Text(strings.copyLabel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Calligraphy Showcase Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: arabicFontSize != null
                            ? math.max(46.0 * textScale, arabicFontSize)
                            : 46.0 * textScale,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (appLanguage != 'ar') ...[
                    // Malayalam Meaning Card
                    _MeaningDetailBlock(
                      label: strings.meaningMalayalamLabel,
                      value: item.malayalamMeaning,
                      cs: cs,
                      highlight: true,
                      textScale: textScale,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Arabic Explanation Card
                  _MeaningDetailBlock(
                    label: strings.meaningArabicLabel,
                    value: item.arabicMeaning,
                    cs: cs,
                    highlight: appLanguage == 'ar',
                    isRtl: true,
                    textScale: textScale,
                  ),
                  const SizedBox(height: 10),

                  // Reflection Block (Malayalam)
                  if (appLanguage != 'ar')
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.reflectionLabel,
                            style: TextStyle(
                              fontSize: 11.5 * textScale,
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.reflectionMl,
                            style: TextStyle(
                              fontSize: 13.5 * textScale,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  // Prev / Next Controls
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: currentIdx > 0
                              ? () {
                                  setSheetState(() => currentIdx--);
                                  onNavigateName?.call(
                                    AsmaulHusnaCatalog.names[currentIdx],
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                          label: Text(
                            currentIdx > 0
                                ? AsmaulHusnaCatalog
                                    .names[currentIdx - 1].transliteration
                                : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: currentIdx < total - 1
                              ? () {
                                  setSheetState(() => currentIdx++);
                                  onNavigateName?.call(
                                    AsmaulHusnaCatalog.names[currentIdx],
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded, size: 20),
                          label: Text(
                            currentIdx < total - 1
                                ? AsmaulHusnaCatalog
                                    .names[currentIdx + 1].transliteration
                                : '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
}

class _MeaningDetailBlock extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme cs;
  final bool highlight;
  final bool isRtl;
  final double textScale;

  const _MeaningDetailBlock({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
    this.isRtl = false,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight
            ? cs.primaryContainer.withValues(alpha: 0.34)
            : cs.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? cs.primary.withValues(alpha: 0.35)
              : cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5 * textScale,
                fontWeight: FontWeight.w700,
                color: highlight ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: Text(
              value,
              textDirection: isRtl ? TextDirection.rtl : null,
              textAlign: isRtl ? TextAlign.right : TextAlign.start,
              style: isRtl
                  ? GoogleFonts.amiri(
                      fontSize: 18 * textScale,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.45,
                    )
                  : TextStyle(
                      fontSize: 15 * textScale,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                      height: 1.35,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class AsmaulHusnaView extends ConsumerStatefulWidget {
  const AsmaulHusnaView({super.key});

  @override
  ConsumerState<AsmaulHusnaView> createState() => _AsmaulHusnaViewState();
}

class _AsmaulHusnaViewState extends ConsumerState<AsmaulHusnaView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ({Color cardBg, Color cardBorder}) _palette(
    BuildContext context,
    AppSettings settings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';
    return (
      cardBg: isDark
          ? const Color(0xFF141A17)
          : (isSepia ? const Color(0xFFFFFDF7) : Colors.white),
      cardBorder: isDark
          ? const Color(0xFF23302A)
          : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6)),
    );
  }

  void _recordNameActivity(AsmaulHusnaItem item) {
    ref.read(recentActivityProvider.notifier).record(
          RecentActivityEntry(
            id: 'asma:${item.number}',
            type: RecentActivityType.asmaulHusna,
            titleEn: '${item.number}. ${item.transliteration}',
            titleMl: '${item.number}. ${item.malayalamMeaning}',
            titleAr: '${item.number}. ${item.arabic}',
            subtitleEn: item.englishMeaning,
            subtitleMl: item.transliteration,
            subtitleAr: item.englishMeaning,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            featureSubTab: 4,
            asmaIndex: item.number - 1,
          ),
        );
  }

  String _arabicDigits(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => digits[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _palette(context, settings);
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: settings.tvModeEnabled,
      normalMaxWidth: 1040,
    );
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.5) : 1.0;
    final double arabicCardSize = settings.tvModeEnabled
        ? math.max(25.0 * settings.tvFontScale, settings.arabicFontSize)
        : 25.0;
    final String viewMode = settings.names99ViewMode;

    final trimmed = _query.trim().toLowerCase();
    final strippedQuery = _stripArabicTashkeel(_query.trim());

    final filtered = trimmed.isEmpty
        ? AsmaulHusnaCatalog.names
        : AsmaulHusnaCatalog.names.where((item) {
            return item.number.toString() == trimmed ||
                item.transliteration.toLowerCase().contains(trimmed) ||
                item.englishMeaning.toLowerCase().contains(trimmed) ||
                item.malayalamMeaning.toLowerCase().contains(trimmed) ||
                item.arabicMeaning.contains(_query.trim()) ||
                item.arabic.contains(_query.trim()) ||
                (strippedQuery.isNotEmpty &&
                    _stripArabicTashkeel(item.arabic).contains(strippedQuery));
          }).toList();

    return Column(
      children: [
        // Top Header + Dual View Toggle + Live Search
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
          decoration: BoxDecoration(
            color: palette.cardBg,
            border: Border(bottom: BorderSide(color: palette.cardBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: isDark ? AppBranding.accentGold : cs.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.names99Title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '${filtered.length}/99',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'grid',
                      icon: const Icon(Icons.grid_on_rounded, size: 16),
                      label: Text(
                        t.names99GridMode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    ButtonSegment(
                      value: 'list',
                      icon: const Icon(Icons.view_agenda_outlined, size: 16),
                      label: Text(
                        t.names99ListMode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (sel) {
                    ref.read(settingsProvider.notifier).updateWith(
                          (s) => s.copyWith(names99ViewMode: sel.first),
                        );
                  },
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: t.names99SearchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        )
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: palette.cardBorder),
                  ),
                ),
              ),
              if (viewMode == 'grid') ...[
                const SizedBox(height: 8),
                Text(
                  t.names99GridHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),

        // 3-Column RTL Arabic Calligraphy Grid OR Detailed Cards
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      t.noSearchResults,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : viewMode == 'grid'
                  ? Directionality(
                      textDirection: TextDirection.rtl,
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.08,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, idx) {
                          final item = filtered[idx];
                          final accent =
                              isDark ? AppBranding.accentGold : cs.primary;
                          return Material(
                            color: palette.cardBg,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                _recordNameActivity(item);
                                showAsmaulHusnaDetailSheet(
                                  context,
                                  initialIndex: item.number - 1,
                                  strings: t,
                                  appLanguage: settings.appLanguage,
                                  onNavigateName: _recordNameActivity,
                                  textScale: uiScale,
                                  arabicFontSize: arabicCardSize,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: palette.cardBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer
                                            .withValues(alpha: 0.55),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _arabicDigits(item.number),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: cs.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Center(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item.arabic,
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: GoogleFonts.amiri(
                                              fontSize: arabicCardSize,
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                              color: accent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final int cols = w >= 1020 ? 3 : (w >= 640 ? 2 : 1);
                        if (cols == 1) {
                          return ListView.builder(
                            padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
                            itemCount: filtered.length,
                            itemBuilder: (_, idx) {
                              final item = filtered[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _AsmaulHusnaCard(
                                  item: item,
                                  strings: t,
                                  cs: cs,
                                  isDark: isDark,
                                  cardBg: palette.cardBg,
                                  cardBorder: palette.cardBorder,
                                  uiScale: uiScale,
                                  arabicFontSize: arabicCardSize,
                                  onTap: () {
                                    _recordNameActivity(item);
                                    showAsmaulHusnaDetailSheet(
                                      context,
                                      initialIndex: item.number - 1,
                                      strings: t,
                                      appLanguage: settings.appLanguage,
                                      onNavigateName: _recordNameActivity,
                                      textScale: uiScale,
                                      arabicFontSize: arabicCardSize,
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        }

                        return GridView.builder(
                          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 28),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 172 * uiScale.clamp(1.0, 1.4),
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) {
                            final item = filtered[idx];
                            return _AsmaulHusnaCard(
                              item: item,
                              strings: t,
                              cs: cs,
                              isDark: isDark,
                              cardBg: palette.cardBg,
                              cardBorder: palette.cardBorder,
                              uiScale: uiScale,
                              arabicFontSize: arabicCardSize,
                              onTap: () {
                                _recordNameActivity(item);
                                showAsmaulHusnaDetailSheet(
                                  context,
                                  initialIndex: item.number - 1,
                                  strings: t,
                                  appLanguage: settings.appLanguage,
                                  onNavigateName: _recordNameActivity,
                                  textScale: uiScale,
                                  arabicFontSize: arabicCardSize,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _AsmaulHusnaCard extends StatelessWidget {
  final AsmaulHusnaItem item;
  final AppStrings strings;
  final ColorScheme cs;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final double uiScale;
  final double arabicFontSize;
  final VoidCallback onTap;

  const _AsmaulHusnaCard({
    required this.item,
    required this.strings,
    required this.cs,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    this.uiScale = 1.0,
    this.arabicFontSize = 25.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppBranding.accentGold : cs.primary;
    final shareAndCopyText =
        '${item.arabic} (${item.transliteration})\n${item.malayalamMeaning}\n${item.arabicMeaning}';

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tier 1: Number + Transliteration/Malayalam + Arabic Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.number.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 13 * uiScale.clamp(1.0, 1.3),
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.transliteration,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.8 * uiScale.clamp(1.0, 1.35),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.malayalamMeaning,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * uiScale.clamp(1.0, 1.35),
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiri(
                      fontSize: arabicFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.arabicMeaning,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 14.5 * uiScale.clamp(1.0, 1.25),
                  color: cs.onSurfaceVariant,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              // Tier 2: Share & Copy action bar
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _AsmaCardActionBtn(
                    icon: Icons.share_rounded,
                    label: strings.share,
                    color: accent,
                    borderColor: cardBorder,
                    onTap: () => ExportService.shareText(
                      shareAndCopyText,
                      subject: '${item.transliteration} (${item.arabic})',
                    ),
                  ),
                  _AsmaCardActionBtn(
                    icon: Icons.copy_rounded,
                    label: strings.copyLabel,
                    color: cs.onSurfaceVariant,
                    borderColor: cardBorder,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: shareAndCopyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.copiedNameNotice),
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
      ),
    );
  }
}

class _AsmaCardActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;

  const _AsmaCardActionBtn({
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
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14.5, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.2,
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
