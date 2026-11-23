'use client';

import React, { useMemo, useState } from 'react';
import {
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Copy,
  LayoutGrid,
  List,
  Search,
  Sparkles,
  X,
} from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { ASMAUL_HUSNA_LIST } from '@/data/asmaulHusna';
import { toArabicNumber } from '@/lib/apiConfig';
import type { AsmaulHusnaItem } from '@/types';

export function AsmaulHusnaView() {
  const { settings, updateSettings, toggleStudiedName99, t, showToast } = useIbadia();
  const [query, setQuery] = useState('');
  const [selectedItem, setSelectedItem] = useState<AsmaulHusnaItem | null>(null);

  const viewMode = settings.names99ViewMode;
  const studiedSet = useMemo(() => new Set(settings.studiedNames99), [settings.studiedNames99]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return ASMAUL_HUSNA_LIST;
    return ASMAUL_HUSNA_LIST.filter(
      (item) =>
        String(item.number) === q ||
        item.arabic.includes(query.trim()) ||
        item.transliteration.toLowerCase().includes(q) ||
        item.englishMeaning.toLowerCase().includes(q) ||
        item.malayalamMeaning.toLowerCase().includes(q)
    );
  }, [query]);

  const stepSelected = (delta: number) => {
    if (!selectedItem) return;
    const nextNum = ((selectedItem.number - 1 + delta + 99) % 99) + 1;
    const next = ASMAUL_HUSNA_LIST.find((x) => x.number === nextNum);
    if (next) setSelectedItem(next);
  };

  const copyName = async (item: AsmaulHusnaItem) => {
    const text = `${item.number}. ${item.arabic} (${item.transliteration})\n${item.englishMeaning} | ${item.malayalamMeaning}`;
    try {
      await navigator.clipboard.writeText(text);
    } catch {
      // ignore
    }
    showToast(t.copiedNameNotice);
  };

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      {/* Header & Dual View Switcher */}
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 shadow-sm">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-extrabold text-[var(--text-primary)]">{t.names99Title}</h2>
            <p className="text-xs text-[var(--text-muted)] mt-0.5 tabular-nums">
              {t.names99Studied}: {studiedSet.size} / 99
            </p>
          </div>

          {/* Grid (Arabic-Only) vs List (With Meanings) */}
          <div className="inline-flex rounded-xl bg-[var(--bg-elevated)] border border-[var(--border-color)] p-1 gap-1">
            <button
              type="button"
              onClick={() => updateSettings({ names99ViewMode: 'grid' })}
              className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                viewMode === 'grid'
                  ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                  : 'text-[var(--text-secondary)]'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              <span>{t.names99GridMode}</span>
            </button>
            <button
              type="button"
              onClick={() => updateSettings({ names99ViewMode: 'list' })}
              className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                viewMode === 'list'
                  ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                  : 'text-[var(--text-secondary)]'
              }`}
            >
              <List className="w-3.5 h-3.5" />
              <span>{t.names99ListMode}</span>
            </button>
          </div>
        </div>

        {/* Search Input */}
        <div className="relative mt-3">
          <Search className="w-4 h-4 text-[var(--text-muted)] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder={t.names99SearchHint}
            className="w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/60 pl-10 pr-9 py-2.5 text-sm placeholder:text-[var(--text-muted)] focus:outline-none focus:ring-2 focus:ring-emerald-600/30"
          />
          {query && (
            <button
              type="button"
              onClick={() => setQuery('')}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 p-1 rounded-md text-[var(--text-muted)]"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>

        {viewMode === 'grid' && (
          <p className="mt-2.5 text-xs text-[var(--text-muted)] flex items-center gap-1.5">
            <Sparkles className="w-3.5 h-3.5 text-[var(--gold-accent)] shrink-0" />
            <span>{t.names99GridHint}</span>
          </p>
        )}
      </div>

      {/* MODE 1: 3-COLUMN RTL ARABIC-ONLY CALLIGRAPHY GRID */}
      {viewMode === 'grid' ? (
        <div
          dir="rtl"
          className="grid grid-cols-3 gap-2 sm:gap-3 rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3 sm:p-4 shadow-sm"
        >
          {filtered.map((item) => {
            const studied = studiedSet.has(item.number);
            return (
              <button
                key={item.number}
                type="button"
                onClick={() => setSelectedItem(item)}
                className={`relative rounded-xl border px-2 py-4 sm:py-5 flex flex-col items-center justify-center text-center transition hover:border-emerald-600/60 hover:bg-[var(--emerald-soft)]/50 active:scale-[0.98] ${
                  studied
                    ? 'border-emerald-600/40 bg-[var(--emerald-soft)]/30'
                    : 'border-[var(--border-color)] bg-[var(--bg-elevated)]/40'
                }`}
              >
                <span className="absolute top-1.5 right-2 text-[11px] font-bold text-[var(--text-muted)] tabular-nums">
                  {toArabicNumber(item.number)}
                </span>
                {studied && (
                  <CheckCircle2 className="w-3.5 h-3.5 text-[var(--emerald-primary)] absolute top-1.5 left-2" />
                )}
                <span className="font-arabic text-2xl sm:text-3xl font-bold text-[var(--emerald-primary)] leading-relaxed">
                  {item.arabic}
                </span>
              </button>
            );
          })}
        </div>
      ) : (
        /* MODE 2: DETAILED SEARCHABLE LIST VIEW */
        <div className="space-y-2.5">
          {filtered.map((item) => {
            const studied = studiedSet.has(item.number);
            return (
              <button
                key={item.number}
                type="button"
                onClick={() => setSelectedItem(item)}
                className="w-full rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] px-4 py-3.5 flex items-center justify-between gap-3 text-left hover:border-emerald-600/50 transition"
              >
                <div className="flex items-center gap-3 min-w-0 flex-1">
                  <div className="w-9 h-9 rounded-xl bg-[var(--emerald-soft)] text-[var(--emerald-primary)] font-bold text-xs flex items-center justify-center shrink-0 tabular-nums">
                    {item.number}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-sm text-[var(--text-primary)] truncate">
                        {item.transliteration}
                      </span>
                      {studied && <CheckCircle2 className="w-3.5 h-3.5 text-[var(--emerald-primary)] shrink-0" />}
                    </div>
                    <p className="text-xs text-[var(--text-secondary)] truncate mt-0.5">
                      {settings.appLanguage === 'ml'
                        ? item.malayalamMeaning
                        : settings.appLanguage === 'ar'
                        ? item.arabicMeaning
                        : `${item.englishMeaning} · ${item.malayalamMeaning}`}
                    </p>
                  </div>
                </div>
                <span dir="rtl" className="font-arabic text-2xl font-bold text-[var(--emerald-primary)] shrink-0">
                  {item.arabic}
                </span>
              </button>
            );
          })}
        </div>
      )}

      {/* DETAIL MODAL SHEET FOR ANY TAPPED NAME */}
      {selectedItem && (
        <div
          className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/55 p-0 sm:p-4"
          onClick={() => setSelectedItem(null)}
        >
          <div
            className="w-full sm:max-w-lg rounded-t-3xl sm:rounded-3xl bg-[var(--bg-card)] border border-[var(--border-color)] p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-extrabold uppercase tracking-wider text-[var(--emerald-primary)] tabular-nums">
                #{selectedItem.number} / 99
              </span>
              <div className="flex items-center gap-1">
                <button
                  type="button"
                  onClick={() => copyName(selectedItem)}
                  className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-secondary)]"
                  aria-label="Copy"
                >
                  <Copy className="w-4 h-4" />
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedItem(null)}
                  className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-secondary)]"
                  aria-label="Close"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            <div className="rounded-2xl bg-gradient-to-br from-emerald-900/10 via-[var(--bg-elevated)] to-amber-500/10 px-4 py-6 text-center">
              <p dir="rtl" className="font-arabic text-5xl font-bold text-[var(--emerald-primary)] leading-relaxed">
                {selectedItem.arabic}
              </p>
              <p className="mt-2 text-lg font-extrabold text-[var(--text-primary)]">
                {selectedItem.transliteration}
              </p>
            </div>

            <div className="space-y-3">
              <div className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/40 p-3">
                <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  {t.meaningEnglishLabel}
                </p>
                <p className="mt-1 text-sm font-bold text-[var(--text-primary)]">
                  {selectedItem.englishMeaning}
                </p>
              </div>

              <div className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/40 p-3">
                <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  {t.meaningMalayalamLabel}
                </p>
                <p className="mt-1 text-sm font-bold font-malayalam text-[var(--text-primary)]">
                  {selectedItem.malayalamMeaning}
                </p>
              </div>

              <div className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/40 p-3">
                <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--text-muted)]">
                  {t.meaningArabicLabel}
                </p>
                <p dir="rtl" className="mt-1 text-base font-arabic text-[var(--text-primary)]">
                  {selectedItem.arabicMeaning}
                </p>
              </div>

              <div className="rounded-xl border border-emerald-700/20 bg-[var(--emerald-soft)]/50 p-3.5">
                <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--emerald-primary)]">
                  {t.reflectionLabel}
                </p>
                <p className="mt-1 text-sm text-[var(--text-secondary)] leading-relaxed">
                  {settings.appLanguage === 'ml' ? selectedItem.reflectionMl : selectedItem.reflectionEn}
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={() => toggleStudiedName99(selectedItem.number)}
              className={`w-full rounded-xl py-2.5 text-sm font-bold flex items-center justify-center gap-2 border transition ${
                studiedSet.has(selectedItem.number)
                  ? 'bg-emerald-700 text-white border-emerald-700'
                  : 'bg-[var(--bg-elevated)] text-[var(--text-primary)] border-[var(--border-color)]'
              }`}
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>{t.names99MarkStudied}</span>
            </button>

            <div className="flex items-center justify-between gap-3 pt-1">
              <button
                type="button"
                onClick={() => stepSelected(-1)}
                className="flex-1 rounded-xl border border-[var(--border-color)] py-2.5 text-xs font-bold inline-flex items-center justify-center gap-1 hover:bg-[var(--bg-elevated)]"
              >
                <ChevronLeft className="w-4 h-4" />
                <span>{t.previousLabel}</span>
              </button>
              <button
                type="button"
                onClick={() => stepSelected(1)}
                className="flex-1 rounded-xl border border-[var(--border-color)] py-2.5 text-xs font-bold inline-flex items-center justify-center gap-1 hover:bg-[var(--bg-elevated)]"
              >
                <span>{t.nextLabel}</span>
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
