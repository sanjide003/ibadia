import type { PrayerKey, PrayerAlarmConfig, AppLanguage } from '@/types';

export interface FeaturedSurahItem {
  number: number;
  en: string;
  ml: string;
  ar: string;
}

export interface JuzInfo {
  number: number;
  arabicName: string;
  openingCue: string;
  startSurah: number;
  startAyah: number;
  startPage: number;
}

export interface QuranReciter {
  id: string;
  englishName: string;
  malayalamName: string;
  arabicName: string;
  cdnBitrate: number;
  everyAyahFolder: string;
}

export interface PrayerCalculationMethod {
  id: number;
  englishName: string;
  malayalamName: string;
  arabicName: string;
}

export interface CityPreset {
  city: string;
  country: string;
  latitude: number;
  longitude: number;
}

export interface AlarmSoundOption {
  id: string;
  englishName: string;
  malayalamName: string;
  arabicName: string;
  remoteUrl?: string;
}

export const APP_BRANDING = {
  appNameEn: 'Ibadia',
  appNameMl: 'ഇബാദിയ',
  appNameAr: 'عبادية',
  appTagline: 'Read, Listen & Reflect',
  appVersion: '5.0.0',
  appBuildNumber: 5,
  logoAsset: '/branding/app_logo.png',
  webAppUrl: process.env.NEXT_PUBLIC_WEB_APP_URL || 'https://ibadia.vercel.app',
  androidApkUrl: process.env.NEXT_PUBLIC_ANDROID_APK_URL || '',
  updateManifestUrl: process.env.NEXT_PUBLIC_UPDATE_MANIFEST_URL || '',
};

export function localizedBrandName(lang: AppLanguage): string {
  if (lang === 'ml') return APP_BRANDING.appNameMl;
  if (lang === 'ar') return APP_BRANDING.appNameAr;
  return APP_BRANDING.appNameEn;
}

export const QURAN_API_CONFIG = {
  baseUrl: process.env.NEXT_PUBLIC_QURAN_API_BASE_URL || 'https://api.alquran.cloud/v1',
  arabicEdition: 'quran-uthmani',
  englishTranslationEdition: 'en.sahih',
  malayalamTranslationEdition: 'ml.abdulhameed',
  arabicTafsirEdition: 'ar.muyassar',
};

export const FEATURED_SURAHS: FeaturedSurahItem[] = [
  { number: 89, en: 'Al-Fajr', ml: 'അൽ-ഫജ്ർ', ar: 'الفجر' },
  { number: 109, en: 'Al-Kaafiroon', ml: 'അൽ-കാഫിറൂൻ', ar: 'الكافرون' },
  { number: 36, en: 'Yaseen', ml: 'യാസീൻ', ar: 'يس' },
  { number: 18, en: 'Al-Kahf', ml: 'അൽ-കഹ്ഫ്', ar: 'الكهف' },
  { number: 67, en: 'Al-Mulk', ml: 'അൽ-മുൽക്ക്', ar: 'الملك' },
  { number: 55, en: 'Ar-Rahman', ml: 'അർ-റഹ്മാൻ', ar: 'الرحمن' },
  { number: 56, en: 'Al-Waqiah', ml: 'അൽ-വാഖിഅ', ar: 'الواقعة' },
  { number: 32, en: 'As-Sajdah', ml: 'അസ്-സജ്ദ', ar: 'السجدة' },
  { number: 1, en: 'Al-Fatihah', ml: 'അൽ-ഫാതിഹ', ar: 'الفاتحة' },
  { number: 112, en: 'Al-Ikhlas', ml: 'അൽ-ഇഖ്‌ലാസ്', ar: 'الإخلاص' },
];

