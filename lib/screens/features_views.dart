import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import '../providers/islamic_features_providers.dart';
import '../providers/quran_providers.dart';
import '../services/storage_service.dart';
import 'adhkar_tasbih_views.dart';

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

/// Shared Masjid Time Tune widget (+/- minutes per Salah) used in Prayer Times & Settings.
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

/// Shared Prayer Alarm Sound, Volume, Vibration & Master Toggle controls.
class PrayerAlarmSoundControls extends ConsumerWidget {
  final bool compact;

  const PrayerAlarmSoundControls({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final alarmState = ref.watch(prayerAlarmProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final alarmNotifier = ref.read(prayerAlarmProvider.notifier);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: compact,
          title: Text(
            t.masterAlarmToggle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13.5 : 14.5,
            ),
          ),
          subtitle: Text(
            t.masterAlarmDesc,
            style: TextStyle(fontSize: compact ? 11.5 : 12),
          ),
          value: settings.prayerAlarmMasterEnabled,
          onChanged: (val) => alarmNotifier.setMasterAlarmEnabled(val),
        ),
        const SizedBox(height: 10),
        Text(
          t.alarmSoundTypeLabel,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13 : 13.5,
          ),
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            prefixIcon: Icon(
              Icons.music_note_rounded,
              size: 19,
              color: cs.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: AlAdhanCatalog.soundById(settings.alarmSoundType).id,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(12),
              items: AlAdhanCatalog.alarmSounds.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt.id,
                  child: Text(
                    opt.displayName(settings.appLanguage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) async {
                if (val == null) return;
                if (alarmState.isPreviewingSound) {
                  await alarmNotifier.stopPreviewSound();
                }
                await settingsNotifier.update(
                  settings.copyWith(alarmSoundType: val),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.volume_up_rounded, size: 19, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.alarmVolumeLabel,
                style: TextStyle(
                  fontSize: compact ? 13 : 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${(settings.alarmVolume * 100).round()}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: cs.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(
          value: settings.alarmVolume.clamp(0.1, 1.0),
          min: 0.1,
          max: 1.0,
          divisions: 9,
          onChanged: (val) => settingsNotifier.update(
            settings.copyWith(alarmVolume: val),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.alarmVibrateLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 13.5,
            ),
          ),
          value: settings.alarmVibrate,
          onChanged: (val) => settingsNotifier.update(
            settings.copyWith(alarmVibrate: val),
          ),
        ),
        const SizedBox(height: 6),
        FilledButton.tonalIcon(
          onPressed: () => alarmNotifier.togglePreviewSound(),
          icon: Icon(
            alarmState.isPreviewingSound
                ? Icons.stop_rounded
                : Icons.play_arrow_rounded,
            size: 20,
          ),
          label: Text(
            alarmState.isPreviewingSound
                ? t.stopSoundLabel
                : t.previewSoundLabel,
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal sheet for editing prayer alarm sounds directly from Prayer Times screen.
Future<void> showPrayerAlarmSoundSheet(
  BuildContext context,
  WidgetRef ref,
  AppStrings t,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) {
      return Directionality(
        textDirection: t.textDirection,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            18,
            4,
            18,
            24 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.alarmSoundSettings,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(t.done),
                  ),
                ],
              ),
              const Divider(height: 18),
              const PrayerAlarmSoundControls(),
            ],
          ),
        ),
      );
    },
  );
  // Stop preview playback cleanly when closing sheet
  await ref.read(prayerAlarmProvider.notifier).stopPreviewSound();
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
  final void Function(int surahNumber)? onOpenSurah;

