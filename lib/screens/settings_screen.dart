import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';
import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import '../providers/audio_provider.dart';
import '../providers/islamic_features_providers.dart';
import '../providers/quran_providers.dart';
import '../providers/update_provider.dart';
import '../services/prayer_alarm_bridge.dart';
import '../widgets/quick_reader_controls.dart';
import '../widgets/web_pwa_widgets.dart';
import 'features_views.dart';

enum SettingsScope { quran, features, ibadah, all }

/// Modular Ibadah & Salah Guide display toggles (Arabic-only default + study aids).
class IbadahSettingsSection extends ConsumerWidget {
  const IbadahSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.ibadahSettingsDesc,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.malayalamHeadingsSetting,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          subtitle: Text(
            t.malayalamHeadingsDesc,
            style: const TextStyle(fontSize: 11.5),
          ),
          value: settings.ibadahMalayalamHeadings,
          onChanged: (v) => notifier.updateWith(
            (cur) => cur.copyWith(ibadahMalayalamHeadings: v),
          ),
        ),
        const Divider(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.showTransliterationSetting,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          value: settings.ibadahShowTransliteration,
          onChanged: (v) => notifier.updateWith(
            (cur) => cur.copyWith(ibadahShowTransliteration: v),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.showMeaningSetting,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          value: settings.ibadahShowMeaning,
          onChanged: (v) => notifier.updateWith(
            (cur) => cur.copyWith(ibadahShowMeaning: v),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.showNotesSetting,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          value: settings.ibadahShowNotes,
          onChanged: (v) => notifier.updateWith(
            (cur) => cur.copyWith(ibadahShowNotes: v),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.showAudioSetting,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          ),
          value: settings.ibadahShowAudio,
          onChanged: (v) => notifier.updateWith(
            (cur) => cur.copyWith(ibadahShowAudio: v),
          ),
        ),
      ],
    );
  }
}

/// Modular Quran Reader & Display Preferences section.
class QuranSettingsSection extends ConsumerWidget {
  const QuranSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Reading Mode
        Text(
          t.readingMode,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'mushaf',
                icon: const Icon(Icons.menu_book_rounded, size: 16),
                label: Text(
                  t.modeMushaf,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              ButtonSegment(
                value: 'verse',
                icon: const Icon(Icons.view_agenda_outlined, size: 16),
                label: Text(
                  t.modeVerse,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
            selected: {settings.readingMode},
            onSelectionChanged: (s) =>
                notifier.updateWith((cur) => cur.copyWith(readingMode: s.first)),
          ),
        ),

        const SizedBox(height: 16),

        // 2. Reading Theme
        Text(
          t.readingTheme,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'light',
                label: Text(
                  t.themeLight,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              ButtonSegment(
                value: 'sepia',
                label: Text(
                  t.themeSepia,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              ButtonSegment(
                value: 'dark',
                label: Text(
                  t.themeDark,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) =>
                notifier.updateWith((cur) => cur.copyWith(themeMode: s.first)),
          ),
        ),

        const SizedBox(height: 16),

        // 3. App Language
        Text(
          t.appLanguage,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: 'en',
                label: Text('English', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'ml',
                label: Text('മലയാളം', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'ar',
                label: Text('العربية', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {settings.appLanguage},
            onSelectionChanged: (s) =>
                notifier.updateWith((cur) => cur.copyWith(appLanguage: s.first)),
          ),
        ),

        const Divider(height: 26),

        // 4. Reciter Dropdown Selection (Al Quran Cloud / EveryAyah)
        Text(
          t.reciter,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            prefixIcon: Icon(
              Icons.graphic_eq_rounded,
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
              value: ApiConfig.reciterById(settings.reciterId).id,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(12),
              items: ApiConfig.reciters.map((reciter) {
                return DropdownMenuItem<String>(
                  value: reciter.id,
                  child: Text(
                    reciter.displayName(settings.appLanguage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                notifier.updateWith((cur) => cur.copyWith(reciterId: val));
                ref.read(quranAudioProvider.notifier).onReciterChanged(val);
              },
            ),
          ),
        ),

        const Divider(height: 24),

        // 5. Translation Toggle + Multi-Language Chips
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            t.showTranslation,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            t.showTranslationDesc,
            style: const TextStyle(fontSize: 12),
          ),
          value: settings.showTranslation,
          onChanged: (val) => notifier.updateWith(
            (cur) => cur.copyWith(showTranslation: val),
          ),
        ),
        if (settings.showTranslation) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              FilterChip(
                label: Text(t.langEnglish),
                selected: settings.selectedTranslations.contains('en'),
                onSelected: (_) => notifier.toggleTranslationLang('en'),
              ),
              FilterChip(
                label: Text(t.langMalayalam),
                selected: settings.selectedTranslations.contains('ml'),
                onSelected: (_) => notifier.toggleTranslationLang('ml'),
              ),
              FilterChip(
                label: Text(t.langArabicTafsir),
                selected: settings.selectedTranslations.contains('ar'),
                onSelected: (_) => notifier.toggleTranslationLang('ar'),
              ),
            ],
          ),
        ],

        const Divider(height: 26),

        // 6. Reset Floating Button Position
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.restart_alt_rounded, size: 18),
            label: Text(
              t.resetButtonPos,
              style: const TextStyle(fontSize: 13),
            ),
            onPressed: () {
              notifier.updateWith((cur) => cur.copyWith(clearFabPos: true));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.done),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ),

        const Divider(height: 24),

        // 7. Interactive Speed & Font Size Controls
        Text(
          t.floatingControlsTipTitle,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 10),
        const QuickReaderControls(compact: true),
      ],
    );
  }
}

