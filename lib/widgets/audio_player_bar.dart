import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';
import '../providers/audio_provider.dart';
import '../providers/quran_providers.dart';

/// Compact audio transport & seekable line-progress bar docked directly
/// below the SurahReaderScreen AppBar while recitation is active or paused.
class ReaderAudioPlayerBar extends ConsumerStatefulWidget {
  const ReaderAudioPlayerBar({super.key});

  @override
  ConsumerState<ReaderAudioPlayerBar> createState() =>
      _ReaderAudioPlayerBarState();
}

class _ReaderAudioPlayerBarState extends ConsumerState<ReaderAudioPlayerBar> {
  bool _isDragging = false;
  double _dragMs = 0.0;

  String _formatDuration(Duration d) {
    final totalSeconds = d.inSeconds;
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(quranAudioProvider);
    final t = ref.watch(stringsProvider);
    final appLanguage =
        ref.watch(settingsProvider.select((s) => s.appLanguage));

    if (!audio.isVisible) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    final reciter = ApiConfig.reciterById(audio.reciterId);
    final surahDisplay = appLanguage == 'ar' && audio.surahArabicName.isNotEmpty
        ? audio.surahArabicName
        : (audio.surahName.isNotEmpty
            ? audio.surahName
            : '${t.surahLabel} ${audio.surahNumber ?? ''}');

    final double maxMs = math.max(1.0, audio.duration.inMilliseconds.toDouble());
    final double currentMs = _isDragging
        ? _dragMs.clamp(0.0, maxMs)
        : audio.position.inMilliseconds.toDouble().clamp(0.0, maxMs);
    final Duration displayedPos =
        Duration(milliseconds: currentMs.round());

    final double hPad =
        math.max(12.0, (MediaQuery.sizeOf(context).width - 820) / 2);

    return Material(
      color: cs.surfaceContainerLow,
      elevation: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Metadata (Surah · Ayah · Reciter), Duration Clock, Close Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    audio.errorKey != null
                        ? t.audioLoadError
                        : '$surahDisplay  ·  ${t.ayahLabel} ${audio.ayahNumber ?? 1}  ·  ${reciter.displayName(appLanguage)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: audio.errorKey != null
                          ? cs.error
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatDuration(displayedPos)} / ${_formatDuration(audio.duration)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 2),
                IconButton(
                  tooltip: t.closePlayer,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () =>
                      ref.read(quranAudioProvider.notifier).stopAndClose(),
                ),
              ],
            ),

            // Row 2: Seekable Line Progress Slider
            SizedBox(
              height: 24,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.5,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 13,
                  ),
                  activeTrackColor: cs.primary,
                  inactiveTrackColor: cs.primary.withValues(alpha: 0.18),
                  thumbColor: cs.primary,
                ),
                child: Slider(
                  min: 0.0,
                  max: maxMs,
                  value: currentMs,
                  onChangeStart: (v) {
                    setState(() {
                      _isDragging = true;
                      _dragMs = v;
                    });
                  },
                  onChanged: (v) {
                    setState(() => _dragMs = v);
                  },
                  onChangeEnd: (v) {
                    setState(() => _isDragging = false);
                    ref
                        .read(quranAudioProvider.notifier)
                        .seekTo(Duration(milliseconds: v.round()));
                  },
                ),
              ),
            ),

            // Row 3: Previous Ayah (Left) — Play/Pause (Center) — Next Ayah (Right)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: t.previousAyah,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 38,
                    ),
                    icon: Icon(
                      Icons.skip_previous_rounded,
                      size: 24,
                      color: audio.canGoPrev
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                    onPressed: audio.canGoPrev
                        ? () =>
                            ref.read(quranAudioProvider.notifier).prevAyah()
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Material(
                    color: cs.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => ref
                          .read(quranAudioProvider.notifier)
                          .togglePlayPause(),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: audio.isBuffering
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : Icon(
                                  audio.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 24,
                                  color: cs.onPrimary,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    tooltip: t.nextAyah,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 38,
                    ),
                    icon: Icon(
                      Icons.skip_next_rounded,
                      size: 24,
                      color: audio.canGoNext
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.3),
                    ),
                    onPressed: audio.canGoNext
                        ? () =>
                            ref.read(quranAudioProvider.notifier).nextAyah()
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
