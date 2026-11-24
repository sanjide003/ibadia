import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/api_config.dart';
import '../providers/audio_provider.dart';
import '../providers/quran_providers.dart';

class ReaderAudioPlayerBar extends ConsumerWidget {
  const ReaderAudioPlayerBar({super.key});

  String _formatDuration(Duration d) {
    final totalSec = d.inSeconds;
    final mins = (totalSec ~/ 60).toString().padLeft(1, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(quranAudioProvider);
    if (!audio.isVisible) return const SizedBox.shrink();

    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final reciter = ApiConfig.reciterById(settings.reciterId);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surahTitle = audio.summary == null
        ? '${t.surahLabel} ${audio.surahNumber ?? 1}'
        : ((settings.appLanguage == 'ar' || settings.appLanguage == 'ml')
            ? audio.summary!.nameArabic
            : '${audio.summary!.number}. ${audio.summary!.englishName}');

    final totalMs = audio.duration.inMilliseconds;
    final posMs = audio.position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);
    final progress = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? cs.surfaceContainerHigh
            : cs.primaryContainer.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: audio.isBuffering
                    ? Padding(
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(
                        Icons.graphic_eq_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$surahTitle • ${t.ayahLabel} ${audio.ayahNumber ?? 1}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      audio.errorMessage ??
                          '${reciter.displayName(settings.appLanguage)}${totalMs > 0 ? ' · ${_formatDuration(audio.position)} / ${_formatDuration(audio.duration)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: audio.errorMessage != null
                            ? cs.error
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.previousAyah,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_previous_rounded, size: 22),
                onPressed: () =>
                    ref.read(quranAudioProvider.notifier).playPreviousAyah(),
              ),
              FilledButton(
                onPressed: () =>
                    ref.read(quranAudioProvider.notifier).togglePlayPause(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(40, 34),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Icon(
                  audio.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 20,
                ),
              ),
              IconButton(
                tooltip: t.nextAyah,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.skip_next_rounded, size: 22),
                onPressed: () =>
                    ref.read(quranAudioProvider.notifier).playNextAyah(),
              ),
              IconButton(
                tooltip: t.repeatAyah,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.repeat_one_rounded,
                  size: 20,
                  color: audio.repeatAyah ? cs.primary : cs.onSurfaceVariant,
                ),
                onPressed: () =>
                    ref.read(quranAudioProvider.notifier).toggleRepeatAyah(),
              ),
              IconButton(
                tooltip: t.closePlayer,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () =>
                    ref.read(quranAudioProvider.notifier).stopAndClose(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: audio.isBuffering ? null : progress,
              minHeight: 3,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.35),
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
