import { FIVE_PRAYER_KEYS } from '@/lib/apiConfig';
import {
  loadDailyPrayerCache,
  loadHijriCalendarCache,
  saveDailyPrayerCache,
  saveHijriCalendarCache,
} from '@/lib/storage';
import type {
  AppSettings,
  CalendarDayEntry,
  ComputedPrayerSlot,
  DailyPrayerData,
  PrayerKey,
} from '@/types';

export function formatDateKey(dt: Date): string {
  const y = dt.getFullYear();
  const m = String(dt.getMonth() + 1).padStart(2, '0');
  const d = String(dt.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

export function formatAlAdhanDate(dt: Date): string {
  const d = String(dt.getDate()).padStart(2, '0');
  const m = String(dt.getMonth() + 1).padStart(2, '0');
  const y = dt.getFullYear();
  return `${d}-${m}-${y}`;
}

export function buildCacheSignature(settings: AppSettings): string {
  if (settings.prayerLocationMode === 'gps') {
    return `gps|${settings.prayerLat.toFixed(3)}|${settings.prayerLon.toFixed(3)}|m${settings.prayerMethod}|s${settings.prayerSchool}|a${settings.hijriAdjustment}`;
  }
  return `city|${settings.prayerCity.trim().toLowerCase()}|${settings.prayerCountry.trim().toLowerCase()}|m${settings.prayerMethod}|s${settings.prayerSchool}|a${settings.hijriAdjustment}`;
}

export function displayLocationLabel(settings: AppSettings): string {
  if (settings.prayerLocationMode === 'gps') {
    return settings.prayerCity.trim() ? `${settings.prayerCity} (GPS)` : 'GPS Location';
  }
  return `${settings.prayerCity}, ${settings.prayerCountry}`;
}

function cleanTime(raw: unknown): string {
  const str = String(raw ?? '00:00');
  const m = str.match(/(\d{1,2}:\d{2})/);
  return m?.[1] ?? '00:00';
}

export async function fetchDailyPrayerTimes(
  settings: AppSettings,
  targetDate = new Date(),
  forceRefresh = false
): Promise<DailyPrayerData> {
  const dateKey = formatDateKey(targetDate);
  const apiDate = formatAlAdhanDate(targetDate);
  const cacheSig = buildCacheSignature(settings);

  if (!forceRefresh) {
    const cached = loadDailyPrayerCache();
    if (cached && cached.dateKey === dateKey && cached.cacheSig === cacheSig) {
      return { ...cached, loadedFromCache: true };
    }
  }

  const base = 'https://api.aladhan.com/v1';
  const params = new URLSearchParams({
    method: String(settings.prayerMethod),
    school: String(settings.prayerSchool),
    adjustment: String(settings.hijriAdjustment),
    calendarMethod: 'MATHEMATICAL',
  });

  let url = '';
  if (settings.prayerLocationMode === 'gps') {
    params.set('latitude', settings.prayerLat.toFixed(5));
    params.set('longitude', settings.prayerLon.toFixed(5));
    url = `${base}/timings/${apiDate}?${params.toString()}`;
  } else {
    params.set('city', settings.prayerCity.trim() || 'Kochi');
    params.set('country', settings.prayerCountry.trim() || 'India');
    url = `${base}/timingsByCity/${apiDate}?${params.toString()}`;
  }

  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`AlAdhan HTTP ${res.status}`);
    const body = (await res.json()) as { data?: Record<string, unknown> };
    const data = body.data;
    if (!data) throw new Error('Invalid AlAdhan response');

    const timings = (data.timings as Record<string, unknown>) ?? {};
    const date = (data.date as Record<string, unknown>) ?? {};
    const meta = (data.meta as Record<string, unknown>) ?? {};
    const hijri = (date.hijri as Record<string, unknown>) ?? {};
    const greg = (date.gregorian as Record<string, unknown>) ?? {};
    const hMonth = (hijri.month as Record<string, unknown>) ?? {};
    const hWeekday = (hijri.weekday as Record<string, unknown>) ?? {};
    const gWeekday = (greg.weekday as Record<string, unknown>) ?? {};

    const parsed: DailyPrayerData = {
      dateKey,
      locationLabel: displayLocationLabel(settings),
      latitude: Number(meta.latitude ?? settings.prayerLat),
      longitude: Number(meta.longitude ?? settings.prayerLon),
      timezone: String(meta.timezone ?? 'Asia/Kolkata'),
      methodId: settings.prayerMethod,
      school: settings.prayerSchool,
      hijriAdjustment: settings.hijriAdjustment,
      gregorianReadable: String(date.readable ?? dateKey),
      hijriDay: String(hijri.day ?? '1'),
      hijriMonthNumber: Number(hMonth.number ?? 1),
      hijriMonthEn: String(hMonth.en ?? ''),
      hijriMonthAr: String(hMonth.ar ?? ''),
      hijriYear: String(hijri.year ?? '1448'),
      weekdayEn: String(gWeekday.en ?? hWeekday.en ?? ''),
      weekdayAr: String(hWeekday.ar ?? ''),
      baseTimings: {
        fajr: cleanTime(timings.Fajr),
        sunrise: cleanTime(timings.Sunrise),
        dhuhr: cleanTime(timings.Dhuhr),
        asr: cleanTime(timings.Asr),
        maghrib: cleanTime(timings.Maghrib),
        isha: cleanTime(timings.Isha),
      },
      loadedFromCache: false,
      cacheSig,
    };

    saveDailyPrayerCache(parsed);
    return parsed;
  } catch (err) {
    const cached = loadDailyPrayerCache();
    if (cached && cached.cacheSig === cacheSig) {
      return { ...cached, loadedFromCache: true };
    }
    throw err;
  }
}

