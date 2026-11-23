# Ibadia (ഇബാദിയ / عبادية)

Modern offline-first Islamic companion & Quran application built with **Flutter** (Android APK + Web PWA, Hive CE offline persistence, and Riverpod), including a companion **Next.js** web codebase in `src/` and native Kotlin Android alarm, DND, and home-screen widget support (`android_config/MainActivity.kt`).

## Key Features

- **3-Tab Navigation**: Clean bottom navigation bar with **Home**, **Quran**, and **Settings**.
  - **Quran Tab** provides `Surah | Juz | Bookmarks | Export` directly at the top with scroll-position restoration.
  - **Home Tab** displays the localized brand header (`Ibadia` / `ഇബാദിയ` / `عبادية`), universal search, live Next Prayer & Last-Read hero cards, Recent Activity chips, daily Name/Tajweed highlights, and feature launcher tiles.
  - **Isolated Feature Views**: Tapping **Prayer Times & Auto-Silent DND**, **Hijri Calendar**, **Adhkar & Duas**, **Digital Tasbih**, **99 Names of Allah**, **Export PDF / PNG**, or **Tajweed Guide** opens each feature cleanly with Back-to-Home navigation.
- **99 Names of Allah (Asmaul Husna) Dual View**:
  - **3-Column RTL Arabic Calligraphy Grid** with detail sheet (transliteration, English/Malayalam/Arabic meanings, reflection, and studied tracker `N / 99`).
  - **Searchable Detailed List** for instant lookup.
- **Quran Reader & Audio (`lib/screens/surah_reader_screen.dart`)**:
  - **Mushaf Page View** & **Verse List View**, bi-directional continuous Surah scrolling, viewport anchor auto-save, interactive Tajweed color-coding (`lib/services/tajweed_engine.dart` & `lib/widgets/tajweed_widgets.dart`), multi-language translations (`Malayalam`, `English`, `Arabic Tafsir`), draggable auto-scroll controls, and Ayah-by-Ayah recitation player (`lib/providers/audio_provider.dart`).
- **Ibadah & Salah Complete Guide (`lib/screens/ibadah_guide_screen.dart`)**:
  - 100% offline Kerala-standard **Shafi'i Fiqh** companion backed by bundled JSON datasets (`assets/data/ibadah/niyyah.json`, `salah_guide.json`, `sunnah_and_surahs.json`, `mayyith_guide.json`) and a shared single-stream offline audio controller (`lib/services/ibadah_audio_controller.dart`).
  - **4 Focused Modules**: **Niyyah** (5 Fard with *Munfarid / Imam / Ma'moom* + 11 major Sunnah prayers), **Salah Guide** (persistent Hive Shart checklist, 13 Arkan pillars, and 14 sequential steps from *Takbiratul Ihram* to *Salam*), **Rawatib & Recommended Surahs** (with one-tap deep link into `SurahReaderScreen`), and **Mayyith Guide** (*Ihtidar*, *Ghusl*, *Kafan*, 4 funeral Niyyahs, 4 Takbirs, and *Dafn* + *Talqeen*).
  - Optional MP3 recordings placed in `assets/audio/ibadah/` matching each `audioPath` play automatically offline; missing files fall back gracefully with a localized notice.
- **Prayer Times, Hijri Calendar, Home Widget & Android Auto-Silent DND**:
  - Live countdown, GPS or quick city presets, per-prayer Iqamah & alarm configuration, Hijri moon adjustment (`-1/0/+1`), Android home-screen widget sync (`com.ibadia.ibadia.PrayerHomeWidgetProvider`), and native Android `PrayerAlarmController` (`com.ibadia.ibadia`).
- **PDF & PNG Export (`lib/screens/export_screen.dart` & `lib/services/export_service.dart`)**:
  - Export Ayah ranges, full Surahs, or full Juz as print-ready PDFs or shareable PNG cards with auto-saved preferences.
- **Instant Auto-Save**: Reader settings, theme (`Light`, `Sepia`, `Dark`), language (`EN`, `ML`, `AR`), bookmarks, Tasbih counts, Adhkar progress, and Ibadah Shart checklist state persist cleanly to Hive CE (`lib/services/hive_db.dart`).

## Flutter Development & Build

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter build apk --release
flutter build web --release
```

Automated Android APK releases are built via `.github/workflows/android-build.yml` (`--org com.ibadia`, package ID `com.ibadia.ibadia`, output `Ibadia.apk`).
