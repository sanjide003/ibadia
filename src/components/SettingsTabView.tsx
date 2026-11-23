'use client';

import React from 'react';
import {
  CheckCircle2,
  Download,
  Globe,
  RotateCcw,
  Share2,
  ShieldAlert,
  Sparkles,
  Volume2,
} from 'lucide-react';
import { PWAInstallButton } from '@/components/PWAWidgets';
import { useIbadia } from '@/context/IbadiaProvider';
import {
  APP_BRANDING,
  localizedBrandName,
  PRAYER_METHODS,
  RECITERS,
  reciterDisplayName,
} from '@/lib/apiConfig';
import { getNativeBridge } from '@/lib/storage';
import type { AppLanguage, ReadingMode, ThemeMode, TranslationCode } from '@/types';

export function SettingsTabView() {
  const { settings, updateSettings, toggleTranslationLang, t, openHomeFeature, showToast } =
    useIbadia();

  const handleShareApp = async () => {
    const shareUrl = APP_BRANDING.webAppUrl;
    const shareTitle = localizedBrandName(settings.appLanguage);
    if (typeof navigator !== 'undefined' && navigator.share) {
      try {
        await navigator.share({
          title: shareTitle,
          text: `${shareTitle} — Quran, Prayer Times, Adhkar & 99 Names`,
          url: shareUrl,
        });
        return;
      } catch {
        // fallback to clipboard
      }
    }
    try {
      await navigator.clipboard.writeText(shareUrl);
      showToast(t.shareAppCopied);
    } catch {
      showToast(shareUrl);
    }
  };

  const bridge = getNativeBridge();

  return (
    <div className="mx-auto max-w-4xl px-4 pt-3 pb-28 space-y-4">
      {/* Instant Auto-Save Indicator */}
      <div className="rounded-2xl border border-emerald-600/30 bg-[var(--emerald-soft)] px-4 py-2.5 flex items-center gap-2 text-xs font-bold text-[var(--emerald-primary)]">
        <CheckCircle2 className="w-4 h-4 shrink-0" />
        <span>{t.autoSavedHint}</span>
      </div>

      {/* SECTION 1: QURAN READER SETTINGS */}
      <section className="rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-5 shadow-sm space-y-5">
        <h2 className="text-sm font-extrabold uppercase tracking-wider text-[var(--emerald-primary)]">
          {t.quranSettingsTitle}
        </h2>

        {/* App Language */}
        <div>
          <label className="text-xs font-bold text-[var(--text-muted)] flex items-center gap-1.5">
            <Globe className="w-3.5 h-3.5" />
            <span>{t.appLanguage}</span>
          </label>
          <div className="mt-2 grid grid-cols-3 gap-1.5 rounded-xl bg-[var(--bg-elevated)] p-1">
            {(
              [
                ['en', 'English'],
                ['ml', 'മലയാളം'],
                ['ar', 'العربية'],
              ] as [AppLanguage, string][]
            ).map(([code, label]) => (
              <button
                key={code}
                type="button"
                onClick={() => updateSettings({ appLanguage: code })}
                className={`rounded-lg py-2 text-xs font-bold transition ${
                  settings.appLanguage === code
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Reading Theme */}
        <div>
          <label className="text-xs font-bold text-[var(--text-muted)]">{t.readingTheme}</label>
          <div className="mt-2 grid grid-cols-3 gap-1.5 rounded-xl bg-[var(--bg-elevated)] p-1">
            {(
              [
                ['light', t.themeLight],
                ['sepia', t.themeSepia],
                ['dark', t.themeDark],
              ] as [ThemeMode, string][]
            ).map(([mode, label]) => (
              <button
                key={mode}
                type="button"
                onClick={() => updateSettings({ themeMode: mode })}
                className={`rounded-lg py-2 text-xs font-bold transition ${
                  settings.themeMode === mode
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Default Reading Mode */}
        <div>
          <label className="text-xs font-bold text-[var(--text-muted)]">{t.readingMode}</label>
          <div className="mt-2 grid grid-cols-2 gap-1.5 rounded-xl bg-[var(--bg-elevated)] p-1">
            {(
              [
                ['mushaf', t.modeMushaf],
                ['verse', t.modeVerse],
              ] as [ReadingMode, string][]
            ).map(([mode, label]) => (
              <button
                key={mode}
                type="button"
                onClick={() => updateSettings({ readingMode: mode })}
                className={`rounded-lg py-2 text-xs font-bold transition ${
                  settings.readingMode === mode
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {label}
              </button>
            ))}
          </div>
        </div>

        {/* Reciter */}
        <div>
          <label className="text-xs font-bold text-[var(--text-muted)] flex items-center gap-1.5">
            <Volume2 className="w-3.5 h-3.5" />
            <span>{t.reciter}</span>
          </label>
          <select
            value={settings.reciterId}
            onChange={(e) => updateSettings({ reciterId: e.target.value })}
            className="mt-1.5 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2.5 text-sm font-semibold"
          >
            {RECITERS.map((r) => (
              <option key={r.id} value={r.id}>
                {reciterDisplayName(r, settings.appLanguage)}
              </option>
            ))}
          </select>
        </div>

        {/* Translation Master Toggle + Multi-Select Languages */}
        <div className="space-y-3 rounded-2xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/50 p-3.5">
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-sm font-bold text-[var(--text-primary)]">{t.showTranslation}</p>
              <p className="text-xs text-[var(--text-muted)]">{t.showTranslationDesc}</p>
            </div>
            <input
              type="checkbox"
              checked={settings.showTranslation}
              onChange={(e) => updateSettings({ showTranslation: e.target.checked })}
              className="w-4 h-4 accent-emerald-700"
            />
          </div>

          {settings.showTranslation && (
            <div>
              <p className="text-[11px] font-bold uppercase tracking-wider text-[var(--text-muted)] mb-2">
                {t.translationLanguages}
              </p>
              <div className="flex flex-wrap gap-2">
                {(
                  [
                    ['ml', t.langMalayalam],
                    ['en', t.langEnglish],
                    ['ar', t.langArabicTafsir],
                  ] as [TranslationCode, string][]
                ).map(([code, label]) => {
                  const active = settings.selectedTranslations.includes(code);
                  return (
                    <button
                      key={code}
                      type="button"
                      onClick={() => toggleTranslationLang(code)}
                      className={`rounded-xl border px-3 py-1.5 text-xs font-bold transition ${
                        active
                          ? 'border-emerald-700 bg-emerald-700 text-white'
                          : 'border-[var(--border-color)] bg-[var(--bg-card)] text-[var(--text-secondary)]'
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* Tajweed Color Coding */}
        <label className="flex items-center justify-between rounded-2xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/50 px-4 py-3 cursor-pointer">
          <div className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-[var(--emerald-primary)]" />
            <span className="text-sm font-bold">{t.tajweedColorCoding}</span>
          </div>
          <input
            type="checkbox"
            checked={settings.tajweedEnabled}
            onChange={(e) => updateSettings({ tajweedEnabled: e.target.checked })}
            className="w-4 h-4 accent-emerald-700"
          />
        </label>

        {/* Font Size & Scroll Speed Sliders */}
        <div className="space-y-4">
          <div>
            <div className="flex justify-between text-xs font-bold">
              <span>{t.arabicFontSize}</span>
              <span className="tabular-nums text-[var(--emerald-primary)]">
                {settings.arabicFontSize}px
              </span>
            </div>
            <input
              type="range"
              min={20}
              max={44}
              value={settings.arabicFontSize}
              onChange={(e) => updateSettings({ arabicFontSize: Number(e.target.value) })}
              className="mt-1.5 w-full accent-emerald-700"
            />
          </div>

          <div>
            <div className="flex justify-between text-xs font-bold">
              <span>{t.translationFontSize}</span>
              <span className="tabular-nums text-[var(--emerald-primary)]">
                {settings.translationFontSize}px
              </span>
            </div>
            <input
              type="range"
              min={12}
              max={24}
              value={settings.translationFontSize}
              onChange={(e) => updateSettings({ translationFontSize: Number(e.target.value) })}
              className="mt-1.5 w-full accent-emerald-700"
            />
          </div>

          <div>
            <div className="flex justify-between text-xs font-bold">
              <span>{t.autoScrollSpeed}</span>
              <span className="tabular-nums text-[var(--emerald-primary)]">
                {settings.autoScrollSpeed.toFixed(1)}x
              </span>
            </div>
            <input
              type="range"
              min={0.3}
              max={3.0}
              step={0.1}
              value={settings.autoScrollSpeed}
              onChange={(e) => updateSettings({ autoScrollSpeed: Number(e.target.value) })}
              className="mt-1.5 w-full accent-emerald-700"
            />
          </div>
        </div>

        <button
          type="button"
          onClick={() => {
            updateSettings({ fabX: null, fabY: null });
            showToast(t.done);
          }}
          className="inline-flex items-center gap-2 rounded-xl border border-[var(--border-color)] px-3.5 py-2 text-xs font-bold text-[var(--text-secondary)] hover:bg-[var(--bg-elevated)]"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          <span>{t.resetButtonPos}</span>
        </button>
      </section>

      {/* SECTION 2: PRAYER, AUTO-SILENT DND & KAHF REMINDERS */}
      <section className="rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-5 shadow-sm space-y-4">
        <div className="flex items-center justify-between gap-2">
          <h2 className="text-sm font-extrabold uppercase tracking-wider text-[var(--emerald-primary)]">
            {t.featuresSettingsTitle}
          </h2>
          <button
            type="button"
            onClick={() => openHomeFeature('prayer')}
            className="text-xs font-bold text-[var(--emerald-primary)] hover:underline"
          >
            {t.actionPrayer} →
          </button>
        </div>

        <div>
          <label className="text-xs font-bold text-[var(--text-muted)]">
            {t.calculationMethod}
          </label>
          <select
            value={settings.prayerMethod}
            onChange={(e) => updateSettings({ prayerMethod: Number(e.target.value) })}
            className="mt-1.5 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-xs sm:text-sm font-semibold"
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

        {/* Auto-Silent Quick Toggle */}
        <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/50 p-3.5 space-y-2.5">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <ShieldAlert className="w-4 h-4 text-[var(--emerald-primary)] shrink-0" />
              <span className="text-sm font-bold">{t.autoSilentTitle}</span>
            </div>
            <input
              type="checkbox"
              checked={settings.autoSilentEnabled}
              onChange={(e) => updateSettings({ autoSilentEnabled: e.target.checked })}
              className="w-4 h-4 accent-emerald-700"
            />
          </div>
          {settings.autoSilentEnabled && (
            <div className="flex items-center gap-2 text-xs">
              <span className="text-[var(--text-muted)]">{t.autoSilentDurationLabel}:</span>
              <span className="font-bold tabular-nums">{settings.autoSilentDurationMinutes} min</span>
              {bridge?.restoreDndNow && (
                <button
                  type="button"
                  onClick={() => {
                    bridge.restoreDndNow?.();
                    showToast(t.restoreSoundNowBtn);
                  }}
                  className="ml-auto rounded-lg bg-emerald-700 px-2.5 py-1 text-[11px] font-bold text-white"
                >
                  {t.restoreSoundNowBtn}
                </button>
              )}
            </div>
          )}
        </div>

        {/* Surah Al-Kahf Weekly Reminder Controls */}
        <div className="rounded-2xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/50 p-3.5 space-y-3">
          <p className="text-xs font-extrabold uppercase tracking-wider text-[var(--text-muted)]">
            {t.kahfReminderTitle}
          </p>

          <div className="flex items-center justify-between gap-2">
            <span className="text-xs sm:text-sm font-semibold">{t.kahfThuLabel}</span>
            <div className="flex items-center gap-2">
              <input
                type="time"
                value={`${String(settings.kahfThuHour).padStart(2, '0')}:${String(
                  settings.kahfThuMinute
                ).padStart(2, '0')}`}
                onChange={(e) => {
                  const [hh, mm] = e.target.value.split(':').map(Number);
                  if (!Number.isNaN(hh) && !Number.isNaN(mm)) {
                    updateSettings({ kahfThuHour: hh, kahfThuMinute: mm });
                  }
                }}
                className="rounded-lg border border-[var(--border-color)] bg-[var(--bg-card)] px-2 py-1 text-xs font-bold tabular-nums"
              />
              <input
                type="checkbox"
                checked={settings.kahfThursdayEnabled}
                onChange={(e) => updateSettings({ kahfThursdayEnabled: e.target.checked })}
                className="w-4 h-4 accent-emerald-700"
              />
            </div>
          </div>

          <div className="flex items-center justify-between gap-2">
            <span className="text-xs sm:text-sm font-semibold">{t.kahfFriLabel}</span>
            <div className="flex items-center gap-2">
              <input
                type="time"
                value={`${String(settings.kahfFriHour).padStart(2, '0')}:${String(
                  settings.kahfFriMinute
                ).padStart(2, '0')}`}
                onChange={(e) => {
                  const [hh, mm] = e.target.value.split(':').map(Number);
                  if (!Number.isNaN(hh) && !Number.isNaN(mm)) {
                    updateSettings({ kahfFriHour: hh, kahfFriMinute: mm });
                  }
                }}
                className="rounded-lg border border-[var(--border-color)] bg-[var(--bg-card)] px-2 py-1 text-xs font-bold tabular-nums"
              />
              <input
                type="checkbox"
                checked={settings.kahfFridayEnabled}
                onChange={(e) => updateSettings({ kahfFridayEnabled: e.target.checked })}
                className="w-4 h-4 accent-emerald-700"
              />
            </div>
          </div>
        </div>
      </section>

      {/* SECTION 3: APP INSTALL, APK & SHARE */}
      <section className="rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-5 shadow-sm space-y-3">
        <PWAInstallButton />

        {APP_BRANDING.androidApkUrl && (
          <a
            href={APP_BRANDING.androidApkUrl}
            target="_blank"
            rel="noreferrer"
            className="w-full inline-flex items-center justify-center gap-2 rounded-xl border border-emerald-600/30 bg-[var(--emerald-soft)] py-3 px-4 text-sm font-bold text-[var(--emerald-primary)] hover:brightness-95 transition"
          >
            <Download className="w-4 h-4" />
            <span>{t.downloadAndroidApk}</span>
          </a>
        )}

        <button
          type="button"
          onClick={handleShareApp}
          className="w-full inline-flex items-center justify-center gap-2 rounded-xl border border-[var(--border-color)] py-3 px-4 text-sm font-bold text-[var(--text-primary)] hover:bg-[var(--bg-elevated)] transition"
        >
          <Share2 className="w-4 h-4" />
          <span>{t.shareApp}</span>
        </button>

        <p className="text-center text-xs text-[var(--text-muted)] pt-1">
          {localizedBrandName(settings.appLanguage)} · v{APP_BRANDING.appVersion}
        </p>
      </section>
    </div>
  );
}
