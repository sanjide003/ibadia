import 'dart:typed_data';
import 'dart:ui';

import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/surah_model.dart';

class ExportService {
  /// Logical widths for page layouts.
  /// Automatic uses a mobile-friendly 360px logical width with normal text sizes.
  /// A4 uses standard 595x842 point proportions.
  static const double automaticWidth = 360.0;
  static const double a4Width = 595.0;
  static const double a4Height = 842.0;

  static List<ExportPageData> paginateSurah({
    required SurahDetail detail,
    required int fromAyah,
    required int toAyah,
    required ExportPageSize pageSize,
    required bool includeTranslation,
    required List<String> translationCodes,
    required String headerTitle,
    required String headerSubtitle,
  }) {
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
      headerTitle: headerTitle,
      headerSubtitle: headerSubtitle,
    );
  }

  static List<ExportPageData> paginateJuz({
    required JuzDetail detail,
    required ExportPageSize pageSize,
    required bool includeTranslation,
    required List<String> translationCodes,
    required String headerTitle,
    required String headerSubtitle,
  }) {
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
      headerTitle: headerTitle,
      headerSubtitle: headerSubtitle,
    );
  }

  static List<ExportPageData> _paginateSectionUnits({
    required List<_SurahUnit> units,
    required ExportPageSize pageSize,
    required bool includeTranslation,
    required String headerTitle,
    required String headerSubtitle,
  }) {
    // Budget in approximate vertical points of body content inside the card.
    final bool isA4 = pageSize == ExportPageSize.a4;
    final double maxBodyWeight = isA4 ? 575.0 : 490.0;
    final double headerBannerWeight = isA4 ? 54.0 : 58.0;
    final double bismillahWeight = isA4 ? 38.0 : 40.0;
    final double arabicCharsPerLine = isA4 ? 56.0 : 30.0;
    final double arabicLineHeight = isA4 ? 34.0 : 39.0;
    final double transCharsPerLine = isA4 ? 76.0 : 40.0;
    final double transLineHeight = isA4 ? 17.5 : 21.0;

    final rawPages = <List<ExportSurahSection>>[];
    List<ExportSurahSection> currentPageSections = [];
    double currentWeight = 0.0;

    for (final unit in units) {
      bool isFirstSliceOfUnit = true;
      int idx = 0;

      while (idx < unit.blocks.length) {
        final firstAyahNo = unit.blocks[idx].numberInSurah;
        final bool showBismillah = isFirstSliceOfUnit &&
            firstAyahNo == 1 &&
            unit.summary.number != 1 &&
            unit.summary.number != 9;

        final double sectionHeaderCost =
            headerBannerWeight + (showBismillah ? bismillahWeight : 0.0);

        // If the section header + first ayah won't fit on the current page, flush page first.
        final double firstAyahWeight = _estimateAyahWeight(
          block: unit.blocks[idx],
          includeTranslation: includeTranslation,
          arabicCharsPerLine: arabicCharsPerLine,
          arabicLineHeight: arabicLineHeight,
          transCharsPerLine: transCharsPerLine,
          transLineHeight: transLineHeight,
        );

        if (currentPageSections.isNotEmpty &&
            currentWeight + sectionHeaderCost + firstAyahWeight >
                maxBodyWeight) {
          rawPages.add(currentPageSections);
          currentPageSections = [];
          currentWeight = 0.0;
        }

        final sliceBlocks = <ExportAyahBlock>[];
        currentWeight += sectionHeaderCost;

        while (idx < unit.blocks.length) {
          final block = unit.blocks[idx];
          final w = _estimateAyahWeight(
            block: block,
            includeTranslation: includeTranslation,
            arabicCharsPerLine: arabicCharsPerLine,
            arabicLineHeight: arabicLineHeight,
            transCharsPerLine: transCharsPerLine,
            transLineHeight: transLineHeight,
          );

          if (sliceBlocks.isNotEmpty && currentWeight + w > maxBodyWeight) {
            break;
          }

          sliceBlocks.add(block);
          currentWeight += w;
          idx++;
        }

        currentPageSections.add(
          ExportSurahSection(
            summary: unit.summary,
            showBismillah: showBismillah,
            ayahs: sliceBlocks,
          ),
        );
        isFirstSliceOfUnit = false;

        if (idx < unit.blocks.length) {
          rawPages.add(currentPageSections);
          currentPageSections = [];
          currentWeight = 0.0;
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

  static double _estimateAyahWeight({
    required ExportAyahBlock block,
    required bool includeTranslation,
    required double arabicCharsPerLine,
    required double arabicLineHeight,
    required double transCharsPerLine,
    required double transLineHeight,
  }) {
    // Include ayah number ornament length (+7 chars)
    final arLines = ((block.arabicText.length + 7) / arabicCharsPerLine)
        .ceil()
        .clamp(1, 100);
    double weight = arLines * arabicLineHeight + 10.0;

    if (includeTranslation && block.translations.isNotEmpty) {
      weight += 8.0;
      for (final text in block.translations.values) {
        final trLines = ((text.length + 6) / transCharsPerLine)
            .ceil()
            .clamp(1, 200);
        weight += trLines * transLineHeight + 6.0;
      }
    }
    return weight;
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

  static Future<void> savePdfBytes({
    required Uint8List bytes,
    required String baseName,
  }) async {
    await FileSaver.instance.saveFile(
      name: _sanitizeName(baseName),
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  static Future<void> savePngPages({
    required List<Uint8List> pages,
    required String baseName,
  }) async {
    final cleanBase = _sanitizeName(baseName);
    for (int i = 0; i < pages.length; i++) {
      final suffix = pages.length > 1 ? '_page_${i + 1}' : '';
      await FileSaver.instance.saveFile(
        name: '$cleanBase$suffix',
        bytes: pages[i],
        ext: 'png',
        mimeType: MimeType.png,
      );
      if (i < pages.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    }
  }

  /// Shares PDF via native share sheet; falls back to download if unsupported (e.g. desktop/iframe web).
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

  /// Shares paginated PNG images via native share sheet; falls back to download if unsupported.
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
