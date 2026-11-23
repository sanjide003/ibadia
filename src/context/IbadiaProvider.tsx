'use client';

import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import {
  alQuranCloudAudioUrl,
  ALARM_SOUNDS,
  everyAyahAudioUrl,
  reciterById,
} from '@/lib/apiConfig';
import { getStrings } from '@/lib/appStrings';
import {
  computeDailySlots,
  fetchDailyPrayerTimes,
  format12Hour,
  formatDateKey,
} from '@/lib/islamicFeaturesApi';
import { fetchSurahDetail, fetchSurahList } from '@/lib/quranApi';
import {
  createDefaultSettings,
  getNativeBridge,
  idbGet,
  idbSet,
  loadBookmarks,
  loadDismissedAlarms,
  loadLastRead,
  loadRecentActivity,
  loadSettings,
  saveBookmarksNow,
  saveDismissedAlarmsNow,
  saveLastReadNow,
  saveRecentActivityNow,
  saveSettingsNow,
} from '@/lib/storage';
import type {
  AppSettings,
  BookmarkItem,
  ComputedPrayerSlot,
  DailyPrayerData,
  HomeFeatureView,
  LastReadState,
  MainTab,
  PrayerKey,
  QuranSubTab,
  RecentActivityEntry,
  RecentActivityType,
  SurahSummary,
  TranslationCode,
} from '@/types';

export interface ReaderLaunchTarget {
  surahNumber: number;
  ayahNumber?: number;
  scrollOffset?: number;
}

export interface AudioPlaybackState {
  active: boolean;
  isPlaying: boolean;
  isLoading: boolean;
  surahNumber: number;
  surahName: string;
  ayahNumber: number;
  totalAyahs: number;
  repeatOne: boolean;
  error: string | null;
}

interface IbadiaContextValue {
  settings: AppSettings;
  updateSettings: (patch: Partial<AppSettings>) => void;
  toggleTranslationLang: (code: TranslationCode) => void;
  toggleStudiedName99: (num: number) => void;
  t: ReturnType<typeof getStrings>;

  activeTab: MainTab;
  setActiveTab: (tab: MainTab) => void;
  quranSubTab: QuranSubTab;
  setQuranSubTab: (sub: QuranSubTab) => void;
  homeFeatureView: HomeFeatureView;
  openHomeFeature: (view: HomeFeatureView) => void;

  readerTarget: ReaderLaunchTarget | null;
  openReader: (surahNumber: number, ayahNumber?: number, scrollOffset?: number) => void;
  closeReader: () => void;

  surahs: SurahSummary[];
  surahsLoading: boolean;
  surahsError: string | null;
  reloadSurahs: () => void;

  lastRead: LastReadState | null;
  commitLastRead: (next: LastReadState) => void;

  bookmarks: BookmarkItem[];
  isBookmarked: (surahNumber: number, ayahNumber: number) => boolean;
  isSurahBookmarked: (surahNumber: number) => boolean;
  toggleBookmark: (item: Omit<BookmarkItem, 'id' | 'createdAtMs'>) => boolean;
  removeBookmark: (id: string) => void;

  recentActivity: RecentActivityEntry[];
  recordActivity: (
    entry: Omit<RecentActivityEntry, 'id' | 'timestampMs'>
  ) => void;
  clearRecentActivity: () => void;

  prayerData: DailyPrayerData | null;
  prayerSlots: ComputedPrayerSlot[];
  nextPrayerSlot: ComputedPrayerSlot | null;
  countdownLabel: string;
  prayerLoading: boolean;
  prayerError: string | null;
  gpsLoading: boolean;
  refreshPrayerTimes: (force?: boolean) => Promise<void>;
  useGpsLocation: () => void;
  dismissAlarmToday: (prayerKey: PrayerKey) => void;

  previewAlarmSound: (soundId?: string) => void;
  stopAlarmPreview: () => void;
  isPreviewPlaying: boolean;

  audio: AudioPlaybackState;
  playAyahAudio: (surahNumber: number, ayahNumber: number) => Promise<void>;
  toggleAudioPlayPause: () => void;
  nextAudioAyah: () => Promise<void>;
  prevAudioAyah: () => Promise<void>;
  toggleRepeatAudio: () => void;
  stopAudio: () => void;

  toastMessage: string | null;
  showToast: (msg: string) => void;
}

