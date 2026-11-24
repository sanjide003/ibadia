import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_branding.dart';
import '../providers/quran_providers.dart';
import '../services/web_platform_bridge.dart';
import 'web_pwa_widgets.dart';

/// Applies OS-level landscape lock & immersive UI on native devices,
/// and triggers fullscreen + landscape orientation lock on Web browsers.
Future<void> applyTvModePlatformState(bool enabled) async {
  try {
    if (enabled) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(const []);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  } catch (_) {}

  if (kIsWeb) {
    await WebPlatformBridge.instance.setTvModeBrowser(enabled);
  }
}

/// Toggles TV / Classroom Mode, persists preference, applies landscape/fullscreen,
/// and displays a sleek top banner without overlapping drawers.
Future<void> toggleTvMode(
  BuildContext context,
  WidgetRef ref, {
  bool? forceValue,
}) async {
  final current = ref.read(settingsProvider);
  final next = forceValue ?? !current.tvModeEnabled;
  if (next == current.tvModeEnabled && forceValue != null) return;

  final t = ref.read(stringsProvider);
  await applyTvModePlatformState(next);

  await ref.read(settingsProvider.notifier).updateWith((cur) {
    // Boost default font sizes gently on first TV entry if still at small phone defaults
    final double nextArabic =
        next && cur.arabicFontSize < 34.0 ? 38.0 : cur.arabicFontSize;
    final double nextTrans =
        next && cur.translationFontSize < 19.0 ? 20.0 : cur.translationFontSize;
    return cur.copyWith(
      tvModeEnabled: next,
      arabicFontSize: nextArabic,
      translationFontSize: nextTrans,
    );
  });

  if (!context.mounted) return;
  showTopForegroundNotice(
    context,
    message: next ? t.tvModeEnabledNotice : t.tvModeOffNotice,
    textDirection: t.textDirection,
    icon: next ? Icons.tv_rounded : Icons.stay_current_portrait_rounded,
  );
}

