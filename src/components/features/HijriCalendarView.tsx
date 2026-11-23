'use client';

import React, { useEffect, useState } from 'react';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, Loader2, Sparkles } from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { HIJRI_MONTHS_AR, HIJRI_MONTHS_EN } from '@/lib/apiConfig';
import { fetchHijriMonthCalendar, resolveTodayHijriDate } from '@/lib/islamicFeaturesApi';
import type { CalendarDayEntry } from '@/types';

export function HijriCalendarView() {
  const { settings, updateSettings, t } = useIbadia();
  const [hijriYear, setHijriYear] = useState(1448);
  const [hijriMonth, setHijriMonth] = useState(1);
  const [todayHijri, setTodayHijri] = useState<{ year: number; month: number; day: number } | null>(null);
  const [days, setDays] = useState<CalendarDayEntry[]>([]);
  const [selectedDay, setSelectedDay] = useState<CalendarDayEntry | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    resolveTodayHijriDate(settings.hijriAdjustment)
      .then((res) => {
        setTodayHijri(res);
        setHijriYear(res.year);
        setHijriMonth(res.month);
      })
      .catch(() => {});
  }, [settings.hijriAdjustment]);

  useEffect(() => {
    let cancelled = false;
    void Promise.resolve()
      .then(() => {
        if (!cancelled) setLoading(true);
        return fetchHijriMonthCalendar(hijriYear, hijriMonth, settings.hijriAdjustment);
      })
      .then((list) => {
        if (cancelled) return;
        setDays(list);
        const matchToday = list.find(
          (d) =>
            todayHijri &&
            d.hijriYear === todayHijri.year &&
            d.hijriMonthNumber === todayHijri.month &&
            d.hijriDay === todayHijri.day
        );
        setSelectedDay(matchToday ?? list[0] ?? null);
        setLoading(false);
      })
      .catch(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [hijriYear, hijriMonth, settings.hijriAdjustment, todayHijri]);

  const changeMonth = (delta: number) => {
    let m = hijriMonth + delta;
    let y = hijriYear;
    if (m > 12) {
      m = 1;
      y++;
    } else if (m < 1) {
      m = 12;
      y--;
    }
    setHijriMonth(m);
    setHijriYear(y);
  };

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 sm:p-5 shadow-sm space-y-4">
        <div className="flex items-center justify-between gap-2">
          <button
            type="button"
            onClick={() => changeMonth(-1)}
            className="p-2 rounded-xl border border-[var(--border-color)] hover:bg-[var(--bg-elevated)]"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>

          <div className="text-center">
            <h2 className="text-base sm:text-lg font-extrabold text-[var(--emerald-primary)]">
              {HIJRI_MONTHS_EN[hijriMonth - 1]} {hijriYear} AH
            </h2>
            <p className="font-arabic text-lg text-[var(--text-secondary)]">
              {HIJRI_MONTHS_AR[hijriMonth - 1]}
            </p>
          </div>

          <button
            type="button"
            onClick={() => changeMonth(1)}
            className="p-2 rounded-xl border border-[var(--border-color)] hover:bg-[var(--bg-elevated)]"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>

        {/* Hijri Moon Sighting Offset (-1 / 0 / +1) */}
        <div>
          <p className="text-xs font-bold text-[var(--text-muted)] mb-1.5">{t.hijriAdjustment}</p>
          <div className="grid grid-cols-3 gap-2">
            {[-1, 0, 1].map((adj) => (
              <button
                key={adj}
                type="button"
                onClick={() => updateSettings({ hijriAdjustment: adj })}
                className={`rounded-xl py-2 text-xs font-bold border transition ${
                  settings.hijriAdjustment === adj
                    ? 'border-emerald-600 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                    : 'border-[var(--border-color)] text-[var(--text-secondary)]'
                }`}
              >
                {adj === -1 ? '-1 Day' : adj === 0 ? '0 (Default)' : '+1 Day'}
              </button>
            ))}
          </div>
        </div>

        {/* Calendar Grid */}
        {loading ? (
          <div className="py-12 flex justify-center">
            <Loader2 className="w-7 h-7 animate-spin text-[var(--emerald-primary)]" />
          </div>
        ) : (
          <div className="grid grid-cols-7 gap-1.5 sm:gap-2">
            {days.map((d) => {
              const isToday =
                todayHijri &&
                d.hijriYear === todayHijri.year &&
                d.hijriMonthNumber === todayHijri.month &&
                d.hijriDay === todayHijri.day;
              const isSel = selectedDay?.hijriDay === d.hijriDay;
              return (
                <button
                  key={`${d.hijriDay}-${d.gregorianDay}`}
                  type="button"
                  onClick={() => setSelectedDay(d)}
                  className={`rounded-xl border p-2 text-center transition flex flex-col items-center justify-center ${
                    isSel
                      ? 'border-emerald-700 bg-emerald-700 text-white'
                      : isToday
                      ? 'border-amber-500 bg-amber-500/10 text-[var(--text-primary)]'
                      : 'border-[var(--border-color)] bg-[var(--bg-elevated)]/40 hover:border-emerald-600/50'
                  }`}
                >
                  <span className="text-sm font-extrabold tabular-nums">{d.hijriDay}</span>
                  <span className={`text-[10px] tabular-nums ${isSel ? 'text-emerald-100' : 'text-[var(--text-muted)]'}`}>
                    {d.gregorianDay} {d.gregorianMonthEn.slice(0, 3)}
                  </span>
                  {d.holidays.length > 0 && (
                    <span className={`w-1.5 h-1.5 rounded-full mt-0.5 ${isSel ? 'bg-amber-300' : 'bg-amber-500'}`} />
                  )}
                </button>
              );
            })}
          </div>
        )}
      </div>

      {/* Selected Day Info Card */}
      {selectedDay && (
        <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 flex items-start justify-between gap-3">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <CalendarIcon className="w-4 h-4 text-[var(--emerald-primary)]" />
              <span className="text-sm font-extrabold">
                {selectedDay.hijriDay} {selectedDay.hijriMonthEn} {selectedDay.hijriYear} AH
              </span>
            </div>
            <p className="text-xs text-[var(--text-secondary)]">
              {selectedDay.weekdayEn}, {selectedDay.gregorianDay} {selectedDay.gregorianMonthEn} {selectedDay.gregorianYear}
            </p>
            {selectedDay.holidays.length > 0 && (
              <p className="text-xs font-bold text-[var(--gold-accent)] flex items-center gap-1 pt-1">
                <Sparkles className="w-3.5 h-3.5" />
                <span>{selectedDay.holidays.join(' · ')}</span>
              </p>
            )}
          </div>
          <span className="font-arabic text-xl font-bold text-[var(--emerald-primary)]">
            {selectedDay.hijriMonthAr}
          </span>
        </div>
      )}
    </div>
  );
}
