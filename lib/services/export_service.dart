import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../core/config/api_config.dart';
import '../models/surah_model.dart';

enum ExportScope { range, surah, juz }

enum ExportFormat { pdf, image }

class ExportAyahBlock {
  final int numberInSurah;
  final String arabicText;
  final Map<String, String> translations;

  const ExportAyahBlock({
    required this.numberInSurah,
    required this.arabicText,
    required this.translations,
  });
}

class ExportSurahSection {
  final SurahSummary summary;
  final bool showBanner;
  final bool showBismillah;
  final List<ExportAyahBlock> ayahs;

  const ExportSurahSection({
    required this.summary,
    required this.showBanner,
    required this.showBismillah,
    required this.ayahs,
  });
}

class ExportPageData {
  final int pageIndex;
  final int totalPages;
  final String headerTitle;
  final String headerSubtitle;
  final List<ExportSurahSection> sections;

  const ExportPageData({
    required this.pageIndex,
    required this.totalPages,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.sections,
  });
}

class RenderedExportPage {
  final Uint8List bytes;
  final Size logicalSize;

  const RenderedExportPage({
    required this.bytes,
    required this.logicalSize,
  });
}

/// Exact mobile-first typography & spacing specification shared identically
/// between TextPainter pagination, preview cards, and offscreen PNG canvas rendering.
class ExportLayoutSpec {
  static const double mobileWidth = 360.0;

