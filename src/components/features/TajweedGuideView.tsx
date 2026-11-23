'use client';

import React from 'react';
import { BookOpenCheck } from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { TajweedText } from '@/components/TajweedText';
import { TAJWEED_LEGEND } from '@/lib/tajweedEngine';

export function TajweedGuideView() {
  const { settings, updateSettings, t } = useIbadia();
  const isDark = settings.themeMode === 'dark';

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 shadow-sm flex items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[var(--emerald-soft)] text-[var(--emerald-primary)] flex items-center justify-center shrink-0">
            <BookOpenCheck className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-sm sm:text-base font-bold text-[var(--text-primary)]">
              {t.tajweedGuideTitle}
            </h2>
            <p className="text-xs text-[var(--text-muted)]">
              {t.tajweedColorCoding}
            </p>
          </div>
        </div>

        <label className="inline-flex items-center gap-2 cursor-pointer">
          <span className="text-xs font-bold text-[var(--text-secondary)]">
            {settings.tajweedEnabled ? 'ON' : 'OFF'}
          </span>
          <input
            type="checkbox"
            checked={settings.tajweedEnabled}
            onChange={(e) => updateSettings({ tajweedEnabled: e.target.checked })}
            className="w-4 h-4 accent-emerald-700"
          />
        </label>
      </div>

      {/* Interactive Live Preview Sample */}
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 text-center space-y-2">
        <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--text-muted)]">
          Tap any colored letter to inspect rule
        </p>
        <div dir="rtl" className="font-arabic text-3xl leading-[2.1] text-[var(--text-primary)]">
          <TajweedText
            text="بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ ۝ إِنَّا أَعْطَيْنَاكَ ٱلْكَوْثَرَ ۝ قُلْ هُوَ ٱللَّهُ أَحَدٌ"
            enabled={true}
          />
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        {TAJWEED_LEGEND.map((item) => {
          const color = isDark ? item.darkColor : item.lightColor;
          const title =
            settings.appLanguage === 'ml'
              ? item.nameMl
              : settings.appLanguage === 'ar'
              ? item.nameAr
              : item.nameEn;
          const desc =
            settings.appLanguage === 'ml'
              ? item.descMl
              : settings.appLanguage === 'ar'
              ? item.descAr
              : item.descEn;

          return (
            <div
              key={item.rule}
              className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 space-y-2"
            >
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2.5 min-w-0">
                  <span
                    className="w-3.5 h-3.5 rounded-full shrink-0"
                    style={{ backgroundColor: color }}
                  />
                  <h3 className="text-sm font-bold text-[var(--text-primary)] truncate">
                    {title}
                  </h3>
                </div>
                <span
                  dir="rtl"
                  className="font-arabic text-lg font-bold shrink-0"
                  style={{ color }}
                >
                  {item.sampleAr}
                </span>
              </div>
              <p className="text-xs leading-relaxed text-[var(--text-secondary)]">
                {desc}
              </p>
            </div>
          );
        })}
      </div>
    </div>
  );
}