  const FeaturesContainerView({
    super.key,
    required this.controller,
    this.onOpenSurah,
  });

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: controller,
      children: [
        PrayerTimesView(onOpenSurah: onOpenSurah),
        const HijriCalendarView(),
        const AdhkarDuasView(),
        const DigitalTasbihView(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. PRAYER TIMES VIEW (Adhan, Iqamah & Alarm Schedule Cards)
// ---------------------------------------------------------------------------
class PrayerTimesView extends ConsumerStatefulWidget {
  final void Function(int surahNumber)? onOpenSurah;

  const PrayerTimesView({super.key, this.onOpenSurah});

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

  String _prayerName(String key, AppStrings t) {
    switch (key) {
      case 'fajr':
        return t.fajrName;
      case 'sunrise':
        return t.sunriseName;
      case 'dhuhr':
        return t.dhuhrName;
      case 'asr':
        return t.asrName;
      case 'maghrib':
        return t.maghribName;
      case 'isha':
        return t.ishaName;
      default:
        return key;
    }
  }

  IconData _prayerIcon(String key) {
    switch (key) {
      case 'fajr':
        return Icons.wb_twilight_rounded;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'dhuhr':
        return Icons.light_mode_rounded;
      case 'asr':
        return Icons.sunny_snowing;
      case 'maghrib':
        return Icons.nights_stay_outlined;
      case 'isha':
        return Icons.bedtime_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  ({String key, String name, DateTime time})? _resolveNextPrayer(
    DailyPrayerData data,
    AppSettings settings,
    AppStrings t,
  ) {
    for (final key in AlAdhanCatalog.fivePrayerKeys) {
      final dt = data.tunedTimeFor(key, settings.tuneFor(key), _now);
      if (dt.isAfter(_now)) {
        return (key: key, name: _prayerName(key, t), time: dt);
      }
    }
    final tomorrow = _now.add(const Duration(days: 1));
    final nextFajr =
        data.tunedTimeFor('fajr', settings.prayerTuneFajr, tomorrow);
    return (key: 'fajr', name: t.fajrName, time: nextFajr);
  }

  String _formatCountdown(Duration diff) {
    final safe = diff.isNegative ? Duration.zero : diff;
    final h = safe.inHours.toString().padLeft(2, '0');
    final m = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final s = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _openSlotEditor(ComputedPrayerSlot slot) async {
    final t = ref.read(stringsProvider);
    final settings = ref.read(settingsProvider);
    final currentCfg = settings.alarmConfigFor(slot.prayerKey);

    bool enabled = currentCfg.enabled;
    int iqamahGap = currentCfg.iqamahGapMinutes.clamp(
      0,
      slot.maxAllowedIqamahGap,
    );
    PrayerAlarmRef alarmRef = currentCfg.alarmRef;
    int alarmOffset = currentCfg.alarmOffsetMinutes;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final cs = Theme.of(sheetCtx).colorScheme;
            final iqamahDt = slot.adhanTime.add(Duration(minutes: iqamahGap));
            const int minIqamahOffset = -60;
            final int maxIqamahOffset =
                slot.safetyLimitTime.difference(iqamahDt).inMinutes.clamp(0, 60);

            if (alarmRef == PrayerAlarmRef.beforeAdhan) {
              alarmOffset = alarmOffset.clamp(0, 120);
            } else {
              alarmOffset = alarmOffset.clamp(minIqamahOffset, maxIqamahOffset);
            }

            DateTime? previewAlarmDt;
            if (enabled) {
              if (alarmRef == PrayerAlarmRef.beforeAdhan) {
                previewAlarmDt =
                    slot.adhanTime.subtract(Duration(minutes: alarmOffset));
              } else {
                previewAlarmDt = iqamahDt.add(Duration(minutes: alarmOffset));
              }
              if (previewAlarmDt.isAfter(slot.safetyLimitTime)) {
                previewAlarmDt = slot.safetyLimitTime;
              }
            }

            final String offsetHuman;
            if (alarmRef == PrayerAlarmRef.beforeAdhan) {
              offsetHuman = '$alarmOffset ${t.minutesUnitShort}';
            } else if (alarmOffset == 0) {
              offsetHuman = t.atIqamahTime;
            } else if (alarmOffset > 0) {
              offsetHuman = '+$alarmOffset ${t.minutesUnitShort}';
            } else {
              offsetHuman = '$alarmOffset ${t.minutesUnitShort}';
            }

            final nextBoundaryName = _prayerName(slot.nextBoundaryKey, t);
            final limitFormatted =
                DailyPrayerData.format12Hour(slot.safetyLimitTime);

            return Directionality(
              textDirection: t.textDirection,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  24 + MediaQuery.viewInsetsOf(sheetCtx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _prayerIcon(slot.prayerKey),
                          color: cs.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_prayerName(slot.prayerKey, t)} — ${t.editScheduleLabel}',
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${t.adhanLabel}: ${DailyPrayerData.format12Hour(slot.adhanTime)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: cs.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),

                    // Live computed summary row inside editor
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          _ScheduleMetricColumn(
                            label: t.adhanLabel,
                            value: DailyPrayerData.format12Hour(slot.adhanTime),
                            accentColor: cs.onSurface,
                          ),
                          _ScheduleMetricColumn(
                            label: t.iqamahLabel,
                            value: DailyPrayerData.format12Hour(iqamahDt),
                            accentColor: cs.primary,
                          ),
                          _ScheduleMetricColumn(
                            label: t.alarmLabel,
                            value: previewAlarmDt != null
                                ? DailyPrayerData.format12Hour(previewAlarmDt)
                                : t.alarmOffLabel,
                            accentColor: previewAlarmDt != null
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Iqamah Gap Stepper
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.iqamahGapLabel,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '+$iqamahGap ${t.minutesUnitShort} (max ${slot.maxAllowedIqamahGap}${t.minutesUnitShort})',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StepperChipButton(
                          icon: Icons.remove_rounded,
                          tooltip: '-1',
                          onTap: iqamahGap > 0
                              ? () => setSheetState(() => iqamahGap -= 1)
                              : null,
                        ),
                        SizedBox(
                          width: 56,
                          child: Text(
                            '+$iqamahGap${t.minutesUnitShort}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ),
                        _StepperChipButton(
                          icon: Icons.add_rounded,
                          tooltip: '+1',
                          onTap: iqamahGap < slot.maxAllowedIqamahGap
                              ? () => setSheetState(() => iqamahGap += 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [5, 10, 15, 20, 30]
                          .where((v) => v <= slot.maxAllowedIqamahGap)
                          .map((presetMin) {
                        final selected = iqamahGap == presetMin;
                        return ChoiceChip(
                          label: Text('+$presetMin${t.minutesUnitShort}'),
                          selected: selected,
                          onSelected: (_) =>
                              setSheetState(() => iqamahGap = presetMin),
                        );
                      }).toList(),
                    ),

                    const Divider(height: 24),

                    // Per-Prayer Alarm Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${_prayerName(slot.prayerKey, t)} ${t.alarmLabel}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      value: enabled,
                      onChanged: (v) => setSheetState(() => enabled = v),
                    ),

                    if (enabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        t.alarmRefLabel,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<PrayerAlarmRef>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: PrayerAlarmRef.beforeAdhan,
                              label: Text(
                                t.beforeAdhanOption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            ButtonSegment(
                              value: PrayerAlarmRef.relativeToIqamah,
                              label: Text(
                                t.relativeToIqamahOption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          selected: {alarmRef},
                          onSelectionChanged: (sel) {
                            setSheetState(() {
                              alarmRef = sel.first;
                              if (alarmRef == PrayerAlarmRef.beforeAdhan) {
                                alarmOffset = 10;
                              } else {
                                alarmOffset = -5.clamp(
                                  minIqamahOffset,
                                  maxIqamahOffset,
                                );
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alarmRef == PrayerAlarmRef.beforeAdhan
                                  ? t.minutesBeforeLabel
                                  : t.offsetFromIqamahLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          _StepperChipButton(
                            icon: Icons.remove_rounded,
                            tooltip: '-1',
                            onTap: (alarmRef == PrayerAlarmRef.beforeAdhan
                                    ? alarmOffset > 0
                                    : alarmOffset > minIqamahOffset)
                                ? () => setSheetState(() => alarmOffset -= 1)
                                : null,
                          ),
                          SizedBox(
                            width: 74,
                            child: Text(
                              offsetHuman,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: cs.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                          _StepperChipButton(
                            icon: Icons.add_rounded,
                            tooltip: '+1',
                            onTap: (alarmRef == PrayerAlarmRef.beforeAdhan
                                    ? alarmOffset < 120
                                    : alarmOffset < maxIqamahOffset)
                                ? () => setSheetState(() => alarmOffset += 1)
                                : null,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Safety limit notice box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.safetyBufferNote(
                                nextBoundaryName,
                                limitFormatted,
                              ),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(t.cancelLabel),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final nextCfg = PrayerAlarmConfig(
                                prayerKey: slot.prayerKey,
                                enabled: enabled,
                                iqamahGapMinutes: iqamahGap,
                                alarmRef: alarmRef,
                                alarmOffsetMinutes: alarmOffset,
                              );
                              final latest = ref.read(settingsProvider);
                              await ref.read(settingsProvider.notifier).update(
                                    latest.copyWithPrayerAlarmConfig(nextCfg),
                                  );
                              if (enabled && !latest.prayerAlarmMasterEnabled) {
                                await ref
                                    .read(prayerAlarmProvider.notifier)
                                    .setMasterAlarmEnabled(true);
                              }
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                              }
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(t.applyLabel),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayerState = ref.watch(prayerTimesProvider);
    final alarmState = ref.watch(prayerAlarmProvider);
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
    final soundOption = AlAdhanCatalog.soundById(settings.alarmSoundType);

    final List<ComputedPrayerSlot> slots = data != null
        ? (alarmState.slots.length == 5
            ? alarmState.slots
            : data.computeDailySlots(
                referenceDay: _now,
                tuneFor: settings.tuneFor,
                configs: settings.prayerConfigs,
                masterAlarmEnabled: settings.prayerAlarmMasterEnabled,
                dismissedTodayKeys: alarmState.dismissedTodayKeys,
              ))
        : const [];

    final showKahfBanner = ref.watch(kahfBannerVisibleProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
      children: [
        if (showKahfBanner && widget.onOpenSurah != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.kahfBannerTitle,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.kahfBannerDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () => widget.onOpenSurah!(18),
                  child: Text(t.kahfOpenSurahBtn),
                ),
                IconButton(
                  tooltip: t.closeLabel,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => ref
                      .read(kahfBannerVisibleProvider.notifier)
                      .dismissForToday(),
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],

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

        const SizedBox(height: 12),

        // Master Prayer Alarm & Sound Quick Control Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: settings.prayerAlarmMasterEnabled
                ? cs.primaryContainer.withValues(alpha: 0.38)
                : palette.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: settings.prayerAlarmMasterEnabled
                  ? cs.primary.withValues(alpha: 0.5)
                  : palette.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                settings.prayerAlarmMasterEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                color: settings.prayerAlarmMasterEnabled
                    ? cs.primary
                    : cs.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.prayerAlarmsTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      soundOption.displayName(settings.appLanguage),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: t.alarmSoundSettings,
                onPressed: () => showPrayerAlarmSoundSheet(context, ref, t),
                icon: Icon(Icons.graphic_eq_rounded, color: cs.primary),
              ),
              Switch(
                value: settings.prayerAlarmMasterEnabled,
                onChanged: (v) => ref
                    .read(prayerAlarmProvider.notifier)
                    .setMasterAlarmEnabled(v),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Prayer Schedule Cards (Adhan, Iqamah, Alarm) or Loading/Error
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
          // Build chronological cards: Fajr, Sunrise strip, Dhuhr, Asr, Maghrib, Isha
          ...slots.expand((slot) {
            final isNext = nextInfo != null &&
                nextInfo.key == slot.prayerKey &&
                nextInfo.time.day == _now.day;
            final label = _prayerName(slot.prayerKey, t);
            final icon = _prayerIcon(slot.prayerKey);
            final cfg = settings.alarmConfigFor(slot.prayerKey);

            final String alarmText;
            final Color alarmColor;
            if (!settings.prayerAlarmMasterEnabled ||
                !slot.prayerAlarmEnabled ||
                slot.alarmTime == null) {
              alarmText = t.alarmOffLabel;
              alarmColor = cs.onSurfaceVariant;
            } else if (slot.dismissedToday) {
              alarmText = t.dismissedTodayLabel;
              alarmColor = AppBranding.accentGold;
            } else {
              alarmText = DailyPrayerData.format12Hour(slot.alarmTime!);
              alarmColor = cs.primary;
            }

            final cardWidget = Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isNext
                    ? cs.primaryContainer.withValues(alpha: 0.45)
                    : palette.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isNext ? cs.primary : palette.cardBorder,
                  width: isNext ? 1.5 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openSlotEditor(slot),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 11, 10, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              icon,
                              size: 20,
                              color: isNext ? cs.primary : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: isNext
                                          ? FontWeight.w800
                                          : FontWeight.w700,
                                      color:
                                          isNext ? cs.primary : cs.onSurface,
                                    ),
                                  ),
                                  if (slot.tuneMinutes != 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      slot.tuneMinutes > 0
                                          ? '+${slot.tuneMinutes}m'
                                          : '${slot.tuneMinutes}m',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: t.editScheduleLabel,
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _openSlotEditor(slot),
                              icon: Icon(
                                Icons.tune_rounded,
                                size: 19,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            IconButton(
                              tooltip: '$label ${t.alarmLabel}',
                              visualDensity: VisualDensity.compact,
                              onPressed: () async {
                                final updated = settings.copyWithPrayerAlarmConfig(
                                  cfg.copyWith(enabled: !cfg.enabled),
                                );
                                await ref
                                    .read(settingsProvider.notifier)
                                    .update(updated);
                                if (!cfg.enabled &&
                                    !updated.prayerAlarmMasterEnabled) {
                                  await ref
                                      .read(prayerAlarmProvider.notifier)
                                      .setMasterAlarmEnabled(true);
                                }
                              },
                              icon: Icon(
                                (settings.prayerAlarmMasterEnabled &&
                                        cfg.enabled)
                                    ? Icons.alarm_on_rounded
                                    : Icons.alarm_off_rounded,
                                size: 20,
                                color: (settings.prayerAlarmMasterEnabled &&
                                        cfg.enabled)
                                    ? (slot.dismissedToday
                                        ? AppBranding.accentGold
                                        : cs.primary)
                                    : cs.onSurfaceVariant.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.36),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            children: [
                              _ScheduleMetricColumn(
                                label: t.adhanLabel,
                                value: DailyPrayerData.format12Hour(
                                  slot.adhanTime,
                                ),
                                accentColor: cs.onSurface,
                              ),
                              _ScheduleMetricColumn(
                                label:
                                    '${t.iqamahLabel} (+${slot.effectiveIqamahGap}${t.minutesUnitShort})',
                                value: DailyPrayerData.format12Hour(
                                  slot.iqamahTime,
                                ),
                                accentColor: cs.primary,
                              ),
                              _ScheduleMetricColumn(
                                label: t.alarmLabel,
                                value: alarmText,
                                accentColor: alarmColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            if (slot.prayerKey == 'fajr') {
              final sunriseDt = data.tunedTimeFor('sunrise', 0, _now);
              final sunriseStrip = Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 18,
                      color: AppBranding.accentGold,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.sunriseName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      DailyPrayerData.format12Hour(sunriseDt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppBranding.accentGold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
              return [cardWidget, sunriseStrip];
            }
            return [cardWidget];
          }),

          const SizedBox(height: 4),

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

          const SizedBox(height: 14),

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

class _ScheduleMetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _ScheduleMetricColumn({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. HIJRI-MONTH-FIRST CALENDAR VIEW (Large Hijri Day + Small English Date)
// ---------------------------------------------------------------------------
class HijriCalendarView extends ConsumerWidget {
  const HijriCalendarView({super.key});

  static const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static const _fullGregMonths = [
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

  static const _shortGregMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

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
    final hijriMonthPrimary = cal.days.isNotEmpty
        ? (t.lang == 'ar'
            ? cal.days.first.hijriMonthAr
            : cal.days.first.hijriMonthEn)
        : HijriMonthCatalog.monthName(cal.hijriMonth, settings.appLanguage);
    final hijriMonthArabic = cal.days.isNotEmpty
        ? cal.days.first.hijriMonthAr
        : HijriMonthCatalog.monthName(cal.hijriMonth, 'ar');

    String gregorianSpan = '';
    if (cal.days.isNotEmpty) {
      final first = cal.days.first;
      final last = cal.days.last;
      final fm = _shortGregMonths[(first.gregorianMonth - 1).clamp(0, 11)];
      final lm = _shortGregMonths[(last.gregorianMonth - 1).clamp(0, 11)];
      if (first.gregorianYear == last.gregorianYear) {
        gregorianSpan = fm == lm
            ? '$fm ${first.gregorianYear}'
            : '$fm – $lm ${last.gregorianYear}';
      } else {
        gregorianSpan =
            '$fm ${first.gregorianYear} – $lm ${last.gregorianYear}';
      }
    }

    // Offset blank cells before Hijri Day 1 based on its Gregorian weekday (Sun=0..Sat=6)
    final int firstWeekday = cal.days.isNotEmpty
        ? (cal.days.first.gregorianDate.weekday % 7)
        : 0;

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
        // Hijri Month Navigation Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      '$hijriMonthPrimary ${cal.hijriYear} AH',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gregorianSpan.isEmpty
                          ? hijriMonthArabic
                          : '$hijriMonthArabic  •  $gregorianSpan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

        // Hijri Calendar Grid Card (Large Hijri Day + Small English Date below)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            children: [
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
                        onPressed: () => notifier.loadHijriMonth(
                          cal.hijriYear,
                          cal.hijriMonth,
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
                    childAspectRatio: 0.86,
                  ),
                  itemCount: firstWeekday + cal.days.length,
                  itemBuilder: (_, idx) {
                    if (idx < firstWeekday) {
                      return const SizedBox.shrink();
                    }
                    final dayIndex = idx - firstWeekday;
                    final dayEntry = cal.days[dayIndex];
                    final gDate = dayEntry.gregorianDate;
                    final isToday = gDate.year == now.year &&
                        gDate.month == now.month &&
                        gDate.day == now.day;
                    final isSelected = gDate.year == cal.selectedDate.year &&
                        gDate.month == cal.selectedDate.month &&
                        gDate.day == cal.selectedDate.day;
                    final isFriday = gDate.weekday == DateTime.friday;
                    final hasHoliday = dayEntry.holidays.isNotEmpty;

                    final showGregMonth =
                        dayIndex == 0 || dayEntry.gregorianDay == 1;
                    final smallEnglishText = showGregMonth
                        ? dayEntry.shortGregorianLabel
                        : '${dayEntry.gregorianDay}';

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
                            vertical: 3,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${dayEntry.hijriDay}',
                                    style: TextStyle(
                                      fontSize: 16.5,
                                      height: 1.05,
                                      fontWeight: FontWeight.w800,
                                      color: isToday
                                          ? Colors.white
                                          : cs.onSurface,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  if (hasHoliday) ...[
                                    const SizedBox(width: 2),
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: isToday
                                            ? Colors.white
                                            : AppBranding.accentGold,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  smallEnglishText,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: showGregMonth
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isToday
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : (showGregMonth
                                            ? cs.primary
                                            : cs.onSurfaceVariant),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${selectedEntry.hijriDay}',
                    style: GoogleFonts.amiri(
                      fontSize: 24,
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
                        '${selectedEntry.weekdayEn}, ${selectedEntry.gregorianDay} ${_fullGregMonths[(selectedEntry.gregorianMonth - 1).clamp(0, 11)]} ${selectedEntry.gregorianYear}',
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

        // Hijri Moon Sighting Offset (-1 / 0 / +1)
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
