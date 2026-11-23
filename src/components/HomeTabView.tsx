'use client';

import React, { useMemo, useState } from 'react';
import {
  ArrowRight,
  Bookmark,
  BookOpen,
  BookOpenCheck,
  CalendarDays,
  Clock,
  FileDown,
  HandHeart,
  Layers,
  Repeat,
  Search,
  Settings,
  Sparkles,
  Trash2,
  VolumeX,
  X,
} from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { ADHKAR_ENTRIES } from '@/data/adhkar';
import { ASMAUL_HUSNA_LIST } from '@/data/asmaulHusna';
import { format12Hour } from '@/lib/islamicFeaturesApi';
import type { HomeFeatureView } from '@/types';

export function HomeTabView() {
  const {
    settings,
    t,
    surahs,
    lastRead,
    openReader,
    setActiveTab,
    setQuranSubTab,
    openHomeFeature,
    prayerData,
    nextPrayerSlot,
    countdownLabel,
    recentActivity,
    clearRecentActivity,
    bookmarks,
  } = useIbadia();

  const [search, setSearch] = useState('');

  const todayDow = new Date().getDay();
  const showKahfBanner = todayDow === 4 || todayDow === 5; // Thursday or Friday

  const featureTiles: Array<{
    id: string;
    title: string;
    subtitle: string;
    icon: React.ReactNode;
    accent: string;
    onClick: () => void;
    keywords: string;
  }> = useMemo(
    () => [
      {
        id: 'prayer',
        title: t.actionPrayer,
        subtitle: nextPrayerSlot
          ? `${format12Hour(nextPrayerSlot.adhanTime)}`
          : 'Adhan & Iqamah',
        icon: <Clock className="w-5 h-5" />,
        accent: 'bg-emerald-500/10 text-emerald-700 dark:text-emerald-300',
        onClick: () => openHomeFeature('prayer'),
        keywords: 'prayer salah namaz adhan iqamah alarm dnd silent',
      },
      {
        id: 'dnd',
        title: t.actionAutoSilent,
        subtitle: settings.autoSilentEnabled
          ? `ON · ${settings.autoSilentDurationMinutes} min`
          : 'Auto DND Mode',
        icon: <VolumeX className="w-5 h-5" />,
        accent: 'bg-teal-500/10 text-teal-700 dark:text-teal-300',
        onClick: () => openHomeFeature('prayer'),
        keywords: 'auto silent dnd do not disturb prayer mute ringer',
      },
      {
        id: 'hijri',
        title: t.actionHijri,
        subtitle: prayerData
          ? `${prayerData.hijriDay} ${prayerData.hijriMonthEn}`
          : 'Islamic Dates',
        icon: <CalendarDays className="w-5 h-5" />,
        accent: 'bg-amber-500/10 text-amber-700 dark:text-amber-300',
        onClick: () => openHomeFeature('hijri'),
        keywords: 'hijri calendar ramadan eid moon islamic date',
      },
      {
        id: 'adhkar',
        title: t.actionAdhkar,
        subtitle: `${ADHKAR_ENTRIES.length} Duas`,
        icon: <HandHeart className="w-5 h-5" />,
        accent: 'bg-sky-500/10 text-sky-700 dark:text-sky-300',
        onClick: () => openHomeFeature('adhkar'),
        keywords: 'adhkar dua morning evening hisnul muslim',
      },
      {
        id: 'tasbih',
        title: t.actionCounter,
        subtitle: 'SubhanAllah · 33/99',
        icon: <Repeat className="w-5 h-5" />,
        accent: 'bg-indigo-500/10 text-indigo-700 dark:text-indigo-300',
        onClick: () => openHomeFeature('tasbih'),
        keywords: 'tasbih counter dhikr tally zikr',
      },
      {
        id: 'names99',
        title: t.actionNames99,
        subtitle: `${settings.studiedNames99.length}/99 · Grid & List`,
        icon: <Sparkles className="w-5 h-5" />,
        accent: 'bg-amber-500/15 text-amber-700 dark:text-amber-300',
        onClick: () => openHomeFeature('names99'),
        keywords: '99 names allah asmaul husna arabic table',
      },
      {
        id: 'export',
        title: t.actionExport,
        subtitle: 'PDF & PNG Cards',
        icon: <FileDown className="w-5 h-5" />,
        accent: 'bg-emerald-600/10 text-emerald-700 dark:text-emerald-300',
        onClick: () => openHomeFeature('export'),
        keywords: 'export pdf png image share print surah',
      },
      {
        id: 'tajweed',
        title: t.actionTajweed,
        subtitle: settings.tajweedEnabled ? 'Color Coding ON' : '8 Rules Guide',
        icon: <BookOpenCheck className="w-5 h-5" />,
        accent: 'bg-rose-500/10 text-rose-700 dark:text-rose-300',
        onClick: () => openHomeFeature('tajweed'),
        keywords: 'tajweed color rules ghunnah qalqalah madd ikhfa',
      },
      {
        id: 'quran_read',
        title: t.actionReadQuran,
        subtitle: '114 Surahs',
        icon: <BookOpen className="w-5 h-5" />,
        accent: 'bg-emerald-700/10 text-emerald-700 dark:text-emerald-300',
        onClick: () => {
          setQuranSubTab('surah');
          setActiveTab('quran');
        },
        keywords: 'read quran surah mushaf',
      },
      {
        id: 'juz',
        title: t.actionJuz,
        subtitle: '30 Juz Index',
        icon: <Layers className="w-5 h-5" />,
        accent: 'bg-cyan-500/10 text-cyan-700 dark:text-cyan-300',
        onClick: () => {
          setQuranSubTab('juz');
          setActiveTab('quran');
        },
        keywords: 'juz para 30 index',
      },
      {
        id: 'bookmarks',
        title: t.actionBookmarks,
        subtitle: `${bookmarks.length} Saved`,
        icon: <Bookmark className="w-5 h-5" />,
        accent: 'bg-violet-500/10 text-violet-700 dark:text-violet-300',
        onClick: () => {
          setQuranSubTab('bookmarks');
          setActiveTab('quran');
        },
        keywords: 'bookmarks saved ayahs',
      },
      {
        id: 'settings',
        title: t.actionSettings,
        subtitle: t.autoSavedHint,
        icon: <Settings className="w-5 h-5" />,
        accent: 'bg-slate-500/10 text-slate-700 dark:text-slate-300',
        onClick: () => setActiveTab('settings'),
        keywords: 'settings theme language reciter font',
      },
    ],
    [
      t,
      nextPrayerSlot,
      settings.autoSilentEnabled,
      settings.autoSilentDurationMinutes,
      settings.studiedNames99.length,
      settings.tajweedEnabled,
      prayerData,
      bookmarks.length,
      openHomeFeature,
      setQuranSubTab,
      setActiveTab,
    ]
  );

  const searchResults = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return null;

    const matchingTools = featureTiles.filter(
      (ft) =>
        ft.title.toLowerCase().includes(q) ||
        ft.subtitle.toLowerCase().includes(q) ||
        ft.keywords.includes(q)
    );
    const matchingSurahs = surahs
      .filter(
        (s) =>
          String(s.number) === q ||
          s.englishName.toLowerCase().includes(q) ||
          s.englishNameTranslation.toLowerCase().includes(q) ||
          s.nameArabic.includes(search.trim())
      )
      .slice(0, 6);
    const matchingNames = ASMAUL_HUSNA_LIST.filter(
      (n) =>
        String(n.number) === q ||
        n.transliteration.toLowerCase().includes(q) ||
        n.englishMeaning.toLowerCase().includes(q) ||
        n.malayalamMeaning.includes(search.trim()) ||
        n.arabic.includes(search.trim())
    ).slice(0, 5);
    const matchingAdhkar = ADHKAR_ENTRIES.filter(
      (a) =>
        a.titleEn.toLowerCase().includes(q) ||
        a.titleMl.includes(search.trim()) ||
        a.arabic.includes(search.trim())
    ).slice(0, 4);

    return {
      tools: matchingTools,
      surahs: matchingSurahs,
      names: matchingNames,
      adhkar: matchingAdhkar,
      empty:
        matchingTools.length === 0 &&
        matchingSurahs.length === 0 &&
        matchingNames.length === 0 &&
        matchingAdhkar.length === 0,
    };
  }, [search, featureTiles, surahs]);

  const prayerNameFor = (k?: string) => {
    if (!k) return '--';
    if (k === 'fajr') return t.fajrName;
    if (k === 'dhuhr') return t.dhuhrName;
    if (k === 'asr') return t.asrName;
    if (k === 'maghrib') return t.maghribName;
    return t.ishaName;
  };

  return (
    <div className="mx-auto max-w-4xl px-4 pt-3 pb-28 space-y-4">
      {/* Universal Search Bar */}
      <div className="relative">
        <Search className="w-4 h-4 text-[var(--text-muted)] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder={t.dashboardSearchHint}
          className="w-full rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] pl-10 pr-9 py-3 text-sm text-[var(--text-primary)] placeholder:text-[var(--text-muted)] shadow-sm focus:outline-none focus:ring-2 focus:ring-emerald-600/30"
        />
        {search && (
          <button
            type="button"
            onClick={() => setSearch('')}
            className="absolute right-3 top-1/2 -translate-y-1/2 p-1 rounded-lg text-[var(--text-muted)] hover:bg-[var(--bg-elevated)]"
            aria-label="Clear search"
          >
            <X className="w-4 h-4" />
          </button>
        )}
      </div>

      {/* Live Search Results Mode */}
      {searchResults ? (
        <div className="space-y-4">
          {searchResults.empty && (
            <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-8 text-center text-sm text-[var(--text-muted)]">
              {t.noSearchResults}
            </div>
          )}

          {searchResults.tools.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)] px-1">
                {t.quickActionsTitle}
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                {searchResults.tools.map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    onClick={item.onClick}
                    className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3.5 text-left hover:border-emerald-600/40 transition flex items-start gap-3"
                  >
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${item.accent}`}>
                      {item.icon}
                    </div>
                    <div className="min-w-0">
                      <p className="text-xs sm:text-sm font-bold text-[var(--text-primary)] truncate">
                        {item.title}
                      </p>
                      <p className="text-[11px] text-[var(--text-muted)] truncate mt-0.5">
                        {item.subtitle}
                      </p>
                    </div>
                  </button>
                ))}
              </div>
            </div>
          )}

          {searchResults.surahs.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)] px-1">
                {t.surahTabLabel}
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {searchResults.surahs.map((s) => (
                  <button
                    key={s.number}
                    type="button"
                    onClick={() => openReader(s.number)}
                    className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-3 flex items-center justify-between hover:border-emerald-600/40 text-left"
                  >
                    <div>
                      <p className="text-sm font-bold">
                        {s.number}. {s.englishName}
                      </p>
                      <p className="text-xs text-[var(--text-muted)]">
                        {s.numberOfAyahs} {t.ayahsLabel}
                      </p>
                    </div>
                    <span className="font-arabic text-xl font-bold text-[var(--emerald-primary)]">
                      {s.nameArabic}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {searchResults.names.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)] px-1">
                {t.names99Title}
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {searchResults.names.map((n) => (
                  <button
                    key={n.number}
                    type="button"
                    onClick={() => openHomeFeature('names99')}
                    className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-3 flex items-center justify-between hover:border-emerald-600/40 text-left"
                  >
                    <div>
                      <p className="text-sm font-bold">
                        {n.number}. {n.transliteration}
                      </p>
                      <p className="text-xs text-[var(--text-muted)]">
                        {settings.appLanguage === 'ml' ? n.malayalamMeaning : n.englishMeaning}
                      </p>
                    </div>
                    <span className="font-arabic text-xl font-bold text-[var(--emerald-primary)]">
                      {n.arabic}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {searchResults.adhkar.length > 0 && (
            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)] px-1">
                {t.actionAdhkar}
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {searchResults.adhkar.map((a) => (
                  <button
                    key={a.id}
                    type="button"
                    onClick={() => openHomeFeature('adhkar')}
                    className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-3 text-left hover:border-emerald-600/40"
                  >
                    <p className="text-sm font-bold truncate">
                      {settings.appLanguage === 'ml' ? a.titleMl : a.titleEn}
                    </p>
                    <p className="font-arabic text-base text-[var(--emerald-primary)] truncate mt-0.5">
                      {a.arabic}
                    </p>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      ) : (
        <>
          {/* Hero Row: Live Prayer Card + Last Read */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {/* Next Prayer Live Strip */}
            <button
              type="button"
              onClick={() => openHomeFeature('prayer')}
              className="rounded-3xl bg-gradient-to-br from-emerald-800 via-emerald-700 to-teal-800 text-white p-5 text-left shadow-md hover:brightness-105 transition flex flex-col justify-between"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-100/80">
                    {t.nextPrayerLabel}
                  </span>
                  <h2 className="mt-1 text-2xl font-extrabold flex items-baseline gap-2">
                    <span>{prayerNameFor(nextPrayerSlot?.prayerKey)}</span>
                    <span className="text-lg font-bold text-amber-300 tabular-nums">
                      {nextPrayerSlot ? format12Hour(nextPrayerSlot.adhanTime) : '--:--'}
                    </span>
                  </h2>
                </div>
                <span className="rounded-xl bg-white/15 px-2.5 py-1 text-xs font-bold tabular-nums">
                  {countdownLabel}
                </span>
              </div>

              <div className="mt-4 pt-3 border-t border-white/15 flex items-center justify-between text-xs text-emerald-100">
                <span className="truncate">
                  {prayerData
                    ? `${prayerData.hijriDay} ${prayerData.hijriMonthEn} ${prayerData.hijriYear}`
                    : settings.prayerCity}
                </span>
                <span className="inline-flex items-center gap-1 font-bold text-white shrink-0">
                  {t.actionPrayer} <ArrowRight className="w-3.5 h-3.5" />
                </span>
              </div>
            </button>

            {/* Last Read Card OR Start Reading Quran */}
            <button
              type="button"
              onClick={() =>
                lastRead
                  ? openReader(lastRead.surahNumber, lastRead.ayahNumber, lastRead.scrollOffset)
                  : openReader(1, 1)
              }
              className="rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-5 text-left shadow-sm hover:border-emerald-600/50 transition flex flex-col justify-between"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-[var(--emerald-primary)]">
                    {lastRead ? t.lastRead : t.actionReadQuran}
                  </span>
                  <h2 className="mt-1 text-xl font-extrabold text-[var(--text-primary)] truncate">
                    {lastRead ? lastRead.surahNameEn : 'Al-Fatihah'}
                  </h2>
                  <p className="text-xs text-[var(--text-muted)] mt-0.5 tabular-nums">
                    {lastRead
                      ? `${t.ayahLabel} ${lastRead.ayahNumber} · ${t.pageLabel} ${lastRead.pageNumber}`
                      : '114 Surahs · Mushaf & Verse View'}
                  </p>
                </div>
                <span className="font-arabic text-2xl font-bold text-[var(--emerald-primary)] shrink-0">
                  {lastRead ? lastRead.surahNameAr : 'ٱلْفَاتِحَةِ'}
                </span>
              </div>

              <div className="mt-4 pt-3 border-t border-[var(--border-color)] flex items-center justify-between">
                <span className="text-xs font-bold text-[var(--emerald-primary)] inline-flex items-center gap-1.5">
                  <BookOpen className="w-4 h-4" />
                  {t.continueReading}
                </span>
                <ArrowRight className="w-4 h-4 text-[var(--text-muted)]" />
              </div>
            </button>
          </div>

          {/* Jumu'ah Surah Al-Kahf Reminder Banner (Thursdays & Fridays) */}
          {showKahfBanner && (
            <button
              type="button"
              onClick={() => openReader(18, 1)}
              className="w-full rounded-2xl border border-amber-500/35 bg-amber-500/10 px-4 py-3.5 flex items-center justify-between gap-3 text-left hover:bg-amber-500/15 transition"
            >
              <div className="min-w-0">
                <p className="text-xs sm:text-sm font-extrabold text-amber-800 dark:text-amber-300">
                  {t.kahfBannerTitle}
                </p>
                <p className="text-xs text-[var(--text-secondary)] mt-0.5">
                  {t.kahfOpenSurahBtn}
                </p>
              </div>
              <span className="font-arabic text-xl font-bold text-amber-700 dark:text-amber-300 shrink-0">
                سورة الكهف
              </span>
            </button>
          )}

          {/* Recent Activity Chips */}
          {recentActivity.length > 0 && (
            <div>
              <div className="flex items-center justify-between mb-2 px-0.5">
                <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  {t.recentActivityTitle}
                </h3>
                <button
                  type="button"
                  onClick={clearRecentActivity}
                  className="inline-flex items-center gap-1 text-[11px] font-bold text-[var(--text-muted)] hover:text-rose-500"
                >
                  <Trash2 className="w-3 h-3" />
                  <span>{t.clearHistoryLabel}</span>
                </button>
              </div>

              <div className="flex gap-2 overflow-x-auto pb-1">
                {recentActivity.map((act) => {
                  const title =
                    settings.appLanguage === 'ml'
                      ? act.titleMl
                      : settings.appLanguage === 'ar'
                      ? act.titleAr
                      : act.titleEn;
                  return (
                    <button
                      key={act.id}
                      type="button"
                      onClick={() => {
                        if (act.surahNumber) {
                          openReader(act.surahNumber, act.ayahNumber);
                        } else if (act.featureView) {
                          openHomeFeature(act.featureView as Exclude<HomeFeatureView, null>);
                        } else if (act.quranSubTab) {
                          setQuranSubTab(act.quranSubTab);
                          setActiveTab('quran');
                        }
                      }}
                      className="shrink-0 rounded-xl border border-[var(--border-color)] bg-[var(--bg-card)] px-3 py-2 text-left hover:border-emerald-600/40 transition"
                    >
                      <p className="text-xs font-bold text-[var(--text-primary)] whitespace-nowrap">
                        {title}
                      </p>
                      <p className="text-[10px] text-[var(--text-muted)] whitespace-nowrap">
                        {settings.appLanguage === 'ml'
                          ? act.subtitleMl
                          : settings.appLanguage === 'ar'
                          ? act.subtitleAr
                          : act.subtitleEn}
                      </p>
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* Features & Tools Single-Feature Launch Grid */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)] mb-2.5 px-0.5">
              {t.quickActionsTitle}
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
              {featureTiles.map((tile) => (
                <button
                  key={tile.id}
                  type="button"
                  onClick={tile.onClick}
                  className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3.5 text-left hover:border-emerald-600/50 hover:bg-[var(--bg-elevated)]/50 active:scale-[0.98] transition flex flex-col gap-2.5"
                >
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${tile.accent}`}>
                    {tile.icon}
                  </div>
                  <div className="min-w-0">
                    <p className="text-xs sm:text-sm font-bold text-[var(--text-primary)] truncate">
                      {tile.title}
                    </p>
                    <p className="text-[11px] text-[var(--text-muted)] truncate mt-0.5">
                      {tile.subtitle}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
