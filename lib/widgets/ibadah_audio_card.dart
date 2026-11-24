import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../providers/audio_provider.dart';
import '../providers/quran_providers.dart';
import '../services/export_service.dart';
import '../services/ibadah_audio_controller.dart';
import '../services/ibadah_export_service.dart';

class IbadahAudioCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final String? orderBadge;
  final bool isHighlighted;
  final bool isJumpFocused;
  final String? arabicText;
  final String? transliterationMl;
  final String? meaningText;
  final String? noteText;
  final String? audioPath;
  final bool showTransliteration;
  final bool showMeaning;
  final bool showNotes;
  final bool showAudio;
  final AppStrings strings;
  final Color cardBg;
  final Color cardBorder;
  final Widget? footerExtra;

  const IbadahAudioCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.badgeColor,
    this.orderBadge,
    this.isHighlighted = false,
    this.isJumpFocused = false,
    this.arabicText,
    this.transliterationMl,
    this.meaningText,
    this.noteText,
    this.audioPath,
    this.showTransliteration = false,
    this.showMeaning = false,
    this.showNotes = false,
    this.showAudio = false,
    required this.strings,
    required this.cardBg,
    required this.cardBorder,
    this.footerExtra,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audioState = ref.watch(ibadahAudioProvider);
    final (tvMode, tvScale, settingsArabicSize) = ref.watch(
      settingsProvider.select(
        (s) => (s.tvModeEnabled, s.tvFontScale, s.arabicFontSize),
      ),
    );
    final double scale = tvMode ? tvScale : 1.0;
    final double arabicFontPx =
        tvMode ? math.max(22.5 * scale, settingsArabicSize) : 22.5;
    final bool hasExportableContent =
        (arabicText != null && arabicText!.trim().isNotEmpty) ||
            (meaningText != null && meaningText!.trim().isNotEmpty);

    final hasAudio = audioPath != null && audioPath!.trim().isNotEmpty;
    final bool isActiveTrack =
        hasAudio && audioState.activeAudioPath == audioPath!.trim();
    final bool isPlayingThis = isActiveTrack && audioState.isPlaying;
    final bool isLoadingThis = isActiveTrack && audioState.isLoading;

    final Color accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final Color effectiveBadgeColor = badgeColor ?? accentColor;
    final Color resolvedBorder = isJumpFocused
        ? AppBranding.accentGold
        : ((isPlayingThis || isHighlighted)
            ? accentColor.withValues(alpha: isDark ? 0.6 : 0.45)
            : cardBorder);
    final Color resolvedBg = isJumpFocused
        ? Color.alphaBlend(
            accentColor.withValues(alpha: isDark ? 0.14 : 0.06),
            cardBg,
          )
        : cardBg;
    final Color arabicPanelBg = isDark
        ? const Color(0xFF101915)
        : (cardBg == const Color(0xFFFFFDF7)
            ? const Color(0xFFF6EFE0)
            : const Color(0xFFF1F7F4));

    final Duration pos = isActiveTrack ? audioState.position : Duration.zero;
    final Duration dur = isActiveTrack ? audioState.duration : Duration.zero;
    final double maxMs = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final double currentMs =
        pos.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: resolvedBorder,
          width: isJumpFocused ? 2.0 : ((isPlayingThis || isHighlighted) ? 1.4 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isJumpFocused
                ? accentColor.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
            blurRadius: isJumpFocused ? 14 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tier 1: Full-width Card Heading (never squeezed by action icons)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orderBadge != null && orderBadge!.isNotEmpty) ...[
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: effectiveBadgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      orderBadge!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: effectiveBadgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.5 * scale,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.3,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12.2 * scale,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // Tier 2: Badge + Action Row (Download, Share, Copy) directly below heading
            if ((badgeText != null && badgeText!.trim().isNotEmpty) ||
                hasExportableContent ||
                _hasCopyableText) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (badgeText != null && badgeText!.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: effectiveBadgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: effectiveBadgeColor.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 11.2 * scale.clamp(1.0, 1.35),
                          fontWeight: FontWeight.w800,
                          color: effectiveBadgeColor,
                        ),
                      ),
                    ),
                  if (hasExportableContent)
                    _CardActionButton(
                      icon: Icons.download_rounded,
                      label: strings.download,
                      color: accentColor,
                      borderColor: cardBorder,
                      scale: scale,
                      onTap: () => _showExportSheet(context, shareFocused: false),
                    ),
                  if (hasExportableContent || _hasCopyableText)
                    _CardActionButton(
                      icon: Icons.share_rounded,
                      label: strings.share,
                      color: cs.onSurface,
                      borderColor: cardBorder,
                      scale: scale,
                      onTap: () => _showExportSheet(context, shareFocused: true),
                    ),
                  if (_hasCopyableText)
                    _CardActionButton(
                      icon: Icons.copy_rounded,
                      label: strings.copyLabel,
                      color: cs.onSurfaceVariant,
                      borderColor: cardBorder,
                      scale: scale,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(text: _buildShareOrCopyText()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.copiedTextNotice),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],

            // Arabic Section
            if (arabicText != null && arabicText!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: arabicPanelBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: SelectableText(
                    arabicText!,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(
                      fontSize: arabicFontPx,
                      height: 1.9,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],

            // Malayalam Transliteration (toggled in Ibadah Settings)
            if (showTransliteration &&
                transliterationMl != null &&
                transliterationMl!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                strings.transliterationLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5 * scale.clamp(1.0, 1.4),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                transliterationMl!,
                style: TextStyle(
                  fontSize: 13.8 * scale,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],

            // Meaning (toggled in Ibadah Settings)
            if (showMeaning &&
                meaningText != null &&
                meaningText!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                strings.meaningLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5 * scale.clamp(1.0, 1.4),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meaningText!,
                style: TextStyle(
                  fontSize: 13.2 * scale,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],

            // Fiqh / Context Note (toggled in Ibadah Settings)
            if (showNotes &&
                noteText != null &&
                noteText!.trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15 * scale.clamp(1.0, 1.4),
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        noteText!,
                        style: TextStyle(
                          fontSize: 12.2 * scale,
                          height: 1.45,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (footerExtra != null) ...[
              const SizedBox(height: 10),
              footerExtra!,
            ],

            // Inline Offline Audio Control Bar (toggled in Ibadah Settings)
            if (showAudio && hasAudio) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActiveTrack
                      ? accentColor.withValues(alpha: 0.1)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: isActiveTrack
                        ? accentColor.withValues(alpha: 0.35)
                        : cardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Material(
                      color: accentColor,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (ref.read(quranAudioProvider).isVisible) {
                            unawaited(
                              ref.read(quranAudioProvider.notifier).stopAndClose(),
                            );
                          }
                          unawaited(
                            IbadahAudioController.instance
                                .playOrToggle(audioPath!),
                          );
                        },
                        child: SizedBox(
                          width: 36,
                          height: 36,
                          child: isLoadingThis
                              ? const Padding(
                                  padding: EdgeInsets.all(9),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  isPlayingThis
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: accentColor,
                          thumbColor: accentColor,
                          inactiveTrackColor:
                              cs.onSurfaceVariant.withValues(alpha: 0.25),
                        ),
                        child: Slider(
                          min: 0.0,
                          max: maxMs,
                          value: currentMs,
                          onChanged: (isActiveTrack && dur > Duration.zero)
                              ? (v) => IbadahAudioController.instance.seekTo(
                                    Duration(milliseconds: v.round()),
                                  )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dur > Duration.zero
                          ? '${IbadahAudioState.formatDuration(pos)} / ${IbadahAudioState.formatDuration(dur)}'
                          : '00:00',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: isActiveTrack
                            ? accentColor
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasCopyableText =>
      (arabicText != null && arabicText!.trim().isNotEmpty) ||
      (meaningText != null && meaningText!.trim().isNotEmpty) ||
      (transliterationMl != null && transliterationMl!.trim().isNotEmpty);

  String _buildShareOrCopyText() {
    final buffer = StringBuffer(title.trim());
    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      buffer.writeln(' (${subtitle!.trim()})');
    } else {
      buffer.writeln();
    }
    if (arabicText != null && arabicText!.trim().isNotEmpty) {
      buffer.writeln('\n${arabicText!.trim()}');
    }
    if (showTransliteration &&
        transliterationMl != null &&
        transliterationMl!.trim().isNotEmpty) {
      buffer.writeln('\n${transliterationMl!.trim()}');
    }
    if (showMeaning &&
        meaningText != null &&
        meaningText!.trim().isNotEmpty) {
      buffer.writeln('\n${meaningText!.trim()}');
    }
    if (showNotes && noteText != null && noteText!.trim().isNotEmpty) {
      buffer.writeln('\n${noteText!.trim()}');
    }
    return buffer.toString().trim();
  }

  Future<void> _showExportSheet(
    BuildContext context, {
    required bool shareFocused,
  }) async {
    final bool hasExportableContent =
        (arabicText != null && arabicText!.trim().isNotEmpty) ||
            (meaningText != null && meaningText!.trim().isNotEmpty);
    final item = IbadahExportItem(
      title: title,
      subtitle: subtitle,
      badgeText: badgeText,
      orderBadge: orderBadge,
      arabicText: arabicText,
      transliterationMl: transliterationMl,
      meaningText: meaningText,
      noteText: noteText,
    );
    final baseName = 'ibadia_${IbadahExportService.slugifyTitle(title)}';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetCtx) {
        bool busy = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final cs = Theme.of(ctx).colorScheme;

            Future<void> runAction({
              required bool isPdf,
              required bool isShare,
            }) async {
              if (busy) return;
              setSheetState(() => busy = true);
              try {
                if (isPdf) {
                  final pdfBytes = await IbadahExportService.buildSingleCardPdf(
                    item,
                    includeTransliteration: showTransliteration,
                    includeMeaning: showMeaning,
                    includeNotes: showNotes,
                  );
                  if (isShare) {
                    await ExportService.sharePdfBytes(
                      bytes: pdfBytes,
                      baseName: baseName,
                      title: title,
                    );
                  } else {
                    await ExportService.savePdfBytes(
                      bytes: pdfBytes,
                      baseName: baseName,
                    );
                  }
                } else {
                  final rendered = await IbadahExportService.renderCardPng(
                    item,
                    includeTransliteration: showTransliteration,
                    includeMeaning: showMeaning,
                    includeNotes: showNotes,
                  );
                  if (isShare) {
                    await ExportService.sharePngPages(
                      pages: [rendered.bytes],
                      baseName: baseName,
                      title: title,
                    );
                  } else {
                    final savedToGallery = await ExportService.savePngPages(
                      pages: [rendered.bytes],
                      baseName: baseName,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            savedToGallery
                                ? strings.savedToGallery
                                : strings.exportSuccess,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (!isShare && isPdf && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.exportSuccess),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(strings.exportError),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } finally {
                if (ctx.mounted) {
                  setSheetState(() => busy = false);
                }
              }
            }

            return Directionality(
              textDirection: strings.textDirection,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          shareFocused ? Icons.share_rounded : Icons.hd_rounded,
                          color: cs.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shareFocused
                                    ? strings.share
                                    : strings.exportCardTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                strings.exportCardSubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (busy)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (shareFocused) ...[
                      if (_hasCopyableText)
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.tertiaryContainer,
                            child: Icon(Icons.notes_rounded, color: cs.tertiary),
                          ),
                          title: Text(
                            strings.share,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: busy
                              ? null
                              : () async {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  await ExportService.shareText(
                                    _buildShareOrCopyText(),
                                    subject: title,
                                  );
                                },
                        ),
                      if (hasExportableContent) ...[
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.primaryContainer,
                            child: Icon(Icons.image_rounded, color: cs.primary),
                          ),
                          title: Text(
                            strings.shareUltraHdPng,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: busy
                              ? null
                              : () => runAction(isPdf: false, isShare: true),
                        ),
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: cs.secondaryContainer,
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              color: cs.secondary,
                            ),
                          ),
                          title: Text(
                            strings.shareHighQualityPdf,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: busy
                              ? null
                              : () => runAction(isPdf: true, isShare: true),
                        ),
                      ],
                    ] else ...[
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(Icons.image_rounded, color: cs.primary),
                        ),
                        title: Text(
                          strings.saveUltraHdPng,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: const Icon(Icons.download_rounded),
                        onTap: busy
                            ? null
                            : () => runAction(isPdf: false, isShare: false),
                      ),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: cs.secondaryContainer,
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: cs.secondary,
                          ),
                        ),
                        title: Text(
                          strings.saveHighQualityPdf,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        trailing: const Icon(Icons.download_rounded),
                        onTap: busy
                            ? null
                            : () => runAction(isPdf: true, isShare: false),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color borderColor;
  final double scale;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderColor,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.5, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.8 * scale.clamp(1.0, 1.25),
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
