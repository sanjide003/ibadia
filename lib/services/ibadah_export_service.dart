import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'export_service.dart';

class IbadahExportItem {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final String? orderBadge;
  final String? arabicText;
  final String? transliterationMl;
  final String? meaningText;
  final String? noteText;
  final String? footerSource;

  const IbadahExportItem({
    required this.title,
    this.subtitle,
    this.badgeText,
    this.orderBadge,
    this.arabicText,
    this.transliterationMl,
    this.meaningText,
    this.noteText,
    this.footerSource,
  });
}

/// Renders crisp Ultra-HD PNG images (2160px wide) and high-DPI print-grade PDFs
/// for individual Ibadah cards or complete Ibadah study guides.
class IbadahExportService {
  IbadahExportService._();

  static const double _logicalCardWidth = 540.0;
  static const double _targetPixelRatio = 4.0; // 540 * 4.0 = 2160px Ultra-HD
  static const double _maxTextureDimension = 4096.0;

  static const Color _paperBg = Color(0xFFFFFFFF);
  static const Color _emerald = Color(0xFF047857);
  static const Color _emeraldDark = Color(0xFF065F46);
  static const Color _emeraldTint = Color(0xFFECFDF5);
  static const Color _emeraldBorder = Color(0xFFA7F3D0);
  static const Color _arabicPanelBg = Color(0xFFF6EFE0);
  static const Color _arabicPanelBorder = Color(0xFFE7DEC9);
  static const Color _noteBg = Color(0xFFF3F6F4);
  static const Color _inkPrimary = Color(0xFF181C1A);
  static const Color _inkMuted = Color(0xFF475569);

