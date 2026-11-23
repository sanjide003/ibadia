'use client';

import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  ArrowLeft,
  Bookmark,
  Check,
  ChevronLeft,
  ChevronRight,
  Copy,
  Loader2,
  Palette,
  Pause,
  Play,
  Share2,
  SlidersHorizontal,
  X,
} from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { AudioPlayerBar } from '@/components/AudioPlayerBar';
import { TajweedRuleModal, TajweedText } from '@/components/TajweedText';
import { ayahEndMarker, toArabicNumber } from '@/lib/apiConfig';
import { fetchSurahDetail } from '@/lib/quranApi';
import type { TajweedRuleMeta } from '@/lib/tajweedEngine';
import type { AyahItem, SurahDetail, TranslationCode } from '@/types';

const BISMILLAH_HEADER = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

export function SurahReaderScreen() {
  const {
    readerTarget,
    closeReader,
    settings,
    updateSettings,
    toggleTranslationLang,
    t,
    commitLastRead,
    isBookmarked,
    isSurahBookmarked,
    toggleBookmark,
    playAyahAudio,
    audio,
    showToast,
  } = useIbadia();

  const [loadedSurahs, setLoadedSurahs] = useState<SurahDetail[]>([]);
  const [loadingInitial, setLoadingInitial] = useState(true);
  const [loadingPrev, setLoadingPrev] = useState(false);
  const [loadingNext, setLoadingNext] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const [currentSurahNum, setCurrentSurahNum] = useState<number>(readerTarget?.surahNumber ?? 1);
  const [currentAyahNum, setCurrentAyahNum] = useState<number>(readerTarget?.ayahNumber ?? 1);
  const [currentPageNum, setCurrentPageNum] = useState<number>(1);

  const [selectedRule, setSelectedRule] = useState<TajweedRuleMeta | null>(null);
  const [showQuickControls, setShowQuickControls] = useState(false);

  // Auto-scroll state
  const [autoScrollActive, setAutoScrollActive] = useState(false);
  const scrollContainerRef = useRef<HTMLDivElement | null>(null);
  const rafRef = useRef<number | null>(null);
  const lastFrameTimeRef = useRef<number | null>(null);
  const userPausedTouchRef = useRef(false);

  // Draggable FAB coordinates + long-press detector
  const [fabPos, setFabPos] = useState<{ x: number; y: number }>(() => ({
    x: settings.fabX ?? 24,
    y: settings.fabY ?? 120,
  }));
  const dragStateRef = useRef<{
    startX: number;
    startY: number;
    origX: number;
    origY: number;
    moved: boolean;
    longPressTimer: ReturnType<typeof setTimeout> | null;
    triggeredLongPress: boolean;
  } | null>(null);

  const requiredTranslations: TranslationCode[] = useMemo(
    () => (settings.showTranslation ? settings.selectedTranslations : []),
    [settings.showTranslation, settings.selectedTranslations]
  );

  // Load initial target Surah
  useEffect(() => {
    if (!readerTarget) return;
    let cancelled = false;
    void Promise.resolve()
      .then(() => {
        if (cancelled) return null;
        setLoadingInitial(true);
        setErrorMsg(null);
        setLoadedSurahs([]);
        setCurrentSurahNum(readerTarget.surahNumber);
        setCurrentAyahNum(readerTarget.ayahNumber ?? 1);
        return fetchSurahDetail(readerTarget.surahNumber, requiredTranslations);
      })
      .then((detail) => {
        if (cancelled || !detail) return;
        setLoadedSurahs([detail]);
        const targetAyah =
          detail.ayahs.find((a) => a.numberInSurah === (readerTarget.ayahNumber ?? 1)) ?? detail.ayahs[0];
        if (targetAyah) setCurrentPageNum(targetAyah.page);
        setLoadingInitial(false);

        // Scroll to requested ayah or offset cleanly after paint
        requestAnimationFrame(() => {
          if (readerTarget.ayahNumber && readerTarget.ayahNumber > 1) {
            const el = document.getElementById(
              `ayah-${detail.summary.number}-${readerTarget.ayahNumber}`
            );
            el?.scrollIntoView({ behavior: 'auto', block: 'start' });
          } else if (readerTarget.scrollOffset && scrollContainerRef.current) {
            scrollContainerRef.current.scrollTop = readerTarget.scrollOffset;
          }
        });
      })
      .catch(() => {
        if (!cancelled) {
          setErrorMsg(t.loadError);
          setLoadingInitial(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [readerTarget, requiredTranslations, t.loadError]);

  const loadPreviousSurah = useCallback(async () => {
    if (loadingPrev || loadedSurahs.length === 0) return;
    const firstNum = loadedSurahs[0].summary.number;
    if (firstNum <= 1) return;
    const container = scrollContainerRef.current;
    const prevScrollHeight = container?.scrollHeight ?? 0;
    const prevScrollTop = container?.scrollTop ?? 0;

    setLoadingPrev(true);
    try {
      const prevDetail = await fetchSurahDetail(firstNum - 1, requiredTranslations);
      setLoadedSurahs((prev) => {
        if (prev.some((s) => s.summary.number === prevDetail.summary.number)) return prev;
        return [prevDetail, ...prev];
      });
      requestAnimationFrame(() => {
        if (container) {
          const delta = container.scrollHeight - prevScrollHeight;
          container.scrollTop = prevScrollTop + delta;
        }
      });
    } finally {
      setLoadingPrev(false);
    }
  }, [loadedSurahs, loadingPrev, requiredTranslations]);

  const loadNextSurah = useCallback(async () => {
    if (loadingNext || loadedSurahs.length === 0) return;
    const lastNum = loadedSurahs[loadedSurahs.length - 1].summary.number;
    if (lastNum >= 114) return;
    setLoadingNext(true);
    try {
      const nextDetail = await fetchSurahDetail(lastNum + 1, requiredTranslations);
      setLoadedSurahs((prev) => {
        if (prev.some((s) => s.summary.number === nextDetail.summary.number)) return prev;
        return [...prev, nextDetail];
      });
    } finally {
      setLoadingNext(false);
    }
  }, [loadedSurahs, loadingNext, requiredTranslations]);

  // Continuous anchor tracking & instant auto-save of lastRead
  const handleScroll = useCallback(() => {
    const container = scrollContainerRef.current;
    if (!container || loadedSurahs.length === 0) return;

    // Trigger next surah preload near bottom
    const distToBottom = container.scrollHeight - (container.scrollTop + container.clientHeight);
    if (distToBottom < 500) {
      loadNextSurah();
    }

    // Track visible ayah anchor for auto-save
    const containerTop = container.getBoundingClientRect().top + 80;
    const markers = container.querySelectorAll<HTMLElement>('[data-ayah-anchor]');
    let bestEl: HTMLElement | null = null;
    for (let i = 0; i < markers.length; i++) {
      const rect = markers[i].getBoundingClientRect();
      if (rect.top <= containerTop + 40) {
        bestEl = markers[i];
      } else {
        if (!bestEl) bestEl = markers[i];
        break;
      }
    }

    if (bestEl) {
      const sNum = Number(bestEl.dataset.surah);
      const aNum = Number(bestEl.dataset.ayah);
      const pNum = Number(bestEl.dataset.page);
      const sObj = loadedSurahs.find((s) => s.summary.number === sNum);
      if (sObj) {
        setCurrentSurahNum(sNum);
        setCurrentAyahNum(aNum);
        setCurrentPageNum(pNum);
        commitLastRead({
          surahNumber: sNum,
          surahNameEn: sObj.summary.englishName,
          surahNameAr: sObj.summary.nameArabic,
          ayahNumber: aNum,
          pageNumber: pNum,
          scrollOffset: container.scrollTop,
          updatedAtMs: Date.now(),
        });
      }
    }
  }, [commitLastRead, loadNextSurah, loadedSurahs]);

  // Auto-scroll animation loop
  useEffect(() => {
    if (!autoScrollActive) {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      lastFrameTimeRef.current = null;
      return;
    }

    const step = (ts: number) => {
      if (lastFrameTimeRef.current == null) {
        lastFrameTimeRef.current = ts;
      }
      const dt = (ts - lastFrameTimeRef.current) / 1000;
      lastFrameTimeRef.current = ts;

      const container = scrollContainerRef.current;
      if (container && !userPausedTouchRef.current) {
        const pxPerSec = 36 * settings.autoScrollSpeed;
        container.scrollTop += pxPerSec * dt;
      }
      rafRef.current = requestAnimationFrame(step);
    };

    rafRef.current = requestAnimationFrame(step);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [autoScrollActive, settings.autoScrollSpeed]);

  // Auto-follow highlighted audio ayah
  useEffect(() => {
    if (!audio.active || !audio.isPlaying) return;
    const el = document.getElementById(`ayah-${audio.surahNumber}-${audio.ayahNumber}`);
    el?.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }, [audio.active, audio.ayahNumber, audio.isPlaying, audio.surahNumber]);

  if (!readerTarget) return null;

  const activeSurahObj =
    loadedSurahs.find((s) => s.summary.number === currentSurahNum) ?? loadedSurahs[0];
  const wholeSurahBookmarked = activeSurahObj
    ? isSurahBookmarked(activeSurahObj.summary.number)
    : false;

  const copyAyahText = async (surahName: string, ayah: AyahItem, detail: SurahDetail) => {
    const trLines = requiredTranslations
      .map((code) => detail.translations[code]?.[ayah.numberInSurah - 1] ?? '')
      .filter(Boolean)
      .join('\n');
    const payload = `${ayah.arabicText}\n${trLines ? trLines + '\n' : ''}— ${surahName} (${detail.summary.number}:${ayah.numberInSurah})`;
    try {
      await navigator.clipboard.writeText(payload);
      showToast(t.copiedAyah);
    } catch {
      showToast(t.copiedAyah);
    }
  };

  const shareAyahText = async (surahName: string, ayah: AyahItem, detail: SurahDetail) => {
    const tr = requiredTranslations
      .map((code) => detail.translations[code]?.[ayah.numberInSurah - 1] ?? '')
      .filter(Boolean)
      .join('\n');
    const text = `${ayah.arabicText}\n\n${tr}\n— ${surahName} ${detail.summary.number}:${ayah.numberInSurah} (Ibadia)`;
    if (navigator.share) {
      await navigator.share({ title: `${surahName} ${detail.summary.number}:${ayah.numberInSurah}`, text }).catch(() => {});
    } else {
      await copyAyahText(surahName, ayah, detail);
    }
  };

  // Group ayahs by Mushaf page inside each loaded surah
  const groupByPage = (ayahs: AyahItem[]) => {
    const pages: Array<{ pageNumber: number; items: AyahItem[] }> = [];
    for (const a of ayahs) {
      const last = pages[pages.length - 1];
      if (!last || last.pageNumber !== a.page) {
        pages.push({ pageNumber: a.page, items: [a] });
      } else {
        last.items.push(a);
      }
    }
    return pages;
  };

  // FAB Drag & Long-press handlers
  const handleFabPointerDown = (e: React.PointerEvent<HTMLButtonElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    const startX = e.clientX;
    const startY = e.clientY;
    const origX = fabPos.x;
    const origY = fabPos.y;

    const timer = setTimeout(() => {
      if (dragStateRef.current && !dragStateRef.current.moved) {
        dragStateRef.current.triggeredLongPress = true;
        setShowQuickControls(true);
      }
    }, 450);

    dragStateRef.current = {
      startX,
      startY,
      origX,
      origY,
      moved: false,
      longPressTimer: timer,
      triggeredLongPress: false,
    };
  };

  const handleFabPointerMove = (e: React.PointerEvent<HTMLButtonElement>) => {
    const st = dragStateRef.current;
    if (!st) return;
    const dx = st.startX - e.clientX; // anchored from right
    const dy = st.startY - e.clientY; // anchored from bottom
    if (Math.abs(dx) > 6 || Math.abs(dy) > 6) {
      st.moved = true;
      if (st.longPressTimer) {
        clearTimeout(st.longPressTimer);
        st.longPressTimer = null;
      }
      const nextX = Math.max(12, Math.min(window.innerWidth - 72, st.origX + dx));
      const nextY = Math.max(24, Math.min(window.innerHeight - 120, st.origY + dy));
      setFabPos({ x: nextX, y: nextY });
    }
  };

  const handleFabPointerUp = () => {
    const st = dragStateRef.current;
    if (!st) return;
    if (st.longPressTimer) clearTimeout(st.longPressTimer);
    if (st.moved) {
      updateSettings({ fabX: fabPos.x, fabY: fabPos.y });
    } else if (!st.triggeredLongPress) {
      setAutoScrollActive((prev) => !prev);
    }
    dragStateRef.current = null;
  };

  return (
    <div className="fixed inset-0 z-30 flex flex-col bg-[var(--bg-page)] text-[var(--text-primary)]">
      {/* Compact Sticky Reader Top Bar (zero clutter, zero app branding) */}
      <header className="shrink-0 border-b border-[var(--border-color)] bg-[var(--bg-card)]/95 backdrop-blur-md px-3 py-2 flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0">
          <button
            type="button"
            onClick={closeReader}
            className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-primary)] shrink-0"
            aria-label="Back"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>

          {activeSurahObj && (
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-bold text-sm truncate">
                  {activeSurahObj.summary.number}. {activeSurahObj.summary.englishName}
                </span>
                <span className="font-arabic text-base text-[var(--emerald-primary)] shrink-0">
                  {activeSurahObj.summary.nameArabic.replace('سُورَةُ ', '')}
                </span>
              </div>
              <p className="text-[11px] text-[var(--text-muted)] tabular-nums">
                {t.pageLabel} {currentPageNum} · {t.ayahLabel} {currentAyahNum}/{activeSurahObj.summary.numberOfAyahs}
              </p>
            </div>
          )}
        </div>

        <div className="flex items-center gap-1 shrink-0">
          {/* Quick Mode Toggle: Mushaf / Verse */}
          <button
            type="button"
            onClick={() =>
              updateSettings({
                readingMode: settings.readingMode === 'mushaf' ? 'verse' : 'mushaf',
              })
            }
            className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-2.5 py-1.5 text-xs font-bold text-[var(--emerald-primary)]"
          >
            {settings.readingMode === 'mushaf' ? t.modeMushaf : t.modeVerse}
          </button>

          {/* Whole Surah Bookmark */}
          {activeSurahObj && (
            <button
              type="button"
              onClick={() => {
                const saved = toggleBookmark({
                  surahNumber: activeSurahObj.summary.number,
                  surahNameEn: activeSurahObj.summary.englishName,
                  surahNameAr: activeSurahObj.summary.nameArabic,
                  ayahNumber: 1,
                  ayahCount: activeSurahObj.summary.numberOfAyahs,
                  previewArabic: '',
                  isWholeSurah: true,
                });
                showToast(saved ? t.bookmarkSaved : t.bookmarkRemoved);
              }}
              title={t.bookmarkSurah}
              className={`p-2 rounded-xl transition ${
                wholeSurahBookmarked
                  ? 'text-[var(--gold-accent)] bg-amber-500/10'
                  : 'text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]'
              }`}
            >
              <Bookmark className="w-4 h-4" fill={wholeSurahBookmarked ? 'currentColor' : 'none'} />
            </button>
          )}

          {/* Quick Controls Sheet Button */}
          <button
            type="button"
            onClick={() => setShowQuickControls(true)}
            title={t.settings}
            className="p-2 rounded-xl text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]"
          >
            <SlidersHorizontal className="w-4 h-4" />
          </button>
        </div>
      </header>

      {/* Main Scrollable Reading Canvas */}
      <div
        ref={scrollContainerRef}
        onScroll={handleScroll}
        onTouchStart={() => {
          userPausedTouchRef.current = true;
        }}
        onTouchEnd={() => {
          userPausedTouchRef.current = false;
        }}
        className="flex-1 overflow-y-auto px-3 sm:px-6 pt-4 pb-36"
      >
        {loadingInitial && (
          <div className="mx-auto max-w-3xl py-20 flex flex-col items-center gap-3 text-[var(--text-muted)]">
            <Loader2 className="w-8 h-8 animate-spin text-[var(--emerald-primary)]" />
            <p className="text-sm font-medium">{t.surahLabel}...</p>
          </div>
        )}

        {errorMsg && !loadingInitial && (
          <div className="mx-auto max-w-md rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-6 text-center mt-10">
            <p className="text-sm text-[var(--text-secondary)]">{errorMsg}</p>
            <button
              type="button"
              onClick={closeReader}
              className="mt-4 rounded-xl bg-emerald-700 px-4 py-2 text-xs font-bold text-white"
            >
              {t.done}
            </button>
          </div>
        )}

        {!loadingInitial && loadedSurahs.length > 0 && (
          <div className="mx-auto max-w-3xl space-y-6">
            {/* Load Previous Surah Bar */}
            {loadedSurahs[0].summary.number > 1 && (
              <div className="flex justify-center">
                <button
                  type="button"
                  onClick={loadPreviousSurah}
                  disabled={loadingPrev}
                  className="inline-flex items-center gap-2 rounded-xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-2 text-xs font-bold text-[var(--emerald-primary)] hover:bg-[var(--bg-elevated)] transition"
                >
                  {loadingPrev ? (
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <ChevronLeft className="w-4 h-4" />
                  )}
                  <span>{loadingPrev ? t.loadingPrevSurah : t.loadPrevSurahBtn}</span>
                </button>
              </div>
            )}

            {/* Render Each Loaded Surah */}
            {loadedSurahs.map((detail) => {
              const s = detail.summary;
              const showBismillah = s.number !== 1 && s.number !== 9;
              const pageGroups = groupByPage(detail.ayahs);

              return (
                <section key={s.number} className="space-y-5">
                  {/* Ornamental Surah Banner */}
                  <div className="rounded-2xl border-2 border-emerald-700/35 bg-gradient-to-br from-emerald-900/10 via-[var(--bg-card)] to-amber-500/10 px-5 py-4 text-center shadow-sm">
                    <div className="flex items-center justify-between text-xs font-bold text-[var(--text-muted)] tabular-nums">
                      <span>
                        {t.surahLabel} {s.number}
                      </span>
                      <span>
                        {t.revelationLabel(s.revelationType)} · {s.numberOfAyahs} {t.ayahsLabel}
                      </span>
                    </div>
                    <h1 dir="rtl" className="mt-1 font-arabic text-3xl sm:text-4xl font-bold text-[var(--emerald-primary)]">
                      {s.nameArabic}
                    </h1>
                    <p className="mt-1 text-sm font-semibold text-[var(--text-secondary)]">
                      {s.englishName} — {s.englishNameTranslation}
                    </p>
                  </div>

                  {/* Bismillah Header */}
                  {showBismillah && (
                    <p
                      dir="rtl"
                      className="text-center font-arabic text-2xl sm:text-3xl text-[var(--text-primary)] py-1"
                    >
                      {BISMILLAH_HEADER}
                    </p>
                  )}

                  {/* MODE 1: MUSHAF PAGE VIEW */}
                  {settings.readingMode === 'mushaf' ? (
                    <div className="space-y-6">
                      {pageGroups.map((pg) => (
                        <div
                          key={`${s.number}-p-${pg.pageNumber}`}
                          className="rounded-2xl border-2 border-[var(--mushaf-frame)]/30 bg-[var(--bg-card)] px-5 sm:px-8 py-6 shadow-sm"
                        >
                          <div
                            dir="rtl"
                            className="font-arabic text-justify leading-[2.35] text-[var(--text-primary)]"
                            style={{ fontSize: `${settings.arabicFontSize}px` }}
                          >
                            {pg.items.map((ayah) => {
                              const isActiveAudio =
                                audio.active &&
                                audio.surahNumber === s.number &&
                                audio.ayahNumber === ayah.numberInSurah;
                              return (
                                <span
                                  key={ayah.globalNumber}
                                  id={`ayah-${s.number}-${ayah.numberInSurah}`}
                                  data-ayah-anchor="true"
                                  data-surah={s.number}
                                  data-ayah={ayah.numberInSurah}
                                  data-page={ayah.page}
                                  className={`inline transition-colors rounded px-0.5 ${
                                    isActiveAudio ? 'bg-emerald-500/15' : ''
                                  }`}
                                >
                                  <TajweedText
                                    text={ayah.arabicText}
                                    enabled={settings.tajweedEnabled}
                                    onSelectRule={setSelectedRule}
                                  />
                                  <button
                                    type="button"
                                    onClick={() => playAyahAudio(s.number, ayah.numberInSurah)}
                                    title={`${t.playAyah} ${ayah.numberInSurah}`}
                                    className="inline text-[var(--gold-accent)] font-bold mx-1 hover:scale-110 transition-transform"
                                  >
                                    {ayahEndMarker(ayah.numberInSurah)}
                                  </button>
                                </span>
                              );
                            })}
                          </div>

                          {/* Translation Block Below Mushaf Page (when enabled) */}
                          {settings.showTranslation && requiredTranslations.length > 0 && (
                            <div className="mt-5 pt-4 border-t border-[var(--border-color)] space-y-2.5">
                              {pg.items.map((ayah) => (
                                <div
                                  key={`tr-${ayah.globalNumber}`}
                                  className="text-[var(--text-secondary)] leading-relaxed"
                                  style={{ fontSize: `${settings.translationFontSize}px` }}
                                >
                                  <span className="font-bold text-[var(--emerald-primary)] mr-1.5 tabular-nums">
                                    {ayah.numberInSurah}.
                                  </span>
                                  {requiredTranslations.map((code) => {
                                    const txt = detail.translations[code]?.[ayah.numberInSurah - 1];
                                    if (!txt) return null;
                                    return (
                                      <span
                                        key={code}
                                        dir={code === 'ar' ? 'rtl' : 'ltr'}
                                        className={`block ${
                                          code === 'ml'
                                            ? 'font-malayalam'
                                            : code === 'ar'
                                            ? 'font-arabic text-right text-base'
                                            : ''
                                        }`}
                                      >
                                        {txt}
                                      </span>
                                    );
                                  })}
                                </div>
                              ))}
                            </div>
                          )}

                          <div className="mt-4 pt-2 border-t border-[var(--border-color)]/60 text-center text-xs font-semibold text-[var(--text-muted)] tabular-nums">
                            — {toArabicNumber(pg.pageNumber)} · {t.pageLabel} {pg.pageNumber} —
                          </div>
                        </div>
                      ))}
                    </div>
                  ) : (
                    /* MODE 2: VERSE LIST VIEW */
                    <div className="space-y-3">
                      {detail.ayahs.map((ayah) => {
                        const bookmarked = isBookmarked(s.number, ayah.numberInSurah);
                        const isActiveAudio =
                          audio.active &&
                          audio.surahNumber === s.number &&
                          audio.ayahNumber === ayah.numberInSurah;
                        return (
                          <article
                            key={ayah.globalNumber}
                            id={`ayah-${s.number}-${ayah.numberInSurah}`}
                            data-ayah-anchor="true"
                            data-surah={s.number}
                            data-ayah={ayah.numberInSurah}
                            data-page={ayah.page}
                            className={`rounded-2xl border p-4 sm:p-5 transition ${
                              isActiveAudio
                                ? 'border-emerald-600 bg-[var(--emerald-soft)]/50 shadow-sm'
                                : 'border-[var(--border-color)] bg-[var(--bg-card)]'
                            }`}
                          >
                            {/* Top action row */}
                            <div className="flex items-center justify-between gap-2 mb-3">
                              <span className="inline-flex items-center gap-1.5 rounded-xl bg-[var(--bg-elevated)] px-2.5 py-1 text-xs font-bold text-[var(--emerald-primary)] tabular-nums">
                                {s.number}:{ayah.numberInSurah}
                              </span>

                              <div className="flex items-center gap-1">
                                <button
                                  type="button"
                                  onClick={() => playAyahAudio(s.number, ayah.numberInSurah)}
                                  className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--emerald-primary)]"
                                  title={t.playAyah}
                                >
                                  <Play className="w-4 h-4" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => {
                                    const saved = toggleBookmark({
                                      surahNumber: s.number,
                                      surahNameEn: s.englishName,
                                      surahNameAr: s.nameArabic,
                                      ayahNumber: ayah.numberInSurah,
                                      ayahCount: s.numberOfAyahs,
                                      previewArabic: ayah.arabicText,
                                      isWholeSurah: false,
                                    });
                                    showToast(saved ? t.bookmarkSaved : t.bookmarkRemoved);
                                  }}
                                  className={`p-2 rounded-xl hover:bg-[var(--bg-elevated)] ${
                                    bookmarked ? 'text-[var(--gold-accent)]' : 'text-[var(--text-muted)]'
                                  }`}
                                  title={t.bookmarksTab}
                                >
                                  <Bookmark
                                    className="w-4 h-4"
                                    fill={bookmarked ? 'currentColor' : 'none'}
                                  />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => copyAyahText(s.englishName, ayah, detail)}
                                  className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-muted)]"
                                  title="Copy"
                                >
                                  <Copy className="w-4 h-4" />
                                </button>
                                <button
                                  type="button"
                                  onClick={() => shareAyahText(s.englishName, ayah, detail)}
                                  className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-muted)]"
                                  title={t.share}
                                >
                                  <Share2 className="w-4 h-4" />
                                </button>
                              </div>
                            </div>

                            {/* Arabic Verse */}
                            <div
                              dir="rtl"
                              className="font-arabic leading-[2.2] text-right text-[var(--text-primary)]"
                              style={{ fontSize: `${settings.arabicFontSize}px` }}
                            >
                              <TajweedText
                                text={ayah.arabicText}
                                enabled={settings.tajweedEnabled}
                                onSelectRule={setSelectedRule}
                              />
                              <span className="text-[var(--gold-accent)]">
                                {ayahEndMarker(ayah.numberInSurah)}
                              </span>
                            </div>

                            {/* Translations */}
                            {settings.showTranslation && requiredTranslations.length > 0 && (
                              <div className="mt-4 pt-3 border-t border-[var(--border-color)]/70 space-y-2.5">
                                {requiredTranslations.map((code) => {
                                  const txt = detail.translations[code]?.[ayah.numberInSurah - 1];
                                  if (!txt) return null;
                                  return (
                                    <p
                                      key={code}
                                      dir={code === 'ar' ? 'rtl' : 'ltr'}
                                      style={{ fontSize: `${settings.translationFontSize}px` }}
                                      className={`leading-relaxed text-[var(--text-secondary)] ${
                                        code === 'ml'
                                          ? 'font-malayalam'
                                          : code === 'ar'
                                          ? 'font-arabic text-right'
                                          : ''
                                      }`}
                                    >
                                      {txt}
                                    </p>
                                  );
                                })}
                              </div>
                            )}
                          </article>
                        );
                      })}
                    </div>
                  )}
                </section>
              );
            })}

            {/* Load Next Surah Button / Status */}
            {loadedSurahs[loadedSurahs.length - 1].summary.number < 114 && (
              <div className="flex justify-center pt-2">
                <button
                  type="button"
                  onClick={loadNextSurah}
                  disabled={loadingNext}
                  className="inline-flex items-center gap-2 rounded-xl border border-[var(--border-color)] bg-[var(--bg-card)] px-5 py-2.5 text-xs font-bold text-[var(--emerald-primary)] hover:bg-[var(--bg-elevated)]"
                >
                  {loadingNext ? (
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  ) : (
                    <ChevronRight className="w-4 h-4" />
                  )}
                  <span>{loadingNext ? t.loadingNextSurah : t.loadNextSurahBtn}</span>
                </button>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Draggable Long-Press Auto-Scroll FAB */}
      <button
        type="button"
        onPointerDown={handleFabPointerDown}
        onPointerMove={handleFabPointerMove}
        onPointerUp={handleFabPointerUp}
        style={{ right: `${fabPos.x}px`, bottom: `${fabPos.y}px`, touchAction: 'none' }}
        title={t.autoScrollHint}
        className={`fixed z-40 w-13 h-13 rounded-full shadow-xl flex flex-col items-center justify-center transition-colors select-none ${
          autoScrollActive
            ? 'bg-amber-600 text-white'
            : 'bg-emerald-700 text-white hover:bg-emerald-800'
        }`}
      >
        {autoScrollActive ? <Pause className="w-5 h-5" /> : <Play className="w-5 h-5 ml-0.5" />}
        <span className="text-[9px] font-bold leading-none mt-0.5 tabular-nums">
          {settings.autoScrollSpeed.toFixed(1)}x
        </span>
      </button>

      {/* Audio Player Bar docked inside Reader */}
      <AudioPlayerBar elevatedAboveBottomNav={false} />

      {/* Quick Reader Controls Modal (Speed, Font sizes, Theme, Tajweed, Translations) */}
      {showQuickControls && (
        <div
          className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 p-0 sm:p-4"
          onClick={() => setShowQuickControls(false)}
        >
          <div
            className="w-full sm:max-w-md max-h-[85vh] overflow-y-auto rounded-t-2xl sm:rounded-2xl bg-[var(--bg-card)] border border-[var(--border-color)] p-5 shadow-2xl space-y-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold">{t.quranSettingsTitle}</h3>
              <button
                type="button"
                onClick={() => setShowQuickControls(false)}
                className="p-1.5 rounded-lg hover:bg-[var(--bg-elevated)]"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Theme Quick Picker */}
            <div>
              <p className="text-xs font-bold text-[var(--text-muted)] mb-2">{t.readingTheme}</p>
              <div className="grid grid-cols-3 gap-2">
                {(['light', 'sepia', 'dark'] as const).map((tm) => (
                  <button
                    key={tm}
                    type="button"
                    onClick={() => updateSettings({ themeMode: tm })}
                    className={`rounded-xl py-2 text-xs font-bold border transition ${
                      settings.themeMode === tm
                        ? 'border-emerald-600 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                        : 'border-[var(--border-color)] text-[var(--text-secondary)]'
                    }`}
                  >
                    {tm === 'light' ? t.themeLight : tm === 'sepia' ? t.themeSepia : t.themeDark}
                  </button>
                ))}
              </div>
            </div>

            {/* Auto-scroll Speed Slider */}
            <div>
              <div className="flex justify-between text-xs font-bold mb-1">
                <span>{t.autoScrollSpeed}</span>
                <span className="tabular-nums text-[var(--emerald-primary)]">
                  {settings.autoScrollSpeed.toFixed(1)}x
                </span>
              </div>
              <input
                type="range"
                min={0.3}
                max={5.0}
                step={0.1}
                value={settings.autoScrollSpeed}
                onChange={(e) => updateSettings({ autoScrollSpeed: Number(e.target.value) })}
                className="w-full accent-emerald-700"
              />
            </div>

            {/* Arabic Font Size */}
            <div>
              <div className="flex justify-between text-xs font-bold mb-1">
                <span>{t.arabicFontSize}</span>
                <span className="tabular-nums text-[var(--emerald-primary)]">
                  {settings.arabicFontSize}px
                </span>
              </div>
              <input
                type="range"
                min={20}
                max={46}
                step={1}
                value={settings.arabicFontSize}
                onChange={(e) => updateSettings({ arabicFontSize: Number(e.target.value) })}
                className="w-full accent-emerald-700"
              />
            </div>

            {/* Translation Font Size */}
            <div>
              <div className="flex justify-between text-xs font-bold mb-1">
                <span>{t.translationFontSize}</span>
                <span className="tabular-nums text-[var(--emerald-primary)]">
                  {settings.translationFontSize}px
                </span>
              </div>
              <input
                type="range"
                min={12}
                max={24}
                step={1}
                value={settings.translationFontSize}
                onChange={(e) => updateSettings({ translationFontSize: Number(e.target.value) })}
                className="w-full accent-emerald-700"
              />
            </div>

            {/* Tajweed Toggle */}
            <label className="flex items-center justify-between py-1 cursor-pointer">
              <span className="inline-flex items-center gap-2 text-sm font-bold">
                <Palette className="w-4 h-4 text-[var(--emerald-primary)]" />
                {t.tajweedColorCoding}
              </span>
              <input
                type="checkbox"
                checked={settings.tajweedEnabled}
                onChange={(e) => updateSettings({ tajweedEnabled: e.target.checked })}
                className="w-4 h-4 accent-emerald-700"
              />
            </label>

            {/* Translation Toggle + Multi-Langs */}
            <label className="flex items-center justify-between py-1 cursor-pointer">
              <span className="text-sm font-bold">{t.showTranslation}</span>
              <input
                type="checkbox"
                checked={settings.showTranslation}
                onChange={(e) => updateSettings({ showTranslation: e.target.checked })}
                className="w-4 h-4 accent-emerald-700"
              />
            </label>

            {settings.showTranslation && (
              <div className="flex flex-wrap gap-2">
                {(['en', 'ml', 'ar'] as const).map((code) => {
                  const selected = settings.selectedTranslations.includes(code);
                  const label =
                    code === 'en'
                      ? t.langEnglish
                      : code === 'ml'
                      ? t.langMalayalam
                      : t.langArabicTafsir;
                  return (
                    <button
                      key={code}
                      type="button"
                      onClick={() => toggleTranslationLang(code)}
                      className={`inline-flex items-center gap-1.5 rounded-xl px-3 py-1.5 text-xs font-bold border transition ${
                        selected
                          ? 'border-emerald-600 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                          : 'border-[var(--border-color)] text-[var(--text-secondary)]'
                      }`}
                    >
                      {selected && <Check className="w-3.5 h-3.5" />}
                      <span>{label}</span>
                    </button>
                  );
                })}
              </div>
            )}

            <button
              type="button"
              onClick={() => setShowQuickControls(false)}
              className="w-full rounded-xl bg-emerald-700 py-2.5 text-sm font-bold text-white hover:bg-emerald-800"
            >
              {t.done}
            </button>
          </div>
        </div>
      )}

      {/* Tajweed Rule Detail Modal */}
      <TajweedRuleModal ruleMeta={selectedRule} onClose={() => setSelectedRule(null)} />
    </div>
  );
}
