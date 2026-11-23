# Ibadia — Complete Flutter App, Web PWA & Android Transformation Plan

Transform **Al-Quran** into **Ibadia** (`ഇബാദിയ` / `عبادية`) directly within the existing **Flutter** codebase (Android APK + Flutter Web/PWA hosted at `https://ibadia.vercel.app`), introducing a streamlined 3-tab **Home / Quran / Settings** architecture, single-feature focused workspaces from Home, a dual-mode 99 Names calligraphy view, guaranteed instant auto-save persistence across all screens, and a permanent native fix for Android's Do Not Disturb (DND) auto-off failure.

---

## User Review & Critical Decisions

> [!IMPORTANT]
> **Please review and approve this Flutter implementation plan before code edits begin.** All four choices you confirmed are locked in below, alongside UI/UX refinements tailored for mobile notches, tablets, and desktop screens.

- **Confirmed Decision 1 — Keep Original Flutter Stack**: All UI, functional, persistence, rebranding, and native Android fixes will be implemented directly inside the existing **Flutter + Riverpod + Hive + Kotlin Native Bridge** codebase so both the **Android APK** and **Flutter Web/PWA** share one unified, fast, offline-cached codebase.
- **Confirmed Decision 2 — 3-Tab Bottom Bar & Conditional Notch-Safe Header**: Bottom navigation is simplified to **Home** (renamed from Dashboard), **Quran**, and **Settings**. The **Ibadia** app name and logo appear in the top bar on **Home** and **Settings**, while the **Quran** tab **completely hides the app name** while preserving safe top spacing below display cutouts/camera punches and keeping the **Settings** button cleanly accessible alongside the sub-tabs.
- **Confirmed Decision 3 — Focused Single-Feature Launches + Dual Access to Bookmarks & Export**: Launching any feature from **Home** opens **only that standalone feature** in a dedicated full-screen workspace (with a Back button to return Home—no horizontal cross-feature tab strip). **Bookmarks** and **Export** remain available inside the **Quran** tab (`Surah | Juz | Bookmarks | Export`) **and** as direct standalone launches from **Home**.
- **Confirmed Decision 4 — 99 Names Dual Mode & Rebrand**: **Asmaul Husna** supports instant switching between a **3-column RTL Arabic-only calligraphy grid** (numeral + Arabic name only; tapping any cell opens the detailed meaning sheet) and the **existing detailed list view**. The app is fully rebranded to **Ibadia** / **ഇബാദിയ** / **عبادية** with shareable web URL `https://ibadia.vercel.app`.

---

## 1. Overview & Core Concept

- **What It Does**: Ibadia delivers a distraction-free offline-cached Quran reader (Mushaf Page View, Verse List View, bi-directional continuous Surah scrolling, Tajweed color-coding with interactive rule sheets, draggable long-press auto-scroll speed button, Ayah audio with reciter selection, and PDF/PNG export) paired with location-aware Prayer Times, Adhan/Iqamah alarms, Auto-Silent (DND), Hijri Calendar, Daily Adhkar, Digital Tasbih, and 99 Names of Allah.
- **Target Audience & Context**: Everyday Muslim readers and worshippers on Android phones (native APK with lock-screen alarms, home-screen widget, and auto-DND) as well as mobile/desktop browser and installed PWA users on `https://ibadia.vercel.app`.
- **Key Value**: Removes the extra Features bottom tab and cross-feature clutter, gives the Quran tab maximum vertical reading room while respecting camera cutouts, eliminates lost settings or unsaved edits, and guarantees Android devices automatically exit Prayer DND mode on schedule.

---

## 2. User Experience & Visual Design

### Navigation & Screen Flow

