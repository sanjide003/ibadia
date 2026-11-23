'use client';

import React, { useMemo, useState } from 'react';
import { Plus, RotateCcw, Trash2, Vibrate, X } from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { DEFAULT_TASBIH_PRESETS } from '@/data/adhkar';
import { formatDateKey } from '@/lib/islamicFeaturesApi';
import {
  loadCustomTasbihPresets,
  loadTasbihState,
  saveCustomTasbihPresetsNow,
  saveTasbihStateNow,
  type TasbihStateStored,
} from '@/lib/storage';
import type { TasbihPreset } from '@/types';

const TARGET_OPTIONS = [33, 99, 100, 1000, 0] as const;

export function TasbihView() {
  const { settings, t, showToast } = useIbadia();
  const todayKey = formatDateKey(new Date());

  const [customPresets, setCustomPresets] = useState<TasbihPreset[]>(() =>
    loadCustomTasbihPresets()
  );
  const [state, setState] = useState<TasbihStateStored>(() => loadTasbihState(todayKey));
  const [showAddModal, setShowAddModal] = useState(false);
  const [newArabic, setNewArabic] = useState('');
  const [newTitleEn, setNewTitleEn] = useState('');
  const [newTarget, setNewTarget] = useState(33);

  const allPresets = useMemo(
    () => [...DEFAULT_TASBIH_PRESETS, ...customPresets],
    [customPresets]
  );

  const activePreset =
    allPresets.find((p) => p.id === state.selectedId) ?? allPresets[0];

  const activeTarget =
    state.targets[activePreset.id] !== undefined
      ? state.targets[activePreset.id]
      : activePreset.defaultTarget;

  const commitState = (next: TasbihStateStored) => {
    setState(next);
    saveTasbihStateNow(next);
  };

  const selectPreset = (preset: TasbihPreset) => {
    commitState({
      ...state,
      selectedId: preset.id,
      currentCount: 0,
    });
  };

  const setTargetForCurrent = (target: number) => {
    commitState({
      ...state,
      targets: { ...state.targets, [activePreset.id]: target },
    });
  };

  const handleTap = () => {
    const nextCount = state.currentCount + 1;
    const hitTarget = activeTarget > 0 && nextCount >= activeTarget;

    if (state.vibrateOnTap && typeof navigator !== 'undefined' && navigator.vibrate) {
      navigator.vibrate(hitTarget ? [35, 35, 50] : 16);
    }

    commitState({
      ...state,
      dateKey: todayKey,
      currentCount: hitTarget ? 0 : nextCount,
      todayTotal: state.todayTotal + 1,
      lifetimeTotal: state.lifetimeTotal + 1,
      cyclesCompleted: hitTarget ? state.cyclesCompleted + 1 : state.cyclesCompleted,
    });

    if (hitTarget) {
      showToast(`${activePreset.titleEn} (${activeTarget}) completed!`);
    }
  };

  const handleResetCycle = () => {
    commitState({
      ...state,
      currentCount: 0,
    });
  };

  const handleCreateCustom = (e: React.FormEvent) => {
    e.preventDefault();
    const title = newTitleEn.trim();
    const arabic = newArabic.trim();
    if (!title && !arabic) return;
    const item: TasbihPreset = {
      id: `custom_${Date.now()}`,
      arabic: arabic || title,
      titleEn: title || arabic,
      titleMl: title || arabic,
      defaultTarget: newTarget,
      isCustom: true,
    };
    const nextCustom = [...customPresets, item];
    setCustomPresets(nextCustom);
    saveCustomTasbihPresetsNow(nextCustom);
    commitState({
      ...state,
      selectedId: item.id,
      currentCount: 0,
      targets: { ...state.targets, [item.id]: newTarget },
    });
    setNewArabic('');
    setNewTitleEn('');
    setNewTarget(33);
    setShowAddModal(false);
  };

  const deleteCustomPreset = (id: string) => {
    const nextCustom = customPresets.filter((p) => p.id !== id);
    setCustomPresets(nextCustom);
    saveCustomTasbihPresetsNow(nextCustom);
    if (state.selectedId === id) {
      commitState({ ...state, selectedId: DEFAULT_TASBIH_PRESETS[0].id, currentCount: 0 });
    }
  };

  const progressRatio =
    activeTarget > 0 ? Math.min(1, state.currentCount / activeTarget) : 0;
  const radius = 84;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset = circumference * (1 - progressRatio);

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      {/* Preset Chips */}
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3.5 shadow-sm">
        <div className="flex items-center justify-between gap-2 mb-2.5">
          <span className="text-xs font-bold uppercase tracking-wider text-[var(--text-muted)]">
            {t.tasbihTitle}
          </span>
          <button
            type="button"
            onClick={() => setShowAddModal(true)}
            className="inline-flex items-center gap-1 rounded-xl bg-[var(--emerald-soft)] px-2.5 py-1.5 text-xs font-bold text-[var(--emerald-primary)] hover:brightness-95"
          >
            <Plus className="w-3.5 h-3.5" />
            <span>{t.addCustomDhikr}</span>
          </button>
        </div>

        <div className="flex gap-2 overflow-x-auto pb-1">
          {allPresets.map((p) => {
            const active = p.id === activePreset.id;
            return (
              <div key={p.id} className="relative shrink-0 flex items-center">
                <button
                  type="button"
                  onClick={() => selectPreset(p)}
                  className={`rounded-xl border px-3 py-2 text-left transition ${
                    active
                      ? 'border-emerald-700 bg-emerald-700 text-white shadow-sm'
                      : 'border-[var(--border-color)] bg-[var(--bg-elevated)] text-[var(--text-primary)]'
                  } ${p.isCustom ? 'pr-8' : ''}`}
                >
                  <p className="font-arabic text-base font-bold leading-snug">{p.arabic}</p>
                  <p
                    className={`text-[11px] font-semibold mt-0.5 ${
                      active ? 'text-emerald-100' : 'text-[var(--text-muted)]'
                    }`}
                  >
                    {settings.appLanguage === 'ml' ? p.titleMl : p.titleEn}
                  </p>
                </button>
                {p.isCustom && (
                  <button
                    type="button"
                    onClick={() => deleteCustomPreset(p.id)}
                    className={`absolute right-1.5 top-1.5 p-1 rounded-lg ${
                      active
                        ? 'text-emerald-100 hover:bg-white/15'
                        : 'text-[var(--text-muted)] hover:text-rose-500'
                    }`}
                    aria-label="Delete custom dhikr"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Stats Strip */}
      <div className="grid grid-cols-3 gap-2.5">
        <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3 text-center">
          <p className="text-[11px] font-bold uppercase text-[var(--text-muted)]">
            {t.todayTotalLabel}
          </p>
          <p className="mt-0.5 text-lg font-extrabold text-[var(--emerald-primary)] tabular-nums">
            {state.todayTotal}
          </p>
        </div>
        <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3 text-center">
          <p className="text-[11px] font-bold uppercase text-[var(--text-muted)]">
            {t.lifetimeTotalLabel}
          </p>
          <p className="mt-0.5 text-lg font-extrabold text-[var(--text-primary)] tabular-nums">
            {state.lifetimeTotal}
          </p>
        </div>
        <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-3 text-center">
          <p className="text-[11px] font-bold uppercase text-[var(--text-muted)]">
            Cycles
          </p>
          <p className="mt-0.5 text-lg font-extrabold text-amber-600 dark:text-amber-400 tabular-nums">
            {state.cyclesCompleted}
          </p>
        </div>
      </div>

      {/* Interactive Circular Counter / Tap Zone */}
      <div
        role="button"
        tabIndex={0}
        onClick={() => {
          if (state.tapAnywhere) handleTap();
        }}
        onKeyDown={(e) => {
          if (e.key === ' ' || e.key === 'Enter') {
            e.preventDefault();
            handleTap();
          }
        }}
        className={`rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-6 shadow-sm flex flex-col items-center select-none transition ${
          state.tapAnywhere ? 'cursor-pointer active:bg-[var(--bg-elevated)]/60' : ''
        }`}
      >
        <p dir="rtl" className="font-arabic text-2xl sm:text-3xl font-bold text-[var(--emerald-primary)] text-center">
          {activePreset.arabic}
        </p>
        <p className="mt-1 text-xs font-semibold text-[var(--text-secondary)]">
          {settings.appLanguage === 'ml' ? activePreset.titleMl : activePreset.titleEn}
        </p>

        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            handleTap();
          }}
          className="relative mt-6 w-52 h-52 rounded-full flex items-center justify-center active:scale-95 transition-transform focus:outline-none"
          aria-label={t.tapToCount}
        >
          <svg className="w-52 h-52 -rotate-90" viewBox="0 0 200 200">
            <circle
              cx="100"
              cy="100"
              r={radius}
              stroke="var(--border-color)"
              strokeWidth="12"
              fill="var(--bg-elevated)"
            />
            {activeTarget > 0 && (
              <circle
                cx="100"
                cy="100"
                r={radius}
                stroke="var(--emerald-primary)"
                strokeWidth="12"
                strokeLinecap="round"
                fill="none"
                strokeDasharray={circumference}
                strokeDashoffset={strokeDashoffset}
                className="transition-all duration-150"
              />
            )}
          </svg>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-5xl font-black text-[var(--text-primary)] tabular-nums">
              {state.currentCount}
            </span>
            <span className="mt-1 text-xs font-bold text-[var(--text-muted)] tabular-nums">
              {activeTarget > 0 ? `/ ${activeTarget}` : t.unlimitedLabel}
            </span>
          </div>
        </button>

        <p className="mt-4 text-xs text-[var(--text-muted)]">{t.tapToCount}</p>

        {/* Controls inside card stop propagation so they don't increment */}
        <div
          className="mt-5 w-full pt-4 border-t border-[var(--border-color)] space-y-3"
          onClick={(e) => e.stopPropagation()}
        >
          {/* Target Selector */}
          <div className="flex flex-wrap items-center justify-between gap-2">
            <span className="text-xs font-bold text-[var(--text-secondary)]">
              {t.targetLabel}
            </span>
            <div className="flex flex-wrap gap-1.5">
              {TARGET_OPTIONS.map((opt) => (
                <button
                  key={opt}
                  type="button"
                  onClick={() => setTargetForCurrent(opt)}
                  className={`rounded-lg px-2.5 py-1 text-xs font-bold tabular-nums transition ${
                    activeTarget === opt
                      ? 'bg-emerald-700 text-white'
                      : 'bg-[var(--bg-elevated)] text-[var(--text-secondary)]'
                  }`}
                >
                  {opt === 0 ? t.unlimitedLabel : opt}
                </button>
              ))}
            </div>
          </div>

          {/* Toggles + Reset */}
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex flex-wrap gap-2">
              <button
                type="button"
                onClick={() =>
                  commitState({ ...state, vibrateOnTap: !state.vibrateOnTap })
                }
                className={`inline-flex items-center gap-1.5 rounded-xl border px-3 py-1.5 text-xs font-bold transition ${
                  state.vibrateOnTap
                    ? 'border-emerald-600/40 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                    : 'border-[var(--border-color)] text-[var(--text-secondary)]'
                }`}
              >
                <Vibrate className="w-3.5 h-3.5" />
                <span>{t.vibrateOnTapLabel}</span>
              </button>

              <button
                type="button"
                onClick={() =>
                  commitState({ ...state, tapAnywhere: !state.tapAnywhere })
                }
                className={`rounded-xl border px-3 py-1.5 text-xs font-bold transition ${
                  state.tapAnywhere
                    ? 'border-emerald-600/40 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                    : 'border-[var(--border-color)] text-[var(--text-secondary)]'
                }`}
              >
                {t.tapAnywhereLabel}
              </button>
            </div>

            <button
              type="button"
              onClick={handleResetCycle}
              className="inline-flex items-center gap-1.5 rounded-xl border border-[var(--border-color)] px-3 py-1.5 text-xs font-bold text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>{t.resetCycleLabel}</span>
            </button>
          </div>
        </div>
      </div>

      {/* Add Custom Dhikr Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/55 p-4">
          <form
            onSubmit={handleCreateCustom}
            className="w-full max-w-sm rounded-3xl bg-[var(--bg-card)] border border-[var(--border-color)] p-5 shadow-2xl space-y-4"
          >
            <div className="flex items-center justify-between">
              <h3 className="text-base font-bold">{t.addCustomDhikr}</h3>
              <button
                type="button"
                onClick={() => setShowAddModal(false)}
                className="p-1.5 rounded-xl hover:bg-[var(--bg-elevated)]"
                aria-label="Close"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div>
              <label className="text-xs font-bold text-[var(--text-muted)]">
                Title (English / Malayalam)
              </label>
              <input
                type="text"
                value={newTitleEn}
                onChange={(e) => setNewTitleEn(e.target.value)}
                placeholder="e.g. HasbunAllahu wa Ni'mal Wakeel"
                className="mt-1 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-sm"
              />
            </div>

            <div>
              <label className="text-xs font-bold text-[var(--text-muted)]">
                Arabic Text (Optional)
              </label>
              <input
                type="text"
                dir="rtl"
                value={newArabic}
                onChange={(e) => setNewArabic(e.target.value)}
                placeholder="حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ"
                className="mt-1 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 font-arabic text-lg"
              />
            </div>

            <div>
              <label className="text-xs font-bold text-[var(--text-muted)]">
                {t.targetLabel}
              </label>
              <div className="mt-1.5 flex gap-1.5">
                {TARGET_OPTIONS.map((opt) => (
                  <button
                    key={opt}
                    type="button"
                    onClick={() => setNewTarget(opt)}
                    className={`flex-1 rounded-xl py-1.5 text-xs font-bold tabular-nums ${
                      newTarget === opt
                        ? 'bg-emerald-700 text-white'
                        : 'bg-[var(--bg-elevated)] text-[var(--text-secondary)]'
                    }`}
                  >
                    {opt === 0 ? t.unlimitedLabel : opt}
                  </button>
                ))}
              </div>
            </div>

            <button
              type="submit"
              className="w-full rounded-xl bg-emerald-700 py-2.5 text-sm font-bold text-white hover:bg-emerald-800"
            >
              {t.applyLabel}
            </button>
          </form>
        </div>
      )}
    </div>
  );
}
