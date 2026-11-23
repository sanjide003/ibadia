'use client';

import React, { useMemo } from 'react';
import { X } from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import {
  metaForTajweedRule,
  parseAyahTajweed,
  type TajweedRule,
  type TajweedRuleMeta,
} from '@/lib/tajweedEngine';

interface TajweedTextProps {
  text: string;
  enabled: boolean;
  onSelectRule?: (meta: TajweedRuleMeta) => void;
  className?: string;
}

export function TajweedText({
  text,
  enabled,
  onSelectRule,
  className = '',
}: TajweedTextProps) {
  const { settings } = useIbadia();
  const isDark = settings.themeMode === 'dark';

  const tokens = useMemo(() => {
    if (!enabled) return null;
    return parseAyahTajweed(text);
  }, [text, enabled]);

  if (!enabled || !tokens) {
    return <span className={className}>{text}</span>;
  }

  return (
    <span className={className}>
      {tokens.map((tok, idx) => {
        if (tok.rule === 'none') {
          return <React.Fragment key={idx}>{tok.text}</React.Fragment>;
        }
        const meta = metaForTajweedRule(tok.rule as TajweedRule);
        const color = meta ? (isDark ? meta.darkColor : meta.lightColor) : undefined;
        return (
          <span
            key={idx}
            style={{ color }}
            onClick={(e) => {
              if (meta && onSelectRule) {
                e.stopPropagation();
                onSelectRule(meta);
              }
            }}
            className={onSelectRule ? 'cursor-pointer hover:underline decoration-dotted' : undefined}
          >
            {tok.text}
          </span>
        );
      })}
    </span>
  );
}

export function TajweedRuleModal({
  ruleMeta,
  onClose,
}: {
  ruleMeta: TajweedRuleMeta | null;
  onClose: () => void;
}) {
  const { settings, t } = useIbadia();
  if (!ruleMeta) return null;
  const isDark = settings.themeMode === 'dark';
  const color = isDark ? ruleMeta.darkColor : ruleMeta.lightColor;

  const title =
    settings.appLanguage === 'ml'
      ? ruleMeta.nameMl
      : settings.appLanguage === 'ar'
      ? ruleMeta.nameAr
      : ruleMeta.nameEn;

  const desc =
    settings.appLanguage === 'ml'
      ? ruleMeta.descMl
      : settings.appLanguage === 'ar'
      ? ruleMeta.descAr
      : ruleMeta.descEn;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 p-0 sm:p-4"
      onClick={onClose}
    >
      <div
        className="w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl bg-[var(--bg-card)] border border-[var(--border-color)] p-5 shadow-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-2.5">
            <span
              className="w-3.5 h-3.5 rounded-full shrink-0"
              style={{ backgroundColor: color }}
            />
            <h3 className="text-base font-bold" style={{ color }}>
              {title}
            </h3>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-[var(--bg-elevated)]"
            aria-label="Close"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div
          dir="rtl"
          className="mt-4 rounded-xl bg-[var(--bg-elevated)] px-4 py-3 text-center font-arabic text-2xl leading-loose"
          style={{ color }}
        >
          {ruleMeta.sampleAr}
        </div>

        <p className="mt-3 text-sm text-[var(--text-secondary)] leading-relaxed">{desc}</p>

        <button
          type="button"
          onClick={onClose}
          className="mt-4 w-full rounded-xl bg-emerald-700 py-2.5 text-sm font-semibold text-white hover:bg-emerald-800"
        >
          {t.done}
        </button>
      </div>
    </div>
  );
}
