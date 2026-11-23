'use client';

import React from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Loader2,
  Pause,
  Play,
  Repeat,
  RotateCw,
  X,
} from 'lucide-react';
import { useIbadia } from '@/context/IbadiaProvider';
import { reciterById, reciterDisplayName } from '@/lib/apiConfig';

export function AudioPlayerBar({ elevatedAboveBottomNav = true }: { elevatedAboveBottomNav?: boolean }) {
  const {
    audio,
    settings,
    t,
    toggleAudioPlayPause,
    nextAudioAyah,
    prevAudioAyah,
    toggleRepeatAudio,
    stopAudio,
    playAyahAudio,
  } = useIbadia();

  if (!audio.active) return null;

  const reciter = reciterById(settings.reciterId);

  return (
    <div
      className={`fixed left-0 right-0 z-40 px-3 pointer-events-none ${
        elevatedAboveBottomNav ? 'bottom-20' : 'bottom-4'
      }`}
    >
      <div className="pointer-events-auto mx-auto max-w-2xl rounded-2xl border border-emerald-700/25 bg-[var(--bg-card)]/95 backdrop-blur-md shadow-xl px-3.5 py-2.5 flex items-center gap-2.5">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-2">
            <span className="truncate text-sm font-bold text-[var(--text-primary)]">
              {audio.surahName}
            </span>
            <span className="text-xs font-bold text-[var(--emerald-primary)] tabular-nums shrink-0">
              {t.ayahLabel} {audio.ayahNumber}/{audio.totalAyahs}
            </span>
          </div>
          <p className="truncate text-[11px] text-[var(--text-muted)] mt-0.5">
            {audio.error ? (
              <span className="text-rose-500 font-medium">{audio.error}</span>
            ) : (
              reciterDisplayName(reciter, settings.appLanguage)
            )}
          </p>
        </div>

        <div className="flex items-center gap-1 shrink-0">
          <button
            type="button"
            onClick={prevAudioAyah}
            title={t.previousAyah}
            className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-secondary)]"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>

          {audio.error ? (
            <button
              type="button"
              onClick={() => playAyahAudio(audio.surahNumber, audio.ayahNumber)}
              className="w-10 h-10 rounded-full bg-amber-600 text-white flex items-center justify-center shadow"
              title={t.retry}
            >
              <RotateCw className="w-4 h-4" />
            </button>
          ) : (
            <button
              type="button"
              onClick={toggleAudioPlayPause}
              title={audio.isPlaying ? t.pauseAyah : t.resumeAyah}
              className="w-10 h-10 rounded-full bg-emerald-700 text-white flex items-center justify-center shadow hover:bg-emerald-800 transition"
            >
              {audio.isLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : audio.isPlaying ? (
                <Pause className="w-4 h-4" />
              ) : (
                <Play className="w-4 h-4 ml-0.5" />
              )}
            </button>
          )}

          <button
            type="button"
            onClick={nextAudioAyah}
            title={t.nextAyah}
            className="p-2 rounded-xl hover:bg-[var(--bg-elevated)] text-[var(--text-secondary)]"
          >
            <ChevronRight className="w-4 h-4" />
          </button>

          <button
            type="button"
            onClick={toggleRepeatAudio}
            title={t.repeatAyah}
            className={`p-2 rounded-xl transition ${
              audio.repeatOne
                ? 'bg-emerald-700/15 text-[var(--emerald-primary)]'
                : 'text-[var(--text-muted)] hover:bg-[var(--bg-elevated)]'
            }`}
          >
            <Repeat className="w-4 h-4" />
          </button>

          <button
            type="button"
            onClick={stopAudio}
            title={t.closePlayer}
            className="p-2 rounded-xl text-[var(--text-muted)] hover:bg-rose-500/10 hover:text-rose-500"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
