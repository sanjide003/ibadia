import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/api_config.dart';
import '../core/config/app_branding.dart';
import '../providers/audio_provider.dart';
import '../providers/quran_providers.dart';
import '../providers/update_provider.dart';
import '../widgets/quick_reader_controls.dart';
import '../widgets/web_pwa_widgets.dart';

/// Compact slide-in side panel (endDrawer) mounted on both Home & Reader screens.
class CompactSettingsDrawer extends ConsumerWidget {
  const CompactSettingsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);
    final updateState = ref.watch(updateProvider);
    final cs = Theme.of(context).colorScheme;
    final drawerWidth =
        math.min(MediaQuery.sizeOf(context).width * 0.85, 336.0);

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
                        t.settings,
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

              // Compact Controls
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
                            icon: const Icon(Icons.view_agenda_outlined,
                                size: 16),
                            label: Text(
                              t.modeVerse,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ),
                        ],
                        selected: {settings.readingMode},
                        onSelectionChanged: (s) => notifier
                            .update(settings.copyWith(readingMode: s.first)),
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
                            notifier.update(settings.copyWith(themeMode: s.first)),
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
                        onSelectionChanged: (s) => notifier
                            .update(settings.copyWith(appLanguage: s.first)),
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
                            notifier.update(settings.copyWith(reciterId: val));
                            ref
                                .read(quranAudioProvider.notifier)
                                .onReciterChanged(val);
                          },
                        ),
                      ),
                    ),

                    const Divider(height: 24),

                    // 4. Translation Toggle + Multi-Language Chips
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
                      onChanged: (val) => notifier
                          .update(settings.copyWith(showTranslation: val)),
                    ),
                    if (settings.showTranslation) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: Text(t.langEnglish),
                            selected:
                                settings.selectedTranslations.contains('en'),
                            onSelected: (_) =>
                                notifier.toggleTranslationLang('en'),
                          ),
                          FilterChip(
                            label: Text(t.langMalayalam),
                            selected:
                                settings.selectedTranslations.contains('ml'),
                            onSelected: (_) =>
                                notifier.toggleTranslationLang('ml'),
                          ),
                          FilterChip(
                            label: Text(t.langArabicTafsir),
                            selected:
                                settings.selectedTranslations.contains('ar'),
                            onSelected: (_) =>
                                notifier.toggleTranslationLang('ar'),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 26),

                    // 5. Reset Floating Button Position
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        icon: const Icon(Icons.restart_alt_rounded, size: 18),
                        label: Text(
                          t.resetButtonPos,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onPressed: () {
                          notifier.update(settings.copyWith(clearFabPos: true));
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

                    // 6. Interactive Speed & Font Size Controls
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

                    const Divider(height: 28),

                    // Bottom App Actions (Install / Download APK / Share App)
                    DrawerBottomAppActions(strings: t),
                    const SizedBox(height: 12),

                    // Bottom Brand Footer Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
                                  t.appTitle,
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
                    ),
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