  static const Color paperBg = Color(0xFFFFFFFF);
  static const Color inkPrimary = Color(0xFF181C1A);
  static const Color emerald = Color(0xFF047857);
  static const Color emeraldTint = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);
  static const Color divider = Color(0xFFE2E8F0);

  final double cardWidth;
  final double hPad;
  final double vPad;
  final double innerWidth;
  final double arabicMaxWidth;
  final double maxBodyHeight;
  final double sectionGap;

  final TextStyle arabicStyle;
  final TextStyle markerStyle;
  final TextStyle bismillahStyle;
  final TextStyle bannerEnStyle;
  final TextStyle bannerArStyle;
  final TextStyle mlStyle;
  final TextStyle enStyle;
  final TextStyle arTafsirStyle;

  ExportLayoutSpec._({
    required this.cardWidth,
    required this.hPad,
    required this.vPad,
    required this.innerWidth,
    required this.arabicMaxWidth,
    required this.maxBodyHeight,
    required this.sectionGap,
    required this.arabicStyle,
    required this.markerStyle,
    required this.bismillahStyle,
    required this.bannerEnStyle,
    required this.bannerArStyle,
    required this.mlStyle,
    required this.enStyle,
    required this.arTafsirStyle,
  });

  factory ExportLayoutSpec.mobile() {
    const double cardWidth = mobileWidth;
    const double hPad = 20.0;
    const double vPad = 20.0;
    const double innerWidth = cardWidth - hPad * 2;
    const double arabicMaxWidth = innerWidth - 8.0;
    // Screen-sized mobile page (~700pt body -> ~740pt total -> ~1480px tall at 2.0x)
    // eliminates mobile GPU glyph-atlas overflow while keeping pages compact and crisp.
    const double maxBodyHeight = 700.0;

    const double arabicFontSize = 21.0;
    const double arabicLineHeight = 1.88;

    return ExportLayoutSpec._(
      cardWidth: cardWidth,
      hPad: hPad,
      vPad: vPad,
      innerWidth: innerWidth,
      arabicMaxWidth: arabicMaxWidth,
      maxBodyHeight: maxBodyHeight,
      sectionGap: 14.0,
      arabicStyle: GoogleFonts.amiri(
        fontSize: arabicFontSize,
        height: arabicLineHeight,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      markerStyle: GoogleFonts.amiri(
        fontSize: arabicFontSize * 0.86,
        height: arabicLineHeight,
        fontWeight: FontWeight.w700,
        color: emerald,
        decoration: TextDecoration.none,
      ),
      bismillahStyle: GoogleFonts.amiri(
        fontSize: 20.0,
        height: 1.55,
        fontWeight: FontWeight.w700,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      bannerEnStyle: const TextStyle(
        color: emerald,
        fontSize: 13.0,
        height: 1.3,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
      bannerArStyle: GoogleFonts.amiri(
        color: emerald,
        fontSize: 18.5,
        height: 1.35,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
      mlStyle: GoogleFonts.notoSansMalayalam(
        fontSize: 12.8,
        height: 1.50,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      enStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12.2,
        height: 1.45,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      arTafsirStyle: GoogleFonts.notoSansArabic(
        fontSize: 13.8,
        height: 1.55,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
    );
  }

  TextStyle translationStyle(String code) {
    if (code == 'ml') return mlStyle;
    if (code == 'ar') return arTafsirStyle;
    return enStyle;
  }

  List<InlineSpan> buildArabicSpans(List<ExportAyahBlock> ayahs) {
    final spans = <InlineSpan>[];
    for (final ayah in ayahs) {
      spans.add(TextSpan(text: ayah.arabicText, style: arabicStyle));
      spans.add(
        TextSpan(
          text: ApiConfig.ayahEndMarker(ayah.numberInSurah),
          style: markerStyle,
        ),
      );
    }
    return spans;
  }

  double measureBannerHeight(SurahSummary summary) {
    final arPainter = TextPainter(
      text: TextSpan(text: summary.nameArabic, style: bannerArStyle),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: innerWidth * 0.48);
    final arH = arPainter.height;
    arPainter.dispose();

    final enPainter = TextPainter(
      text: TextSpan(
        text: '${summary.number}. ${summary.englishName}',
        style: bannerEnStyle,
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: innerWidth);
    final enH = enPainter.height;
    enPainter.dispose();

    // Vertical padding 7*2 (14) + border 1*2 (2)
    return (arH > enH ? arH : enH) + 16.0;
  }

  double measureBismillahHeight() {
    final tp = TextPainter(
      text: TextSpan(
        text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        style: bismillahStyle,
      ),
      textDirection: TextDirection.rtl,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: innerWidth);
    final h = tp.height;
    tp.dispose();
    // SizedBox(height: 8) + text height
    return 8.0 + h;
  }

  double measureArabicBlockHeight(List<ExportAyahBlock> ayahs) {
    final tp = TextPainter(
      text: TextSpan(
        style: arabicStyle,
        children: buildArabicSpans(ayahs),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      textScaler: TextScaler.noScaling,
    )..layout(minWidth: arabicMaxWidth, maxWidth: arabicMaxWidth);
    final h = tp.height;
    tp.dispose();
    // Padding vertical: 2 * 2 = 4
    return h + 4.0;
  }

  double measureAyahTranslationHeight(
    ExportAyahBlock block,
    List<String> translationCodes,
  ) {
    if (block.translations.isEmpty) return 0.0;
    double total = 0.0;
    for (final code in translationCodes) {
      final text = block.translations[code];
      if (text == null || text.isEmpty) continue;
      final style = translationStyle(code);
      final isAr = code == 'ar';
      final tp = TextPainter(
        text: TextSpan(
          style: style,
          children: [
            TextSpan(
              text: '${block.numberInSurah}. ',
              style: style.copyWith(
                fontWeight: FontWeight.w700,
                color: emerald,
              ),
            ),
            TextSpan(text: text, style: style),
          ],
        ),
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: innerWidth, maxWidth: innerWidth);
      total += tp.height + 2.0; // Padding(bottom: 2)
      tp.dispose();
    }
    if (total <= 0.0) return 0.0;
    return total + 4.0; // Outer Padding(bottom: 4)
  }
}

class ExportService {
  static const double mobileWidth = ExportLayoutSpec.mobileWidth;

  static Future<List<ExportPageData>> paginateSurah({
    required SurahDetail detail,
    required int fromAyah,
    required int toAyah,
    required bool includeTranslation,
    required List<String> translationCodes,
    required String headerTitle,
    required String headerSubtitle,
  }) async {
    final blocks = <ExportAyahBlock>[];
    for (int i = 0; i < detail.ayahs.length; i++) {
      final ayah = detail.ayahs[i];
      if (ayah.numberInSurah < fromAyah || ayah.numberInSurah > toAyah) {
        continue;
      }
      final trans = <String, String>{};
      if (includeTranslation) {
        for (final code in translationCodes) {
          final text = detail.translationAt(code, i).trim();
          if (text.isNotEmpty) {
            trans[code] = text;
          }
        }
      }
      blocks.add(
        ExportAyahBlock(
          numberInSurah: ayah.numberInSurah,
          arabicText: ayah.arabicText,
          translations: trans,
        ),
      );
    }

    if (blocks.isEmpty) return const [];

    return _paginateSectionUnits(
      units: [
        _SurahUnit(
          summary: detail.summary,
          blocks: blocks,
        ),
      ],
      includeTranslation: includeTranslation,
      translationCodes: translationCodes,
      headerTitle: headerTitle,
      headerSubtitle: headerSubtitle,
    );
  }

  static Future<List<ExportPageData>> paginateJuz({
    required JuzDetail detail,
    required bool includeTranslation,
    required List<String> translationCodes,
    required String headerTitle,
    required String headerSubtitle,
  }) async {
    if (detail.entries.isEmpty) return const [];

    final units = <_SurahUnit>[];
    SurahSummary? currentSurah;
    List<ExportAyahBlock> currentBlocks = [];

    for (int i = 0; i < detail.entries.length; i++) {
      final entry = detail.entries[i];
      if (currentSurah != null && currentSurah.number != entry.surah.number) {
        units.add(_SurahUnit(summary: currentSurah, blocks: currentBlocks));
        currentBlocks = [];
      }
      currentSurah = entry.surah;

      final trans = <String, String>{};
      if (includeTranslation) {
        for (final code in translationCodes) {
          final text = detail.translationAt(code, i).trim();
          if (text.isNotEmpty) {
            trans[code] = text;
          }
        }
      }

      currentBlocks.add(
        ExportAyahBlock(
          numberInSurah: entry.ayah.numberInSurah,
          arabicText: entry.ayah.arabicText,
          translations: trans,
        ),
      );
    }

    if (currentSurah != null && currentBlocks.isNotEmpty) {
      units.add(_SurahUnit(summary: currentSurah, blocks: currentBlocks));
    }

    return _paginateSectionUnits(
      units: units,
      includeTranslation: includeTranslation,
      translationCodes: translationCodes,
      headerTitle: headerTitle,
      headerSubtitle: headerSubtitle,
    );
  }

  static Future<List<ExportPageData>> _paginateSectionUnits({
    required List<_SurahUnit> units,
    required bool includeTranslation,
    required List<String> translationCodes,
    required String headerTitle,
    required String headerSubtitle,
  }) async {
    final spec = ExportLayoutSpec.mobile();
    await GoogleFonts.pendingFonts();

    final double bismillahHeight = spec.measureBismillahHeight();
    // SizedBox(height: 8) + Container(padding: top 7, top border 0.8) = 15.8 -> 16.0
    const double translationHeaderChrome = 16.0;
    const double gapBeforeArabic = 8.0;

    final rawPages = <List<ExportSurahSection>>[];
    List<ExportSurahSection> currentPageSections = [];
    double currentHeight = 0.0;

    for (final unit in units) {
      final double bannerHeight = spec.measureBannerHeight(unit.summary);
      final transPrefix = List<double>.filled(unit.blocks.length + 1, 0.0);
      final hasTransPrefix = List<int>.filled(unit.blocks.length + 1, 0);
      if (includeTranslation) {
        for (int i = 0; i < unit.blocks.length; i++) {
          final h = spec.measureAyahTranslationHeight(
            unit.blocks[i],
            translationCodes,
          );
          transPrefix[i + 1] = transPrefix[i] + h;
          hasTransPrefix[i + 1] = hasTransPrefix[i] + (h > 0.0 ? 1 : 0);
        }
      }

      bool isFirstSliceOfUnit = true;
      int idx = 0;

      while (idx < unit.blocks.length) {
        final firstAyahNo = unit.blocks[idx].numberInSurah;
        final bool showBanner = isFirstSliceOfUnit;
        final bool showBismillah = isFirstSliceOfUnit &&
            firstAyahNo == 1 &&
            unit.summary.number != 1 &&
            unit.summary.number != 9;

        final double sectionChromeHeight = (showBanner ? bannerHeight : 0.0) +
            (showBismillah ? bismillahHeight : 0.0) +
            ((showBanner || showBismillah) ? gapBeforeArabic : 0.0);

        double measureSliceHeight(int start, int endExclusive) {
          final slice = unit.blocks.sublist(start, endExclusive);
          double total = sectionChromeHeight + spec.measureArabicBlockHeight(slice);
          if (includeTranslation &&
              (hasTransPrefix[endExclusive] - hasTransPrefix[start]) > 0) {
            total += translationHeaderChrome +
                (transPrefix[endExclusive] - transPrefix[start]);
          }
          return total;
        }

        final double interSectionGap =
            currentPageSections.isNotEmpty ? spec.sectionGap : 0.0;
        final double minOneAyahHeight = measureSliceHeight(idx, idx + 1);

        if (currentPageSections.isNotEmpty &&
            currentHeight + interSectionGap + minOneAyahHeight >
                spec.maxBodyHeight) {
          rawPages.add(currentPageSections);
          currentPageSections = [];
          currentHeight = 0.0;
        }

        final double effectiveGap =
            currentPageSections.isNotEmpty ? spec.sectionGap : 0.0;
        final double remainingBudget =
            spec.maxBodyHeight - currentHeight - effectiveGap;

        int chosenEnd;
        final double fullRemainingHeight =
            measureSliceHeight(idx, unit.blocks.length);

        if (fullRemainingHeight <= remainingBudget) {
          chosenEnd = unit.blocks.length;
        } else if (minOneAyahHeight >= remainingBudget) {
          chosenEnd = idx + 1;
        } else {
          int lo = idx + 1;
          int hi = unit.blocks.length;
          while (lo < hi) {
            final mid = (lo + hi + 1) >> 1;
            if (measureSliceHeight(idx, mid) <= remainingBudget) {
              lo = mid;
            } else {
              hi = mid - 1;
            }
          }
          chosenEnd = lo;
        }

        final double sliceHeight = measureSliceHeight(idx, chosenEnd);
        currentHeight += effectiveGap + sliceHeight;

        currentPageSections.add(
          ExportSurahSection(
            summary: unit.summary,
            showBanner: showBanner,
            showBismillah: showBismillah,
            ayahs: unit.blocks.sublist(idx, chosenEnd),
          ),
        );

        idx = chosenEnd;
        isFirstSliceOfUnit = false;

        if (idx < unit.blocks.length) {
          rawPages.add(currentPageSections);
          currentPageSections = [];
          currentHeight = 0.0;
        }
      }
    }

    if (currentPageSections.isNotEmpty) {
      rawPages.add(currentPageSections);
    }

    final total = rawPages.length;
    return List<ExportPageData>.generate(total, (i) {
      return ExportPageData(
        pageIndex: i,
        totalPages: total,
        headerTitle: headerTitle,
        headerSubtitle: headerSubtitle,
        sections: rawPages[i],
      );
    });
  }

  /// Renders a single export page directly via an isolated offscreen PictureRecorder
  /// at Ultra-HD resolution (5.0x -> 1800px wide for PNG, up to 5.5x -> ~1980px / 360+ DPI for PDF),
  /// completely immune to GPU widget layer glitches and messaging app blur.
  static Future<RenderedExportPage> renderPagePng({
    required ExportPageData page,
    required bool includeTranslation,
    required List<String> translationCodes,
    double targetPixelRatio = 5.0,
  }) async {
    final spec = ExportLayoutSpec.mobile();
    await GoogleFonts.pendingFonts();

    double totalBodyHeight = 0.0;
    for (int sIdx = 0; sIdx < page.sections.length; sIdx++) {
      if (sIdx > 0) totalBodyHeight += spec.sectionGap;
      final section = page.sections[sIdx];
      if (section.showBanner) {
        totalBodyHeight += spec.measureBannerHeight(section.summary);
      }
      if (section.showBismillah) {
        totalBodyHeight += spec.measureBismillahHeight();
      }
      if (section.showBanner || section.showBismillah) {
        totalBodyHeight += 8.0;
      }
      totalBodyHeight += spec.measureArabicBlockHeight(section.ayahs);
      final hasTrans = includeTranslation &&
          section.ayahs.any((a) => a.translations.isNotEmpty);
      if (hasTrans) {
        totalBodyHeight += 15.0;
        for (final ayah in section.ayahs) {
          totalBodyHeight +=
              spec.measureAyahTranslationHeight(ayah, translationCodes);
        }
      }
    }

    final double totalLogicalHeight =
        (spec.vPad * 2 + totalBodyHeight).ceilToDouble();

    // 4096px stays safely inside Android/Web GPU texture limits while keeping
    // normal pages (~740pt tall) at full 5.0x-5.4x (1800px-1944px wide, 360+ DPI).
    double pixelRatio = targetPixelRatio.clamp(3.0, 5.5);
    if (totalLogicalHeight * pixelRatio > 4096.0 && totalLogicalHeight > 0) {
      pixelRatio = (4096.0 / totalLogicalHeight).clamp(2.5, targetPixelRatio);
    }

    final int pxW = (spec.cardWidth * pixelRatio).round();
    final int pxH = (totalLogicalHeight * pixelRatio).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    // Solid opaque white background so shared/exported photos have zero transparency issues
    canvas.drawRect(
      Rect.fromLTWH(0, 0, spec.cardWidth, totalLogicalHeight),
      Paint()..color = ExportLayoutSpec.paperBg,
    );

    double y = spec.vPad;

    for (int sIdx = 0; sIdx < page.sections.length; sIdx++) {
      if (sIdx > 0) y += spec.sectionGap;
      final section = page.sections[sIdx];
      final surah = section.summary;

      if (section.showBanner) {
        final bannerH = spec.measureBannerHeight(surah);
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(spec.hPad, y, spec.innerWidth, bannerH),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          rrect,
          Paint()..color = ExportLayoutSpec.emeraldTint,
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = ExportLayoutSpec.emeraldBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );

        final arTp = TextPainter(
          text: TextSpan(text: surah.nameArabic, style: spec.bannerArStyle),
          textDirection: TextDirection.rtl,
          textScaler: TextScaler.noScaling,
          maxLines: 1,
        )..layout(maxWidth: spec.innerWidth * 0.48);

        final double enMaxW =
            (spec.innerWidth - 28.0 - arTp.width - 8.0).clamp(40.0, spec.innerWidth);
        final enTp = TextPainter(
          text: TextSpan(
            text: '${surah.number}. ${surah.englishName}',
            style: spec.bannerEnStyle,
          ),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
          maxLines: 1,
          ellipsis: '...',
        )..layout(maxWidth: enMaxW);

        enTp.paint(
          canvas,
          Offset(spec.hPad + 14.0, y + (bannerH - enTp.height) / 2),
        );
        arTp.paint(
          canvas,
          Offset(
            spec.cardWidth - spec.hPad - 14.0 - arTp.width,
            y + (bannerH - arTp.height) / 2,
          ),
        );
        enTp.dispose();
        arTp.dispose();
        y += bannerH;
      }

      if (section.showBismillah) {
        y += 8.0;
        final bisTp = TextPainter(
          text: TextSpan(
            text: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
            style: spec.bismillahStyle,
          ),
          textDirection: TextDirection.rtl,
          textScaler: TextScaler.noScaling,
        )..layout(maxWidth: spec.innerWidth);
        bisTp.paint(canvas, Offset((spec.cardWidth - bisTp.width) / 2, y));
        y += bisTp.height;
        bisTp.dispose();
      }

      if (section.showBanner || section.showBismillah) {
        y += 8.0;
      }

      final arTp = TextPainter(
        text: TextSpan(
          style: spec.arabicStyle,
          children: spec.buildArabicSpans(section.ayahs),
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: spec.arabicMaxWidth, maxWidth: spec.arabicMaxWidth);
      arTp.paint(canvas, Offset(spec.hPad + 4.0, y + 2.0));
      y += arTp.height + 4.0;
      arTp.dispose();

      final hasTrans = includeTranslation &&
          section.ayahs.any((a) => a.translations.isNotEmpty);
      if (hasTrans) {
        y += 8.0;
        canvas.drawLine(
          Offset(spec.hPad, y + 0.4),
          Offset(spec.cardWidth - spec.hPad, y + 0.4),
          Paint()
            ..color = ExportLayoutSpec.divider
            ..strokeWidth = 0.8,
        );
        y += 7.0;

        for (final ayah in section.ayahs) {
          if (ayah.translations.isEmpty) continue;
          bool paintedAny = false;
          for (final code in translationCodes) {
            final text = ayah.translations[code];
            if (text == null || text.isEmpty) continue;
            paintedAny = true;
            final style = spec.translationStyle(code);
            final bool isAr = code == 'ar';
            final trTp = TextPainter(
              text: TextSpan(
                style: style,
                children: [
                  TextSpan(
                    text: '${ayah.numberInSurah}. ',
                    style: style.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ExportLayoutSpec.emerald,
                    ),
                  ),
                  TextSpan(text: text, style: style),
                ],
              ),
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              textScaler: TextScaler.noScaling,
            )..layout(minWidth: spec.innerWidth, maxWidth: spec.innerWidth);
            trTp.paint(canvas, Offset(spec.hPad, y));
            y += trTp.height + 2.0;
            trTp.dispose();
          }
          if (paintedAny) {
            y += 4.0;
          }
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(pxW, pxH);
    picture.dispose();
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode PNG bytes');
      }
      return RenderedExportPage(
        bytes: byteData.buffer.asUint8List(),
        logicalSize: Size(spec.cardWidth, totalLogicalHeight),
      );
    } finally {
      image.dispose();
    }
  }

  static Future<Uint8List> buildPdfBytes({
    required List<Uint8List> pagePngs,
    required List<Size> pageLogicalSizes,
  }) async {
    final doc = pw.Document(
      title: 'Ibadia Export',
      creator: 'Ibadia App',
    );

    for (int i = 0; i < pagePngs.length; i++) {
      final png = pagePngs[i];
      final memImg = pw.MemoryImage(png);
      final sz = i < pageLogicalSizes.length
          ? pageLogicalSizes[i]
          : const Size(mobileWidth, 620);
      final format = PdfPageFormat(
        sz.width * PdfPageFormat.point,
        sz.height * PdfPageFormat.point,
        marginAll: 0,
      );

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Container(
            width: format.width,
            height: format.height,
            color: PdfColors.white,
            alignment: pw.Alignment.center,
            child: pw.Image(
              memImg,
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return doc.save();
  }

  /// Saves PDF directly via browser download on Web or native Save As (Downloads) on Android.
  static Future<bool> savePdfBytes({
    required Uint8List bytes,
    required String baseName,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: cleanBase,
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
      return true;
    }

    final savedPath = await FileSaver.instance.saveAs(
      name: cleanBase,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
    return savedPath != null && savedPath.isNotEmpty;
  }

  /// Saves every PNG page directly into Android Gallery ('Ibadia' album) via MediaStore,
  /// or triggers browser downloads on Web.
  static Future<bool> savePngPages({
    required List<Uint8List> pages,
    required String baseName,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    if (!kIsWeb) {
      for (int i = 0; i < pages.length; i++) {
        final suffix = pages.length > 1 ? '_page_${i + 1}' : '';
        await Gal.putImageBytes(
          pages[i],
          album: 'Ibadia',
          name: '$cleanBase$suffix',
        );
      }
      return true;
    }

    for (int i = 0; i < pages.length; i++) {
      final suffix = pages.length > 1 ? '_page_${i + 1}' : '';
      await FileSaver.instance.saveFile(
        name: '$cleanBase$suffix',
        bytes: pages[i],
        ext: 'png',
        mimeType: MimeType.png,
      );
      if (i < pages.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 380));
      }
    }
    return false;
  }

  /// Shares PDF via native share sheet with explicit .pdf filename override.
  static Future<bool> sharePdfBytes({
    required Uint8List bytes,
    required String baseName,
    required String title,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    final fileName = '$cleanBase.pdf';
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: 'application/pdf',
          ),
        ],
        fileNameOverrides: [fileName],
        subject: title,
      );
      return true;
    } catch (_) {
      await savePdfBytes(bytes: bytes, baseName: cleanBase);
      return false;
    }
  }

  /// Shares all paginated PNG images cleanly as pure photo attachments with explicit
  /// .png fileNameOverrides (no conflicting text/subject extras) so WhatsApp opens them directly.
  static Future<bool> sharePngPages({
    required List<Uint8List> pages,
    required String baseName,
    required String title,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    final fileNames = List<String>.generate(pages.length, (i) {
      final suffix = pages.length > 1 ? '_page_${i + 1}' : '';
      return '$cleanBase$suffix.png';
    });
    final files = List<XFile>.generate(pages.length, (i) {
      return XFile.fromData(
        pages[i],
        name: fileNames[i],
        mimeType: 'image/png',
      );
    });
    try {
      await Share.shareXFiles(
        files,
        fileNameOverrides: fileNames,
      );
      return true;
    } catch (_) {
      await savePngPages(pages: pages, baseName: cleanBase);
      return false;
    }
  }

  static String _sanitizeName(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'quran_export' : cleaned;
  }
}

class _SurahUnit {
  final SurahSummary summary;
  final List<ExportAyahBlock> blocks;

  const _SurahUnit({
    required this.summary,
    required this.blocks,
  });
}
