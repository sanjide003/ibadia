import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_providers.dart';

const List<double> kAutoScrollSpeedPresets = [
  0.25,
  0.35,
  0.5,
  1.0,
  1.5,
  2.0,
  3.0,
  4.0,
];

String formatAutoScrollSpeed(double speed) {
  final hundredths = (speed * 100).round();
  if (hundredths % 10 != 0) {
    return '${(hundredths / 100).toStringAsFixed(2)}x';
  }
  return '${(hundredths / 100).toStringAsFixed(1)}x';
}

double stepDownAutoScrollSpeed(double current) {
  if (current > 0.55) return (current - 0.5).clamp(0.5, 4.0);
  if (current > 0.36) return 0.35;
  return 0.25;
}

double stepUpAutoScrollSpeed(double current) {
  if (current < 0.34) return 0.35;
  if (current < 0.49) return 0.5;
  return (current + 0.5).clamp(0.25, 4.0);
}

/// Shared interactive controls for Auto-Scroll Speed, Arabic Font Size (20–50),
/// and Translation Font Size (13–24). Mounted identically in both the Settings
/// side drawer and the reader floating quick-control bottom sheet.
class QuickReaderControls extends ConsumerWidget {
  final bool compact;
  final ValueNotifier<bool>? isAutoScrollingListenable;
  final VoidCallback? onToggleAutoScroll;

  const QuickReaderControls({
    super.key,
    this.compact = false,
    this.isAutoScrollingListenable,
    this.onToggleAutoScroll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    final double headingSize = compact ? 13.5 : 15.5;
    final double fontValueSize = compact ? 13.5 : 15.0;
    final VisualDensity chipDensity =
        compact ? VisualDensity.compact : VisualDensity.standard;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Auto-Scroll Speed (+ optional Play/Pause when opened inside Reader)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${t.autoScrollSpeed}: ${formatAutoScrollSpeed(settings.autoScrollSpeed)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (isAutoScrollingListenable != null && onToggleAutoScroll != null)
              ValueListenableBuilder<bool>(
                valueListenable: isAutoScrollingListenable!,
                builder: (_, isScrolling, __) {
                  return FilledButton.tonalIcon(
                    icon: Icon(
                      isScrolling
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    label: Text(isScrolling ? t.pause : t.play),
                    onPressed: onToggleAutoScroll,
                  );
                },
              ),
          ],
        ),
        SizedBox(height: compact ? 4 : 8),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: chipDensity,
              icon: Icon(Icons.remove_rounded, size: compact ? 18 : 22),
              onPressed: () {
                notifier.updateWith(
                  (s) => s.copyWith(
                    autoScrollSpeed: stepDownAutoScrollSpeed(s.autoScrollSpeed),
                  ),
                );
              },
            ),
            Expanded(
              child: Slider(
                min: 0.25,
                max: 4.0,
                divisions: 75,
                value: settings.autoScrollSpeed.clamp(0.25, 4.0),
                onChanged: (v) =>
                    notifier.updateWith((s) => s.copyWith(autoScrollSpeed: v)),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: chipDensity,
              icon: Icon(Icons.add_rounded, size: compact ? 18 : 22),
              onPressed: () {
                notifier.updateWith(
                  (s) => s.copyWith(
                    autoScrollSpeed: stepUpAutoScrollSpeed(s.autoScrollSpeed),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: compact ? 6 : 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: kAutoScrollSpeedPresets.map((spd) {
            final selected = (settings.autoScrollSpeed - spd).abs() < 0.02;
            return ChoiceChip(
              visualDensity: chipDensity,
              label: Text(
                formatAutoScrollSpeed(spd),
                style: TextStyle(
                  fontSize: compact ? 11.5 : 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              selected: selected,
              onSelected: (_) =>
                  notifier.updateWith((s) => s.copyWith(autoScrollSpeed: spd)),
            );
          }).toList(),
        ),

        Divider(height: compact ? 22 : 26),

        // 2. Arabic Font Size (+/- buttons & Slider)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.arabicFontSize,
              style: TextStyle(
                fontSize: fontValueSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${settings.arabicFontSize.round()}',
              style: TextStyle(
                fontSize: fontValueSize,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: chipDensity,
              icon: Icon(Icons.remove_rounded, size: compact ? 18 : 22),
              onPressed: () {
                notifier.updateWith(
                  (s) => s.copyWith(
                    arabicFontSize:
                        (s.arabicFontSize - 1.0).clamp(20.0, 50.0),
                  ),
                );
              },
            ),
            Expanded(
              child: Slider(
                min: 20,
                max: 50,
                divisions: 30,
                value: settings.arabicFontSize.clamp(20.0, 50.0),
                onChanged: (v) =>
                    notifier.updateWith((s) => s.copyWith(arabicFontSize: v)),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: chipDensity,
              icon: Icon(Icons.add_rounded, size: compact ? 18 : 22),
              onPressed: () {
                notifier.updateWith(
                  (s) => s.copyWith(
                    arabicFontSize:
                        (s.arabicFontSize + 1.0).clamp(20.0, 50.0),
                  ),
                );
              },
            ),
          ],
        ),

        SizedBox(height: compact ? 6 : 10),

        // 3. Translation Font Size (+/- buttons & Slider)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.translationFontSize,
              style: TextStyle(
                fontSize: fontValueSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '${settings.translationFontSize.round()}',
              style: TextStyle(
                fontSize: fontValueSize,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 6),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: chipDensity,
              icon: Icon(Icons.remove_rounded, size: compact ? 18 : 22),
              onPressed: () {
                notifier.updateWith(
                  (s) => s.copyWith(
                    translationFontSize:
                        (s.translationFontSize - 1.0).clamp(13.0, 24.0),
                  ),
                );
              },
            ),
            Expanded(
              child: Slider(
                min: 13,
                max: 24,
                divisions: 11,
                value: settings.translationFontSize.clamp(13.0, 24.0),
                onChanged: (v) => notifier.updateWith(
                  (s) => s.copyWith(translationFontSize: v),
                ),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: chipDensity,
              icon: Icon(Icons.add_rounded, size: compact ? 18 : 22),
              onPressed: () {
                notifier.updateWith(
                  (s) => s.copyWith(
                    translationFontSize:
                        (s.translationFontSize + 1.0).clamp(13.0, 24.0),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