export const JUZ_CATALOG: JuzInfo[] = [
  { number: 1, arabicName: 'الجزء الأول', openingCue: 'الفاتحة', startSurah: 1, startAyah: 1, startPage: 1 },
  { number: 2, arabicName: 'الجزء الثاني', openingCue: 'سيقول السفهاء', startSurah: 2, startAyah: 142, startPage: 22 },
  { number: 3, arabicName: 'الجزء الثالث', openingCue: 'تلك الرسل', startSurah: 2, startAyah: 253, startPage: 42 },
  { number: 4, arabicName: 'الجزء الرابع', openingCue: 'كل الطعام', startSurah: 3, startAyah: 93, startPage: 62 },
  { number: 5, arabicName: 'الجزء الخامس', openingCue: 'والمحصنات', startSurah: 4, startAyah: 24, startPage: 82 },
  { number: 6, arabicName: 'الجزء السادس', openingCue: 'لا يحب الله الجهر بالسوء', startSurah: 4, startAyah: 148, startPage: 102 },
  { number: 7, arabicName: 'الجزء السابع', openingCue: 'لتجدن أشد الناس', startSurah: 5, startAyah: 82, startPage: 121 },
  { number: 8, arabicName: 'الجزء الثامن', openingCue: 'ولو أننا نزلنا', startSurah: 6, startAyah: 111, startPage: 142 },
  { number: 9, arabicName: 'الجزء التاسع', openingCue: 'قال الملأ', startSurah: 7, startAyah: 88, startPage: 162 },
  { number: 10, arabicName: 'الجزء العاشر', openingCue: 'واعلموا', startSurah: 8, startAyah: 41, startPage: 182 },
  { number: 11, arabicName: 'الجزء الحادي عشر', openingCue: 'يعتذرون', startSurah: 9, startAyah: 93, startPage: 201 },
  { number: 12, arabicName: 'الجزء الثاني عشر', openingCue: 'وما من دابة', startSurah: 11, startAyah: 6, startPage: 222 },
  { number: 13, arabicName: 'الجزء الثالث عشر', openingCue: 'وما أبرئ', startSurah: 12, startAyah: 53, startPage: 242 },
  { number: 14, arabicName: 'الجزء الرابع عشر', openingCue: 'ربما', startSurah: 15, startAyah: 1, startPage: 262 },
  { number: 15, arabicName: 'الجزء الخامس عشر', openingCue: 'سبحان الذي', startSurah: 17, startAyah: 1, startPage: 282 },
  { number: 16, arabicName: 'الجزء السادس عشر', openingCue: 'قال ألم', startSurah: 18, startAyah: 75, startPage: 302 },
  { number: 17, arabicName: 'الجزء السابع عشر', openingCue: 'اقترب للناس', startSurah: 21, startAyah: 1, startPage: 322 },
  { number: 18, arabicName: 'الجزء الثامن عشر', openingCue: 'قد أفلح', startSurah: 23, startAyah: 1, startPage: 342 },
  { number: 19, arabicName: 'الجزء التاسع عشر', openingCue: 'وقال الذين', startSurah: 25, startAyah: 21, startPage: 362 },
  { number: 20, arabicName: 'الجزء العشرون', openingCue: 'أمن خلق', startSurah: 27, startAyah: 56, startPage: 382 },
  { number: 21, arabicName: 'الجزء الحادي والعشرون', openingCue: 'اتل ما أوحي', startSurah: 29, startAyah: 46, startPage: 402 },
  { number: 22, arabicName: 'الجزء الثاني والعشرون', openingCue: 'ومن يقنت', startSurah: 33, startAyah: 31, startPage: 422 },
  { number: 23, arabicName: 'الجزء الثالث والعشرون', openingCue: 'وما لي', startSurah: 36, startAyah: 28, startPage: 442 },
  { number: 24, arabicName: 'الجزء الرابع والعشرون', openingCue: 'فمن أظلم', startSurah: 39, startAyah: 32, startPage: 462 },
  { number: 25, arabicName: 'الجزء الخامس والعشرون', openingCue: 'إليه يرد', startSurah: 41, startAyah: 47, startPage: 482 },
  { number: 26, arabicName: 'الجزء السادس والعشرون', openingCue: 'حم', startSurah: 46, startAyah: 1, startPage: 502 },
  { number: 27, arabicName: 'الجزء السابع والعشرون', openingCue: 'قال فما خطبكم', startSurah: 51, startAyah: 31, startPage: 522 },
  { number: 28, arabicName: 'الجزء الثامن والعشرون', openingCue: 'قد سمع الله', startSurah: 58, startAyah: 1, startPage: 542 },
  { number: 29, arabicName: 'الجزء التاسع والعشرون', openingCue: 'تبارك الذي', startSurah: 67, startAyah: 1, startPage: 562 },
  { number: 30, arabicName: 'الجزء الثلاثون', openingCue: 'عم يتساءلون', startSurah: 78, startAyah: 1, startPage: 582 },
];

