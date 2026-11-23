import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/l10n/app_strings.dart';
import '../services/tajweed_engine.dart';

export '../services/tajweed_engine.dart';

mixin TajweedRecognizerPool<T extends StatefulWidget> on State<T> {
  final List<TapGestureRecognizer> _recognizers = [];

  void resetRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  List<InlineSpan> buildTajweedSpans({
    required String arabicText,
    required TextStyle baseStyle,
    required bool isDark,
    Color? backgroundColor,
    required void Function(TajweedRuleMeta meta, String sample) onRuleTap,
  }) {
    final tokens = TajweedEngine.tokenize(arabicText);
    if (tokens.isEmpty) {
      return [
        TextSpan(
          text: arabicText,
          style: backgroundColor != null
              ? baseStyle.copyWith(backgroundColor: backgroundColor)
              : baseStyle,
        ),
      ];
    }

    final spans = <InlineSpan>[];
    for (final tok in tokens) {
      if (tok.rule == TajweedRule.none) {
        spans.add(
          TextSpan(
            text: tok.text,
            style: backgroundColor != null
                ? baseStyle.copyWith(backgroundColor: backgroundColor)
                : baseStyle,
          ),
        );
        continue;
      }

      final meta = TajweedEngine.metaForRule(tok.rule);
      if (meta == null) {
        spans.add(
          TextSpan(
            text: tok.text,
            style: backgroundColor != null
                ? baseStyle.copyWith(backgroundColor: backgroundColor)
                : baseStyle,
          ),
        );
        continue;
      }

      final rec = TapGestureRecognizer()
        ..onTap = () => onRuleTap(meta, tok.text);
      _recognizers.add(rec);

      spans.add(
        TextSpan(
          text: tok.text,
          recognizer: rec,
          style: baseStyle.copyWith(
            color: meta.colorFor(isDark),
            backgroundColor: backgroundColor,
          ),
        ),
      );
    }
    return spans;
  }

  @override
  void dispose() {
    resetRecognizers();
    super.dispose();
  }
}

class TajweedAyahRichText extends StatefulWidget {
  final String arabicText;
  final String endMarker;
  final TextStyle baseStyle;
  final TextStyle markerStyle;
  final AppStrings strings;
  final Color? backgroundColor;

  const TajweedAyahRichText({
    super.key,
    required this.arabicText,
    required this.endMarker,
    required this.baseStyle,
    required this.markerStyle,
    required this.strings,
    this.backgroundColor,
  });

  @override
  State<TajweedAyahRichText> createState() => _TajweedAyahRichTextState();
}

class _TajweedAyahRichTextState extends State<TajweedAyahRichText>
    with TajweedRecognizerPool<TajweedAyahRichText> {
  @override
  Widget build(BuildContext context) {
    resetRecognizers();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.strings;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text.rich(
        TextSpan(
          style: widget.baseStyle,
          children: [
            ...buildTajweedSpans(
              arabicText: widget.arabicText,
              baseStyle: widget.baseStyle,
              isDark: isDark,
              backgroundColor: widget.backgroundColor,
              onRuleTap: (meta, sample) => showTajweedRuleInspectorSheet(
                context,
                meta: meta,
                tappedArabic: sample,
                strings: t,
                onOpenFullGuide: () => showTajweedLegendSheet(
                  context,
                  strings: t,
                ),
              ),
            ),
            TextSpan(
              text: widget.endMarker,
              style: widget.backgroundColor != null
                  ? widget.markerStyle.copyWith(
                      backgroundColor: widget.backgroundColor,
                    )
                  : widget.markerStyle,
            ),
          ],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

class TajweedLegendMiniBar extends StatelessWidget {
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;

  const TajweedLegendMiniBar({
    super.key,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = strings.lang;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.palette_outlined, size: 15, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: TajweedEngine.legend.map((meta) {
                    final color = meta.colorFor(isDark);
                    return Padding(
                      padding: const EdgeInsetsDirectional.only(end: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showTajweedRuleInspectorSheet(
                          context,
                          meta: meta,
                          strings: strings,
                          onOpenFullGuide: () =>
                              showTajweedLegendSheet(context, strings: strings),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                meta.titleFor(lang).split('(').first.trim(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showTajweedLegendSheet(context, strings: strings),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  strings.tajweedLegendShort,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showTajweedRuleInspectorSheet(
  BuildContext context, {
  required TajweedRuleMeta meta,
  String? tappedArabic,
  required AppStrings strings,
  VoidCallback? onOpenFullGuide,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final cs = Theme.of(ctx).colorScheme;
      final color = meta.colorFor(isDark);
      final cleanTapped = (tappedArabic ?? '').replaceAll('\u200D', '').trim();

      return Directionality(
        textDirection: strings.textDirection,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      meta.titleFor(strings.lang),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                  if (cleanTapped.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        cleanTapped,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      meta.descriptionFor(strings.lang),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings.tajweedExamplesLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          meta.sampleAr,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOpenFullGuide != null) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onOpenFullGuide();
                  },
                  icon: const Icon(Icons.palette_outlined, size: 18),
                  label: Text(strings.tajweedFullGuideBtn),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showTajweedLegendSheet(
  BuildContext context, {
  required AppStrings strings,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final cs = Theme.of(ctx).colorScheme;

      return Directionality(
        textDirection: strings.textDirection,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (_, scrollCtrl) {
            return ListView.separated(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: TajweedEngine.legend.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, idx) {
                if (idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tajweedGuideTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.tajweedTapHint,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final meta = TajweedEngine.legend[idx - 1];
                final color = meta.colorFor(isDark);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: color.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              meta.titleFor(strings.lang),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                          Text(
                            meta.sampleAr,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta.descriptionFor(strings.lang),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}
