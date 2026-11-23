'use client';

import React, { useMemo, useState } from 'react';
import {
  Bookmark,
  BookOpen,
  Layers,
  RefreshCw,
  Search,
  Trash2,
  X,
} from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { FEATURED_SURAHS, JUZ_CATALOG } from '@/lib/apiConfig';

export function QuranTabView() {
  const {
    surahs,
    surahsLoading,
    surahsError,
    reloadSurahs,
    quranSubTab,
    setQuranSubTab,
    openReader,
    bookmarks,
    removeBookmark,
    lastRead,
    settings,
    t,
  } = useIbadia();

  const [query, setQuery] = useState('');

  const filteredSurahs = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return surahs;
    return surahs.filter(
      (s) =>
        String(s.number).includes(q) ||
        s.englishName.toLowerCase().includes(q) ||
        s.englishNameTranslation.toLowerCase().includes(q) ||
        s.nameArabic.includes(query.trim())
    );
  }, [surahs, query]);

  const filteredJuz = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return JUZ_CATALOG;
    return JUZ_CATALOG.filter(
      (j) =>
        String(j.number).includes(q) ||
        j.arabicName.includes(query.trim()) ||
        j.openingCue.includes(query.trim())
    );
  }, [query]);

  return (
    <div className="mx-auto max-w-4xl px-4 pt-3 pb-28">
      {/* NOTE: Per user requirement, the app name header is completely hidden when Quran tab is open */}

      {/* Compact Resume Strip (only if user has read before) */}
      {lastRead && (
        <button
          type="button"
          onClick={() => openReader(lastRead.surahNumber, lastRead.ayahNumber, lastRead.scrollOffset)}
          className="mb-3 w-full rounded-2xl border border-emerald-700/20 bg-gradient-to-r from-emerald-800 to-emerald-700 text-white px-4 py-3 flex items-center justify-between shadow-sm hover:brightness-105 transition text-left"
        >
          <div className="min-w-0">
            <p className="text-[11px] uppercase tracking-wider text-emerald-100/80 font-semibold">
              {t.lastRead}
            </p>
            <p className="text-sm sm:text-base font-bold truncate mt-0.5">
              {lastRead.surahNameEn} · {t.ayahLabel} {lastRead.ayahNumber}
            </p>
          </div>
          <div className="flex items-center gap-3 shrink-0">
            <span className="font-arabic text-xl">{lastRead.surahNameAr}</span>
            <span className="rounded-xl bg-white/15 px-3 py-1.5 text-xs font-bold">
              {t.continueReading}
            </span>
          </div>
        </button>
      )}

      {/* Surah | Juz | Bookmarks Segmented Sub-Tabs */}
      <div className="rounded-2xl bg-[var(--bg-elevated)] border border-[var(--border-color)] p-1 grid grid-cols-3 gap-1">
        <button
          type="button"
          onClick={() => setQuranSubTab('surah')}
          className={`flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs sm:text-sm font-bold transition ${
            quranSubTab === 'surah'
              ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
              : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
          }`}
        >
          <BookOpen className="w-4 h-4" />
          <span>{t.surahTabLabel}</span>
        </button>

        <button
          type="button"
          onClick={() => setQuranSubTab('juz')}
          className={`flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs sm:text-sm font-bold transition ${
            quranSubTab === 'juz'
              ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
              : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>{t.juzTabLabel}</span>
        </button>

        <button
          type="button"
          onClick={() => setQuranSubTab('bookmarks')}
          className={`flex items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs sm:text-sm font-bold transition ${
            quranSubTab === 'bookmarks'
              ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
              : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)]'
          }`}
        >
          <Bookmark className="w-4 h-4" />
          <span>{t.bookmarksTab}</span>
          {bookmarks.length > 0 && (
            <span className="text-[11px] font-bold opacity-75 tabular-nums">
              ({bookmarks.length})
            </span>
          )}
        </button>
      </div>

      {/* Search Bar for Surah & Juz */}
      {quranSubTab !== 'bookmarks' && (
        <div className="relative mt-3">
          <Search className="w-4 h-4 text-[var(--text-muted)] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={t.searchHint}
            className="w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-card)] pl-10 pr-9 py-2.5 text-sm text-[var(--text-primary)] placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-2 focus:ring-emerald-600/30"
          />
          {query && (
            <button
              type="button"
              onClick={() => setQuery('')}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 p-1 rounded-md text-[var(--text-muted)] hover:bg-[var(--bg-elevated)]"
              aria-label="Clear search"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      )}

      {/* SUB-TAB 1: SURAH LIST */}
      {quranSubTab === 'surah' && (
        <div className="mt-4 space-y-4">
          {/* Commonly Recited Horizontal Calligraphy Cards */}
          {!query && (
            <div>
              <h2 className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)] mb-2 px-0.5">
                {t.commonlyRecited}
              </h2>
              <div className="flex gap-2.5 overflow-x-auto pb-1.5">
                {FEATURED_SURAHS.map((fs) => (
                  <button
                    key={fs.number}
                    type="button"
                    onClick={() => openReader(fs.number)}
                    className="shrink-0 min-w-[116px] rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-3.5 py-2.5 text-center hover:border-emerald-600/40 hover:bg-[var(--bg-elevated)] transition"
                  >
                    <p className="font-arabic text-xl font-bold text-[var(--emerald-primary)]">
                      {fs.ar}
                    </p>
                    <p className="text-xs font-semibold text-[var(--text-primary)] mt-1 truncate">
                      {settings.appLanguage === 'ml' ? fs.ml : fs.en}
                    </p>
                  </button>
                ))}
              </div>
            </div>
          )}

          {surahsLoading && (
            <div className="space-y-2">
              {Array.from({ length: 8 }).map((_, i) => (
                <div
                  key={i}
                  className="h-16 rounded-2xl bg-[var(--bg-card)] border border-[var(--border-color)] animate-pulse"
                />
              ))}
            </div>
          )}

          {surahsError && !surahsLoading && (
            <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-6 text-center">
              <p className="text-sm text-[var(--text-secondary)]">{t.loadError}</p>
              <button
                type="button"
                onClick={reloadSurahs}
                className="mt-3 inline-flex items-center gap-2 rounded-xl bg-emerald-700 px-4 py-2 text-xs font-bold text-white"
              >
                <RefreshCw className="w-3.5 h-3.5" />
                {t.retry}
              </button>
            </div>
          )}

          {!surahsLoading && !surahsError && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {filteredSurahs.map((s) => (
                <button
                  key={s.number}
                  type="button"
                  onClick={() => openReader(s.number)}
                  className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-3 flex items-center gap-3.5 text-left hover:border-emerald-600/50 hover:bg-[var(--bg-elevated)]/60 transition"
                >
                  <div className="w-10 h-10 rounded-xl bg-[var(--emerald-soft)] text-[var(--emerald-primary)] font-bold text-sm flex items-center justify-center shrink-0 tabular-nums">
                    {s.number}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-bold text-sm text-[var(--text-primary)] truncate">
                        {s.englishName}
                      </span>
                      <span className="font-arabic text-xl font-bold text-[var(--emerald-primary)] shrink-0">
                        {s.nameArabic.replace('سُورَةُ ', '')}
                      </span>
                    </div>
                    <p className="text-xs text-[var(--text-muted)] truncate mt-0.5">
                      {s.englishNameTranslation} · {t.revelationLabel(s.revelationType)} ·{' '}
                      <span className="tabular-nums">{s.numberOfAyahs}</span> {t.ayahsLabel}
                    </p>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      )}

      {/* SUB-TAB 2: JUZ INDEX */}
      {quranSubTab === 'juz' && (
        <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2.5">
          {filteredJuz.map((j) => {
            const startSurah = surahs.find((s) => s.number === j.startSurah);
            return (
              <button
                key={j.number}
                type="button"
                onClick={() => openReader(j.startSurah, j.startAyah)}
                className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-3.5 flex items-center justify-between gap-3 text-left hover:border-emerald-600/50 hover:bg-[var(--bg-elevated)]/60 transition"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="w-10 h-10 rounded-xl bg-[var(--emerald-soft)] text-[var(--emerald-primary)] font-bold text-sm flex items-center justify-center shrink-0 tabular-nums">
                    {j.number}
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-bold text-[var(--text-primary)]">
                      {t.juzLabel} {j.number}
                    </p>
                    <p className="text-xs text-[var(--text-muted)] truncate mt-0.5">
                      {startSurah?.englishName ?? `Surah ${j.startSurah}`} · {t.ayahLabel} {j.startAyah} · {t.pageLabel} {j.startPage}
                    </p>
                  </div>
                </div>
                <span className="font-arabic text-lg font-bold text-[var(--emerald-primary)] shrink-0">
                  {j.arabicName}
                </span>
              </button>
            );
          })}
        </div>
      )}

      {/* SUB-TAB 3: BOOKMARKS (Inside Quran Tab as requested) */}
      {quranSubTab === 'bookmarks' && (
        <div className="mt-4">
          {bookmarks.length === 0 ? (
            <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-8 text-center">
              <Bookmark className="w-10 h-10 mx-auto text-[var(--text-muted)] opacity-50" />
              <p className="mt-3 text-sm text-[var(--text-secondary)] max-w-sm mx-auto leading-relaxed">
                {t.noBookmarks}
              </p>
            </div>
          ) : (
            <div className="space-y-2.5">
              {bookmarks.map((b) => (
                <div
                  key={b.id}
                  className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 flex items-start justify-between gap-3 hover:border-emerald-600/40 transition"
                >
                  <button
                    type="button"
                    onClick={() => openReader(b.surahNumber, b.isWholeSurah ? 1 : b.ayahNumber)}
                    className="flex-1 min-w-0 text-left"
                  >
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-bold text-sm text-[var(--emerald-primary)]">
                        {b.surahNameEn}
                      </span>
                      <span className="font-arabic text-base text-[var(--text-primary)]">
                        {b.surahNameAr}
                      </span>
                      <span className="text-xs font-semibold text-[var(--text-muted)] tabular-nums">
                        {b.isWholeSurah ? t.fullSurahBadge : `${t.ayahLabel} ${b.ayahNumber}`}
                      </span>
                    </div>
                    {b.previewArabic && (
                      <p dir="rtl" className="mt-2 font-arabic text-lg text-[var(--text-primary)] line-clamp-2 leading-loose">
                        {b.previewArabic}
                      </p>
                    )}
                  </button>
                  <button
                    type="button"
                    onClick={() => removeBookmark(b.id)}
                    className="p-2 rounded-xl text-[var(--text-muted)] hover:bg-rose-500/10 hover:text-rose-500 shrink-0"
                    aria-label="Remove bookmark"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
