'use client';

import React, { useState } from 'react';
import {
  Bell,
  BellOff,
  Edit3,
  MapPin,
  Navigation,
  RefreshCw,
  ShieldAlert,
  SlidersHorizontal,
  Volume2,
  VolumeX,
  X,
} from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import {
  ALARM_SOUNDS,
  FIVE_PRAYER_KEYS,
  PRAYER_METHODS,
  QUICK_CITIES,
} from '@/lib/apiConfig';
import { format12Hour } from '@/lib/islamicFeaturesApi';
import { getNativeBridge } from '@/lib/storage';
import type { ComputedPrayerSlot, PrayerKey } from '@/types';

export function PrayerTimesView() {
  const {
    settings,
    updateSettings,
    t,
    prayerData,
    prayerSlots,
    nextPrayerSlot,
    countdownLabel,
    prayerLoading,
    gpsLoading,
    refreshPrayerTimes,
    useGpsLocation,
    dismissAlarmToday,
    previewAlarmSound,
    stopAlarmPreview,
    isPreviewPlaying,
    showToast,
  } = useIbadia();

  const [showLocationModal, setShowLocationModal] = useState(false);
  const [cityInput, setCityInput] = useState(settings.prayerCity);
  const [countryInput, setCountryInput] = useState(settings.prayerCountry);
  const [editingSlot, setEditingSlot] = useState<ComputedPrayerSlot | null>(null);
  const [showTunes, setShowTunes] = useState(false);

  const prayerLabel = (k: PrayerKey | 'sunrise') => {
    if (k === 'fajr') return t.fajrName;
    if (k === 'sunrise') return t.sunriseName;
    if (k === 'dhuhr') return t.dhuhrName;
    if (k === 'asr') return t.asrName;
    if (k === 'maghrib') return t.maghribName;
    return t.ishaName;
  };

  const bridge = getNativeBridge();
  const hasNativeDnd = bridge?.hasDndPermission?.() ?? true;
  const activeNativeDnd = bridge?.isDndSessionActive?.() ?? false;

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      {/* Hero Next Prayer Card */}
      <div className="rounded-3xl bg-gradient-to-br from-emerald-800 via-emerald-700 to-emerald-900 text-white p-5 shadow-lg">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-xs font-bold uppercase tracking-wider text-emerald-100/80">
              {t.nextPrayerLabel}
            </p>
            <h2 className="mt-1 text-2xl sm:text-3xl font-extrabold">
              {nextPrayerSlot ? prayerLabel(nextPrayerSlot.prayerKey) : '--'}{' '}
              <span className="text-emerald-200 font-bold tabular-nums">
                {nextPrayerSlot ? format12Hour(nextPrayerSlot.adhanTime) : ''}
              </span>
            </h2>
            <p className="mt-1 text-sm text-emerald-100 tabular-nums">
              {t.remainingLabel} {countdownLabel}
            </p>
          </div>

          <button
            type="button"
            onClick={() => refreshPrayerTimes(true)}
            disabled={prayerLoading}
            className="p-2.5 rounded-xl bg-white/15 hover:bg-white/25 transition"
            title={t.refreshLabel}
          >
            <RefreshCw className={`w-4 h-4 ${prayerLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>

        <div className="mt-4 pt-3 border-t border-white/15 flex flex-wrap items-center justify-between gap-2 text-xs">
          <div className="flex items-center gap-1.5">
            <MapPin className="w-3.5 h-3.5 text-amber-300" />
            <span className="font-semibold">
              {prayerData?.locationLabel ?? `${settings.prayerCity}, ${settings.prayerCountry}`}
            </span>
          </div>
          {prayerData && (
            <span className="font-semibold text-emerald-100">
              {prayerData.hijriDay} {prayerData.hijriMonthEn} {prayerData.hijriYear}
              {prayerData.loadedFromCache ? ` · ${t.offlineCachedNote}` : ''}
            </span>
          )}
        </div>

        <div className="mt-3 flex gap-2">
          <button
            type="button"
            onClick={useGpsLocation}
            disabled={gpsLoading}
            className="flex-1 rounded-xl bg-white/15 hover:bg-white/25 py-2 px-3 text-xs font-bold inline-flex items-center justify-center gap-1.5"
          >
            <Navigation className="w-3.5 h-3.5" />
            <span>{gpsLoading ? t.gpsFetching : t.useGps}</span>
          </button>
          <button
            type="button"
            onClick={() => {
              setCityInput(settings.prayerCity);
              setCountryInput(settings.prayerCountry);
              setShowLocationModal(true);
            }}
            className="flex-1 rounded-xl bg-white text-emerald-900 py-2 px-3 text-xs font-bold inline-flex items-center justify-center gap-1.5"
          >
            <MapPin className="w-3.5 h-3.5" />
            <span>{t.changeCity}</span>
          </button>
        </div>
      </div>

      {/* 5 Daily Prayers Table / Cards */}
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] overflow-hidden shadow-sm">
        <div className="px-4 py-3 border-b border-[var(--border-color)] flex items-center justify-between">
          <span className="text-sm font-extrabold">{t.actionPrayer}</span>
          <label className="inline-flex items-center gap-2 text-xs font-bold cursor-pointer">
            <span>{t.masterAlarmToggle}</span>
            <input
              type="checkbox"
              checked={settings.masterAlarmEnabled}
              onChange={(e) => updateSettings({ masterAlarmEnabled: e.target.checked })}
              className="w-4 h-4 accent-emerald-700"
            />
          </label>
        </div>

        <div className="divide-y divide-[var(--border-color)]">
          {prayerSlots.map((slot) => {
            const isNext = nextPrayerSlot?.prayerKey === slot.prayerKey;
            const cfg = settings.prayerConfigs[slot.prayerKey];
            return (
              <div
                key={slot.prayerKey}
                className={`px-4 py-3.5 flex items-center justify-between gap-3 ${
                  isNext ? 'bg-[var(--emerald-soft)]/55' : ''
                }`}
              >
                <div className="min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-sm sm:text-base">{prayerLabel(slot.prayerKey)}</span>
                    {slot.tuneMinutes !== 0 && (
                      <span className="text-[11px] font-bold text-[var(--gold-accent)] tabular-nums">
                        ({slot.tuneMinutes > 0 ? `+${slot.tuneMinutes}` : slot.tuneMinutes}m)
                      </span>
                    )}
                  </div>
                  <div className="flex flex-wrap items-center gap-x-3 gap-y-0.5 text-xs text-[var(--text-secondary)] mt-0.5 tabular-nums">
                    <span>
                      {t.adhanLabel}: <strong className="text-[var(--text-primary)]">{format12Hour(slot.adhanTime)}</strong>
                    </span>
                    <span>
                      {t.iqamahLabel}: <strong>{format12Hour(slot.iqamahTime)}</strong>
                    </span>
                    {slot.alarmTime && slot.masterEnabled && slot.prayerAlarmEnabled && (
                      <span className="text-[var(--emerald-primary)] font-semibold">
                        {t.alarmLabel}: {format12Hour(slot.alarmTime)}
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-1 shrink-0">
                  <button
                    type="button"
                    onClick={() => setEditingSlot(slot)}
                    className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-secondary)]"
                    title="Edit Iqamah & Alarm"
                  >
                    <Edit3 className="w-4 h-4" />
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      updateSettings({
                        prayerConfigs: {
                          ...settings.prayerConfigs,
                          [slot.prayerKey]: { ...cfg, enabled: !cfg.enabled },
                        },
                      })
                    }
                    className={`p-2 rounded-xl transition ${
                      cfg.enabled && settings.masterAlarmEnabled
                        ? 'text-[var(--emerald-primary)] bg-[var(--emerald-soft)]'
                        : 'text-[var(--text-muted)] hover:bg-[var(--bg-elevated)]'
                    }`}
                    title={t.alarmLabel}
                  >
                    {cfg.enabled && settings.masterAlarmEnabled ? (
                      <Bell className="w-4 h-4" />
                    ) : (
                      <BellOff className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Auto-Silent (DND) during Prayer */}
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 sm:p-5 space-y-3 shadow-sm">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h3 className="text-sm sm:text-base font-extrabold flex items-center gap-2">
              <VolumeX className="w-4 h-4 text-[var(--emerald-primary)]" />
              <span>{t.autoSilentTitle}</span>
            </h3>
            <p className="text-xs text-[var(--text-secondary)] mt-1 leading-relaxed">
              {t.autoSilentDesc}
            </p>
          </div>
          <input
            type="checkbox"
            checked={settings.autoSilentEnabled}
            onChange={(e) => updateSettings({ autoSilentEnabled: e.target.checked })}
            className="w-5 h-5 accent-emerald-700 shrink-0 mt-0.5 cursor-pointer"
          />
        </div>

        {settings.autoSilentEnabled && (
          <div className="space-y-3 pt-2 border-t border-[var(--border-color)]">
            <div>
              <p className="text-xs font-bold text-[var(--text-muted)] mb-2">
                {t.autoSilentDurationLabel}
              </p>
              <div className="flex flex-wrap gap-2">
                {[10, 15, 20, 25, 30].map((min) => (
                  <button
                    key={min}
                    type="button"
                    onClick={() => updateSettings({ autoSilentDurationMinutes: min })}
                    className={`rounded-xl px-3 py-1.5 text-xs font-bold border tabular-nums transition ${
                      settings.autoSilentDurationMinutes === min
                        ? 'bg-emerald-700 text-white border-emerald-700'
                        : 'border-[var(--border-color)] bg-[var(--bg-elevated)]/50 text-[var(--text-secondary)]'
                    }`}
                  >
                    {min} min
                  </button>
                ))}
              </div>
            </div>

            <div>
              <p className="text-xs font-bold text-[var(--text-muted)] mb-2">
                {t.autoSilentPrayersLabel}
              </p>
              <div className="flex flex-wrap gap-2">
                {FIVE_PRAYER_KEYS.map((pk) => {
                  const active = settings.autoSilentPrayers[pk];
                  return (
                    <button
                      key={pk}
                      type="button"
                      onClick={() =>
                        updateSettings({
                          autoSilentPrayers: { ...settings.autoSilentPrayers, [pk]: !active },
                        })
                      }
                      className={`rounded-xl px-3 py-1.5 text-xs font-bold border transition ${
                        active
                          ? 'border-emerald-600 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                          : 'border-[var(--border-color)] text-[var(--text-muted)]'
                      }`}
                    >
                      {prayerLabel(pk)}
                    </button>
                  );
                })}
              </div>
            </div>

            {bridge ? (
              <div className="flex flex-wrap gap-2 pt-1">
                {!hasNativeDnd && bridge.requestDndPermission && (
                  <button
                    type="button"
                    onClick={() => bridge.requestDndPermission?.()}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-amber-600 px-3 py-2 text-xs font-bold text-white"
                  >
                    <ShieldAlert className="w-3.5 h-3.5" />
                    <span>{t.grantDndPermissionBtn}</span>
                  </button>
                )}
                {activeNativeDnd && bridge.restoreDndNow && (
                  <button
                    type="button"
                    onClick={() => bridge.restoreDndNow?.()}
                    className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-700 px-3 py-2 text-xs font-bold text-white"
                  >
                    <Volume2 className="w-3.5 h-3.5" />
                    <span>{t.restoreSoundNowBtn}</span>
                  </button>
                )}
              </div>
            ) : (
              <p className="text-xs text-[var(--text-muted)] bg-[var(--bg-elevated)]/60 rounded-xl px-3 py-2">
                {t.autoSilentWebNote}
              </p>
            )}
          </div>
        )}
      </div>

      {/* Calculation Method, Asr School, Masjid Tune & Alarm Sound */}
      <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-card)] p-4 sm:p-5 space-y-4 shadow-sm">
        <div>
          <label className="block text-xs font-bold text-[var(--text-muted)] mb-1.5">
            {t.calculationMethod}
          </label>
          <select
            value={settings.prayerMethod}
            onChange={(e) => updateSettings({ prayerMethod: Number(e.target.value) })}
            className="w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2.5 text-sm font-semibold"
          >
            {PRAYER_METHODS.map((m) => (
              <option key={m.id} value={m.id}>
                {settings.appLanguage === 'ml'
                  ? m.malayalamName
                  : settings.appLanguage === 'ar'
                  ? m.arabicName
                  : m.englishName}
              </option>
            ))}
          </select>
        </div>

        <div>
          <p className="text-xs font-bold text-[var(--text-muted)] mb-1.5">{t.asrSchool}</p>
          <div className="grid grid-cols-2 gap-2">
            {[
              { id: 0, label: t.schoolShafi },
              { id: 1, label: t.schoolHanafi },
            ].map((s) => (
              <button
                key={s.id}
                type="button"
                onClick={() => updateSettings({ prayerSchool: s.id })}
                className={`rounded-xl py-2 text-xs font-bold border transition ${
                  settings.prayerSchool === s.id
                    ? 'border-emerald-600 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                    : 'border-[var(--border-color)] text-[var(--text-secondary)]'
                }`}
              >
                {s.label}
              </button>
            ))}
          </div>
        </div>

        {/* Alarm Sound & Preview */}
        <div className="pt-2 border-t border-[var(--border-color)] space-y-3">
          <p className="text-xs font-bold text-[var(--text-muted)]">{t.alarmSoundSettings}</p>
          <div className="flex gap-2">
            <select
              value={settings.alarmSoundType}
              onChange={(e) => updateSettings({ alarmSoundType: e.target.value })}
              className="flex-1 rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-xs font-semibold"
            >
              {ALARM_SOUNDS.map((s) => (
                <option key={s.id} value={s.id}>
                  {settings.appLanguage === 'ml'
                    ? s.malayalamName
                    : settings.appLanguage === 'ar'
                    ? s.arabicName
                    : s.englishName}
                </option>
              ))}
            </select>
            <button
              type="button"
              onClick={() => (isPreviewPlaying ? stopAlarmPreview() : previewAlarmSound())}
              className="rounded-xl bg-emerald-700 text-white px-3.5 py-2 text-xs font-bold shrink-0"
            >
              {isPreviewPlaying ? t.stopSoundLabel : t.previewSoundLabel}
            </button>
          </div>
          <div>
            <div className="flex justify-between text-xs font-semibold mb-1">
              <span>{t.alarmVolumeLabel}</span>
              <span className="tabular-nums">{Math.round(settings.alarmVolume * 100)}%</span>
            </div>
            <input
              type="range"
              min={0.1}
              max={1.0}
              step={0.05}
              value={settings.alarmVolume}
              onChange={(e) => updateSettings({ alarmVolume: Number(e.target.value) })}
              className="w-full accent-emerald-700"
            />
          </div>
        </div>

        {/* Masjid Time Tune Accordion */}
        <div className="pt-2 border-t border-[var(--border-color)]">
          <button
            type="button"
            onClick={() => setShowTunes((v) => !v)}
            className="w-full flex items-center justify-between text-xs font-bold text-[var(--emerald-primary)]"
          >
            <span className="inline-flex items-center gap-1.5">
              <SlidersHorizontal className="w-3.5 h-3.5" />
              {t.tuneMinutes}
            </span>
            <span>{showTunes ? '−' : '+'}</span>
          </button>

          {showTunes && (
            <div className="mt-3 space-y-2.5">
              {FIVE_PRAYER_KEYS.map((k) => {
                const val = settings.prayerTunes[k] ?? 0;
                return (
                  <div key={k} className="flex items-center justify-between text-xs">
                    <span className="font-semibold w-24">{prayerLabel(k)}</span>
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() =>
                          updateSettings({ prayerTunes: { ...settings.prayerTunes, [k]: val - 1 } })
                        }
                        className="w-7 h-7 rounded-lg border border-[var(--border-color)] font-bold"
                      >
                        −
                      </button>
                      <span className="w-12 text-center font-bold tabular-nums">
                        {val > 0 ? `+${val}` : val}m
                      </span>
                      <button
                        type="button"
                        onClick={() =>
                          updateSettings({ prayerTunes: { ...settings.prayerTunes, [k]: val + 1 } })
                        }
                        className="w-7 h-7 rounded-lg border border-[var(--border-color)] font-bold"
                      >
                        +
                      </button>
                    </div>
                  </div>
                );
              })}
              <button
                type="button"
                onClick={() =>
                  updateSettings({ prayerTunes: { fajr: 0, dhuhr: 0, asr: 0, maghrib: 0, isha: 0 } })
                }
                className="text-xs font-bold text-rose-500 hover:underline"
              >
                {t.resetTune}
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Location Picker Modal */}
      {showLocationModal && (
        <div
          className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 p-0 sm:p-4"
          onClick={() => setShowLocationModal(false)}
        >
          <div
            className="w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl bg-[var(--bg-card)] border border-[var(--border-color)] p-5 space-y-4 max-h-[85vh] overflow-y-auto"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-base">{t.changeCity}</h3>
              <button type="button" onClick={() => setShowLocationModal(false)} className="p-1">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-2">
              <input
                type="text"
                value={cityInput}
                onChange={(e) => setCityInput(e.target.value)}
                placeholder={t.cityFieldLabel}
                className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-sm"
              />
              <input
                type="text"
                value={countryInput}
                onChange={(e) => setCountryInput(e.target.value)}
                placeholder={t.countryFieldLabel}
                className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-sm"
              />
            </div>

            <button
              type="button"
              onClick={() => {
                updateSettings({
                  prayerLocationMode: 'city',
                  prayerCity: cityInput.trim() || 'Kochi',
                  prayerCountry: countryInput.trim() || 'India',
                });
                setShowLocationModal(false);
                showToast('City updated');
              }}
              className="w-full rounded-xl bg-emerald-700 py-2.5 text-sm font-bold text-white"
            >
              {t.applyLabel}
            </button>

            <div>
              <p className="text-xs font-bold text-[var(--text-muted)] mb-2">{t.popularCities}</p>
              <div className="flex flex-wrap gap-1.5">
                {QUICK_CITIES.map((c) => (
                  <button
                    key={`${c.city}_${c.country}`}
                    type="button"
                    onClick={() => {
                      updateSettings({
                        prayerLocationMode: 'city',
                        prayerCity: c.city,
                        prayerCountry: c.country,
                        prayerLat: c.latitude,
                        prayerLon: c.longitude,
                      });
                      setShowLocationModal(false);
                    }}
                    className="rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-1.5 text-xs font-semibold hover:border-emerald-600"
                  >
                    {c.city}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Iqamah & Alarm Modal */}
      {editingSlot && (
        <div
          className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/50 p-0 sm:p-4"
          onClick={() => setEditingSlot(null)}
        >
          <div
            className="w-full sm:max-w-md rounded-t-2xl sm:rounded-2xl bg-[var(--bg-card)] border border-[var(--border-color)] p-5 space-y-4"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-base">
                {prayerLabel(editingSlot.prayerKey)} — {t.iqamahLabel} & {t.alarmLabel}
              </h3>
              <button type="button" onClick={() => setEditingSlot(null)} className="p-1">
                <X className="w-4 h-4" />
              </button>
            </div>

            {(() => {
              const cfg = settings.prayerConfigs[editingSlot.prayerKey];
              return (
                <div className="space-y-4">
                  <div>
                    <div className="flex justify-between text-xs font-bold mb-1">
                      <span>{t.iqamahGapLabel}</span>
                      <span className="tabular-nums text-[var(--emerald-primary)]">
                        {cfg.iqamahGapMinutes}m
                      </span>
                    </div>
                    <input
                      type="range"
                      min={0}
                      max={Math.min(90, editingSlot.maxAllowedIqamahGap)}
                      value={cfg.iqamahGapMinutes}
                      onChange={(e) =>
                        updateSettings({
                          prayerConfigs: {
                            ...settings.prayerConfigs,
                            [editingSlot.prayerKey]: {
                              ...cfg,
                              iqamahGapMinutes: Number(e.target.value),
                            },
                          },
                        })
                      }
                      className="w-full accent-emerald-700"
                    />
                  </div>

                  <div>
                    <p className="text-xs font-bold mb-1.5">{t.alarmRefLabel}</p>
                    <div className="grid grid-cols-2 gap-2">
                      {(
                        [
                          { id: 'beforeAdhan', label: t.beforeAdhanOption },
                          { id: 'relativeToIqamah', label: t.relativeToIqamahOption },
                        ] as const
                      ).map((opt) => (
                        <button
                          key={opt.id}
                          type="button"
                          onClick={() =>
                            updateSettings({
                              prayerConfigs: {
                                ...settings.prayerConfigs,
                                [editingSlot.prayerKey]: { ...cfg, alarmRef: opt.id },
                              },
                            })
                          }
                          className={`rounded-xl py-2 text-xs font-bold border ${
                            cfg.alarmRef === opt.id
                              ? 'border-emerald-600 bg-[var(--emerald-soft)] text-[var(--emerald-primary)]'
                              : 'border-[var(--border-color)]'
                          }`}
                        >
                          {opt.label}
                        </button>
                      ))}
                    </div>
                  </div>

                  <div>
                    <div className="flex justify-between text-xs font-bold mb-1">
                      <span>Offset (minutes)</span>
                      <span className="tabular-nums">{cfg.alarmOffsetMinutes}m</span>
                    </div>
                    <input
                      type="range"
                      min={cfg.alarmRef === 'beforeAdhan' ? 0 : -45}
                      max={cfg.alarmRef === 'beforeAdhan' ? 60 : 45}
                      value={cfg.alarmOffsetMinutes}
                      onChange={(e) =>
                        updateSettings({
                          prayerConfigs: {
                            ...settings.prayerConfigs,
                            [editingSlot.prayerKey]: {
                              ...cfg,
                              alarmOffsetMinutes: Number(e.target.value),
                            },
                          },
                        })
                      }
                      className="w-full accent-emerald-700"
                    />
                  </div>

                  <button
                    type="button"
                    onClick={() => dismissAlarmToday(editingSlot.prayerKey)}
                    className={`w-full rounded-xl py-2.5 text-xs font-bold border ${
                      editingSlot.dismissedToday
                        ? 'border-amber-600 bg-amber-500/10 text-amber-600'
                        : 'border-[var(--border-color)]'
                    }`}
                  >
                    {editingSlot.dismissedToday ? t.dismissedTodayLabel : t.dismissTodayAlarm}
                  </button>
                </div>
              );
            })()}
          </div>
        </div>
      )}
    </div>
  );
}
