export type AppLanguage = 'en' | 'ml' | 'ar';
export type ReadingMode = 'mushaf' | 'verse';
export type ThemeMode = 'light' | 'sepia' | 'dark';
export type TranslationCode = 'en' | 'ml' | 'ar';

export type MainTab = 'home' | 'quran' | 'settings';
export type QuranSubTab = 'surah' | 'juz' | 'bookmarks';
export type HomeFeatureView =
  | null
  | 'prayer'
  | 'hijri'
  | 'adhkar'
  | 'tasbih'
  | 'names99'
  | 'export'
  | 'tajweed';

export interface SurahSummary {
  number: number;
  nameArabic: string;
  englishName: string;
  englishNameTranslation: string;
  numberOfAyahs: number;
  revelationType: string;
}

export interface AyahItem {
  numberInSurah: number;
  globalNumber: number;
  arabicText: string;
  juz: number;
  page: number;
}

export interface SurahDetail {
  summary: SurahSummary;
  ayahs: AyahItem[];
  translations: Partial<Record<TranslationCode, string[]>>;
}

export interface JuzAyahEntry {
  surah: SurahSummary;
  ayah: AyahItem;
}

export interface JuzDetail {
  juzNumber: number;
  entries: JuzAyahEntry[];
  translations: Partial<Record<TranslationCode, string[]>>;
}

export interface BookmarkItem {
  id: string;
  surahNumber: number;
  surahNameEn: string;
  surahNameAr: string;
  ayahNumber: number;
  ayahCount: number;
  previewArabic: string;
  isWholeSurah: boolean;
  createdAtMs: number;
}

export interface LastReadState {
  surahNumber: number;
  surahNameEn: string;
  surahNameAr: string;
  ayahNumber: number;
  pageNumber: number;
  scrollOffset?: number;
  updatedAtMs: number;
}

export type PrayerKey = 'fajr' | 'dhuhr' | 'asr' | 'maghrib' | 'isha';
export type PrayerAlarmRef = 'beforeAdhan' | 'relativeToIqamah';

export interface PrayerAlarmConfig {
  prayerKey: PrayerKey;
  enabled: boolean;
  iqamahGapMinutes: number;
  alarmRef: PrayerAlarmRef;
  alarmOffsetMinutes: number;
}

export interface ComputedPrayerSlot {
  prayerKey: PrayerKey;
  adhanTime: Date;
  iqamahTime: Date;
  alarmTime: Date | null;
  nextBoundaryAdhan: Date;
  safetyLimitTime: Date;
  nextBoundaryKey: PrayerKey | 'sunrise';
  masterEnabled: boolean;
  prayerAlarmEnabled: boolean;
  dismissedToday: boolean;
  tuneMinutes: number;
  effectiveIqamahGap: number;
  maxAllowedIqamahGap: number;
}

export interface DailyPrayerData {
  dateKey: string;
  locationLabel: string;
  latitude: number;
  longitude: number;
  timezone: string;
  methodId: number;
  school: number;
  hijriAdjustment: number;
  gregorianReadable: string;
  hijriDay: string;
  hijriMonthNumber: number;
  hijriMonthEn: string;
  hijriMonthAr: string;
  hijriYear: string;
  weekdayEn: string;
  weekdayAr: string;
  baseTimings: Record<'fajr' | 'sunrise' | 'dhuhr' | 'asr' | 'maghrib' | 'isha', string>;
  loadedFromCache?: boolean;
  cacheSig?: string;
}

export interface CalendarDayEntry {
  gregorianDay: number;
  gregorianMonth: number;
  gregorianYear: number;
  gregorianMonthEn: string;
  weekdayEn: string;
  hijriDay: number;
  hijriMonthNumber: number;
  hijriMonthEn: string;
  hijriMonthAr: string;
  hijriYear: number;
  holidays: string[];
}

export interface AdhkarEntry {
  id: string;
  category: 'morning' | 'evening' | 'after_salah' | 'daily_duas';
  titleEn: string;
  titleMl: string;
  arabic: string;
  translationEn: string;
  translationMl: string;
  reference: string;
  targetCount: number;
}

export interface TasbihPreset {
  id: string;
  arabic: string;
  titleEn: string;
  titleMl: string;
  defaultTarget: number;
  isCustom?: boolean;
}

export interface AsmaulHusnaItem {
  number: number;
  arabic: string;
  transliteration: string;
  englishMeaning: string;
  malayalamMeaning: string;
  arabicMeaning: string;
  reflectionEn: string;
  reflectionMl: string;
}

export type RecentActivityType =
  | 'surah'
  | 'juz'
  | 'prayer'
  | 'hijri'
  | 'adhkar'
  | 'counter'
  | 'asmaulHusna'
  | 'tajweed'
  | 'autoSilent'
  | 'bookmark'
  | 'exportPdf'
  | 'settings';

export interface RecentActivityEntry {
  id: string;
  type: RecentActivityType;
  titleEn: string;
  titleMl: string;
  titleAr: string;
  subtitleEn: string;
  subtitleMl: string;
  subtitleAr: string;
  timestampMs: number;
  surahNumber?: number;
  ayahNumber?: number;
  featureView?: HomeFeatureView;
  quranSubTab?: QuranSubTab;
  asmaIndex?: number;
}

export interface AppSettings {
  appLanguage: AppLanguage;
  readingMode: ReadingMode;
  themeMode: ThemeMode;
  showTranslation: boolean;
  selectedTranslations: TranslationCode[];
  arabicFontSize: number;
  translationFontSize: number;
  autoScrollSpeed: number;
  tajweedEnabled: boolean;
  reciterId: string;
  fabX: number | null;
  fabY: number | null;
  prayerLocationMode: 'city' | 'gps';
  prayerCity: string;
  prayerCountry: string;
  prayerLat: number;
  prayerLon: number;
  prayerMethod: number;
  prayerSchool: number;
  hijriAdjustment: number;
  prayerTunes: Record<PrayerKey, number>;
  masterAlarmEnabled: boolean;
  alarmSoundType: string;
  alarmVolume: number;
  alarmVibrate: boolean;
  prayerConfigs: Record<PrayerKey, PrayerAlarmConfig>;
  autoSilentEnabled: boolean;
  autoSilentDurationMinutes: number;
  autoSilentPrayers: Record<PrayerKey, boolean>;
  kahfThursdayEnabled: boolean;
  kahfThuHour: number;
  kahfThuMinute: number;
  kahfFridayEnabled: boolean;
  kahfFriHour: number;
  kahfFriMinute: number;
  names99ViewMode: 'grid' | 'list';
  studiedNames99: number[];
}

export type ExportScope = 'range' | 'surah' | 'juz';
export type ExportPageSize = 'automatic' | 'a4';
export type ExportFormat = 'pdf' | 'image';

export interface ExportAyahBlock {
  numberInSurah: number;
  arabicText: string;
  translations: Partial<Record<TranslationCode, string>>;
}

export interface ExportSurahSection {
  summary: SurahSummary;
  showBanner: boolean;
  showBismillah: boolean;
  ayahs: ExportAyahBlock[];
}