export const RECITERS: QuranReciter[] = [
  {
    id: 'ar.alafasy',
    englishName: 'Mishary Rashid Alafasy',
    malayalamName: 'മിഷാരി റാഷിദ് അൽ-അഫാസി',
    arabicName: 'مشاري راشد العفاسي',
    cdnBitrate: 64,
    everyAyahFolder: 'Alafasy_64kbps',
  },
  {
    id: 'ar.abdulbasitmurattal',
    englishName: 'Abdul Basit (Murattal)',
    malayalamName: 'അബ്ദുൽ ബാസിത് (മുറത്തൽ)',
    arabicName: 'عبد الباسط عبد الصمد (مرتل)',
    cdnBitrate: 64,
    everyAyahFolder: 'Abdul_Basit_Murattal_64kbps',
  },
  {
    id: 'ar.husary',
    englishName: 'Mahmoud Khalil Al-Husary',
    malayalamName: 'മഹ്‌മൂദ് ഖലീൽ അൽ-ഹുസ്വരി',
    arabicName: 'محمود خليل الحصري',
    cdnBitrate: 128,
    everyAyahFolder: 'Husary_64kbps',
  },
  {
    id: 'ar.minshawi',
    englishName: 'Mohamed Siddiq Al-Minshawi',
    malayalamName: 'മുഹമ്മദ് സിദ്ദീഖ് അൽ-മിൻഷാവി',
    arabicName: 'محمد صديق المنشاوي',
    cdnBitrate: 128,
    everyAyahFolder: 'Minshawy_Murattal_128kbps',
  },
];

export function reciterById(id: string): QuranReciter {
  return RECITERS.find((r) => r.id === id) ?? RECITERS[0];
}

export function reciterDisplayName(r: QuranReciter, lang: AppLanguage): string {
  if (lang === 'ml') return r.malayalamName;
  if (lang === 'ar') return r.arabicName;
  return r.englishName;
}

export function alQuranCloudAudioUrl(reciter: QuranReciter, globalAyahNumber: number): string {
  return `https://cdn.islamic.network/quran/audio/${reciter.cdnBitrate}/${reciter.id}/${globalAyahNumber}.mp3`;
}

export function everyAyahAudioUrl(
  reciter: QuranReciter,
  surahNumber: number,
  ayahNumber: number
): string {
  const sss = String(surahNumber).padStart(3, '0');
  const aaa = String(ayahNumber).padStart(3, '0');
  return `https://everyayah.com/data/${reciter.everyAyahFolder}/${sss}${aaa}.mp3`;
}

export function toArabicNumber(num: number): string {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return String(num)
    .split('')
    .map((ch) => digits[Number(ch)] ?? ch)
    .join('');
}

export function ayahEndMarker(num: number): string {
  return ` ﴿${toArabicNumber(num)}﴾ `;
}

export const FIVE_PRAYER_KEYS: PrayerKey[] = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

export const ALARM_SOUNDS: AlarmSoundOption[] = [
  {
    id: 'adhan_alafasy',
    englishName: 'Adhan — Mishary Alafasy',
    malayalamName: 'ബാങ്ക് — മിശാരി അൽ-അഫാസി',
    arabicName: 'الأذان — مشاري العفاسي',
    remoteUrl: 'https://cdn.aladhan.com/audio/adhans/a4.mp3',
  },
  {
    id: 'adhan_nafees',
    englishName: 'Adhan — Ahmad al-Nafees',
    malayalamName: 'ബാങ്ക് — അഹ്‌മദ് അൽ-നഫീസ്',
    arabicName: 'الأذان — أحمد النفيس',
    remoteUrl: 'https://cdn.aladhan.com/audio/adhans/a1.mp3',
  },
  {
    id: 'alarm_tone',
    englishName: 'Alarm Tone (Device / Chime)',
    malayalamName: 'അലാറം ടോൺ (സാധാരണ ശബ്ദം)',
    arabicName: 'نغمة منبه',
  },
];

