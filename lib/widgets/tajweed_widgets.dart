import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../services/tajweed_engine.dart';

void showTajweedRuleInspectorSheet(
  BuildContext context, {
  required TajweedRuleMeta meta,
  required String tappedArabic,
  required AppStrings strings,
  VoidCallback? onOpenFullGuide,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final ruleColor = meta.colorFor(isDark);
  final cleanSample = tappedArabic.replaceAll('\u200D', '').trim();

  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return Directionality(
        textDirection: strings.textDirection,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ruleColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: ruleColor.withValues(alpha: 0.45),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cleanSample.isNotEmpty ? cleanSample : meta.sampleAr,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ruleColor,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.tajweedRuleHeader,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: ruleColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta.titleFor(strings.lang),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (strings.lang != 'ar')
                    Text(
                      meta.nameAr,
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.amiri(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      meta.descriptionFor(strings.lang),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          '${strings.tajweedExamplesLabel}: ',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            meta.sampleAr,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: ruleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOpenFullGuide != null) ...[
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(ctx);
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

void showTajweedLegendSheet(
  BuildContext context, {
  required AppStrings strings,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return Directionality(
        textDirection: strings.textDirection,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          builder: (_, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_rounded, color: cs.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
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
                          Text(
                            strings.tajweedTapHint,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...TajweedEngine.legend.map((meta) {
                  final color = meta.colorFor(isDark);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
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
                            height: 1.45,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );
    },
  );
}

/// Manages lifecycle-safe TapGestureRecognizers for interactive Tajweed spans
/// across both Ayah List View and multi-ayah Mushaf Page View paragraphs.
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
    required void Function(TajweedRuleMeta meta, String tappedSample) onRuleTap,
  }) {
    final tokens = TajweedEngine.parseAyah(arabicText);
    final spans = <InlineSpan>[];

    for (final tok in tokens) {
      final meta =
          tok.rule == TajweedRule.none ? null : TajweedEngine.metaFor(tok.rule);

      if (meta == null) {
        spans.add(
          TextSpan(
            text: tok.text,
            style: backgroundColor != null
                ? baseStyle.copyWith(backgroundColor: backgroundColor)
                : null,
          ),
        );
      } else {
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
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationColor: meta.colorFor(isDark).withValues(alpha: 0.45),
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  void dispose() {
    resetRecognizers();
    super.dispose();
  }
}

/// Always-on interactive Tajweed text widget for Verse List mode.
class TajweedAyahRichText extends StatefulWidget {
  final String arabicText;
  final String endMarker;
  final TextStyle baseStyle;
  final TextStyle markerStyle;
  final AppStrings strings;
  final Color? highlightBg;

  const TajweedAyahRichText({
    super.key,
    required this.arabicText,
    required this.endMarker,
    required this.baseStyle,
    required this.markerStyle,
    required this.strings,
    this.highlightBg,
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
              backgroundColor: widget.highlightBg,
              onRuleTap: (meta, sample) => showTajweedRuleInspectorSheet(
                context,
                meta: meta,
                tappedArabic: sample,
                strings: widget.strings,
                onOpenFullGuide: () => showTajweedLegendSheet(
                  context,
                  strings: widget.strings,
                ),
              ),
            ),
            TextSpan(
              text: widget.endMarker,
              style: widget.markerStyle,
            ),
          ],
        ),
        textAlign: TextAlign.right,
      ),
    );
  }
}

/// Small inline Tajweed banner chip in Surah reader showing a quick tap cue + legend trigger.
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
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showTajweedLegendSheet(context, strings: strings),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: TajweedEngine.legend.take(5).map((m) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    decoration: BoxDecoration(
                      color: m.colorFor(isDark),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.tajweedTapHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                strings.tajweedLegendShort,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppBranding.accentGold : cs.primary,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isDark ? AppBranding.accentGold : cs.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
