import type {
  AppSettings,
  BookmarkItem,
  DailyPrayerData,
  LastReadState,
  PrayerKey,
  RecentActivityEntry,
  TasbihPreset,
} from '@/types';
import { defaultPrayerConfigs } from '@/lib/apiConfig';

const KEYS = {
  SETTINGS: 'ibadia_settings_v1',
  LAST_READ: 'ibadia_last_read_v1',
  BOOKMARKS: 'ibadia_bookmarks_v1',
  RECENT_ACTIVITY: 'ibadia_recent_activity_v1',
  PRAYER_CACHE: 'ibadia_prayer_cache_v1',
  HIJRI_PREFIX: 'ibadia_hijri_cal_',
  DISMISSED_ALARMS: 'ibadia_dismissed_alarms_v1',
  ADHKAR_COUNTS: 'ibadia_adhkar_counts_v1',
  ADHKAR_FAVORITES: 'ibadia_adhkar_favs_v1',
  TASBIH_STATE: 'ibadia_tasbih_state_v1',
  CUSTOM_TASBIH: 'ibadia_custom_tasbih_v1',
} as const;

export function createDefaultSettings(): AppSettings {
  return {
    appLanguage: 'en',
    readingMode: 'mushaf',
    themeMode: 'light',
    showTranslation: true,
    selectedTranslations: ['ml'],
    arabicFontSize: 28,
    translationFontSize: 15,
    autoScrollSpeed: 1.0,
    tajweedEnabled: true,
    reciterId: 'ar.alafasy',
    fabX: null,
    fabY: null,
    prayerLocationMode: 'city',
    prayerCity: 'Kochi',
    prayerCountry: 'India',
    prayerLat: 9.9312,
    prayerLon: 76.2673,
    prayerMethod: 1,
    prayerSchool: 0,
    hijriAdjustment: 0,
    prayerTunes: { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 },
    masterAlarmEnabled: true,
    alarmSoundType: 'adhan_alafasy',
    alarmVolume: 0.85,
    alarmVibrate: true,
    prayerConfigs: defaultPrayerConfigs(),
    autoSilentEnabled: false,
    autoSilentDurationMinutes: 15,
    autoSilentPrayers: { fajr: true, dhuhr: true, asr: true, maghrib: true, isha: true },
    kahfThursdayEnabled: true,
    kahfThuHour: 20,
    kahfThuMinute: 0,
    kahfFridayEnabled: true,
    kahfFriHour: 8,
    kahfFriMinute: 0,
    names99ViewMode: 'grid',
    studiedNames99: [],
  };
}

