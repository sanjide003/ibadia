import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../services/ibadah_audio_controller.dart';

class IbadahAudioCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final String? orderBadge;
  final bool isHighlighted;
  final String? arabicText;
  final String? transliterationMl;
  final String? meaningText;
  final String? noteText;
  final String? audioPath;
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
    this.arabicText,
    this.transliterationMl,
    this.meaningText,
    this.noteText,
    this.audioPath,
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
    final hasAudio = audioPath != null && audioPath!.trim().isNotEmpty;
    final bool isActiveTrack =
        hasAudio && audioState.activeAudioPath == audioPath!.trim();
    final bool isPlayingThis = isActiveTrack && audioState.isPlaying;
    final bool isLoadingThis = isActiveTrack && audioState.isLoading;

    final Color accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final Color effectiveBadgeColor = badgeColor ?? accentColor;
    final Color resolvedBorder = (isPlayingThis || isHighlighted)
        ? accentColor.withValues(alpha: isDark ? 0.6 : 0.45)
        : cardBorder;
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
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: resolvedBorder,
          width: (isPlayingThis || isHighlighted) ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orderBadge != null && orderBadge!.isNotEmpty) ...[
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: effectiveBadgeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      orderBadge!,
                      style: TextStyle(
                        fontSize: 12.5,
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.25,
                        ),
                      ),
                      if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badgeText != null && badgeText!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: effectiveBadgeColor,
                      ),
                    ),
                  ),
                ],
                if (arabicText != null && arabicText!.trim().isNotEmpty)
                  IconButton(
                    tooltip: strings.copiedTextNotice,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.copy_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    onPressed: () {
                      final buffer = StringBuffer(arabicText!.trim());
                      if (transliterationMl != null &&
                          transliterationMl!.trim().isNotEmpty) {
                        buffer.writeln('\n${transliterationMl!.trim()}');
                      }
                      if (meaningText != null &&
                          meaningText!.trim().isNotEmpty) {
                        buffer.writeln(meaningText!.trim());
                      }
                      Clipboard.setData(ClipboardData(text: buffer.toString()));
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
                      fontSize: 22.5,
                      height: 1.9,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),
            ],

            // Malayalam Transliteration
            if (transliterationMl != null &&
                transliterationMl!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                strings.transliterationLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                transliterationMl!,
                style: TextStyle(
                  fontSize: 13.8,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],

            // Meaning
            if (meaningText != null && meaningText!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                strings.meaningLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meaningText!,
                style: TextStyle(
                  fontSize: 13.2,
                  height: 1.5,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],

            // Fiqh / Context Note
            if (noteText != null && noteText!.trim().isNotEmpty) ...[
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
                      size: 15,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        noteText!,
                        style: TextStyle(
                          fontSize: 12.2,
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

            // Inline Offline Audio Control Bar
            if (hasAudio) ...[
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
                        onTap: () => IbadahAudioController.instance
                            .playOrToggle(audioPath!),
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
}