```text
┌──────────────────────────────────────────────────────────────────────────┐
│  CONDITIONAL TOP BAR (Cutout & Safe-Area Aware)                          │
│  • Home Tab     → [ Ibadia Logo + Ibadia / ഇബാദിയ / عبادية ] + Settings │
│  • Quran Tab    → App Name HIDDEN · Safe top pad for camera cutout +     │
│                   Sub-Tabs [ Surah | Juz | Bookmarks | Export ] + ⚙      │
│  • Settings Tab → [ Ibadia / ഇബാദിയ / عبادية ]                          │
└──────────────────────────────────────────────────────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        ▼                             ▼                             ▼
┌───────────────┐           ┌───────────────────┐           ┌──────────────┐
│     HOME      │           │       QURAN       │           │   SETTINGS   │
│  (Tab 1 of 3) │           │    (Tab 2 of 3)   │           │  (Tab 3 of 3)│
└───────┬───────┘           └─────────┬─────────┘           └──────────────┘
        │                             │
        │ Tap any feature card        ▼
        │ (Opens ONLY that view)  ┌────────────────────────────────────────┐
        ├───────────────┐         │ QURAN READER (Full-screen focused view) │
        ▼               │         │ • Mushaf Page Mode & Verse List Mode   │
┌───────────────┐       │         │ • Bi-directional continuous Surah load │
│ Standalone    │       │         │ • Tajweed rules + interactive sheet    │
│ Feature Route │───────┘         │ • Draggable long-press auto-scroll FAB │
│ (Back → Home) │                 │ • Sticky Ayah audio bar & Qari picker  │
├───────────────┤                 └────────────────────────────────────────┘
│ • Prayer & DND│
│ • Hijri Cal.  │
│ • Adhkar/Duas │
│ • Tasbih      │
│ • 99 Names    │
│ • Bookmarks   │
│ • Export      │
│ • Tajweed Key │
└───────────────┘
```

### Quran Tab Top Bar (No App Name + Camera-Cutout Safe Spacing)

```text
┌────────────────────────────────────────────────────────┐
│  ░░░░░░  SafeArea Top Padding (Status Bar / Camera)    │
├──────────────────────────────────────────────┬─────────┤
│  📖 Surah  │  ▦ Juz  │  🔖 Saved  │  ↗ Export │   [⚙]   │
└──────────────────────────────────────────────┴─────────┘
```

- Removing the app title from the Quran tab reclaims vertical screen space without colliding with punch-hole cameras, notches, or dynamic islands because `SafeArea` top insets keep the sub-tabs and compact Settings gear button cleanly below the system bar.

### 99 Names (Asmaul Husna) Dual-View Concept

```text
┌──────────────────────────────────────────────────────────┐
│  ← Home     99 Names of Allah   [ ▦ Arabic | ≡ Detail ]  │
│  Search (Arabic / Transliteration / Meaning / Number)    │
├──────────────────────────────────────────────────────────┤
│  MODE 1: 3-Column RTL Arabic Calligraphy Grid            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  ٣   الْمَلِكُ │  │  ٢  الرَّحِيمُ │  │  ١  الرَّحْمَٰنُ │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│  (Pure Arabic calligraphy + numeral only; zero meaning   │
│   clutter inside cells)                                  │
├──────────────────────────────────────────────────────────┤
│  Tap any cell ──► Detail Bottom Sheet                    │
│   • Large calligraphic showcase + transliteration        │
│   • Malayalam & English meanings + reflection            │
│   • Copy button + Previous / Next sequential navigation  │
├──────────────────────────────────────────────────────────┤
│  MODE 2: Detailed List / Responsive Card View            │
│  • Existing card layout with number badge,               │
│    transliteration, Malayalam & English meanings,        │
│    and right-aligned Arabic calligraphy                  │
└──────────────────────────────────────────────────────────┘
```

### Visual Identity, Suggestions & Ergonomics

- **Cohesive Emerald & Parchment Palette**:
  - Brand Accents: **Deep Emerald** (`#047857`, `#065F46`, `#064E3B`) and **Warm Amber Gold** (`#D97706`).
  - **Light Mode**: Clean crisp white cards over soft mint-tinted canvas (`#F3F6F4`).
  - **Sepia Mode**: Warm manuscript paper (`#FBF6E9`) with soft ivory cards (`#FFFDF7`) and muted parchment borders (`#E7DEC9`) for comfortable long reading.
  - **Dark Mode**: Deep obsidian-emerald (`#0A0D0C`) with elevated charcoal-emerald surfaces (`#141A17`) and gold accents.
- **Recommended UI/UX Refinements (Beyond Core Prompt)**:
  1. **Unified Top Navigation Consistency on Standalone Features**: Every standalone feature opened from Home (Prayer Times, Hijri Calendar, Adhkar, Tasbih, 99 Names, Standalone Bookmarks, Standalone Export) displays a clean localized header with a single Back button to Home and a subtle contextual settings action (where applicable, e.g., Prayer Settings / Export Theme), keeping users oriented without any cross-feature tab bar.
  2. **Smart Home Tile Cleanup**: Keep the Home floating Prayer Hero card, Continue Reading banner, 3-column quick action grid, Recent Activity strip, and Daily Inspiration cards cleanly organized so every Islamic feature—including Bookmarks and Export—opens smoothly in one tap, and recent activity items open the exact standalone feature or Quran sub-tab accurately.
  3. **In-App Auto-Save Feedback Subtlety**: Ensure sliders, prayer schedule editors, DND toggles, Tasbih counters, and 99 Names view-mode switches persist silently in the background without blocking dialogs, while updating live UI previews immediately.