function safeReadJson<T>(key: string): T | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = window.localStorage.getItem(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

function safeWriteJson(key: string, value: unknown): void {
  if (typeof window === 'undefined') return;
  try {
    const serialized = JSON.stringify(value);
    window.localStorage.setItem(key, serialized);
  } catch {
    // Storage quota or private mode guard
  }
}

// Optional native Android WebView bridge interface for instant APK sync
export interface IbadiaNativeBridge {
  syncSettings?: (settingsJson: string) => void;
  scheduleDndWindows?: (enabled: boolean, windowsJson: string) => void;
  schedulePrayerAlarms?: (payloadJson: string) => void;
  requestDndPermission?: () => void;
  hasDndPermission?: () => boolean;
  isDndSessionActive?: () => boolean;
  restoreDndNow?: () => void;
  syncHomeWidget?: (payloadJson: string) => void;
  openExternalUrl?: (url: string) => void;
}

export function getNativeBridge(): IbadiaNativeBridge | null {
  if (typeof window === 'undefined') return null;
  const w = window as unknown as { IbadiaNative?: IbadiaNativeBridge };
  return w.IbadiaNative ?? null;
}

export function loadSettings(): AppSettings {
  const defaults = createDefaultSettings();
  const parsed = safeReadJson<Partial<AppSettings>>(KEYS.SETTINGS);
  if (!parsed) return defaults;
  const mergedConfigs = { ...defaults.prayerConfigs };
  if (parsed.prayerConfigs) {
    (Object.keys(mergedConfigs) as PrayerKey[]).forEach((k) => {
      if (parsed.prayerConfigs?.[k]) {
        mergedConfigs[k] = { ...mergedConfigs[k], ...parsed.prayerConfigs[k] };
      }
    });
  }
  return {
    ...defaults,
    ...parsed,
    prayerTunes: { ...defaults.prayerTunes, ...(parsed.prayerTunes ?? {}) },
    autoSilentPrayers: { ...defaults.autoSilentPrayers, ...(parsed.autoSilentPrayers ?? {}) },
    prayerConfigs: mergedConfigs,
    selectedTranslations:
      Array.isArray(parsed.selectedTranslations) && parsed.selectedTranslations.length > 0
        ? parsed.selectedTranslations
        : defaults.selectedTranslations,
    studiedNames99: Array.isArray(parsed.studiedNames99) ? parsed.studiedNames99 : [],
  };
}

export function saveSettingsNow(settings: AppSettings): void {
  safeWriteJson(KEYS.SETTINGS, settings);
  const bridge = getNativeBridge();
  if (bridge?.syncSettings) {
    try {
      bridge.syncSettings(JSON.stringify(settings));
    } catch {
      // ignore bridge failure on non-native web
    }
  }
}

export function loadLastRead(): LastReadState | null {
  return safeReadJson<LastReadState>(KEYS.LAST_READ);
}

export function saveLastReadNow(state: LastReadState): void {
  safeWriteJson(KEYS.LAST_READ, state);
}

export function loadBookmarks(): BookmarkItem[] {
  return safeReadJson<BookmarkItem[]>(KEYS.BOOKMARKS) ?? [];
}

export function saveBookmarksNow(items: BookmarkItem[]): void {
  safeWriteJson(KEYS.BOOKMARKS, items);
}

export function loadRecentActivity(): RecentActivityEntry[] {
  return safeReadJson<RecentActivityEntry[]>(KEYS.RECENT_ACTIVITY) ?? [];
}

export function saveRecentActivityNow(entries: RecentActivityEntry[]): void {
  safeWriteJson(KEYS.RECENT_ACTIVITY, entries.slice(0, 7));
}

export function loadDailyPrayerCache(): (DailyPrayerData & { cacheSig?: string }) | null {
  return safeReadJson<DailyPrayerData & { cacheSig?: string }>(KEYS.PRAYER_CACHE);
}

export function saveDailyPrayerCache(data: DailyPrayerData & { cacheSig?: string }): void {
  safeWriteJson(KEYS.PRAYER_CACHE, data);
}

export function loadHijriCalendarCache(year: number, month: number, adj: number) {
  return safeReadJson<unknown[]>(`${KEYS.HIJRI_PREFIX}${year}_${month}_adj${adj}`);
}

export function saveHijriCalendarCache(year: number, month: number, adj: number, items: unknown[]) {
  safeWriteJson(`${KEYS.HIJRI_PREFIX}${year}_${month}_adj${adj}`, items);
}

export function loadDismissedAlarms(): string[] {
  return safeReadJson<string[]>(KEYS.DISMISSED_ALARMS) ?? [];
}

export function saveDismissedAlarmsNow(keys: string[]): void {
  safeWriteJson(KEYS.DISMISSED_ALARMS, keys);
}

export interface AdhkarCountsStored {
  dateKey: string;
  counts: Record<string, number>;
}

export function loadAdhkarCounts(todayKey: string): Record<string, number> {
  const stored = safeReadJson<AdhkarCountsStored>(KEYS.ADHKAR_COUNTS);
  if (!stored || stored.dateKey !== todayKey) return {};
  return stored.counts ?? {};
}

export function saveAdhkarCountsNow(todayKey: string, counts: Record<string, number>): void {
  safeWriteJson(KEYS.ADHKAR_COUNTS, { dateKey: todayKey, counts });
}

export function loadAdhkarFavorites(): string[] {
  return safeReadJson<string[]>(KEYS.ADHKAR_FAVORITES) ?? [];
}

export function saveAdhkarFavoritesNow(ids: string[]): void {
  safeWriteJson(KEYS.ADHKAR_FAVORITES, ids);
}

export interface TasbihStateStored {
  selectedId: string;
  dateKey: string;
  currentCount: number;
  todayTotal: number;
  lifetimeTotal: number;
  cyclesCompleted: number;
  targets: Record<string, number>;
  vibrateOnTap: boolean;
  tapAnywhere: boolean;
}

export function loadTasbihState(todayKey: string): TasbihStateStored {
  const stored = safeReadJson<TasbihStateStored>(KEYS.TASBIH_STATE);
  if (!stored) {
    return {
      selectedId: 'tasbih_subhanallah',
      dateKey: todayKey,
      currentCount: 0,
      todayTotal: 0,
      lifetimeTotal: 0,
      cyclesCompleted: 0,
      targets: {},
      vibrateOnTap: true,
      tapAnywhere: true,
    };
  }
  return {
    ...stored,
    dateKey: todayKey,
    todayTotal: stored.dateKey === todayKey ? stored.todayTotal : 0,
  };
}

export function saveTasbihStateNow(state: TasbihStateStored): void {
  safeWriteJson(KEYS.TASBIH_STATE, state);
}

export function loadCustomTasbihPresets(): TasbihPreset[] {
  return safeReadJson<TasbihPreset[]>(KEYS.CUSTOM_TASBIH) ?? [];
}

export function saveCustomTasbihPresetsNow(list: TasbihPreset[]): void {
  safeWriteJson(KEYS.CUSTOM_TASBIH, list);
}

// IndexedDB cache for offline Surahs, Juz texts, and Audio blobs
const IDB_NAME = 'ibadia_offline_db_v1';
const IDB_STORE = 'kv_cache';
let dbPromise: Promise<IDBDatabase> | null = null;

function openOfflineDb(): Promise<IDBDatabase> {
  if (dbPromise) return dbPromise;
  dbPromise = new Promise((resolve, reject) => {
    if (typeof window === 'undefined' || !('indexedDB' in window)) {
      reject(new Error('IndexedDB unavailable'));
      return;
    }
    const req = window.indexedDB.open(IDB_NAME, 1);
    req.onupgradeneeded = () => {
      const db = req.result;
      if (!db.objectStoreNames.contains(IDB_STORE)) {
        db.createObjectStore(IDB_STORE);
      }
    };
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
  return dbPromise;
}

export async function idbGet<T>(key: string): Promise<T | null> {
  try {
    const db = await openOfflineDb();
    return await new Promise<T | null>((resolve) => {
      const tx = db.transaction(IDB_STORE, 'readonly');
      const store = tx.objectStore(IDB_STORE);
      const req = store.get(key);
      req.onsuccess = () => resolve((req.result as T) ?? null);
      req.onerror = () => resolve(null);
    });
  } catch {
    return null;
  }
}

export async function idbSet(key: string, value: unknown): Promise<void> {
  try {
    const db = await openOfflineDb();
    await new Promise<void>((resolve) => {
      const tx = db.transaction(IDB_STORE, 'readwrite');
      const store = tx.objectStore(IDB_STORE);
      store.put(value, key);
      tx.oncomplete = () => resolve();
      tx.onerror = () => resolve();
    });
  } catch {
    // ignore offline IDB write error
  }
}