export async function resolveTodayHijriDate(
  adjustment: number
): Promise<{ year: number; month: number; day: number }> {
  const normAdj = Math.max(-1, Math.min(1, adjustment));
  const apiDate = formatAlAdhanDate(new Date());
  const res = await fetch(
    `https://api.aladhan.com/v1/gToH/${apiDate}?calendarMethod=MATHEMATICAL&adjustment=${normAdj}`
  );
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const body = (await res.json()) as { data?: { hijri?: Record<string, unknown> } };
  const hijri = body.data?.hijri ?? {};
  const hMonth = (hijri.month as Record<string, unknown>) ?? {};
  return {
    year: Number(hijri.year ?? 1448),
    month: Math.max(1, Math.min(12, Number(hMonth.number ?? 1))),
    day: Number(hijri.day ?? 1),
  };
}

export async function fetchHijriMonthCalendar(
  hijriYear: number,
  hijriMonth: number,
  adjustment: number,
  forceRefresh = false
): Promise<CalendarDayEntry[]> {
  const normAdj = Math.max(-1, Math.min(1, adjustment));
  const normMonth = Math.max(1, Math.min(12, hijriMonth));

  if (!forceRefresh) {
    const cached = loadHijriCalendarCache(hijriYear, normMonth, normAdj) as CalendarDayEntry[] | null;
    if (cached && cached.length > 0) return cached;
  }

  const res = await fetch(
    `https://api.aladhan.com/v1/hToGCalendar/${normMonth}/${hijriYear}?calendarMethod=MATHEMATICAL&adjustment=${normAdj}`
  );
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const body = (await res.json()) as { data?: Array<Record<string, unknown>> };
  const rawList = body.data ?? [];

  const entries: CalendarDayEntry[] = rawList.map((item) => {
    const greg = (item.gregorian as Record<string, unknown>) ?? {};
    const hijri = (item.hijri as Record<string, unknown>) ?? {};
    const gMonth = (greg.month as Record<string, unknown>) ?? {};
    const gWeekday = (greg.weekday as Record<string, unknown>) ?? {};
    const hMonth = (hijri.month as Record<string, unknown>) ?? {};
    const holidays = Array.isArray(hijri.holidays) ? hijri.holidays.map(String) : [];

    return {
      gregorianDay: Number(greg.day ?? 1),
      gregorianMonth: Number(gMonth.number ?? 1),
      gregorianYear: Number(greg.year ?? 2026),
      gregorianMonthEn: String(gMonth.en ?? ''),
      weekdayEn: String(gWeekday.en ?? ''),
      hijriDay: Number(hijri.day ?? 1),
      hijriMonthNumber: Number(hMonth.number ?? normMonth),
      hijriMonthEn: String(hMonth.en ?? ''),
      hijriMonthAr: String(hMonth.ar ?? ''),
      hijriYear: Number(hijri.year ?? hijriYear),
      holidays,
    };
  });

  saveHijriCalendarCache(hijriYear, normMonth, normAdj, entries);
  return entries;
}