---

## 3. Key Product Decisions & Trade-Offs

- **Decision 1 — Functional State Updates + Serialized Hive Persistence (Guaranteed Auto-Save)**
  - *Root Cause Found in Existing Code*:
    1. Concurrent `saveSettings()` calls race with each other during rapid interactions (such as dragging font-size or scroll-speed sliders, tapping multiple prayer tune steppers, or toggling chips right after startup) because updates pass a captured `AppSettings` snapshot without a serialized write queue or functional updater.
    2. The per-prayer **Iqamah & Alarm Schedule Editor** currently holds edits in temporary local modal state and discards them if the user swipes down or taps outside the sheet without tapping Save.
    3. Export preferences and the new 99 Names view mode (`grid` vs `list`) are held only in ephemeral widget state and reset on navigation or restart.
  - *Chosen Approach*: Introduce functional `updateWith((current) => ...)` state transitions and a sequential write-coalescing persistence queue in the settings notifier, auto-commit every change inside the Prayer Schedule Editor immediately on tap, persist Export options and 99 Names view mode in Hive, and flush resume/scroll state cleanly on lifecycle pauses and route pops.
  - *Why*: Every change made anywhere in the app takes effect immediately and survives sudden app closures, tab switches, or refreshes with zero manual Save friction.
- **Decision 2 — Permanent Native Android DND Auto-Off Fix**
  - *Root Cause Found in Existing Native Handler*:
    1. **Missing WakeLock in DND End Receiver**: The DND Start Receiver acquires a `PARTIAL_WAKE_LOCK`, whereas the DND End Receiver acquires none—allowing the device CPU to go back to sleep under Doze before restoring normal ringer/DND mode.
    2. **Throttled End Alarms & Zero Stale-State Reconciliation**: DND end alarms currently rely on `setExactAndAllowWhileIdle` (which OEM battery managers and Android Doze frequently delay or drop), while prayer alarms use Doze-exempt `setAlarmClock`. Furthermore, when rescheduling past windows (`+24h`) on app open, boot, or window rollover, the controller **never checks whether the active DND session flag is still stuck `true` outside every configured prayer window**—so a single missed end alarm leaves DND permanently locked on.
    3. **ZenMode vs RingerMode Transition Race**: Calling `setInterruptionFilter(prevFilter)` immediately followed by `AudioManager.setRingerMode(prevRinger)` on Android 10–15 triggers competing OS audio policy transitions that can leave ringer muted or corrupt saved prior state on re-entry.
  - *Chosen Approach*:
    - Acquire and safely release a scoped `PARTIAL_WAKE_LOCK` inside both `PrayerDndStartReceiver` and `PrayerDndEndReceiver`.
    - Schedule the active session's **DND End** boundary with Doze-exempt alarm reliability (`setAlarmClock` fallback-safe when exact alarm is permitted, plus `setExactAndAllowWhileIdle` backup) and register `TIME_SET` / `TIMEZONE_CHANGED` / `BOOT_COMPLETED` reconciliation.
    - Add a deterministic **`reconcileDndState()`** guard executed on native reschedule, boot, app resume, and periodic foreground tick: if a DND session is marked active while current time is outside all enabled `[start, end)` prayer windows (or Auto-Silent was turned off), automatically restore the saved interruption filter and ringer state immediately.
    - Sequence `setInterruptionFilter` restoration cleanly before conditional `ringerMode` restoration (only restoring `prevRinger` when `prevFilter == INTERRUPTION_FILTER_ALL` and validating against stuck silent states).
  - *Why*: Prevents DND from ever staying stuck after Iqamah ends, even after device sleep, OEM battery optimization, clock shifts, or reboots.
- **Decision 3 — Full Localization & Complete Rebrand to Ibadia**
  - *Chosen Approach*: Update central branding tokens, localized app names (`Ibadia` / `ഇബാദിയ` / `عبادية`), web domain (`https://ibadia.vercel.app`), Android manifest & home widget labels, APK release naming (`Ibadia.apk` with backward-safe update manifest handling), PWA manifest/splash/meta tags, and export metadata/gallery album name (`Ibadia`).
  - *Why*: Ensures consistent branding across Android launcher, home widget, browser tab, PWA install prompt, share sheet, and exported PDFs/images.

---

## 4. Technical Architecture & Data Strategy *(Technical Reference)*

