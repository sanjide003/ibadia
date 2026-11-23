'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { CheckCircle2, Copy, RotateCcw, Star } from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { ADHKAR_ENTRIES } from '@/data/adhkar';
import { formatDateKey } from '@/lib/islamicFeaturesApi';
import {
  loadAdhkarCounts,
  loadAdhkarFavorites,
  saveAdhkarCountsNow,
  saveAdhkarFavoritesNow,
} from '@/lib/storage';

type AdhkarFilter = 'all' | 'morning' | 'evening' | 'after_salah' | 'daily_duas' | 'favorites';

export function AdhkarView() {
  const { settings, t, showToast } = useIbadia();
  const todayKey = formatDateKey(new Date());

  const [filter, setFilter] = useState<AdhkarFilter>('morning');
  const [counts, setCounts] = useState<Record<string, number>>({});
  const [favorites, setFavorites] = useState<string[]>([]);

  useEffect(() => {
    let active = true;
    void Promise.resolve().then(() => {
      if (!active) return;
      setCounts(loadAdhkarCounts(todayKey));
      setFavorites(loadAdhkarFavorites());
    });
    return () => {
      active = false;
    };
  }, [todayKey]);

  const filtered = useMemo(() => {
    if (filter === 'all') return ADHKAR_ENTRIES;
    if (filter === 'favorites') return ADHKAR_ENTRIES.filter((e) => favorites.includes(e.id));
    return ADHKAR_ENTRIES.filter((e) => e.category === filter);
  }, [filter, favorites]);

  const completedCount = useMemo(
    () =>
      filtered.filter((e) => (counts[e.id] ?? 0) >= e.targetCount).length,
    [filtered, counts]
  );

  const incrementEntry = (id: string, target: number) => {
    setCounts((prev) => {
      const cur = prev[id] ?? 0;
      if (cur >= target) return prev;
      const next = { ...prev, [id]: cur + 1 };
      saveAdhkarCountsNow(todayKey, next);
      if (typeof navigator !== 'undefined' && navigator.vibrate) {
        navigator.vibrate(cur + 1 >= target ? 35 : 15);
      }
      return next;
    });
  };

  const toggleFavorite = (id: string) => {
    setFavorites((prev) => {
      const next = prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id];
      saveAdhkarFavoritesNow(next);
      return next;
    });
  };

  const resetProgress = () => {
    setCounts({});
    saveAdhkarCountsNow(todayKey, {});
    showToast(t.resetTodayProgress);
  };

  const tabs: Array<{ id: AdhkarFilter; label: string }> = [
    { id: 'morning', label: t.morningAdhkar },
    { id: 'evening', label: t.eveningAdhkar },
    { id: 'after_salah', label: t.afterSalahAdhkar },
    { id: 'daily_duas', label: t.dailyDuasCategory },
    { id: 'favorites', label: t.favoritesOnlyLabel },
    { id: 'all', label: t.allAdhkarLabel },
  ];

  const pct = filtered.length > 0 ? Math.round((completedCount / filtered.length) * 100) : 0;

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 shadow-sm space-y-3">
        <div className="flex items-center justify-between gap-2">
          <p className="text-xs text-[var(--text-secondary)]">{t.hisnulMuslimNote}</p>
          <button
            type="button"
            onClick={resetProgress}
            className="inline-flex items-center gap-1 rounded-xl border border-[var(--border-color)] px-2.5 py-1.5 text-xs font-bold text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)] shrink-0"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>{t.resetTodayProgress}</span>
          </button>
        </div>

        {/* Progress Bar */}
        <div className="space-y-1">
          <div className="flex justify-between text-xs font-bold tabular-nums">
            <span className="text-[var(--emerald-primary)]">
              {completedCount} / {filtered.length} {t.completedLabel}
            </span>
            <span>{pct}%</span>
          </div>
          <div className="h-2 rounded-full bg-[var(--bg-elevated)] overflow-hidden">
            <div
              className="h-full bg-emerald-700 transition-all duration-300"
              style={{ width: `${pct}%` }}
            />
          </div>
        </div>

        {/* Category Tabs */}
        <div className="flex gap-1.5 overflow-x-auto pb-1">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              type="button"
              onClick={() => setFilter(tab.id)}
              className={`shrink-0 rounded-xl px-3 py-1.5 text-xs font-bold border transition ${
                filter === tab.id
                  ? 'bg-emerald-700 text-white border-emerald-700'
                  : 'border-[var(--border-color)] bg-[var(--bg-elevated)]/50 text-[var(--text-secondary)]'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      {/* Adhkar Cards */}
      <div className="space-y-3">
        {filtered.map((entry) => {
          const cur = counts[entry.id] ?? 0;
          const done = cur >= entry.targetCount;
          const isFav = favorites.includes(entry.id);
          return (
            <div
              key={entry.id}
              onClick={() => incrementEntry(entry.id, entry.targetCount)}
              className={`cursor-pointer rounded-2xl border p-4 sm:p-5 transition select-none ${
                done
                  ? 'border-emerald-600/50 bg-[var(--emerald-soft)]/50'
                  : 'border-[var(--border-color)] bg-[var(--bg-card)] hover:border-emerald-600/40'
              }`}
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <h3 className="text-sm font-extrabold text-[var(--text-primary)]">
                    {settings.appLanguage === 'ml' ? entry.titleMl : entry.titleEn}
                  </h3>
                  <p className="text-[11px] text-[var(--text-muted)] mt-0.5">{entry.reference}</p>
                </div>

                <div
                  className="flex items-center gap-1 shrink-0"
                  onClick={(e) => e.stopPropagation()}
                >
                  <button
                    type="button"
                    onClick={() => toggleFavorite(entry.id)}
                    className={`p-2 rounded-xl hover:bg-[var(--bg-elevated)] ${
                      isFav ? 'text-[var(--gold-accent)]' : 'text-[var(--text-muted)]'
                    }`}
                  >
                    <Star className="w-4 h-4" fill={isFav ? 'currentColor' : 'none'} />
                  </button>
                  <button
                    type="button"
                    onClick={async () => {
                      await navigator.clipboard
                        .writeText(`${entry.arabic}\n\n${entry.translationEn}\n— ${entry.reference}`)
                        .catch(() => {});
                      showToast(t.copiedNameNotice);
                    }}
                    className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-muted)]"
                  >
                    <Copy className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <p
                dir="rtl"
                className="mt-3 font-arabic text-2xl leading-[2.1] text-right text-[var(--text-primary)]"
              >
                {entry.arabic}
              </p>

              <p
                className={`mt-3 text-sm leading-relaxed text-[var(--text-secondary)] ${
                  settings.appLanguage === 'ml' ? 'font-malayalam' : ''
                }`}
              >
                {settings.appLanguage === 'ml' ? entry.translationMl : entry.translationEn}
              </p>

              <div className="mt-4 pt-3 border-t border-[var(--border-color)]/70 flex items-center justify-between">
                <span className="text-xs font-bold tabular-nums text-[var(--emerald-primary)]">
                  {cur} / {entry.targetCount}
                </span>
                {done ? (
                  <span className="inline-flex items-center gap-1 text-xs font-bold text-[var(--emerald-primary)]">
                    <CheckCircle2 className="w-4 h-4" />
                    {t.completedLabel}
                  </span>
                ) : (
                  <span className="text-xs font-semibold text-[var(--text-muted)]">
                    Tap card (+1)
                  </span>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