export function tunedTimeFor(
  data: DailyPrayerData,
  prayerKey: PrayerKey | 'sunrise',
  offsetMinutes: number,
  refDay: Date
): Date {
  const raw = data.baseTimings[prayerKey] ?? '00:00';
  const [hStr, mStr] = raw.split(':');
  const dt = new Date(
    refDay.getFullYear(),
    refDay.getMonth(),
    refDay.getDate(),
    Number(hStr) || 0,
    Number(mStr) || 0,
    0,
    0
  );
  return new Date(dt.getTime() + offsetMinutes * 60_000);
}

export function computeDailySlots(
  data: DailyPrayerData,
  settings: AppSettings,
  dismissedSet: Set<string>,
  refDay = new Date()
): ComputedPrayerSlot[] {
  const tune = (k: PrayerKey) => settings.prayerTunes[k] ?? 0;
  const fajrAdhan = tunedTimeFor(data, 'fajr', tune('fajr'), refDay);
  const sunrise = tunedTimeFor(data, 'sunrise', 0, refDay);
  const dhuhrAdhan = tunedTimeFor(data, 'dhuhr', tune('dhuhr'), refDay);
  const asrAdhan = tunedTimeFor(data, 'asr', tune('asr'), refDay);
  const maghribAdhan = tunedTimeFor(data, 'maghrib', tune('maghrib'), refDay);
  const ishaAdhan = tunedTimeFor(data, 'isha', tune('isha'), refDay);
  const tomorrow = new Date(refDay.getFullYear(), refDay.getMonth(), refDay.getDate() + 1);
  const tomorrowFajr = tunedTimeFor(data, 'fajr', tune('fajr'), tomorrow);

  const adhans: Record<PrayerKey, Date> = {
    fajr: fajrAdhan,
    dhuhr: dhuhrAdhan,
    asr: asrAdhan,
    maghrib: maghribAdhan,
    isha: ishaAdhan,
  };

  const boundaries: Record<PrayerKey, { key: PrayerKey | 'sunrise'; dt: Date }> = {
    fajr: { key: 'sunrise', dt: sunrise },
    dhuhr: { key: 'asr', dt: asrAdhan },
    asr: { key: 'maghrib', dt: maghribAdhan },
    maghrib: { key: 'isha', dt: ishaAdhan },
    isha: { key: 'fajr', dt: tomorrowFajr },
  };

  const dateStr = formatDateKey(refDay);

  return FIVE_PRAYER_KEYS.map((key) => {
    const adhan = adhans[key];
    const b = boundaries[key];
    const safetyLimit = new Date(b.dt.getTime() - 10 * 60_000);
    const maxGap = Math.max(0, Math.floor((safetyLimit.getTime() - adhan.getTime()) / 60_000));

    const cfg = settings.prayerConfigs[key];
    const clampedGap = Math.max(0, Math.min(maxGap, cfg.iqamahGapMinutes));
    const iqamah = new Date(adhan.getTime() + clampedGap * 60_000);

    let alarmTime: Date | null = null;
    if (cfg.enabled) {
      if (cfg.alarmRef === 'beforeAdhan') {
        const minsBefore = Math.max(0, Math.min(120, cfg.alarmOffsetMinutes));
        alarmTime = new Date(adhan.getTime() - minsBefore * 60_000);
      } else {
        const signed = Math.max(-60, Math.min(60, cfg.alarmOffsetMinutes));
        alarmTime = new Date(iqamah.getTime() + signed * 60_000);
      }
      if (alarmTime.getTime() > safetyLimit.getTime()) {
        alarmTime = safetyLimit;
      }
    }

    return {
      prayerKey: key,
      adhanTime: adhan,
      iqamahTime: iqamah,
      alarmTime,
      nextBoundaryAdhan: b.dt,
      safetyLimitTime: safetyLimit,
      nextBoundaryKey: b.key,
      masterEnabled: settings.masterAlarmEnabled,
      prayerAlarmEnabled: cfg.enabled,
      dismissedToday: dismissedSet.has(`${dateStr}|${key}`),
      tuneMinutes: tune(key),
      effectiveIqamahGap: clampedGap,
      maxAllowedIqamahGap: maxGap,
    };
  });
}

export function format12Hour(dt: Date): string {
  const h24 = dt.getHours();
  const amPm = h24 >= 12 ? 'PM' : 'AM';
  const h12 = h24 % 12 === 0 ? 12 : h24 % 12;
  const m = String(dt.getMinutes()).padStart(2, '0');
  return `${h12}:${m} ${amPm}`;
}
