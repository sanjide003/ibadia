import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quran_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final t = ref.watch(stringsProvider);

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(t.settings),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Reading Mode: Mushaf Page View vs Verse List View
            Text(
              t.readingMode,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'mushaf',
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: Text(t.modeMushaf),
                ),
                ButtonSegment(
                  value: 'verse',
                  icon: const Icon(Icons.view_agenda_outlined, size: 18),
                  label: Text(t.modeVerse),
                ),
              ],
              selected: {settings.readingMode},
              onSelectionChanged: (s) =>
                  notifier.update(settings.copyWith(readingMode: s.first)),
            ),

            const Divider(height: 30),

            // 2. App Language Switcher (Default: English, plus Malayalam & Arabic)
            Text(
              t.appLanguage,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'en', label: Text('English')),
                ButtonSegment(value: 'ml', label: Text('മലയാളം')),
                ButtonSegment(value: 'ar', label: Text('العربية')),
              ],
              selected: {settings.appLanguage},
              onSelectionChanged: (s) =>
                  notifier.update(settings.copyWith(appLanguage: s.first)),
            ),

            const Divider(height: 30),

            // 3. Translation Toggle + Multi-Language Selection
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                t.showTranslation,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(t.showTranslationDesc),
              value: settings.showTranslation,
              onChanged: (val) =>
                  notifier.update(settings.copyWith(showTranslation: val)),
            ),
            if (settings.showTranslation) ...[
              const SizedBox(height: 6),
              Text(
                t.translationLanguages,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.langEnglish),
                value: settings.selectedTranslations.contains('en'),
                onChanged: (_) => notifier.toggleTranslationLang('en'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.langMalayalam),
                value: settings.selectedTranslations.contains('ml'),
                onChanged: (_) => notifier.toggleTranslationLang('ml'),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.langArabicTafsir),
                value: settings.selectedTranslations.contains('ar'),
                onChanged: (_) => notifier.toggleTranslationLang('ar'),
              ),
            ],

            const Divider(height: 30),

            // 4. Auto-Scroll Speed & Floating Button Reset
            Text(
              '${t.autoScrollSpeed}: ${settings.autoScrollSpeed.toStringAsFixed(1)}x',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            Slider(
              min: 0.5,
              max: 4.0,
              divisions: 7,
              value: settings.autoScrollSpeed,
              onChanged: (v) =>
                  notifier.update(settings.copyWith(autoScrollSpeed: v)),
            ),
            Text(
              t.autoScrollHint,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: Text(t.resetButtonPos),
                onPressed: () =>
                    notifier.update(settings.copyWith(clearFabPos: true)),
              ),
            ),

            const Divider(height: 30),

            // 5. Reading Theme
            Text(
              t.readingTheme,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'light', label: Text(t.themeLight)),
                ButtonSegment(value: 'sepia', label: Text(t.themeSepia)),
                ButtonSegment(value: 'dark', label: Text(t.themeDark)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) =>
                  notifier.update(settings.copyWith(themeMode: s.first)),
            ),

            const SizedBox(height: 22),

            // 6. Font Sizes
            Text(
              '${t.arabicFontSize}: ${settings.arabicFontSize.round()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              min: 20,
              max: 44,
              value: settings.arabicFontSize,
              onChanged: (v) =>
                  notifier.update(settings.copyWith(arabicFontSize: v)),
            ),
            const SizedBox(height: 6),
            Text(
              '${t.translationFontSize}: ${settings.translationFontSize.round()}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              min: 13,
              max: 24,
              value: settings.translationFontSize,
              onChanged: (v) =>
                  notifier.update(settings.copyWith(translationFontSize: v)),
            ),
          ],
        ),
      ),
    );
  }
}
