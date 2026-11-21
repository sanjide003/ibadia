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

/// Shared exact typography & spacing specification used identically by both
/// [ExportService] TextPainter pagination and [_ExportPageCard] rendering.
class ExportLayoutSpec {
  static const double automaticWidth = 360.0;
  static const double a4Width = 595.0;
  static const double a4Height = 842.0;

  static const Color paperBg = Color(0xFFFFFFFF);
  static const Color inkPrimary = Color(0xFF181C1A);
  static const Color emerald = Color(0xFF047857);
  static const Color emeraldTint = Color(0xFFECFDF5);
  static const Color emeraldBorder = Color(0xFFA7F3D0);
  static const Color divider = Color(0xFFE2E8F0);

  final ExportPageSize pageSize;
  final bool isA4;
  final double cardWidth;
  final double? cardHeight;
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
    required this.pageSize,
    required this.isA4,
    required this.cardWidth,
    required this.cardHeight,
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

  factory ExportLayoutSpec.forPageSize(ExportPageSize pageSize) {
    final bool isA4 = pageSize == ExportPageSize.a4;
    final double cardWidth = isA4 ? a4Width : automaticWidth;
    final double? cardHeight = isA4 ? a4Height : null;
    final double hPad = isA4 ? 26.0 : 20.0;
    final double vPad = isA4 ? 22.0 : 20.0;
    final double innerWidth = cardWidth - hPad * 2;
    // Arabic wrapper uses Padding(horizontal: 4, vertical: 2).
    final double arabicMaxWidth = innerWidth - 8.0;
    // A4 fills ~784pt out of 798pt usable vertical height cleanly with headroom so pages never shrink or clip.
    final double maxBodyHeight = isA4 ? (a4Height - vPad * 2 - 14.0) : 1350.0;

    final double arabicFontSize = isA4 ? 19.5 : 21.5;
    final double arabicLineHeight = isA4 ? 1.80 : 1.92;

    return ExportLayoutSpec._(
      pageSize: pageSize,
      isA4: isA4,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
      hPad: hPad,
      vPad: vPad,
      innerWidth: innerWidth,
      arabicMaxWidth: arabicMaxWidth,
      maxBodyHeight: maxBodyHeight,
      sectionGap: isA4 ? 12.0 : 14.0,
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
        fontSize: isA4 ? 19.5 : 20.5,
        height: 1.55,
        fontWeight: FontWeight.w700,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      bannerEnStyle: TextStyle(
        color: emerald,
        fontSize: isA4 ? 12.5 : 13.0,
        height: 1.3,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
      bannerArStyle: GoogleFonts.amiri(
        color: emerald,
        fontSize: isA4 ? 17.5 : 18.5,
        height: 1.35,
        fontWeight: FontWeight.w700,
        decoration: TextDecoration.none,
      ),
      mlStyle: GoogleFonts.notoSansMalayalam(
        fontSize: isA4 ? 11.2 : 13.0,
        height: isA4 ? 1.48 : 1.52,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      enStyle: GoogleFonts.plusJakartaSans(
        fontSize: isA4 ? 10.8 : 12.5,
        height: isA4 ? 1.42 : 1.45,
        color: inkPrimary,
        decoration: TextDecoration.none,
      ),
      arTafsirStyle: GoogleFonts.notoSansArabic(
        fontSize: isA4 ? 12.2 : 14.0,
        height: isA4 ? 1.52 : 1.58,
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
    )..layout(maxWidth: innerWidth);
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
    )..layout(maxWidth: arabicMaxWidth);
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
      )..layout(maxWidth: innerWidth);
      total += tp.height + 2.0; // Padding(bottom: 2)
      tp.dispose();
    }
    if (total <= 0.0) return 0.0;
    return total + 4.0; // Outer Padding(bottom: 4)
  }
}

class ExportService {
  static const double automaticWidth = ExportLayoutSpec.automaticWidth;
  static const double a4Width = ExportLayoutSpec.a4Width;
  static const double a4Height = ExportLayoutSpec.a4Height;

  static Future<List<ExportPageData>> paginateSurah({
    required SurahDetail detail,
    required int fromAyah,
    required int toAyah,
    required ExportPageSize pageSize,
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
      pageSize: pageSize,
      includeTranslation: includeTranslation,
      translationCodes: translationCodes,
      headerTitle: headerTitle,
      headerSubtitle: headerSubtitle,
    );
  }

  static Future<List<ExportPageData>> paginateJuz({
    required JuzDetail detail,
    required ExportPageSize pageSize,
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
      pageSize: pageSize,
      includeTranslation: includeTranslation,
      translationCodes: translationCodes,
      headerTitle: headerTitle,
      headerSubtitle: headerSubtitle,
    );
  }

  static Future<List<ExportPageData>> _paginateSectionUnits({
    required List<_SurahUnit> units,
    required ExportPageSize pageSize,
    required bool includeTranslation,
    required List<String> translationCodes,
    required String headerTitle,
    required String headerSubtitle,
  }) async {
    // Instantiate GoogleFonts styles and await completion so TextPainter measures exact glyph metrics.
    final spec = ExportLayoutSpec.forPageSize(pageSize);
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
      // Pre-compute prefix sums for each ayah's translation height so slice translation height is O(1).
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

  static Future<Uint8List> buildPdfBytes({
    required List<Uint8List> pagePngs,
    required ExportPageSize pageSize,
    required List<Size> pageLogicalSizes,
  }) async {
    final doc = pw.Document(
      title: 'Al-Quran Export',
      creator: 'Al-Quran App',
    );

    for (int i = 0; i < pagePngs.length; i++) {
      final png = pagePngs[i];
      final memImg = pw.MemoryImage(png);
      final PdfPageFormat format;
      if (pageSize == ExportPageSize.a4) {
        format = PdfPageFormat.a4;
      } else {
        final sz = i < pageLogicalSizes.length
            ? pageLogicalSizes[i]
            : const Size(automaticWidth, 620);
        format = PdfPageFormat(
          sz.width * PdfPageFormat.point,
          sz.height * PdfPageFormat.point,
          marginAll: 0,
        );
      }

      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Container(
            width: format.width,
            height: format.height,
            color: PdfColors.white,
            alignment: pw.Alignment.center,
            child: pw.Image(memImg, fit: pw.BoxFit.contain),
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

  /// Saves every PNG page directly into Android Gallery ('Al-Quran' album) via MediaStore,
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
          album: 'Al-Quran',
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

  /// Shares PDF via native share sheet; falls back to download if unsupported (e.g. iframe/desktop web).
  static Future<bool> sharePdfBytes({
    required Uint8List bytes,
    required String baseName,
    required String title,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: '$cleanBase.pdf',
            mimeType: 'application/pdf',
          ),
        ],
        subject: title,
        text: title,
      );
      return true;
    } catch (_) {
      await savePdfBytes(bytes: bytes, baseName: cleanBase);
      return false;
    }
  }

  /// Shares all paginated PNG images via native share sheet; falls back to download if unsupported.
  static Future<bool> sharePngPages({
    required List<Uint8List> pages,
    required String baseName,
    required String title,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    final files = List<XFile>.generate(pages.length, (i) {
      final suffix = pages.length > 1 ? '_page_${i + 1}' : '';
      return XFile.fromData(
        pages[i],
        name: '$cleanBase$suffix.png',
        mimeType: 'image/png',
      );
    });
    try {
      await Share.shareXFiles(
        files,
        subject: title,
        text: title,
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