export const PRAYER_METHODS: PrayerCalculationMethod[] = [
  { id: 1, englishName: 'Karachi (UISK)', malayalamName: 'കറാച്ചി (UISK)', arabicName: 'جامعة العلوم الإسلامية بكراتشي' },
  { id: 3, englishName: 'Muslim World League (MWL)', malayalamName: 'മുസ്‌ലിം വേൾഡ് ലീഗ് (MWL)', arabicName: 'رابطة العالم الإسلامي' },
  { id: 4, englishName: 'Umm Al-Qura, Makkah', malayalamName: 'ഉമ്മുൽ ഖുറ, മക്ക', arabicName: 'أم القرى، مكة المكرمة' },
  { id: 2, englishName: 'ISNA (North America)', malayalamName: 'ISNA (വടക്കേ അമേരിക്ക)', arabicName: 'الجمعية الإسلامية لأمريكا الشمالية' },
  { id: 5, englishName: 'Egyptian General Authority', malayalamName: 'ഈജിപ്ഷ്യൻ അതോറിറ്റി', arabicName: 'الهيئة المصرية العامة للمساحة' },
  { id: 11, englishName: 'MUIS (Singapore)', malayalamName: 'MUIS (സിംഗപ്പൂർ)', arabicName: 'مجلس الشؤون الإسلامية في سنغافورة' },
  { id: 15, englishName: 'Moonsighting Committee', malayalamName: 'മൂൺസൈറ്റിംഗ് കമ്മിറ്റി', arabicName: 'لجنة تحري الهلال' },
];

export const QUICK_CITIES: CityPreset[] = [
  { city: 'Kochi', country: 'India', latitude: 9.9312, longitude: 76.2673 },
  { city: 'Kozhikode', country: 'India', latitude: 11.2588, longitude: 75.7804 },
  { city: 'Malappuram', country: 'India', latitude: 11.051, longitude: 76.0711 },
  { city: 'Thiruvananthapuram', country: 'India', latitude: 8.5241, longitude: 76.9366 },
  { city: 'Thrissur', country: 'India', latitude: 10.5276, longitude: 76.2144 },
  { city: 'Kannur', country: 'India', latitude: 11.8745, longitude: 75.3704 },
  { city: 'Bengaluru', country: 'India', latitude: 12.9716, longitude: 77.5946 },
  { city: 'Chennai', country: 'India', latitude: 13.0827, longitude: 80.2707 },
  { city: 'Mumbai', country: 'India', latitude: 19.076, longitude: 72.8777 },
  { city: 'Makkah', country: 'Saudi Arabia', latitude: 21.3891, longitude: 39.8579 },
  { city: 'Madinah', country: 'Saudi Arabia', latitude: 24.5247, longitude: 39.5692 },
  { city: 'Dubai', country: 'UAE', latitude: 25.2048, longitude: 55.2708 },
  { city: 'Doha', country: 'Qatar', latitude: 25.2854, longitude: 51.531 },
  { city: 'Riyadh', country: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753 },
];

export const HIJRI_MONTHS_EN = [
  'Muharram',
  'Safar',
  'Rabi al-Awwal',
  'Rabi al-Thani',
  'Jumada al-Ula',
  'Jumada al-Akhirah',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhu al-Qi'dah",
  'Dhu al-Hijjah',
];

export const HIJRI_MONTHS_AR = [
  'مُحَرَّم',
  'صَفَر',
  'رَبِيع الأَوَّل',
  'رَبِيع الثَّانِي',
  'جُمَادَى الأُولَى',
  'جُمَادَى الآخِرَة',
  'رَجَب',
  'شَعْبَان',
  'رَمَضَان',
  'شَوَّال',
  'ذُو القَعْدَة',
  'ذُو الحِجَّة',
];

export function defaultPrayerConfigs(): Record<PrayerKey, PrayerAlarmConfig> {
  return {
    fajr: { prayerKey: 'fajr', enabled: true, iqamahGapMinutes: 15, alarmRef: 'beforeAdhan', alarmOffsetMinutes: 10 },
    dhuhr: { prayerKey: 'dhuhr', enabled: true, iqamahGapMinutes: 15, alarmRef: 'beforeAdhan', alarmOffsetMinutes: 10 },
    asr: { prayerKey: 'asr', enabled: true, iqamahGapMinutes: 15, alarmRef: 'beforeAdhan', alarmOffsetMinutes: 10 },
    maghrib: { prayerKey: 'maghrib', enabled: true, iqamahGapMinutes: 15, alarmRef: 'beforeAdhan', alarmOffsetMinutes: 10 },
    isha: { prayerKey: 'isha', enabled: true, iqamahGapMinutes: 15, alarmRef: 'beforeAdhan', alarmOffsetMinutes: 10 },
  };
}