  static Future<RenderedExportPage> renderCardPng(
    IbadahExportItem item, {
    required bool includeTransliteration,
    required bool includeMeaning,
    required bool includeNotes,
  }) async {
    // Ensure required Google Font styles are initialized & ready before offscreen painting.
    final titleStyle = GoogleFonts.notoSansMalayalam(
      fontSize: 18.0,
      fontWeight: FontWeight.w800,
      height: 1.32,
      color: _inkPrimary,
      decoration: TextDecoration.none,
    );
    final subtitleStyle = GoogleFonts.notoSansMalayalam(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: _inkMuted,
      decoration: TextDecoration.none,
    );
    final badgeStyle = GoogleFonts.plusJakartaSans(
      fontSize: 11.5,
      fontWeight: FontWeight.w800,
      color: _emeraldDark,
      decoration: TextDecoration.none,
    );
    final arabicStyle = GoogleFonts.amiri(
      fontSize: 27.0,
      fontWeight: FontWeight.w700,
      height: 1.92,
      color: _inkPrimary,
      decoration: TextDecoration.none,
    );
    final sectionLabelStyle = GoogleFonts.plusJakartaSans(
      fontSize: 11.0,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: _emerald,
      decoration: TextDecoration.none,
    );
    final translitStyle = GoogleFonts.notoSansMalayalam(
      fontSize: 15.0,
      fontWeight: FontWeight.w600,
      height: 1.58,
      color: _inkPrimary,
      decoration: TextDecoration.none,
    );
    final meaningStyle = GoogleFonts.notoSansMalayalam(
      fontSize: 14.5,
      fontWeight: FontWeight.w500,
      height: 1.55,
      color: _inkMuted,
      decoration: TextDecoration.none,
    );
    final noteStyle = GoogleFonts.notoSansMalayalam(
      fontSize: 13.0,
      fontWeight: FontWeight.w500,
      height: 1.48,
      color: _inkMuted,
      decoration: TextDecoration.none,
    );
    final footerStyle = GoogleFonts.plusJakartaSans(
      fontSize: 11.0,
      fontWeight: FontWeight.w700,
      color: _emerald,
      decoration: TextDecoration.none,
    );

    await GoogleFonts.pendingFonts();

    const double outerPad = 24.0;
    const double cardRadius = 18.0;
    const double innerPad = 22.0;
    const double contentWidth = _logicalCardWidth - (outerPad * 2) - (innerPad * 2);

    // Measure header
    final bool hasOrder =
        item.orderBadge != null && item.orderBadge!.trim().isNotEmpty;
    final bool hasBadge =
        item.badgeText != null && item.badgeText!.trim().isNotEmpty;
    double badgeBoxW = 0;
    TextPainter? badgeTp;
    if (hasBadge) {
      badgeTp = TextPainter(
        text: TextSpan(text: item.badgeText!.trim(), style: badgeStyle),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        maxLines: 1,
      )..layout(maxWidth: 140);
      badgeBoxW = badgeTp.width + 20.0;
    }

    final double orderGap = hasOrder ? 44.0 : 0.0;
    final double badgeGap = hasBadge ? (badgeBoxW + 10.0) : 0.0;
    final double titleMaxW =
        (contentWidth - orderGap - badgeGap).clamp(120.0, contentWidth);

    final titleTp = TextPainter(
      text: TextSpan(text: item.title, style: titleStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: titleMaxW);

    TextPainter? subtitleTp;
    if (item.subtitle != null && item.subtitle!.trim().isNotEmpty) {
      subtitleTp = TextPainter(
        text: TextSpan(text: item.subtitle!.trim(), style: subtitleStyle),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: titleMaxW);
    }

    final double headerTextH = titleTp.height +
        (subtitleTp != null ? (4.0 + subtitleTp.height) : 0.0);
    final double headerH = headerTextH < 34.0 ? 34.0 : headerTextH;

    // Measure Arabic
    TextPainter? arabicTp;
    final bool hasArabic =
        item.arabicText != null && item.arabicText!.trim().isNotEmpty;
    double arabicBoxH = 0;
    if (hasArabic) {
      arabicTp = TextPainter(
        text: TextSpan(text: item.arabicText!.trim(), style: arabicStyle),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        textScaler: TextScaler.noScaling,
      )..layout(minWidth: contentWidth - 32.0, maxWidth: contentWidth - 32.0);
      arabicBoxH = arabicTp.height + 30.0;
    }

    // Measure Transliteration
    TextPainter? translitLabelTp;
    TextPainter? translitTp;
    final bool hasTranslit = includeTransliteration &&
        item.transliterationMl != null &&
        item.transliterationMl!.trim().isNotEmpty;
    if (hasTranslit) {
      translitLabelTp = TextPainter(
        text: TextSpan(text: 'TRANSLITERATION', style: sectionLabelStyle),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: contentWidth);
      translitTp = TextPainter(
        text: TextSpan(
          text: item.transliterationMl!.trim(),
          style: translitStyle,
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: contentWidth);
    }

    // Measure Meaning
    TextPainter? meaningLabelTp;
    TextPainter? meaningTp;
    final bool hasMeaning = includeMeaning &&
        item.meaningText != null &&
        item.meaningText!.trim().isNotEmpty;
    if (hasMeaning) {
      meaningLabelTp = TextPainter(
        text: TextSpan(text: 'MEANING', style: sectionLabelStyle),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: contentWidth);
      meaningTp = TextPainter(
        text: TextSpan(text: item.meaningText!.trim(), style: meaningStyle),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: contentWidth);
    }

    // Measure Note
    TextPainter? noteTp;
    final bool hasNote = includeNotes &&
        item.noteText != null &&
        item.noteText!.trim().isNotEmpty;
    double noteBoxH = 0;
    if (hasNote) {
      noteTp = TextPainter(
        text: TextSpan(text: item.noteText!.trim(), style: noteStyle),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: contentWidth - 24.0);
      noteBoxH = noteTp.height + 18.0;
    }

    final footerLabel = (item.footerSource != null && item.footerSource!.isNotEmpty)
        ? 'Ibadia · ${item.footerSource}'
        : 'Ibadia · Shafi\'i Ibadah & Salah Guide';
    final footerTp = TextPainter(
      text: TextSpan(text: footerLabel, style: footerStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: contentWidth);

    double cardBodyH = innerPad + headerH;
    if (hasArabic) cardBodyH += 14.0 + arabicBoxH;
    if (hasTranslit) {
      cardBodyH += 14.0 + translitLabelTp!.height + 4.0 + translitTp!.height;
    }
    if (hasMeaning) {
      cardBodyH += 12.0 + meaningLabelTp!.height + 4.0 + meaningTp!.height;
    }
    if (hasNote) cardBodyH += 12.0 + noteBoxH;
    cardBodyH += 16.0 + 1.0 + 10.0 + footerTp.height + innerPad;

    final double totalLogicalHeight =
        (cardBodyH + outerPad * 2).ceilToDouble();

    double pixelRatio = _targetPixelRatio;
    if (totalLogicalHeight * pixelRatio > _maxTextureDimension &&
        totalLogicalHeight > 0) {
      pixelRatio = (_maxTextureDimension / totalLogicalHeight).clamp(1.8, _targetPixelRatio);
    }

    final int pxW = (_logicalCardWidth * pixelRatio).round();
    final int pxH = (totalLogicalHeight * pixelRatio).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio, pixelRatio);

    // Outer subtle warm paper backdrop
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _logicalCardWidth, totalLogicalHeight),
      Paint()..color = const Color(0xFFF4F7F5),
    );

    // Card surface
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        outerPad,
        outerPad,
        _logicalCardWidth - outerPad * 2,
        totalLogicalHeight - outerPad * 2,
      ),
      const Radius.circular(cardRadius),
    );
    canvas.drawRRect(cardRect, Paint()..color = _paperBg);
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = const Color(0xFFD5E4DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Top emerald accent strip clipped cleanly inside card
    canvas.save();
    canvas.clipRRect(cardRect);
    canvas.drawRect(
      Rect.fromLTWH(outerPad, outerPad, _logicalCardWidth - outerPad * 2, 5.0),
      Paint()..color = _emerald,
    );
    canvas.restore();

    const double x = outerPad + innerPad;
    double y = outerPad + innerPad + 2.0;

    // Order pill
    if (hasOrder) {
      final orderRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 34.0, 34.0),
        const Radius.circular(10),
      );
      canvas.drawRRect(
        orderRRect,
        Paint()..color = _emeraldTint,
      );
      canvas.drawRRect(
        orderRRect,
        Paint()
          ..color = _emeraldBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      final orderTp = TextPainter(
        text: TextSpan(
          text: item.orderBadge!.trim(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.0,
            fontWeight: FontWeight.w800,
            color: _emeraldDark,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      orderTp.paint(
        canvas,
        Offset(x + (34.0 - orderTp.width) / 2, y + (34.0 - orderTp.height) / 2),
      );
      orderTp.dispose();
    }

    // Title & Subtitle
    final double titleX = x + orderGap;
    titleTp.paint(canvas, Offset(titleX, y));
    if (subtitleTp != null) {
      subtitleTp.paint(canvas, Offset(titleX, y + titleTp.height + 4.0));
    }

    // Category Badge
    if (hasBadge && badgeTp != null) {
      final double bx = _logicalCardWidth - outerPad - innerPad - badgeBoxW;
      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bx, y + 2.0, badgeBoxW, badgeTp.height + 10.0),
        const Radius.circular(8),
      );
      canvas.drawRRect(badgeRRect, Paint()..color = _emeraldTint);
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..color = _emeraldBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      badgeTp.paint(canvas, Offset(bx + 10.0, y + 7.0));
      badgeTp.dispose();
    }

    titleTp.dispose();
    subtitleTp?.dispose();
    y += headerH;

    // Arabic Panel
    if (hasArabic && arabicTp != null) {
      y += 14.0;
      final arRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, contentWidth, arabicBoxH),
        const Radius.circular(14),
      );
      canvas.drawRRect(arRect, Paint()..color = _arabicPanelBg);
      canvas.drawRRect(
        arRect,
        Paint()
          ..color = _arabicPanelBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      arabicTp.paint(canvas, Offset(x + 16.0, y + 15.0));
      arabicTp.dispose();
      y += arabicBoxH;
    }

    // Transliteration
    if (hasTranslit && translitLabelTp != null && translitTp != null) {
      y += 14.0;
      translitLabelTp.paint(canvas, Offset(x, y));
      y += translitLabelTp.height + 4.0;
      translitTp.paint(canvas, Offset(x, y));
      y += translitTp.height;
      translitLabelTp.dispose();
      translitTp.dispose();
    }

    // Meaning
    if (hasMeaning && meaningLabelTp != null && meaningTp != null) {
      y += 12.0;
      meaningLabelTp.paint(canvas, Offset(x, y));
      y += meaningLabelTp.height + 4.0;
      meaningTp.paint(canvas, Offset(x, y));
      y += meaningTp.height;
      meaningLabelTp.dispose();
      meaningTp.dispose();
    }

    // Fiqh Note
    if (hasNote && noteTp != null) {
      y += 12.0;
      final noteRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, contentWidth, noteBoxH),
        const Radius.circular(10),
      );
      canvas.drawRRect(noteRect, Paint()..color = _noteBg);
      noteTp.paint(canvas, Offset(x + 12.0, y + 9.0));
      noteTp.dispose();
      y += noteBoxH;
    }

    // Footer Divider + Watermark
    y += 16.0;
    canvas.drawLine(
      Offset(x, y),
      Offset(x + contentWidth, y),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 1.0,
    );
    y += 10.0;
    footerTp.paint(canvas, Offset(x, y));
    footerTp.dispose();

    final picture = recorder.endRecording();
    final image = await picture.toImage(pxW, pxH);
    picture.dispose();
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to encode Ibadah PNG bytes');
      }
      return RenderedExportPage(
        bytes: byteData.buffer.asUint8List(),
        logicalSize: Size(_logicalCardWidth, totalLogicalHeight),
      );
    } finally {
      image.dispose();
    }
  }

  static Future<Uint8List> buildSingleCardPdf(
    IbadahExportItem item, {
    required bool includeTransliteration,
    required bool includeMeaning,
    required bool includeNotes,
  }) async {
    final rendered = await renderCardPng(
      item,
      includeTransliteration: includeTransliteration,
      includeMeaning: includeMeaning,
      includeNotes: includeNotes,
    );
    return ExportService.buildPdfBytes(
      pagePngs: [rendered.bytes],
      pageLogicalSizes: [rendered.logicalSize],
    );
  }

  static Future<Uint8List> buildMultiCardPdf(
    List<IbadahExportItem> items, {
    required String documentTitle,
    required bool includeTransliteration,
    required bool includeMeaning,
    required bool includeNotes,
  }) async {
    final doc = pw.Document(
      title: documentTitle,
      creator: 'Ibadia App',
    );
    for (final item in items) {
      final rendered = await renderCardPng(
        item,
        includeTransliteration: includeTransliteration,
        includeMeaning: includeMeaning,
        includeNotes: includeNotes,
      );
      final memImg = pw.MemoryImage(rendered.bytes);
      final format = PdfPageFormat(
        rendered.logicalSize.width * PdfPageFormat.point,
        rendered.logicalSize.height * PdfPageFormat.point,
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
            child: pw.Image(memImg, fit: pw.BoxFit.contain),
          ),
        ),
      );
    }
    return doc.save();
  }

  static String slugifyTitle(String raw) {
    final cleaned = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'ibadah_card' : cleaned;
  }
}