/// Modular Prayer Times, Alarms & Hijri Calendar Settings section.
class FeaturesSettingsSection extends ConsumerWidget {
  const FeaturesSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final prayerState = ref.watch(prayerTimesProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Location & GPS / City Switcher
        Text(
          t.locationLabel,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Icon(
                settings.prayerLocationMode == 'gps'
                    ? Icons.my_location_rounded
                    : Icons.location_on_rounded,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  settings.displayLocationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
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
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: Text(
                  prayerState.isFetchingGps ? t.gpsFetching : t.useGps,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showPrayerLocationPickerSheet(context, ref, t),
                icon: const Icon(Icons.edit_location_alt_rounded, size: 16),
                label: Text(
                  t.changeCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ),
          ],
        ),

        const Divider(height: 24),

        // 2. Calculation Method Dropdown (Default: Karachi UISK = 1)
        Text(
          t.calculationMethod,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            prefixIcon: Icon(
              Icons.calculate_outlined,
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
            child: DropdownButton<int>(
              value: AlAdhanCatalog.methodById(settings.prayerMethod).id,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(12),
              items: AlAdhanCatalog.methods.map((method) {
                return DropdownMenuItem<int>(
                  value: method.id,
                  child: Text(
                    method.displayName(settings.appLanguage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                notifier.updateWith((cur) => cur.copyWith(prayerMethod: val));
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 3. Asr Juristic School (0: Shafi / Standard, 1: Hanafi)
        Text(
          t.asrSchool,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 0,
                label: Text(
                  t.schoolShafi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
              ButtonSegment(
                value: 1,
                label: Text(
                  t.schoolHanafi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
            selected: {settings.prayerSchool},
            onSelectionChanged: (s) =>
                notifier.updateWith((cur) => cur.copyWith(prayerSchool: s.first)),
          ),
        ),

        const Divider(height: 24),

        // 4. Prayer Alarm & Sound Controls
        Text(
          t.alarmSoundSettings,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        const PrayerAlarmSoundControls(compact: true),

        const Divider(height: 24),

        // 4b. Auto-Silent (DND) during Prayer
        const PrayerAutoSilentSection(compact: true),

        const Divider(height: 24),

        // 5. Masjid Time Tune (+/- minutes per prayer)
        const PrayerTuneControlList(compact: true),

        const Divider(height: 24),

        // 6. Hijri Moon Sighting Offset (-1 / 0 / +1)
        const HijriAdjustmentControl(compact: true),

        const Divider(height: 24),

        // 7. Weekly Surah Al-Kahf Reminder (Thursday Night & Friday Morning)
        Row(
          children: [
            Icon(Icons.auto_stories_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.kahfReminderTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          t.kahfReminderDesc,
          style: TextStyle(
            fontSize: 11.5,
            color: cs.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 6),
        _KahfScheduleRow(
          label: t.kahfThuLabel,
          enabled: settings.kahfThursdayEnabled,
          hour: settings.kahfThuHour,
          minute: settings.kahfThuMinute,
          onToggle: (v) => notifier.updateWith(
            (cur) => cur.copyWith(kahfThursdayEnabled: v),
          ),
          onPickTime: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: settings.kahfThuHour,
                minute: settings.kahfThuMinute,
              ),
            );
            if (picked != null) {
              await notifier.updateWith(
                (cur) => cur.copyWith(
                  kahfThuHour: picked.hour,
                  kahfThuMinute: picked.minute,
                ),
              );
            }
          },
        ),
        _KahfScheduleRow(
          label: t.kahfFriLabel,
          enabled: settings.kahfFridayEnabled,
          hour: settings.kahfFriHour,
          minute: settings.kahfFriMinute,
          onToggle: (v) => notifier.updateWith(
            (cur) => cur.copyWith(kahfFridayEnabled: v),
          ),
          onPickTime: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: settings.kahfFriHour,
                minute: settings.kahfFriMinute,
              ),
            );
            if (picked != null) {
              await notifier.updateWith(
                (cur) => cur.copyWith(
                  kahfFriHour: picked.hour,
                  kahfFriMinute: picked.minute,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 6),
        FilledButton.tonalIcon(
          onPressed: () async {
            if (PrayerAlarmBridge.instance.isNativeAndroid) {
              await PrayerAlarmBridge.instance.requestAlarmPermissions();
              await PrayerAlarmBridge.instance
                  .testKahfNotification(strings: t);
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.kahfTestWebFeedback),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          icon: const Icon(Icons.notifications_active_outlined, size: 18),
          label: Text(t.testKahfReminder),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const Divider(height: 24),

        // 8. Android Home Screen Widget Setup Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.widgets_outlined, size: 20, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.homeWidgetTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      t.homeWidgetDesc,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KahfScheduleRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final int hour;
  final int minute;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  const _KahfScheduleRow({
    required this.label,
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.onToggle,
    required this.onPickTime,
  });

  String _formatTime() {
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final min = minute.toString().padLeft(2, '0');
    return '$h12:$min $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          onPressed: enabled ? onPickTime : null,
          child: Text(
            _formatTime(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: enabled ? cs.primary : cs.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Switch(
          value: enabled,
          onChanged: onToggle,
        ),
      ],
    );
  }
}

class _AppBrandFooterCard extends ConsumerWidget {
  final AppStrings strings;

  const _AppBrandFooterCard({required this.strings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              AppBranding.logoAsset,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.appTitle,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${AppBranding.appTagline} • v${updateState.currentVersion} (#${updateState.currentBuildNumber})',
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
        ],
      ),
    );
  }
}

/// Contextual slide-in side panel (endDrawer) mounted on Home & Reader screens.
class CompactSettingsDrawer extends ConsumerWidget {
  final SettingsScope scope;

  const CompactSettingsDrawer({
    super.key,
    this.scope = SettingsScope.quran,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final drawerWidth =
        math.min(MediaQuery.sizeOf(context).width * 0.85, 344.0);

    final String title;
    switch (scope) {
      case SettingsScope.quran:
        title = t.quranSettingsTitle;
      case SettingsScope.features:
        title = t.featuresSettingsTitle;
      case SettingsScope.ibadah:
        title = t.ibadahSettingsTitle;
      case SettingsScope.all:
        title = t.settings;
    }

    return Directionality(
      textDirection: t.textDirection,
      child: Drawer(
        width: drawerWidth,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.only(
            topStart: Radius.circular(20),
            bottomStart: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Compact Drawer Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 22, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: t.done,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Contextual Controls
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                  children: [
                    if (scope == SettingsScope.quran ||
                        scope == SettingsScope.all)
                      const QuranSettingsSection(),
                    if (scope == SettingsScope.all) const Divider(height: 30),
                    if (scope == SettingsScope.features ||
                        scope == SettingsScope.all)
                      const FeaturesSettingsSection(),
                    if (scope == SettingsScope.ibadah)
                      const IbadahSettingsSection(),
                    if (scope == SettingsScope.all) ...[
                      const Divider(height: 30),
                      const IbadahSettingsSection(),
                    ],
                    const Divider(height: 28),
                    DrawerBottomAppActions(strings: t),
                    const SizedBox(height: 12),
                    _AppBrandFooterCard(strings: t),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full Settings Page mounted as the 3rd primary bottom navigation tab.
class SettingsTabView extends ConsumerWidget {
  const SettingsTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';
    final cardBg = isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white);
    final cardBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6));
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 860) / 2);

    return ListView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 32),
      children: [
        // 1. Quran Settings Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.quranSettingsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              const QuranSettingsSection(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Features Settings Card (Prayer Times, Alarms & Hijri Calendar)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.mosque_rounded, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    t.featuresSettingsTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              const FeaturesSettingsSection(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Ibadah Display Settings Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: cs.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.ibadahSettingsTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              const IbadahSettingsSection(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. App Updates, Install / APK Download, Share & Version Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DrawerBottomAppActions(strings: t),
              const SizedBox(height: 12),
              _AppBrandFooterCard(strings: t),
            ],
          ),
        ),
      ],
    );
  }
}
