import { QURAN_API_CONFIG } from '@/lib/apiConfig';
import { idbGet, idbSet } from '@/lib/storage';
import type { AyahItem, JuzAyahEntry, JuzDetail, SurahDetail, SurahSummary, TranslationCode } from '@/types';

let memSurahList: SurahSummary[] | null = null;
const memArabicSurah = new Map<number, { summary: SurahSummary; ayahs: AyahItem[] }>();
const memSurahTranslation = new Map<string, string[]>();
const memJuzArabic = new Map<number, JuzAyahEntry[]>();
const memJuzTranslation = new Map<string, string[]>();

const BISMILLAH_PREFIX = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ';

function editionForCode(code: TranslationCode): string {
  if (code === 'ml') return QURAN_API_CONFIG.malayalamTranslationEdition;
  if (code === 'ar') return QURAN_API_CONFIG.arabicTafsirEdition;
  return QURAN_API_CONFIG.englishTranslationEdition;
}

export async function fetchSurahList(): Promise<SurahSummary[]> {
  if (memSurahList) return memSurahList;
  const cached = await idbGet<SurahSummary[]>('surah_list_v3');
  if (cached && cached.length > 0) {
    memSurahList = cached;
    return cached;
  }

  const res = await fetch(`${QURAN_API_CONFIG.baseUrl}/surah`);
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  const body = (await res.json()) as { data: Array<Record<string, unknown>> };
  const surahs: SurahSummary[] = body.data.map((s) => ({
    number: Number(s.number),
    nameArabic: String(s.name ?? ''),
    englishName: String(s.englishName ?? ''),
    englishNameTranslation: String(s.englishNameTranslation ?? ''),
    numberOfAyahs: Number(s.numberOfAyahs ?? 0),
    revelationType: String(s.revelationType ?? ''),
  }));
  memSurahList = surahs;
  await idbSet('surah_list_v3', surahs);
  return surahs;
}

async function fetchArabicSurah(
  surahNumber: number
): Promise<{ summary: SurahSummary; ayahs: AyahItem[] }> {
  const mem = memArabicSurah.get(surahNumber);
  if (mem) return mem;

  const key = `surah_ar_v3_${surahNumber}`;
  const cached = await idbGet<{ summary: SurahSummary; ayahs: AyahItem[] }>(key);
  if (cached) {
    memArabicSurah.set(surahNumber, cached);
    return cached;
  }

  const res = await fetch(`${QURAN_API_CONFIG.baseUrl}/surah/${surahNumber}/${QURAN_API_CONFIG.arabicEdition}`);
  if (!res.ok) throw new Error(`Failed Surah ${surahNumber}`);
  const body = (await res.json()) as { data: Record<string, unknown> };
  const d = body.data;
  const summary: SurahSummary = {
    number: Number(d.number),
    nameArabic: String(d.name ?? ''),
    englishName: String(d.englishName ?? ''),
    englishNameTranslation: String(d.englishNameTranslation ?? ''),
    numberOfAyahs: Number(d.numberOfAyahs ?? 0),
    revelationType: String(d.revelationType ?? ''),
  };
  const rawAyahs = (d.ayahs as Array<Record<string, unknown>>) ?? [];
  const ayahs: AyahItem[] = rawAyahs.map((a) => {
    const numInSurah = Number(a.numberInSurah);
    let text = String(a.text ?? '');
    if (surahNumber !== 1 && surahNumber !== 9 && numInSurah === 1 && text.startsWith(BISMILLAH_PREFIX)) {
      text = text.slice(BISMILLAH_PREFIX.length).trim();
    }
    return {
      numberInSurah: numInSurah,
      globalNumber: Number(a.number),
      arabicText: text,
      juz: Number(a.juz ?? 1),
      page: Number(a.page ?? 1),
    };
  });

  const payload = { summary, ayahs };
  memArabicSurah.set(surahNumber, payload);
  await idbSet(key, payload);
  return payload;
}

async function fetchSurahTranslation(surahNumber: number, code: TranslationCode): Promise<string[]> {
  const key = `surah_tr_v3_${surahNumber}_${code}`;
  const mem = memSurahTranslation.get(key);
  if (mem) return mem;

  const cached = await idbGet<string[]>(key);
  if (cached) {
    memSurahTranslation.set(key, cached);
    return cached;
  }

  try {
    const edition = editionForCode(code);
    const res = await fetch(`${QURAN_API_CONFIG.baseUrl}/surah/${surahNumber}/${edition}`);
    if (!res.ok) return [];
    const body = (await res.json()) as { data: { ayahs: Array<{ text?: string }> } };
    const texts = (body.data?.ayahs ?? []).map((a) => String(a.text ?? ''));
    memSurahTranslation.set(key, texts);
    await idbSet(key, texts);
    return texts;
  } catch {
    return [];
  }
}

