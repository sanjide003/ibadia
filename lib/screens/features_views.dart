import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import '../providers/islamic_features_providers.dart';
import '../providers/quran_providers.dart';
import '../services/storage_service.dart';

/// Shared helper to open the City / GPS location picker bottom sheet.
Future<void> showPrayerLocationPickerSheet(
  BuildContext context,
  WidgetRef ref,
  AppStrings t,
) async {
  final settings = ref.read(settingsProvider);
  final cityCtrl = TextEditingController(text: settings.prayerCity);
  final countryCtrl = TextEditingController(text: settings.prayerCountry);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return Directionality(
        textDirection: t.textDirection,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.48,
            maxChildSize: 0.94,
            builder: (_, scrollCtrl) {
              return ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.changeCity,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref
                              .read(prayerTimesProvider.notifier)
                              .useGpsLocation(
                                permissionDeniedMsg: t.gpsPermissionError,
                                serviceDisabledMsg: t.gpsServiceDisabled,
                              );
                        },
                        icon: const Icon(Icons.my_location_rounded, size: 17),
                        label: Text(t.useGps),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: t.cityFieldLabel,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: countryCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (cityCtrl.text.trim().isNotEmpty &&
                                countryCtrl.text.trim().isNotEmpty) {
                              ref
                                  .read(prayerTimesProvider.notifier)
                                  .setCustomCity(
                                    cityCtrl.text,
                                    countryCtrl.text,
                                  );
                              Navigator.pop(ctx);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: t.countryFieldLabel,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (cityCtrl.text.trim().isEmpty ||
                            countryCtrl.text.trim().isEmpty) {
                          return;
                        }
                        ref.read(prayerTimesProvider.notifier).setCustomCity(
                              cityCtrl.text,
                              countryCtrl.text,
                            );
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(t.applyLabel),
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    t.popularCities,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...AlAdhanCatalog.quickCities.map((preset) {
                    final selected = settings.prayerLocationMode == 'city' &&
                        settings.prayerCity.toLowerCase() ==
                            preset.city.toLowerCase() &&
                        settings.prayerCountry.toLowerCase() ==
                            preset.country.toLowerCase();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: selected,
                      selectedTileColor:
                          cs.primaryContainer.withValues(alpha: 0.45),
                      leading: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.location_city_rounded,
                        color: selected ? cs.primary : cs.onSurfaceVariant,
                      ),
                      title: Text(
                        preset.city,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(preset.country),
                      onTap: () {
                        ref
                            .read(prayerTimesProvider.notifier)
                            .selectCityPreset(preset);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              );
            },
          ),
        ),
      );
    },
  );
  cityCtrl.dispose();
  countryCtrl.dispose();
}

/// Shared Masjid Time Tune widget (+/- minutes per Salah) used in Prayer Times view & Settings.
class PrayerTuneControlList extends ConsumerWidget {
  final bool compact;

