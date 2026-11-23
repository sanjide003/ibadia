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
import '../services/storage_service.dart';

String _stripArabicTashkeel(String input) {
  return input.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]'), '');
}

void showAsmaulHusnaDetailSheet(
  BuildContext context, {
  required int initialIndex,
  required AppStrings strings,
  required String appLanguage,
  ValueChanged<AsmaulHusnaItem>? onNavigateName,
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
                  // Top Header: Number + Transliteration + Copy
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
                                fontSize: 18,
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
                      IconButton.filledTonal(
                        tooltip: strings.copiedNameNotice,
                        onPressed: () {
                          final copyText =
                              '${item.arabic} (${item.transliteration})\n${item.malayalamMeaning}\n${item.englishMeaning}';
                          Clipboard.setData(ClipboardData(text: copyText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.copiedNameNotice),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
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
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Malayalam Meaning Card
                  _MeaningDetailBlock(
                    label: strings.meaningMalayalamLabel,
                    value: item.malayalamMeaning,
                    cs: cs,
                    highlight: true,
                  ),
                  const SizedBox(height: 10),

                  // English Meaning Card
                  _MeaningDetailBlock(
                    label: strings.meaningEnglishLabel,
                    value: item.englishMeaning,
                    cs: cs,
                  ),
                  const SizedBox(height: 10),

                  // Reflection Block
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
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
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.reflectionMl,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (appLanguage != 'ml') ...[
                          const SizedBox(height: 6),
                          Text(
                            item.reflectionEn,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.45,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
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

  const _MeaningDetailBlock({
    required this.label,
    required this.value,
    required this.cs,
    this.highlight = false,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: highlight ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.35,
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
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 1040) / 2);
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
                                              fontSize: 25,
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
                                  cs: cs,
                                  isDark: isDark,
                                  cardBg: palette.cardBg,
                                  cardBorder: palette.cardBorder,
                                  onTap: () {
                                    _recordNameActivity(item);
                                    showAsmaulHusnaDetailSheet(
                                      context,
                                      initialIndex: item.number - 1,
                                      strings: t,
                                      appLanguage: settings.appLanguage,
                                      onNavigateName: _recordNameActivity,
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
                            mainAxisExtent: 120,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) {
                            final item = filtered[idx];
                            return _AsmaulHusnaCard(
                              item: item,
                              cs: cs,
                              isDark: isDark,
                              cardBg: palette.cardBg,
                              cardBorder: palette.cardBorder,
                              onTap: () {
                                _recordNameActivity(item);
                                showAsmaulHusnaDetailSheet(
                                  context,
                                  initialIndex: item.number - 1,
                                  strings: t,
                                  appLanguage: settings.appLanguage,
                                  onNavigateName: _recordNameActivity,
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
  final ColorScheme cs;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  const _AsmaulHusnaCard({
    required this.item,
    required this.cs,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppBranding.accentGold : cs.primary;
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
          child: Row(
            children: [
              // Number index badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Text(
                  item.number.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Transliteration + Malayalam + English meanings
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.transliteration,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.malayalamMeaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.englishMeaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Arabic Name
              Text(
                item.arabic,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
