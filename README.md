# Ibadia (ഇബാദിയ / عبادية)

Modern offline-first Islamic companion & Quran web application built with **Next.js (App Router, TypeScript, Tailwind CSS v4)**, plus companion Android APK native alarm & Auto-Silent (DND) support.

## Key Features

- **3-Tab Navigation**: Clean bottom bar with **Home**, **Quran**, and **Settings**.
  - **Quran Tab** hides the top app branding bar so `Surah | Juz | Bookmarks` starts cleanly at the top.
  - **Home Tab** displays the localized brand header (`Ibadia` / `ഇബാദിയ` / `عبادية`), universal search, live Next Prayer & Last-Read hero cards, Recent Activity chips, and single-feature launcher tiles.
  - **Isolated Feature Views**: Tapping **Prayer Times & Auto-Silent DND**, **Hijri Calendar**, **Adhkar & Duas**, **Digital Tasbih**, **99 Names of Allah**, **Export PDF / PNG**, or **Tajweed Guide** opens that feature cleanly on its own with a Back-to-Home action.
- **99 Names of Allah (Asmaul Husna) Dual View**:
  - **3-Column RTL Arabic Calligraphy Grid**: Tap any Arabic name cell to view full transliteration, English/Malayalam/Arabic meanings, reflection, and studied tracker (`N / 99`).
  - **Searchable Detailed List**: View names alongside meanings directly.
- **Quran Reader & Audio**:
  - **Mushaf Page View** & **Verse List View**, bi-directional continuous Surah scrolling, anchor auto-save (`localStorage` + IndexedDB), Tajweed color-coding with interactive rule inspector, multi-language translations (`Malayalam`, `English`, `Arabic Tafsir`), draggable long-press auto-scroll FAB, and IndexedDB-cached Ayah recitation player.
- **Prayer Times, Hijri Calendar & Android Auto-Silent DND**:
  - Live countdown, GPS or quick city presets, per-prayer Iqamah & alarm configuration, Hijri moon adjustment (`-1/0/+1`), and native Android `PrayerAlarmController` integration (`android_config/MainActivity.kt`) with WakeLock-protected DND end receivers and automatic expired-DND reconciliation.
- **Instant Auto-Save**: Every reader setting, theme, language, bookmark, Tasbih count, and Adhkar progress commits synchronously to `localStorage` and flushes on visibility change/unload.

## Development

```bash
npm install
npm run dev
```

Open `http://localhost:3000`.