  const PrayerTuneControlList({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    final prayers = <(String, String)>[
      ('fajr', t.fajrName),
      ('dhuhr', t.dhuhrName),
      ('asr', t.asrName),
      ('maghrib', t.maghribName),
      ('isha', t.ishaName),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.tuneMinutes,
                style: TextStyle(
                  fontSize: compact ? 13 : 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (settings.hasAnyTune)
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => notifier.update(settings.clearTunes()),
                icon: const Icon(Icons.restart_alt_rounded, size: 16),
                label: Text(
                  t.resetTune,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ...prayers.map((entry) {
          final key = entry.$1;
          final label = entry.$2;
          final val = settings.tuneFor(key);
          final formatted = val == 0 ? '0m' : (val > 0 ? '+${val}m' : '${val}m');

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 13 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _StepperChipButton(
                  icon: Icons.remove_rounded,
                  tooltip: '$label -1m',
                  onTap: val > -60
                      ? () => notifier.update(settings.copyWithTune(key, val - 1))
                      : null,
                ),
                SizedBox(
                  width: 54,
                  child: Text(
                    formatted,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: val == 0 ? cs.onSurfaceVariant : cs.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                _StepperChipButton(
                  icon: Icons.add_rounded,
                  tooltip: '$label +1m',
                  onTap: val < 60
                      ? () => notifier.update(settings.copyWithTune(key, val + 1))
                      : null,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StepperChipButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _StepperChipButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 18,
              color: onTap == null
                  ? cs.onSurface.withValues(alpha: 0.25)
                  : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared Hijri moon sighting offset selector (-1 / 0 / +1) used in Hijri Calendar & Settings.
class HijriAdjustmentControl extends ConsumerWidget {
  final bool compact;

  const HijriAdjustmentControl({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.hijriAdjustment,
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: -1,
                label: Text(
                  t.dayMinusOne,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 11.5 : 12.5),
                ),
              ),
              ButtonSegment(
                value: 0,
                label: Text(
                  t.dayZero,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 11.5 : 12.5),
                ),
              ),
              ButtonSegment(
                value: 1,
                label: Text(
                  t.dayPlusOne,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: compact ? 11.5 : 12.5),
                ),
              ),
            ],
            selected: {settings.hijriAdjustment},
            onSelectionChanged: (sel) => notifier.update(
              settings.copyWith(hijriAdjustment: sel.first),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared surface colors helper matching HomeScreen Light / Sepia / Dark modes.
({Color cardBg, Color cardBorder, Color headerBg}) _featurePalette(
  BuildContext context,
  AppSettings settings,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isSepia = settings.themeMode == 'sepia';
  return (
    headerBg: isDark ? AppBranding.darkEmerald : AppBranding.headerEmerald,
    cardBg: isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white),
    cardBorder: isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6)),
  );
}

class FeaturesContainerView extends StatelessWidget {
  final TabController controller;

  const FeaturesContainerView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller,
      children: const [
        PrayerTimesView(),
        QiblaCompassView(),
        HijriCalendarView(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. PRAYER TIMES VIEW
// ---------------------------------------------------------------------------
class PrayerTimesView extends ConsumerStatefulWidget {
  const PrayerTimesView({super.key});

  @override
  ConsumerState<PrayerTimesView> createState() => _PrayerTimesViewState();
}

class _PrayerTimesViewState extends ConsumerState<PrayerTimesView> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  ({String key, String name, DateTime time})? _resolveNextPrayer(
    DailyPrayerData data,
    AppSettings settings,
    AppStrings t,
  ) {
    final entries = <(String, String, int)>[
      ('fajr', t.fajrName, settings.prayerTuneFajr),
      ('dhuhr', t.dhuhrName, settings.prayerTuneDhuhr),
      ('asr', t.asrName, settings.prayerTuneAsr),
      ('maghrib', t.maghribName, settings.prayerTuneMaghrib),
      ('isha', t.ishaName, settings.prayerTuneIsha),
    ];

    for (final item in entries) {
      final dt = data.tunedTimeFor(item.$1, item.$3, _now);
      if (dt.isAfter(_now)) {
        return (key: item.$1, name: item.$2, time: dt);
      }
    }
    // After Isha -> next Fajr tomorrow
    final tomorrow = _now.add(const Duration(days: 1));
    final nextFajr = data.tunedTimeFor('fajr', settings.prayerTuneFajr, tomorrow);
    return (key: 'fajr', name: t.fajrName, time: nextFajr);
  }

  String _formatCountdown(Duration diff) {
    final safe = diff.isNegative ? Duration.zero : diff;
    final h = safe.inHours.toString().padLeft(2, '0');
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerTimesProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final palette = _featurePalette(context, settings);
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 860) / 2);

    final data = prayerState.data;
    final nextInfo =
        data != null ? _resolveNextPrayer(data, settings, t) : null;
    final methodObj = AlAdhanCatalog.methodById(settings.prayerMethod);
    final schoolLabel =
        settings.prayerSchool == 1 ? t.schoolHanafi : t.schoolShafi;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
      children: [
        // Hero Card: Location, Hijri Date & Live Next-Prayer Countdown
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                palette.headerBg,
                AppBranding.darkEmerald,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: palette.headerBg.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    settings.prayerLocationMode == 'gps'
                        ? Icons.my_location_rounded
                        : Icons.location_on_rounded,
                    color: AppBranding.accentGold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      settings.displayLocationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: t.refreshLabel,
                    visualDensity: VisualDensity.compact,
                    onPressed: prayerState.isLoading
                        ? null
                        : () => ref
                            .read(prayerTimesProvider.notifier)
                            .load(forceRefresh: true),
                    icon: prayerState.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ],
              ),
              if (data != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${data.hijriDay} ${t.lang == 'ar' ? data.hijriMonthAr : data.hijriMonthEn} ${data.hijriYear} AH',
                  style: TextStyle(
                    color: AppBranding.accentGold.withValues(alpha: 0.95),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data.weekdayEn}, ${data.gregorianReadable}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (nextInfo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.nextPrayerLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${nextInfo.name} • ${DailyPrayerData.format12Hour(nextInfo.time)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              t.remainingLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              _formatCountdown(nextInfo.time.difference(_now)),
                              style: const TextStyle(
                                color: AppBranding.accentGold,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Quick Location Actions (Use GPS + Change City)
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: prayerState.isFetchingGps
                    ? null
                    : () => ref
                        .read(prayerTimesProvider.notifier)
                        .useGpsLocation(
                          permissionDeniedMsg: t.gpsPermissionError,
                          serviceDisabledMsg: t.gpsServiceDisabled,
                        ),
                icon: prayerState.isFetchingGps
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  prayerState.isFetchingGps ? t.gpsFetching : t.useGps,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showPrayerLocationPickerSheet(context, ref, t),
                icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                label: Text(
                  t.changeCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (prayerState.gpsNotice != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: cs.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prayerState.gpsNotice!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onErrorContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(prayerTimesProvider.notifier).clearGpsNotice(),
                  icon: Icon(Icons.close_rounded,
                      size: 16, color: cs.onErrorContainer),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // Prayer Schedule List or Error/Loading
        if (data == null && prayerState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 42),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (data == null && prayerState.error != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_off_rounded, size: 36, color: cs.error),
                const SizedBox(height: 10),
                Text(t.loadError, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref
                      .read(prayerTimesProvider.notifier)
                      .load(forceRefresh: true),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(t.retry),
                ),
              ],
            ),
          )
        else if (data != null) ...[
          ...[
            ('fajr', t.fajrName, Icons.wb_twilight_rounded),
            ('sunrise', t.sunriseName, Icons.wb_sunny_outlined),
            ('dhuhr', t.dhuhrName, Icons.light_mode_rounded),
            ('asr', t.asrName, Icons.sunny_snowing),
            ('maghrib', t.maghribName, Icons.nights_stay_outlined),
            ('isha', t.ishaName, Icons.bedtime_rounded),
          ].map((row) {
            final key = row.$1;
            final label = row.$2;
            final icon = row.$3;
            final tune = settings.tuneFor(key);
            final dt = data.tunedTimeFor(key, tune, _now);
            final isNext = nextInfo != null &&
                nextInfo.key == key &&
                nextInfo.time.day == _now.day;
            final isSunrise = key == 'sunrise';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: isNext
                    ? cs.primaryContainer.withValues(alpha: 0.48)
                    : palette.cardBg,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isNext ? cs.primary : palette.cardBorder,
                  width: isNext ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: isNext
                        ? cs.primary
                        : (isSunrise
                            ? AppBranding.accentGold
                            : cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight:
                                isNext ? FontWeight.w800 : FontWeight.w600,
                            color: isNext ? cs.primary : cs.onSurface,
                          ),
                        ),
                        if (tune != 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            tune > 0 ? '+${tune}m' : '${tune}m',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: cs.primary.withValues(alpha: 0.85),
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isNext)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                    ),
                  Text(
                    DailyPrayerData.format12Hour(dt),
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: isNext ? cs.primary : cs.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),

          // Method & School Info Strip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined,
                    size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${methodObj.displayName(settings.appLanguage)} • $schoolLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (data.loadedFromCache)
                  Text(
                    t.offlineCachedNote,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Direct Masjid Time Tune Section on Prayer Times Screen
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardBorder),
            ),
            child: const PrayerTuneControlList(),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2. LIVE QIBLA COMPASS VIEW
// ---------------------------------------------------------------------------
class QiblaCompassView extends ConsumerStatefulWidget {
  const QiblaCompassView({super.key});

  @override
  ConsumerState<QiblaCompassView> createState() => _QiblaCompassViewState();
}

class _QiblaCompassViewState extends ConsumerState<QiblaCompassView> {
  StreamSubscription<CompassEvent>? _compassSub;
  double? _rawHeading;
  bool _hasLiveSensor = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      try {
        _compassSub = FlutterCompass.events?.listen(
          (event) {
            if (!mounted) return;
            final h = event.heading;
            if (h != null && h.isFinite) {
              setState(() {
                _rawHeading = (h + 360.0) % 360.0;
                _hasLiveSensor = true;
              });
            }
          },
          onError: (_) {
            if (mounted) {
              setState(() => _hasLiveSensor = false);
            }
          },
        );
      } catch (_) {
        _hasLiveSensor = false;
      }
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final prayerState = ref.watch(prayerTimesProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final palette = _featurePalette(context, settings);
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 860) / 2);

    final qiblaBearing =
        AlAdhanCatalog.computeQiblaBearing(settings.prayerLat, settings.prayerLon);
    final distanceKm =
        AlAdhanCatalog.distanceToKaabaKm(settings.prayerLat, settings.prayerLon);
    final cardinal = AlAdhanCatalog.compassCardinal(qiblaBearing);

    final double heading = _rawHeading ?? 0.0;
    // Signed shortest difference in [-180, 180] between Qibla bearing & current phone heading
    double delta = ((qiblaBearing - heading + 540.0) % 360.0) - 180.0;
    final bool isAligned = _hasLiveSensor && delta.abs() <= 5.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
      children: [
        // Location + Quick Actions Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.displayLocationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    Text(
                      '${settings.prayerLat.toStringAsFixed(2)}° N, ${settings.prayerLon.toStringAsFixed(2)}° E',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.useGps,
                onPressed: prayerState.isFetchingGps
                    ? null
                    : () => ref
                        .read(prayerTimesProvider.notifier)
                        .useGpsLocation(
                          permissionDeniedMsg: t.gpsPermissionError,
                          serviceDisabledMsg: t.gpsServiceDisabled,
                        ),
                icon: prayerState.isFetchingGps
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location_rounded, color: cs.primary),
              ),
              IconButton(
                tooltip: t.changeCity,
                onPressed: () => showPrayerLocationPickerSheet(context, ref, t),
                icon: Icon(Icons.edit_location_alt_rounded,
                    color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Alignment / Sensor Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isAligned
                ? AppBranding.primaryEmerald.withValues(alpha: 0.14)
                : palette.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAligned ? AppBranding.primaryEmerald : palette.cardBorder,
              width: isAligned ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAligned
                    ? Icons.check_circle_rounded
                    : (_hasLiveSensor
                        ? Icons.explore_rounded
                        : Icons.explore_off_rounded),
                color: isAligned
                    ? AppBranding.primaryEmerald
                    : (_hasLiveSensor ? cs.primary : AppBranding.accentGold),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _hasLiveSensor
                      ? (isAligned
                          ? t.facingQibla
                          : t.turnDegreesLabel(
                              delta > 0,
                              delta.abs().round(),
                            ))
                      : t.compassUnavailableNote,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isAligned ? FontWeight.w700 : FontWeight.w600,
                    color: isAligned ? AppBranding.primaryEmerald : cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Precision Emerald & Gold Compass Dial
        Center(
          child: SizedBox(
            width: 286,
            height: 286,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotating compass dial (moves opposite to phone heading)
                Transform.rotate(
                  angle: -heading * math.pi / 180.0,
                  child: CustomPaint(
                    size: const Size(286, 286),
                    painter: _QiblaDialPainter(
                      qiblaBearingDeg: qiblaBearing,
                      primaryColor: cs.primary,
                      goldColor: AppBranding.accentGold,
                      surfaceColor: palette.cardBg,
                      borderColor: palette.cardBorder,
                      textColor: cs.onSurface,
                      isAligned: isAligned,
                    ),
                  ),
                ),
                // Center Kaaba emblem
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isAligned
                        ? AppBranding.primaryEmerald
                        : palette.headerBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppBranding.accentGold,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Bearing & Distance Readout Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.qiblaBearingLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${qiblaBearing.toStringAsFixed(1)}° $cardinal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.kaabaDistanceLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${distanceKm.round()} km',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        if (_hasLiveSensor) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors_rounded, size: 15, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t.compassCalibrationTip,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _QiblaDialPainter extends CustomPainter {
  final double qiblaBearingDeg;
  final Color primaryColor;
  final Color goldColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final bool isAligned;

  const _QiblaDialPainter({
    required this.qiblaBearingDeg,
    required this.primaryColor,
    required this.goldColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.isAligned,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Outer circle background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = surfaceColor
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = isAligned ? primaryColor : borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isAligned ? 2.6 : 1.6,
    );

    // Tick marks every 5 degrees
    for (int deg = 0; deg < 360; deg += 5) {
      final rad = (deg - 90) * math.pi / 180.0;
      final isMajor = deg % 30 == 0;
      final isCardinal = deg % 90 == 0;
      final outer = Offset(
        center.dx + (radius - 4) * math.cos(rad),
        center.dy + (radius - 4) * math.sin(rad),
      );
      final innerLen = isCardinal ? 14.0 : (isMajor ? 9.0 : 5.0);
      final inner = Offset(
        center.dx + (radius - 4 - innerLen) * math.cos(rad),
        center.dy + (radius - 4 - innerLen) * math.sin(rad),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = deg == 0
              ? Colors.redAccent
              : (isCardinal
                  ? primaryColor
                  : textColor.withValues(alpha: isMajor ? 0.55 : 0.22))
          ..strokeWidth = isCardinal ? 2.2 : 1.2,
      );
    }

    // Cardinal labels (N, E, S, W)
    const cardinals = [
      (0, 'N', true),
      (90, 'E', false),
      (180, 'S', false),
      (270, 'W', false),
    ];
    for (final c in cardinals) {
      final rad = (c.$1 - 90) * math.pi / 180.0;
      final pos = Offset(
        center.dx + (radius - 30) * math.cos(rad),
        center.dy + (radius - 30) * math.sin(rad),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: c.$2,
          style: TextStyle(
            color: c.$3 ? Colors.redAccent : textColor.withValues(alpha: 0.78),
            fontSize: c.$3 ? 16 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Qibla Pointer Needle
    final qRad = (qiblaBearingDeg - 90) * math.pi / 180.0;
    final tip = Offset(
      center.dx + (radius - 42) * math.cos(qRad),
      center.dy + (radius - 42) * math.sin(qRad),
    );
    final leftWing = Offset(
      center.dx + 14 * math.cos(qRad - math.pi / 2),
      center.dy + 14 * math.sin(qRad - math.pi / 2),
    );
    final rightWing = Offset(
      center.dx + 14 * math.cos(qRad + math.pi / 2),
      center.dy + 14 * math.sin(qRad + math.pi / 2),
    );

    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();

    canvas.drawPath(
      needlePath,
      Paint()
        ..color = goldColor
        ..style = PaintingStyle.fill,
    );

    // Small gold beacon dot at the rim on the Qibla azimuth
    final rimDot = Offset(
      center.dx + (radius - 12) * math.cos(qRad),
      center.dy + (radius - 12) * math.sin(qRad),
    );
    canvas.drawCircle(rimDot, 5.5, Paint()..color = goldColor);
  }

  @override
  bool shouldRepaint(covariant _QiblaDialPainter old) {
    return old.qiblaBearingDeg != qiblaBearingDeg ||
        old.primaryColor != primaryColor ||
        old.isAligned != isAligned ||
        old.surfaceColor != surfaceColor;
  }
}

// ---------------------------------------------------------------------------
// 3. HIJRI CALENDAR VIEW
// ---------------------------------------------------------------------------
class HijriCalendarView extends ConsumerWidget {
  const HijriCalendarView({super.key});

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cal = ref.watch(hijriCalendarProvider);
    final notifier = ref.read(hijriCalendarProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final palette = _featurePalette(context, settings);
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 860) / 2);

    final now = DateTime.now();
    final monthName = _monthNames[(cal.month - 1).clamp(0, 11)];

    // Determine Hijri months spanned across this Gregorian month
    String hijriHeaderRange = '';
    if (cal.days.isNotEmpty) {
      final first = cal.days.first;
      final last = cal.days.last;
      final firstM = t.lang == 'ar' ? first.hijriMonthAr : first.hijriMonthEn;
      final lastM = t.lang == 'ar' ? last.hijriMonthAr : last.hijriMonthEn;
      hijriHeaderRange = firstM == lastM
          ? '$firstM ${first.hijriYear} AH'
          : '$firstM – $lastM ${last.hijriYear} AH';
    }

    // First day weekday offset (Sunday = 0, Monday = 1 ... Saturday = 6)
    final firstWeekday =
        DateTime(cal.year, cal.month, 1).weekday % 7; // Sunday->0 .. Saturday->6

    CalendarDayEntry? selectedEntry;
    for (final d in cal.days) {
      if (d.gregorianYear == cal.selectedDate.year &&
          d.gregorianMonth == cal.selectedDate.month &&
          d.gregorianDay == cal.selectedDate.day) {
        selectedEntry = d;
        break;
      }
    }
    selectedEntry ??= cal.days.isNotEmpty ? cal.days.first : null;

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
      children: [
        // Month Switcher Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: notifier.previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$monthName ${cal.year}',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (hijriHeaderRange.isNotEmpty)
                      Text(
                        hijriHeaderRange,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: notifier.goToToday,
                child: Text(t.todayLabel),
              ),
              IconButton(
                onPressed: notifier.nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Calendar Grid Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            children: [
              // Weekday Header Row
              Row(
                children: _weekdays.map((wd) {
                  final isFri = wd == 'Fri';
                  return Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          wd,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isFri ? cs.primary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 10),
              if (cal.isLoading && cal.days.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (cal.error != null && cal.days.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 34, color: cs.error),
                      const SizedBox(height: 8),
                      Text(t.loadError, textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => notifier.loadMonth(
                          cal.year,
                          cal.month,
                          forceRefresh: true,
                        ),
                        child: Text(t.retry),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: firstWeekday + cal.days.length,
                  itemBuilder: (_, idx) {
                    if (idx < firstWeekday) {
                      return const SizedBox.shrink();
                    }
                    final dayEntry = cal.days[idx - firstWeekday];
                    final gDate = dayEntry.gregorianDate;
                    final isToday = gDate.year == now.year &&
                        gDate.month == now.month &&
                        gDate.day == now.day;
                    final isSelected = gDate.year == cal.selectedDate.year &&
                        gDate.month == cal.selectedDate.month &&
                        gDate.day == cal.selectedDate.day;
                    final isFriday = gDate.weekday == DateTime.friday;
                    final hasHoliday = dayEntry.holidays.isNotEmpty;

                    return Material(
                      color: isToday
                          ? cs.primary
                          : (isSelected
                              ? cs.primaryContainer.withValues(alpha: 0.65)
                              : (isFriday
                                  ? cs.primary.withValues(alpha: 0.06)
                                  : Colors.transparent)),
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(11),
                        onTap: () => notifier.selectDay(gDate),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            border: isSelected && !isToday
                                ? Border.all(color: cs.primary, width: 1.4)
                                : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${dayEntry.gregorianDay}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isToday ? Colors.white : cs.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                dayEntry.hijriDay == 1
                                    ? '1 ${dayEntry.hijriMonthEn.split(' ').first}'
                                    : '${dayEntry.hijriDay}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: dayEntry.hijriDay == 1
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isToday
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : (hasHoliday
                                          ? AppBranding.accentGold
                                          : cs.primary),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Selected Date Detail Card
        if (selectedEntry != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${selectedEntry.hijriDay}',
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedEntry.hijriDay} ${selectedEntry.hijriMonthEn} (${selectedEntry.hijriMonthAr}) ${selectedEntry.hijriYear} AH',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${selectedEntry.weekdayEn}, ${selectedEntry.gregorianDay} $monthName ${selectedEntry.gregorianYear}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (selectedEntry.holidays.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          selectedEntry.holidays.join(' • '),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppBranding.accentGold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Hijri Moon Sighting Offset (-1 / 0 / +1) directly on Calendar screen
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorder),
          ),
          child: const HijriAdjustmentControl(),
        ),
      ],
    );
  }
}