export async function fetchSurahDetail(
  surahNumber: number,
  requiredTranslations: TranslationCode[]
): Promise<SurahDetail> {
  const base = await fetchArabicSurah(surahNumber);
  const translations: Partial<Record<TranslationCode, string[]>> = {};
  if (requiredTranslations.length > 0) {
    const pairs = await Promise.all(
      requiredTranslations.map(async (code) => [code, await fetchSurahTranslation(surahNumber, code)] as const)
    );
    for (const [code, list] of pairs) {
      translations[code] = list;
    }
  }
  return {
    summary: base.summary,
    ayahs: base.ayahs,
    translations,
  };
}

async function fetchJuzArabic(juzNumber: number): Promise<JuzAyahEntry[]> {
  const mem = memJuzArabic.get(juzNumber);
  if (mem) return mem;

  const key = `juz_ar_v3_${juzNumber}`;
  const cached = await idbGet<JuzAyahEntry[]>(key);
  if (cached) {
    memJuzArabic.set(juzNumber, cached);
    return cached;
  }

  const res = await fetch(`${QURAN_API_CONFIG.baseUrl}/juz/${juzNumber}/${QURAN_API_CONFIG.arabicEdition}`);
  if (!res.ok) throw new Error(`Failed Juz ${juzNumber}`);
  const body = (await res.json()) as { data: { ayahs: Array<Record<string, unknown>> } };

  const entries: JuzAyahEntry[] = (body.data?.ayahs ?? []).map((item) => {
    const s = (item.surah as Record<string, unknown>) ?? {};
    const surah: SurahSummary = {
      number: Number(s.number ?? 1),
      nameArabic: String(s.name ?? ''),
      englishName: String(s.englishName ?? ''),
      englishNameTranslation: String(s.englishNameTranslation ?? ''),
      numberOfAyahs: Number(s.numberOfAyahs ?? 0),
      revelationType: String(s.revelationType ?? ''),
    };
    const numInSurah = Number(item.numberInSurah ?? 1);
    let text = String(item.text ?? '');
    if (surah.number !== 1 && surah.number !== 9 && numInSurah === 1 && text.startsWith(BISMILLAH_PREFIX)) {
      text = text.slice(BISMILLAH_PREFIX.length).trim();
    }
    return {
      surah,
      ayah: {
        numberInSurah: numInSurah,
        globalNumber: Number(item.number ?? 1),
        arabicText: text,
        juz: Number(item.juz ?? juzNumber),
        page: Number(item.page ?? 1),
      },
    };
  });

  memJuzArabic.set(juzNumber, entries);
  await idbSet(key, entries);
  return entries;
}

async function fetchJuzTranslation(juzNumber: number, code: TranslationCode): Promise<string[]> {
  const key = `juz_tr_v3_${juzNumber}_${code}`;
  const mem = memJuzTranslation.get(key);
  if (mem) return mem;

  const cached = await idbGet<string[]>(key);
  if (cached) {
    memJuzTranslation.set(key, cached);
    return cached;
  }

  try {
    const edition = editionForCode(code);
    const res = await fetch(`${QURAN_API_CONFIG.baseUrl}/juz/${juzNumber}/${edition}`);
    if (!res.ok) return [];
    const body = (await res.json()) as { data: { ayahs: Array<{ text?: string }> } };
    const texts = (body.data?.ayahs ?? []).map((a) => String(a.text ?? ''));
    memJuzTranslation.set(key, texts);
    await idbSet(key, texts);
    return texts;
  } catch {
    return [];
  }
}

export async function fetchJuzDetail(
  juzNumber: number,
  requiredTranslations: TranslationCode[]
): Promise<JuzDetail> {
  const entries = await fetchJuzArabic(juzNumber);
  const translations: Partial<Record<TranslationCode, string[]>> = {};
  if (requiredTranslations.length > 0) {
    const pairs = await Promise.all(
      requiredTranslations.map(async (code) => [code, await fetchJuzTranslation(juzNumber, code)] as const)
    );
    for (const [code, list] of pairs) {
      translations[code] = list;
    }
  }
  return { juzNumber, entries, translations };
}
