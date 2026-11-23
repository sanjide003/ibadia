'use client';

import React from 'react';
import { ArrowLeft, BookOpen, Home, Settings } from 'lucide-react';
import { AudioPlayerBar } from '@/components/AudioPlayerBar';
import { HomeTabView } from '@/components/HomeTabView';
import { OfflineIndicator, PWAInstallButton } from '@/components/PWAWidgets';
import { QuranTabView } from '@/components/QuranTabView';
import { SettingsTabView } from '@/components/SettingsTabView';
import { SurahReaderScreen } from '@/components/SurahReaderScreen';
import { AdhkarView } from '@/components/features/AdhkarView';
import { AsmaulHusnaView } from '@/components/features/AsmaulHusnaView';
import { ExportView } from '@/components/features/ExportView';
import { HijriCalendarView } from '@/components/features/HijriCalendarView';
import { PrayerTimesView } from '@/components/features/PrayerTimesView';
import { TajweedGuideView } from '@/components/features/TajweedGuideView';
import { TasbihView } from '@/components/features/TasbihView';
import { useIbadia } from '@/context/IbadiaProvider';
import { localizedBrandName } from '@/lib/apiConfig';
import type { HomeFeatureView } from '@/types';

export function IbadiaShell() {
  const {
    settings,
    t,
    activeTab,
    setActiveTab,
    homeFeatureView,
    openHomeFeature,
    readerTarget,
    toastMessage,
  } = useIbadia();

  const brandName = localizedBrandName(settings.appLanguage);

  const featureTitle = (view: Exclude<HomeFeatureView, null>) => {
    switch (view) {
      case 'prayer':
        return t.actionPrayer;
      case 'hijri':
        return t.actionHijri;
      case 'adhkar':
        return t.actionAdhkar;
      case 'tasbih':
        return t.actionCounter;
      case 'names99':
        return t.names99Title;
      case 'export':
        return t.actionExport;
      case 'tajweed':
        return t.tajweedGuideTitle;
    }
  };

  // Show top app header ONLY on Home and Settings tabs (COMPLETELY HIDDEN when Quran tab is open)
  const showBrandHeader = activeTab !== 'quran';

  return (
    <div dir={t.dir} className="min-h-screen flex flex-col bg-[var(--bg-page)] text-[var(--text-primary)]">
      {/* Conditional App Header: Visible on Home & Settings, hidden on Quran */}
      {showBrandHeader && (
        <header className="sticky top-0 z-30 border-b border-[var(--border-color)] bg-[var(--bg-card)]/92 backdrop-blur-md pt-safe">
          <div className="mx-auto max-w-4xl px-4 h-14 flex items-center justify-between gap-3">
            {activeTab === 'home' && homeFeatureView ? (
              <div className="flex items-center gap-2.5 min-w-0">
                <button
                  type="button"
                  onClick={() => openHomeFeature(null)}
                  className="inline-flex items-center gap-1.5 rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-1.5 text-xs font-bold text-[var(--emerald-primary)] hover:brightness-95"
                >
                  <ArrowLeft className="w-4 h-4" />
                  <span>{t.backToHome}</span>
                </button>
                <h1 className="text-sm sm:text-base font-extrabold truncate">
                  {featureTitle(homeFeatureView)}
                </h1>
              </div>
            ) : (
              <div className="flex items-center gap-2.5 min-w-0">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src="/branding/app_logo.png"
                  alt={brandName}
                  className="w-8 h-8 rounded-xl object-cover shadow-sm"
                />
                <div className="min-w-0">
                  <h1 className="text-base sm:text-lg font-extrabold tracking-tight text-[var(--emerald-primary)] leading-none">
                    {brandName}
                  </h1>
                  <p className="text-[10px] font-medium text-[var(--text-muted)] truncate mt-0.5">
                    {activeTab === 'settings' ? t.settings : t.appTagline}
                  </p>
                </div>
              </div>
            )}

            <div className="shrink-0">
              <PWAInstallButton compact />
            </div>
          </div>
        </header>
      )}

      <OfflineIndicator />

      {/* Main Content Body */}
      <main className="flex-1">
        {activeTab === 'home' && !homeFeatureView && <HomeTabView />}

        {activeTab === 'home' && homeFeatureView === 'prayer' && (
          <div className="pt-3">
            <PrayerTimesView />
          </div>
        )}
        {activeTab === 'home' && homeFeatureView === 'hijri' && (
          <div className="pt-3">
            <HijriCalendarView />
          </div>
        )}
        {activeTab === 'home' && homeFeatureView === 'adhkar' && (
          <div className="pt-3">
            <AdhkarView />
          </div>
        )}
        {activeTab === 'home' && homeFeatureView === 'tasbih' && (
          <div className="pt-3">
            <TasbihView />
          </div>
        )}
        {activeTab === 'home' && homeFeatureView === 'names99' && (
          <div className="pt-3">
            <AsmaulHusnaView />
          </div>
        )}
        {activeTab === 'home' && homeFeatureView === 'export' && (
          <div className="pt-3">
            <ExportView />
          </div>
        )}
        {activeTab === 'home' && homeFeatureView === 'tajweed' && (
          <div className="pt-3">
            <TajweedGuideView />
          </div>
        )}

        {activeTab === 'quran' && <QuranTabView />}
        {activeTab === 'settings' && <SettingsTabView />}
      </main>

      {/* Sticky Audio Bar sits right above Bottom Navigation when reader is closed */}
      {!readerTarget && (
        <div className="fixed bottom-[64px] inset-x-0 z-30 pointer-events-none">
          <div className="pointer-events-auto">
            <AudioPlayerBar />
          </div>
        </div>
      )}

      {/* 3-Tab Bottom Navigation Bar: Home | Quran | Settings */}
      <nav
        aria-label="Primary Navigation"
        className="fixed bottom-0 inset-x-0 z-30 border-t border-[var(--border-color)] bg-[var(--bg-card)]/95 backdrop-blur-md pb-safe"
      >
        <div className="mx-auto max-w-4xl grid grid-cols-3 h-16">
          <button
            type="button"
            onClick={() => {
              openHomeFeature(null);
              setActiveTab('home');
            }}
            className={`flex flex-col items-center justify-center gap-1 text-xs font-bold transition ${
              activeTab === 'home'
                ? 'text-[var(--emerald-primary)]'
                : 'text-[var(--text-muted)] hover:text-[var(--text-primary)]'
            }`}
          >
            <Home className="w-5 h-5" />
            <span>{t.homeTab}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('quran')}
            className={`flex flex-col items-center justify-center gap-1 text-xs font-bold transition ${
              activeTab === 'quran'
                ? 'text-[var(--emerald-primary)]'
                : 'text-[var(--text-muted)] hover:text-[var(--text-primary)]'
            }`}
          >
            <BookOpen className="w-5 h-5" />
            <span>{t.quranTab}</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('settings')}
            className={`flex flex-col items-center justify-center gap-1 text-xs font-bold transition ${
              activeTab === 'settings'
                ? 'text-[var(--emerald-primary)]'
                : 'text-[var(--text-muted)] hover:text-[var(--text-primary)]'
            }`}
          >
            <Settings className="w-5 h-5" />
            <span>{t.settingsTab}</span>
          </button>
        </div>
      </nav>

      {/* Fullscreen Reader Modal Overlay */}
      {readerTarget && <SurahReaderScreen />}

      {/* Global Toast Notification */}
      {toastMessage && (
        <div className="fixed bottom-24 left-1/2 -translate-x-1/2 z-50 rounded-2xl bg-slate-900 dark:bg-emerald-950 text-white border border-emerald-500/30 px-4 py-2.5 text-xs font-bold shadow-xl pointer-events-none">
          {toastMessage}
        </div>
      )}
    </div>
  );
}