const IbadiaContext = createContext<IbadiaContextValue | null>(null);

export function useIbadia(): IbadiaContextValue {
  const ctx = useContext(IbadiaContext);
  if (!ctx) throw new Error('useIbadia must be used inside IbadiaProvider');
  return ctx;
}

function applyDocumentTheme(settings: AppSettings) {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  root.classList.remove('dark', 'sepia');
  if (settings.themeMode === 'dark') {
    root.classList.add('dark');
  } else if (settings.themeMode === 'sepia') {
    root.classList.add('sepia');
  }
  root.lang = settings.appLanguage;
  root.dir = settings.appLanguage === 'ar' ? 'rtl' : 'ltr';
}

export function IbadiaProvider({ children }: { children: React.ReactNode }) {
  const [settings, setSettings] = useState<AppSettings>(() => createDefaultSettings());
  const [hydrated, setHydrated] = useState(false);

  const [activeTab, setActiveTabState] = useState<MainTab>('home');
  const [quranSubTab, setQuranSubTabState] = useState<QuranSubTab>('surah');
  const [homeFeatureView, setHomeFeatureView] = useState<HomeFeatureView>(null);
  const [readerTarget, setReaderTarget] = useState<ReaderLaunchTarget | null>(null);

  const [surahs, setSurahs] = useState<SurahSummary[]>([]);
  const [surahsLoading, setSurahsLoading] = useState(true);
  const [surahsError, setSurahsError] = useState<string | null>(null);

  const [lastRead, setLastRead] = useState<LastReadState | null>(null);
  const lastReadRef = useRef<LastReadState | null>(null);

  const [bookmarks, setBookmarks] = useState<BookmarkItem[]>([]);
  const [recentActivity, setRecentActivity] = useState<RecentActivityEntry[]>([]);
  const [dismissedKeys, setDismissedKeys] = useState<string[]>([]);

  const [prayerData, setPrayerData] = useState<DailyPrayerData | null>(null);
  const [prayerLoading, setPrayerLoading] = useState(true);
  const [prayerError, setPrayerError] = useState<string | null>(null);
  const [gpsLoading, setGpsLoading] = useState(false);
  const [nowMs, setNowMs] = useState(() => Date.now());

  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const toastTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const previewAudioRef = useRef<HTMLAudioElement | null>(null);
  const [isPreviewPlaying, setIsPreviewPlaying] = useState(false);

  const quranAudioRef = useRef<HTMLAudioElement | null>(null);
  const audioObjectUrlRef = useRef<string | null>(null);
  const [audio, setAudio] = useState<AudioPlaybackState>({
    active: false,
    isPlaying: false,
    isLoading: false,
    surahNumber: 1,
    surahName: 'Al-Fatihah',
    ayahNumber: 1,
    totalAyahs: 7,
    repeatOne: false,
    error: null,
  });
  const audioRef = useRef(audio);
  const settingsRef = useRef(settings);

  useEffect(() => {
    audioRef.current = audio;
    settingsRef.current = settings;
  }, [audio, settings]);

  const showToast = useCallback((msg: string) => {
    setToastMessage(msg);
    if (toastTimerRef.current) clearTimeout(toastTimerRef.current);
    toastTimerRef.current = setTimeout(() => setToastMessage(null), 2600);
  }, []);

  // Load persisted state immediately on client mount via microtask
  useEffect(() => {
    let active = true;
    void Promise.resolve().then(() => {
      if (!active) return;
      const loadedSettings = loadSettings();
      setSettings(loadedSettings);
      applyDocumentTheme(loadedSettings);

      const lr = loadLastRead();
      setLastRead(lr);
      lastReadRef.current = lr;

      setBookmarks(loadBookmarks());
      setRecentActivity(loadRecentActivity());
      setDismissedKeys(loadDismissedAlarms());
      setHydrated(true);
    });
    return () => {
      active = false;
    };
  }, []);

  // Guarantee instant flush when user switches tabs, backgrounds, or closes page
  useEffect(() => {
    const flushState = () => {
      saveSettingsNow(settingsRef.current);
      if (lastReadRef.current) saveLastReadNow(lastReadRef.current);
    };
    const onVis = () => {
      if (document.visibilityState === 'hidden') flushState();
    };
    window.addEventListener('visibilitychange', onVis);
    window.addEventListener('pagehide', flushState);
    window.addEventListener('beforeunload', flushState);
    return () => {
      window.removeEventListener('visibilitychange', onVis);
      window.removeEventListener('pagehide', flushState);
      window.removeEventListener('beforeunload', flushState);
    };
  }, []);

  // Update 1-second clock for next-prayer countdown
  useEffect(() => {
    const timer = setInterval(() => setNowMs(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  const loadSurahs = useCallback(async () => {
    await Promise.resolve();
    setSurahsLoading(true);
    setSurahsError(null);
    try {
      const list = await fetchSurahList();
      setSurahs(list);
    } catch {
      setSurahsError('Failed to load Surahs');
    } finally {
      setSurahsLoading(false);
    }
  }, []);

  useEffect(() => {
    void Promise.resolve().then(() => loadSurahs());
  }, [loadSurahs]);

  const syncNativeSchedules = useCallback(
    (s: AppSettings, data: DailyPrayerData | null, dismissed: string[]) => {
      const bridge = getNativeBridge();
      if (!bridge || !data) return;
      const slots = computeDailySlots(data, s, new Set(dismissed), new Date());

      if (bridge.scheduleDndWindows) {
        const windows = slots
          .filter((slot) => s.autoSilentPrayers[slot.prayerKey])
          .map((slot) => {
            const startMs = slot.iqamahTime.getTime();
            const endMs = startMs + s.autoSilentDurationMinutes * 60_000;
            return {
              prayerKey: slot.prayerKey,
              prayerName: slot.prayerKey,
              startMillis: startMs,
              endMillis: endMs,
              durationMinutes: s.autoSilentDurationMinutes,
              notifTitle: 'Ibadia Auto-Silent Active',
              restoreBtn: 'Restore Sound',
            };
          });
        try {
          bridge.scheduleDndWindows(s.autoSilentEnabled, JSON.stringify(windows));
        } catch {
          // ignore
        }
      }

      if (bridge.syncHomeWidget) {
        const now = Date.now();
        const upcoming = slots.find((sl) => sl.adhanTime.getTime() > now) ?? slots[0];
        if (upcoming) {
          try {
            bridge.syncHomeWidget(
              JSON.stringify({
                location: data.locationLabel,
                hijriDate: `${data.hijriDay} ${data.hijriMonthEn} ${data.hijriYear}`,
                prayerName: upcoming.prayerKey.toUpperCase(),
                adhanTime: format12Hour(upcoming.adhanTime),
                iqamahTime: `Iqamah ${format12Hour(upcoming.iqamahTime)}`,
              })
            );
          } catch {
            // ignore
          }
        }
      }
    },
    []
  );

  const refreshPrayerTimes = useCallback(
    async (force = false) => {
      await Promise.resolve();
      setPrayerLoading(true);
      setPrayerError(null);
      try {
        const data = await fetchDailyPrayerTimes(settingsRef.current, new Date(), force);
        setPrayerData(data);
        syncNativeSchedules(settingsRef.current, data, dismissedKeys);
      } catch {
        setPrayerError('Unable to load prayer timings');
      } finally {
        setPrayerLoading(false);
      }
    },
    [dismissedKeys, syncNativeSchedules]
  );

  useEffect(() => {
    if (!hydrated) return;
    void Promise.resolve().then(() => refreshPrayerTimes(false));
  }, [
    hydrated,
    settings.prayerLocationMode,
    settings.prayerCity,
    settings.prayerCountry,
    settings.prayerLat,
    settings.prayerLon,
    settings.prayerMethod,
    settings.prayerSchool,
    settings.hijriAdjustment,
    refreshPrayerTimes,
  ]);

  const updateSettings = useCallback(
    (patch: Partial<AppSettings>) => {
      setSettings((prev) => {
        const next: AppSettings = {
          ...prev,
          ...patch,
          prayerTunes: patch.prayerTunes ? { ...prev.prayerTunes, ...patch.prayerTunes } : prev.prayerTunes,
          autoSilentPrayers: patch.autoSilentPrayers
            ? { ...prev.autoSilentPrayers, ...patch.autoSilentPrayers }
            : prev.autoSilentPrayers,
          prayerConfigs: patch.prayerConfigs ? { ...prev.prayerConfigs, ...patch.prayerConfigs } : prev.prayerConfigs,
        };
        saveSettingsNow(next);
        applyDocumentTheme(next);
        syncNativeSchedules(next, prayerData, dismissedKeys);
        return next;
      });
    },
    [dismissedKeys, prayerData, syncNativeSchedules]
  );

  const toggleTranslationLang = useCallback(
    (code: TranslationCode) => {
      setSettings((prev) => {
        const exists = prev.selectedTranslations.includes(code);
        let list = exists
          ? prev.selectedTranslations.filter((c) => c !== code)
          : [...prev.selectedTranslations, code];
        if (list.length === 0) list = [code];
        const next = { ...prev, selectedTranslations: list };
        saveSettingsNow(next);
        return next;
      });
    },
    []
  );

  const toggleStudiedName99 = useCallback((num: number) => {
    setSettings((prev) => {
      const exists = prev.studiedNames99.includes(num);
      const studiedNames99 = exists
        ? prev.studiedNames99.filter((n) => n !== num)
        : [...prev.studiedNames99, num];
      const next = { ...prev, studiedNames99 };
      saveSettingsNow(next);
      return next;
    });
  }, []);

  const t = useMemo(() => getStrings(settings.appLanguage), [settings.appLanguage]);

  const recordActivity = useCallback(
    (entry: Omit<RecentActivityEntry, 'id' | 'timestampMs'>) => {
      const id = `${entry.type}_${entry.surahNumber ?? ''}_${entry.featureView ?? ''}`;
      setRecentActivity((prev) => {
        const nextEntry: RecentActivityEntry = {
          ...entry,
          id,
          timestampMs: Date.now(),
        };
        const filtered = prev.filter((item) => item.id !== id);
        const next = [nextEntry, ...filtered].slice(0, 7);
        saveRecentActivityNow(next);
        return next;
      });
    },
    []
  );

  const clearRecentActivity = useCallback(() => {
    setRecentActivity([]);
    saveRecentActivityNow([]);
  }, []);

  const commitLastRead = useCallback((next: LastReadState) => {
    lastReadRef.current = next;
    setLastRead(next);
    saveLastReadNow(next);
  }, []);

  const isBookmarked = useCallback(
    (surahNumber: number, ayahNumber: number) =>
      bookmarks.some((b) => !b.isWholeSurah && b.surahNumber === surahNumber && b.ayahNumber === ayahNumber),
    [bookmarks]
  );

  const isSurahBookmarked = useCallback(
    (surahNumber: number) =>
      bookmarks.some((b) => b.isWholeSurah && b.surahNumber === surahNumber),
    [bookmarks]
  );

  const toggleBookmark = useCallback(
    (item: Omit<BookmarkItem, 'id' | 'createdAtMs'>) => {
      const id = item.isWholeSurah ? `surah_${item.surahNumber}` : `${item.surahNumber}:${item.ayahNumber}`;
      let saved = false;
      setBookmarks((prev) => {
        const exists = prev.some((b) => b.id === id);
        const next = exists
          ? prev.filter((b) => b.id !== id)
          : [{ ...item, id, createdAtMs: Date.now() }, ...prev];
        saved = !exists;
        saveBookmarksNow(next);
        return next;
      });
      return saved;
    },
    []
  );

  const removeBookmark = useCallback((id: string) => {
    setBookmarks((prev) => {
      const next = prev.filter((b) => b.id !== id);
      saveBookmarksNow(next);
      return next;
    });
  }, []);

  const setActiveTab = useCallback((tab: MainTab) => {
    setActiveTabState(tab);
    if (tab !== 'home') {
      setHomeFeatureView(null);
    }
  }, []);

  const setQuranSubTab = useCallback((sub: QuranSubTab) => {
    setQuranSubTabState(sub);
  }, []);

  const openHomeFeature = useCallback(
    (view: HomeFeatureView) => {
      setActiveTabState('home');
      setHomeFeatureView(view);
      if (view) {
        const typeMap: Record<Exclude<HomeFeatureView, null>, RecentActivityType> = {
          prayer: 'prayer',
          hijri: 'hijri',
          adhkar: 'adhkar',
          tasbih: 'counter',
          names99: 'asmaulHusna',
          export: 'exportPdf',
          tajweed: 'tajweed',
        };
        const labelMap: Record<Exclude<HomeFeatureView, null>, [string, string, string]> = {
          prayer: ['Prayer Times & DND', 'നിസ്കാര സമയം & DND', 'أوقات الصلاة والصامت'],
          hijri: ['Hijri Calendar', 'ഹിജ്‌രി കലണ്ടർ', 'التقويم الهجري'],
          adhkar: ['Adhkar & Duas', 'ദിക്ർ & ദുആ', 'الأذكار اليومية'],
          tasbih: ['Digital Tasbih', 'തസ്ബീഹ് കൗണ്ടർ', 'المسبحة الرقمية'],
          names99: ['99 Names of Allah', 'അല്ലാഹുവിന്റെ 99 നാമങ്ങൾ', 'أسماء الله الحسنى'],
          export: ['Export PDF / PNG', 'എക്സ്പോർട്ട് PDF / PNG', 'تصدير القرآن'],
          tajweed: ['Tajweed Guide', 'തജ്‌വീദ് നിയമങ്ങൾ', 'أحكام التجويد'],
        };
        const [titleEn, titleMl, titleAr] = labelMap[view];
        recordActivity({
          type: typeMap[view],
          titleEn,
          titleMl,
          titleAr,
          subtitleEn: 'Feature',
          subtitleMl: 'ഫീച്ചർ',
          subtitleAr: 'أداة',
          featureView: view,
        });
      }
    },
    [recordActivity]
  );

  const openReader = useCallback(
    (surahNumber: number, ayahNumber?: number, scrollOffset?: number) => {
      const s = surahs.find((x) => x.number === surahNumber);
      recordActivity({
        type: 'surah',
        titleEn: s ? `Surah ${s.englishName}` : `Surah ${surahNumber}`,
        titleMl: s ? `സൂറത്ത് ${s.englishName}` : `സൂറത്ത് ${surahNumber}`,
        titleAr: s?.nameArabic ?? `سورة ${surahNumber}`,
        subtitleEn: ayahNumber ? `Ayah ${ayahNumber}` : 'Continuous Reading',
        subtitleMl: ayahNumber ? `ആയത്ത് ${ayahNumber}` : 'തുടർ വായന',
        subtitleAr: ayahNumber ? `آية ${ayahNumber}` : 'قراءة متواصلة',
        surahNumber,
        ayahNumber,
      });
      setReaderTarget({ surahNumber, ayahNumber, scrollOffset });
    },
    [recordActivity, surahs]
  );

  const closeReader = useCallback(() => {
    setReaderTarget(null);
  }, []);

  const prayerSlots = useMemo(() => {
    if (!prayerData) return [];
    return computeDailySlots(prayerData, settings, new Set(dismissedKeys), new Date(nowMs));
  }, [prayerData, settings, dismissedKeys, nowMs]);

  const { nextPrayerSlot, countdownLabel } = useMemo(() => {
    if (prayerSlots.length === 0) return { nextPrayerSlot: null, countdownLabel: '--:--:--' };
    let target = prayerSlots.find((s) => s.adhanTime.getTime() > nowMs);
    let diffMs = target ? target.adhanTime.getTime() - nowMs : 0;
    if (!target) {
      target = prayerSlots[0];
      diffMs = target.adhanTime.getTime() + 86_400_000 - nowMs;
    }
    const secTotal = Math.max(0, Math.floor(diffMs / 1000));
    const hrs = Math.floor(secTotal / 3600);
    const mins = Math.floor((secTotal % 3600) / 60);
    const secs = secTotal % 60;
    return {
      nextPrayerSlot: target,
      countdownLabel: `${String(hrs).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`,
    };
  }, [prayerSlots, nowMs]);

  const dismissAlarmToday = useCallback(
    (prayerKey: PrayerKey) => {
      const todayStr = formatDateKey(new Date());
      const k = `${todayStr}|${prayerKey}`;
      setDismissedKeys((prev) => {
        const next = prev.includes(k) ? prev.filter((x) => x !== k) : [...prev, k];
        saveDismissedAlarmsNow(next);
        return next;
      });
    },
    []
  );

  const useGpsLocation = useCallback(() => {
    if (typeof navigator === 'undefined' || !navigator.geolocation) {
      showToast('GPS is not supported in this browser');
      return;
    }
    setGpsLoading(true);
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setGpsLoading(false);
        updateSettings({
          prayerLocationMode: 'gps',
          prayerLat: pos.coords.latitude,
          prayerLon: pos.coords.longitude,
        });
        showToast('GPS location updated');
      },
      () => {
        setGpsLoading(false);
        showToast('Location permission denied. Using saved city.');
      },
      { enableHighAccuracy: false, timeout: 10000 }
    );
  }, [showToast, updateSettings]);

  const stopAlarmPreview = useCallback(() => {
    if (previewAudioRef.current) {
      previewAudioRef.current.pause();
      previewAudioRef.current.currentTime = 0;
    }
    setIsPreviewPlaying(false);
  }, []);

  const previewAlarmSound = useCallback(
    (soundId?: string) => {
      stopAlarmPreview();
      const targetId = soundId ?? settingsRef.current.alarmSoundType;
      const option = ALARM_SOUNDS.find((s) => s.id === targetId) ?? ALARM_SOUNDS[0];

      if (!option.remoteUrl) {
        // Synthesize gentle Web Audio chime for built-in tone
        try {
          const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
          const ctx = new AudioCtx();
          const osc = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.type = 'sine';
          osc.frequency.setValueAtTime(528, ctx.currentTime);
          osc.frequency.exponentialRampToValueAtTime(660, ctx.currentTime + 0.4);
          gain.gain.setValueAtTime(settingsRef.current.alarmVolume * 0.25, ctx.currentTime);
          gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 1.2);
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.start();
          osc.stop(ctx.currentTime + 1.2);
          setIsPreviewPlaying(true);
          setTimeout(() => setIsPreviewPlaying(false), 1250);
        } catch {
          setIsPreviewPlaying(false);
        }
        return;
      }

      const el = new Audio(option.remoteUrl);
      el.volume = settingsRef.current.alarmVolume;
      previewAudioRef.current = el;
      setIsPreviewPlaying(true);
      el.onended = () => setIsPreviewPlaying(false);
      el.onerror = () => setIsPreviewPlaying(false);
      el.play().catch(() => setIsPreviewPlaying(false));
    },
    [stopAlarmPreview]
  );

  const playAyahAudioRef = useRef<(s: number, a: number) => Promise<void>>(async () => {});

  // Quran Audio Recitation Player with IndexedDB caching & fallback CDN
  const stopAudio = useCallback(() => {
    if (quranAudioRef.current) {
      quranAudioRef.current.pause();
      quranAudioRef.current.removeAttribute('src');
      quranAudioRef.current = null;
    }
    if (audioObjectUrlRef.current) {
      URL.revokeObjectURL(audioObjectUrlRef.current);
      audioObjectUrlRef.current = null;
    }
    setAudio((prev) => ({
      ...prev,
      active: false,
      isPlaying: false,
      isLoading: false,
      error: null,
    }));
  }, []);

  const playAyahAudio = useCallback(
    async (surahNumber: number, ayahNumber: number) => {
      const sSummary = surahs.find((s) => s.number === surahNumber);
      const surahName = sSummary?.englishName ?? `Surah ${surahNumber}`;
      const totalAyahs = sSummary?.numberOfAyahs ?? 7;

      setAudio((prev) => ({
        ...prev,
        active: true,
        isLoading: true,
        isPlaying: false,
        surahNumber,
        surahName,
        ayahNumber,
        totalAyahs,
        error: null,
      }));

      try {
        const detail = await fetchSurahDetail(surahNumber, []);
        const ayahObj = detail.ayahs.find((a) => a.numberInSurah === ayahNumber);
        const globalNumber = ayahObj?.globalNumber ?? 1;
        const reciter = reciterById(settingsRef.current.reciterId);

        const cacheKey = `audio_v1_${reciter.id}_${surahNumber}_${ayahNumber}`;
        let blob = await idbGet<Blob>(cacheKey);

        if (!blob) {
          const primaryUrl = alQuranCloudAudioUrl(reciter, globalNumber);
          const fallbackUrl = everyAyahAudioUrl(reciter, surahNumber, ayahNumber);
          let res = await fetch(primaryUrl).catch(() => null);
          if (!res || !res.ok) {
            res = await fetch(fallbackUrl).catch(() => null);
          }
          if (!res || !res.ok) throw new Error('Audio fetch failed');
          blob = await res.blob();
          await idbSet(cacheKey, blob);
        }

        if (audioObjectUrlRef.current) {
          URL.revokeObjectURL(audioObjectUrlRef.current);
        }
        const objUrl = URL.createObjectURL(blob);
        audioObjectUrlRef.current = objUrl;

        if (quranAudioRef.current) {
          quranAudioRef.current.pause();
        }
        const player = new Audio(objUrl);
        player.onended = () => {
          const cur = audioRef.current;
          if (!cur.active) return;
          if (cur.repeatOne) {
            void playAyahAudioRef.current(cur.surahNumber, cur.ayahNumber);
          } else if (cur.ayahNumber < cur.totalAyahs) {
            void playAyahAudioRef.current(cur.surahNumber, cur.ayahNumber + 1);
          } else if (cur.surahNumber < 114) {
            void playAyahAudioRef.current(cur.surahNumber + 1, 1);
          } else {
            setAudio((prev) => ({ ...prev, isPlaying: false }));
          }
        };
        quranAudioRef.current = player;
        await player.play();
        setAudio((prev) => ({
          ...prev,
          active: true,
          isLoading: false,
          isPlaying: true,
          error: null,
        }));
      } catch {
        setAudio((prev) => ({
          ...prev,
          active: true,
          isLoading: false,
          isPlaying: false,
          error: t.audioLoadError,
        }));
      }
    },
    [surahs, t.audioLoadError]
  );

  useEffect(() => {
    playAyahAudioRef.current = playAyahAudio;
  }, [playAyahAudio]);

  const toggleAudioPlayPause = useCallback(() => {
    const el = quranAudioRef.current;
    if (!el) return;
    if (audioRef.current.isPlaying) {
      el.pause();
      setAudio((prev) => ({ ...prev, isPlaying: false }));
    } else {
      el.play().catch(() => {});
      setAudio((prev) => ({ ...prev, isPlaying: true }));
    }
  }, []);

  const nextAudioAyah = useCallback(async () => {
    const cur = audioRef.current;
    if (cur.ayahNumber < cur.totalAyahs) {
      await playAyahAudio(cur.surahNumber, cur.ayahNumber + 1);
    } else if (cur.surahNumber < 114) {
      await playAyahAudio(cur.surahNumber + 1, 1);
    }
  }, [playAyahAudio]);

  const prevAudioAyah = useCallback(async () => {
    const cur = audioRef.current;
    if (cur.ayahNumber > 1) {
      await playAyahAudio(cur.surahNumber, cur.ayahNumber - 1);
    } else if (cur.surahNumber > 1) {
      const prevSurah = surahs.find((s) => s.number === cur.surahNumber - 1);
      await playAyahAudio(cur.surahNumber - 1, prevSurah?.numberOfAyahs ?? 1);
    }
  }, [playAyahAudio, surahs]);

  const toggleRepeatAudio = useCallback(() => {
    setAudio((prev) => ({ ...prev, repeatOne: !prev.repeatOne }));
  }, []);

  const value: IbadiaContextValue = {
    settings,
    updateSettings,
    toggleTranslationLang,
    toggleStudiedName99,
    t,
    activeTab,
    setActiveTab,
    quranSubTab,
    setQuranSubTab,
    homeFeatureView,
    openHomeFeature,
    readerTarget,
    openReader,
    closeReader,
    surahs,
    surahsLoading,
    surahsError,
    reloadSurahs: loadSurahs,
    lastRead,
    commitLastRead,
    bookmarks,
    isBookmarked,
    isSurahBookmarked,
    toggleBookmark,
    removeBookmark,
    recentActivity,
    recordActivity,
    clearRecentActivity,
    prayerData,
    prayerSlots,
    nextPrayerSlot,
    countdownLabel,
    prayerLoading,
    prayerError,
    gpsLoading,
    refreshPrayerTimes,
    useGpsLocation,
    dismissAlarmToday,
    previewAlarmSound,
    stopAlarmPreview,
    isPreviewPlaying,
    audio,
    playAyahAudio,
    toggleAudioPlayPause,
    nextAudioAyah,
    prevAudioAyah,
    toggleRepeatAudio,
    stopAudio,
    toastMessage,
    showToast,
  };

  return <IbadiaContext.Provider value={value}>{children}</IbadiaContext.Provider>;
}