### System Architecture & Component Hierarchy

```text
┌───────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER PRESENTATION LAYER                        │
│  [ Conditional Notch-Safe Header ]   [ 3-Tab Bottom Nav: Home|Quran|Set ] │
├──────────────────┬────────────────────────────┬───────────────────────────┤
│   Home Screen    │      Quran Workspace       │       Settings Tab        │
│ • Prayer Hero    │ • SafeArea Sub-Tab Header  │ • Quran Preferences       │
│ • Continue Read  │ • Surah | Juz | Saved | Exp│ • Prayer, Alarm & DND     │
│ • Quick Grids    │ • Floating Surah Search    │ • Kahf & Home Widget Info │
│ • Recent Strip   │ • Full-Screen Reader Push  │ • PWA Install / Updates   │
│                  │                            │ • Share ibadia.vercel.app │
└────────┬─────────┴─────────────┬──────────────┴─────────────┬─────────────┘
         │                       │                            │
         ▼                       │                            │
┌─────────────────────────┐      │                            │
│ Standalone Feature Push │      │                            │
│ (Back → Home, no tabs)  │      │                            │
│ • Prayer Times & Alarms │      │                            │
│ • Hijri Calendar        │      │                            │
│ • Adhkar & Duas         │      │                            │
│ • Digital Tasbih        │      │                            │
│ • 99 Names (Grid/List)  │      │                            │
│ • Bookmarks (Standalone)│      │                            │
│ • Export (Standalone)   │      │                            │
└────────┬────────────────┘      │                            │
         │                       │                            │
         ▼                       ▼                            ▼
┌───────────────────────────────────────────────────────────────────────────┐
│              RIVERPOD + SERIALIZED HIVE AUTO-SAVE ENGINE                  │
│  • Coalesced Functional Settings Queue (Zero race / zero lost slider)     │
│  • Instant Storage Commits: Bookmarks, LastRead, ResumeState, Recent,     │
│    Tasbih, Adhkar, Export Prefs, 99 Names View Mode                       │
│  • Offline API Cache (Surah/Juz texts, Prayer timings, Hijri calendar)    │
└────────┬────────────────────────────────────────────────────┬─────────────┘
         │                                                    │
         ▼                                                    ▼
┌──────────────────────────────┐             ┌──────────────────────────────┐
│     EXTERNAL DATA SOURCES    │             │  ANDROID KOTLIN NATIVE LAYER │
│ • AlQuran Cloud API          │             │ • Exact Prayer Alarm Engine  │
│ • EveryAyah / Islamic Net    │             │ • WakeLocked DND Start/End   │
│ • AlAdhan API                │             │ • Stale-DND Reconciler       │
└──────────────────────────────┘             └──────────────────────────────┘
```

### Data Model & Auto-Save State Mapping

- **App Settings & Preferences (`AppSettings` → Hive `appPrefsBox`)**:
  - Adds persisted `names99ViewMode` (`'grid'` | `'list'`) and persisted Export preferences (`exportScope`, `exportSurahNo`, `exportJuzNo`, `exportPageSize`, `exportFormat`, `exportIncludeTranslation`).
  - Functional `updateWith(...)` queues sequential Hive writes so fast slider drags, chip toggles, or multi-step sheet edits never overwrite newer state.
- **Navigation & Resume State (`AppResumeState` → Hive `appPrefsBox`)**:
  - Updated cleanly to 3 primary bottom tabs (`0: Home`, `1: Quran`, `2: Settings`) with safe clamping for users upgrading from older 4-tab saved states.
  - Standalone features pushed from Home save cleanly and restore Home safely on return.
- **99 Names Dual View Interaction**:
  - Toggle switches instantaneously between **3-column RTL Grid** (displaying only Arabic calligraphy + Arabic/localized numeral inside clean elevated tiles, preserving crisp RTL reading order from right to left) and **Detailed List** (showing number badge, transliteration, Malayalam & English meanings, and Arabic name).
  - Live search filters across both views; tapping any tile in either mode opens the interactive detail sheet with sequential Prev/Next navigation and copy action.
- **Android Native DND State Machine**:
  - Tracks `[startMillis, endMillis)` windows per enabled prayer, persists original `prevFilter` and `prevRinger` only on fresh entry into an inactive session, enforces WakeLock-protected end triggers, and runs `reconcileDndState()` across `onReceive` (End / Boot / TimeChange), `rescheduleStoredDndWindows`, and Flutter `syncWithNative()` + foreground timer checks so expired DND sessions always restore automatically.
