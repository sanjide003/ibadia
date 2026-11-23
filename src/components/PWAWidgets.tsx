'use client';

import React, { useState } from 'react';
import { Download, Smartphone, WifiOff, X } from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { useOnlineStatus, usePWAInstall } from '@/hooks/usePWAInstall';

export function PWAInstallButton({ compact = false }: { compact?: boolean }) {
  const { isInstallable, isInstalled, isIOS, install } = usePWAInstall();
  const { t } = useIbadia();
  const [showIOSGuide, setShowIOSGuide] = useState(false);

  if (isInstalled) return null;

  if (isInstallable) {
    return (
      <button
        type="button"
        onClick={install}
        className={`inline-flex items-center justify-center gap-2 rounded-xl bg-emerald-700 text-white font-semibold shadow-sm hover:bg-emerald-800 active:scale-[0.98] transition ${
          compact ? 'px-3 py-2 text-xs' : 'w-full px-4 py-3 text-sm'
        }`}
      >
        <Download className="w-4 h-4 shrink-0" />
        <span>{t.installApp}</span>
      </button>
    );
  }

  if (isIOS) {
    return (
      <>
        <button
          type="button"
          onClick={() => setShowIOSGuide(true)}
          className={`inline-flex items-center justify-center gap-2 rounded-xl border border-emerald-700/30 bg-emerald-50/70 dark:bg-emerald-950/40 text-emerald-800 dark:text-emerald-200 font-semibold hover:bg-emerald-100/80 transition ${
            compact ? 'px-3 py-2 text-xs' : 'w-full px-4 py-3 text-sm'
          }`}
        >
          <Smartphone className="w-4 h-4 shrink-0" />
          <span>{t.installApp}</span>
        </button>

        {showIOSGuide && (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-sm rounded-2xl bg-[var(--bg-card)] border border-[var(--border-color)] p-5 shadow-xl">
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-base font-bold">Install on iPhone / iPad</h3>
                <button
                  type="button"
                  onClick={() => setShowIOSGuide(false)}
                  className="p-1.5 rounded-lg hover:bg-[var(--bg-elevated)]"
                  aria-label="Close"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
              <p className="text-sm text-[var(--text-secondary)] leading-relaxed">
                1. Tap the <strong>Share</strong> icon in the Safari toolbar.
                <br />
                2. Scroll down and tap <strong>Add to Home Screen</strong>.
              </p>
              <button
                type="button"
                onClick={() => setShowIOSGuide(false)}
                className="mt-4 w-full rounded-xl bg-emerald-700 py-2.5 text-sm font-semibold text-white hover:bg-emerald-800"
              >
                {t.done}
              </button>
            </div>
          </div>
        )}
      </>
    );
  }

  return null;
}

export function OfflineIndicator() {
  const isOnline = useOnlineStatus();
  const { t } = useIbadia();

  if (isOnline) return null;

  return (
    <div className="mx-4 mt-2 flex items-center gap-2 rounded-xl bg-amber-600/95 px-3.5 py-2 text-xs font-semibold text-white shadow-sm">
      <WifiOff className="w-4 h-4 shrink-0" />
      <span>{t.offlineBanner}</span>
    </div>
  );
}