/// Computes horizontal page padding that expands comfortably for 16:9 TV screens
/// when TV Mode is active, while keeping comfortable readable margins on desktop/mobile.
double responsivePageHorizontalPadding(
  BuildContext context, {
  required bool tvModeEnabled,
  double normalMaxWidth = 960,
  double minPad = 16.0,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final effectiveMax = tvModeEnabled ? 1560.0 : normalMaxWidth;
  final diff = (width - effectiveMax) / 2;
  return diff > minPad ? diff : minPad;
}

/// AppBar action button for toggling TV / Classroom Mode from any top bar.
class TvModeActionButton extends ConsumerWidget {
  final Color iconColor;

  const TvModeActionButton({
    super.key,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvMode = ref.watch(settingsProvider.select((s) => s.tvModeEnabled));
    final t = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Material(
        color: tvMode
            ? AppBranding.accentGold
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => unawaited(toggleTvMode(context, ref)),
          child: Tooltip(
            message: t.tvModeTitle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tvMode ? Icons.connected_tv_rounded : Icons.tv_rounded,
                    size: 18,
                    color: tvMode ? const Color(0xFF1A1400) : iconColor,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    t.tvModeShort,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: tvMode ? const Color(0xFF1A1400) : iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact classroom TV controls rendered directly inside the emerald top header
/// bar when TV Mode is active (zero extra sub-bar beneath the header).
class TvHeaderControlsInline extends ConsumerWidget {
  final VoidCallback? onOpenSettings;

  const TvHeaderControlsInline({
    super.key,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (!settings.tvModeEnabled) return const SizedBox.shrink();

    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppBranding.accentGold,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.connected_tv_rounded,
                  size: 14,
                  color: Color(0xFF1A1400),
                ),
                const SizedBox(width: 4),
                Text(
                  t.tvLandscapeBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1400),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // Arabic Font Size Quick Stepper
          _HeaderTvStepperChip(
            label: t.tvArabicShort,
            valueLabel: '${settings.arabicFontSize.round()}',
            onDecrease: () => notifier.updateWith(
              (s) => s.copyWith(
                arabicFontSize: (s.arabicFontSize - 2.0).clamp(20.0, 72.0),
              ),
            ),
            onIncrease: () => notifier.updateWith(
              (s) => s.copyWith(
                arabicFontSize: (s.arabicFontSize + 2.0).clamp(20.0, 72.0),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // TV Display Text Scale Quick Stepper
          _HeaderTvStepperChip(
            label: t.tvTextShort,
            valueLabel: '${settings.tvFontScale.toStringAsFixed(2)}x',
            onDecrease: () => notifier.updateWith(
              (s) => s.copyWith(
                tvFontScale: (s.tvFontScale - 0.1).clamp(1.0, 2.2),
                translationFontSize:
                    (s.translationFontSize - 1.5).clamp(13.0, 34.0),
              ),
            ),
            onIncrease: () => notifier.updateWith(
              (s) => s.copyWith(
                tvFontScale: (s.tvFontScale + 0.1).clamp(1.0, 2.2),
                translationFontSize:
                    (s.translationFontSize + 1.5).clamp(13.0, 34.0),
              ),
            ),
          ),

          if (onOpenSettings != null) ...[
            const SizedBox(width: 6),
            Material(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onOpenSettings,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.tune_rounded,
                        size: 14.5,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.settings,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(width: 6),
          Material(
            color: const Color(0xFFB91C1C).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () =>
                  unawaited(toggleTvMode(context, ref, forceValue: false)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.close_fullscreen_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.tvModeExitLabel,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderTvStepperChip extends StatelessWidget {
  final String label;
  final String valueLabel;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const _HeaderTvStepperChip({
    required this.label,
    required this.valueLabel,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onDecrease,
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.remove_rounded, size: 15, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              valueLabel,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onIncrease,
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.add_rounded, size: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full TV / Classroom Mode & Font Size controls mounted inside Top Settings Drawer & Settings Tab.
class TvDisplaySettingsSection extends ConsumerWidget {
  const TvDisplaySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          secondary: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (settings.tvModeEnabled
                      ? AppBranding.accentGold
                      : cs.primary)
                  .withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              settings.tvModeEnabled
                  ? Icons.connected_tv_rounded
                  : Icons.tv_rounded,
              color: settings.tvModeEnabled
                  ? AppBranding.accentGold
                  : cs.primary,
              size: 20,
            ),
          ),
          title: Text(
            t.tvModeTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          subtitle: Text(
            t.tvModeDesc,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: cs.onSurfaceVariant,
            ),
          ),
          value: settings.tvModeEnabled,
          onChanged: (v) => unawaited(toggleTvMode(context, ref, forceValue: v)),
        ),
        const SizedBox(height: 10),

        // Classroom Text / Card Scale (1.0x - 2.2x)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                t.tvTextScaleLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${settings.tvFontScale.toStringAsFixed(2)}x',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_rounded, size: 18),
              onPressed: () => notifier.updateWith(
                (s) => s.copyWith(
                  tvFontScale: (s.tvFontScale - 0.1).clamp(1.0, 2.2),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                min: 1.0,
                max: 2.2,
                divisions: 12,
                value: settings.tvFontScale.clamp(1.0, 2.2),
                onChanged: (v) =>
                    notifier.updateWith((s) => s.copyWith(tvFontScale: v)),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => notifier.updateWith(
                (s) => s.copyWith(
                  tvFontScale: (s.tvFontScale + 0.1).clamp(1.0, 2.2),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Arabic Font Size (20 - 72)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                t.arabicFontSize,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${settings.arabicFontSize.round()}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_rounded, size: 18),
              onPressed: () => notifier.updateWith(
                (s) => s.copyWith(
                  arabicFontSize: (s.arabicFontSize - 2.0).clamp(20.0, 72.0),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                min: 20,
                max: 72,
                divisions: 52,
                value: settings.arabicFontSize.clamp(20.0, 72.0),
                onChanged: (v) =>
                    notifier.updateWith((s) => s.copyWith(arabicFontSize: v)),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => notifier.updateWith(
                (s) => s.copyWith(
                  arabicFontSize: (s.arabicFontSize + 2.0).clamp(20.0, 72.0),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Translation / Meaning Font Size (13 - 34)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                t.translationFontSize,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${settings.translationFontSize.round()}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_rounded, size: 18),
              onPressed: () => notifier.updateWith(
                (s) => s.copyWith(
                  translationFontSize:
                      (s.translationFontSize - 1.0).clamp(13.0, 34.0),
                ),
              ),
            ),
            Expanded(
              child: Slider(
                min: 13,
                max: 34,
                divisions: 21,
                value: settings.translationFontSize.clamp(13.0, 34.0),
                onChanged: (v) => notifier.updateWith(
                  (s) => s.copyWith(translationFontSize: v),
                ),
              ),
            ),
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_rounded, size: 18),
              onPressed: () => notifier.updateWith(
                (s) => s.copyWith(
                  translationFontSize:
                      (s.translationFontSize + 1.0).clamp(13.0, 34.0),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
