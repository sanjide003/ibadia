'use client';

import React, { useMemo, useState } from 'react';
import {
  Download,
  FileText,
  Image as ImageIcon,
  Loader2,
  Share2,
  Sparkles,
} from 'lucide-react';
import { jsPDF } from 'jspdf';
import { useIbadia } from '@/context/IbadiaProvider';
import { ayahEndMarker, JUZ_CATALOG } from '@/lib/apiConfig';
import { fetchJuzDetail, fetchSurahDetail } from '@/lib/quranApi';
import type {
  ExportFormat,
  ExportPageSize,
  ExportScope,
  ExportSurahSection,
  TranslationCode,
} from '@/types';

const BISMILLAH_TEXT = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ';

function wrapLines(
  ctx: CanvasRenderingContext2D,
  text: string,
  maxWidth: number
): string[] {
  const words = text.split(/\s+/).filter(Boolean);
  if (words.length === 0) return [];
  const lines: string[] = [];
  let cur = words[0];
  for (let i = 1; i < words.length; i++) {
    const test = `${cur} ${words[i]}`;
    if (ctx.measureText(test).width <= maxWidth) {
      cur = test;
    } else {
      lines.push(cur);
      cur = words[i];
    }
  }
  lines.push(cur);
  return lines;
}

function renderSectionsToCanvases(
  sections: ExportSurahSection[],
  options: {
    pageSize: ExportPageSize;
    theme: 'light' | 'sepia' | 'dark';
    includeTranslation: boolean;
    translationCodes: TranslationCode[];
    headerTitle: string;
  }
): HTMLCanvasElement[] {
  const isA4 = options.pageSize === 'a4';
  const width = isA4 ? 1240 : 1080;
  const height = isA4 ? 1754 : 1620;
  const padX = 76;
  const contentW = width - padX * 2;
  const bottomLimit = height - 90;

  const palette =
    options.theme === 'dark'
      ? {
          bg: '#0c1210',
          card: '#131d19',
          border: '#1f332a',
          accent: '#34d399',
          text: '#f0fdf4',
          muted: '#9cb3a8',
        }
      : options.theme === 'sepia'
      ? {
          bg: '#f4ecda',
          card: '#fbf6e9',
          border: '#d6c3a1',
          accent: '#065f46',
          text: '#2d1e12',
          muted: '#5c4632',
        }
      : {
          bg: '#f4f9f6',
          card: '#ffffff',
          border: '#cde0d5',
          accent: '#047857',
          text: '#0f172a',
          muted: '#475569',
        };

  const pages: HTMLCanvasElement[] = [];

  const createPage = (pageIndex: number) => {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d')!;

    ctx.fillStyle = palette.bg;
    ctx.fillRect(0, 0, width, height);

    ctx.fillStyle = palette.card;
    ctx.strokeStyle = palette.border;
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.roundRect(36, 36, width - 72, height - 72, 24);
    ctx.fill();
    ctx.stroke();

    // Header bar
    ctx.fillStyle = palette.accent;
    ctx.font = '700 22px system-ui, -apple-system, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText(`Ibadia · ${options.headerTitle}`, padX, 86);

    ctx.fillStyle = palette.muted;
    ctx.font = '600 18px system-ui, -apple-system, sans-serif';
    ctx.textAlign = 'right';
    ctx.fillText(`Page ${pageIndex + 1}`, width - padX, 86);

    ctx.strokeStyle = palette.border;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(padX, 106);
    ctx.lineTo(width - padX, 106);
    ctx.stroke();

    pages.push(canvas);
    return { canvas, ctx, y: 146 };
  };

  let cur = createPage(0);

  const ensureSpace = (needed: number) => {
    if (cur.y + needed > bottomLimit) {
      cur = createPage(pages.length);
    }
  };

  for (const sec of sections) {
    if (sec.showBanner) {
      ensureSpace(120);
      cur.ctx.fillStyle = palette.accent;
      cur.ctx.beginPath();
      cur.ctx.roundRect(padX, cur.y, contentW, 74, 16);
      cur.ctx.fill();

      cur.ctx.fillStyle = '#ffffff';
      cur.ctx.textAlign = 'center';
      cur.ctx.font = '700 32px "Amiri", "Traditional Arabic", serif';
      cur.ctx.fillText(sec.summary.nameArabic, width / 2, cur.y + 42);
      cur.ctx.font = '600 17px system-ui, sans-serif';
      cur.ctx.fillText(
        `${sec.summary.number}. ${sec.summary.englishName} (${sec.summary.numberOfAyahs} Ayahs)`,
        width / 2,
        cur.y + 66
      );
      cur.y += 96;
    }

    if (sec.showBismillah) {
      ensureSpace(56);
      cur.ctx.fillStyle = palette.text;
      cur.ctx.textAlign = 'center';
      cur.ctx.font = '700 34px "Amiri", "Traditional Arabic", serif';
      cur.ctx.fillText(BISMILLAH_TEXT, width / 2, cur.y + 28);
      cur.y += 56;
    }

    for (const ayah of sec.ayahs) {
      const arabicFull = `${ayah.arabicText}${ayahEndMarker(ayah.numberInSurah)}`;
      cur.ctx.font = '700 34px "Amiri", "Traditional Arabic", serif';
      const arLines = wrapLines(cur.ctx, arabicFull, contentW - 12);

      const trLineGroups: Array<{ lang: TranslationCode; lines: string[] }> = [];
      if (options.includeTranslation) {
        for (const code of options.translationCodes) {
          const rawTr = ayah.translations[code];
          if (!rawTr) continue;
          cur.ctx.font = '400 20px "Noto Sans Malayalam", system-ui, sans-serif';
          const wrapped = wrapLines(cur.ctx, rawTr, contentW - 24);
          trLineGroups.push({ lang: code, lines: wrapped });
        }
      }

      const arHeight = arLines.length * 52 + 12;
      const trHeight = trLineGroups.reduce(
        (acc, g) => acc + g.lines.length * 30 + 10,
        0
      );
      ensureSpace(arHeight + trHeight + 24);

      // Draw Arabic RTL
      cur.ctx.fillStyle = palette.text;
      cur.ctx.font = '700 34px "Amiri", "Traditional Arabic", serif';
      cur.ctx.textAlign = 'right';
      for (const line of arLines) {
        cur.ctx.fillText(line, width - padX, cur.y + 30);
        cur.y += 52;
      }

      // Draw translations
      for (const g of trLineGroups) {
        cur.ctx.fillStyle = palette.muted;
        cur.ctx.font = '400 20px "Noto Sans Malayalam", system-ui, sans-serif';
        cur.ctx.textAlign = g.lang === 'ar' ? 'right' : 'left';
        const tx = g.lang === 'ar' ? width - padX : padX;
        for (const line of g.lines) {
          cur.ctx.fillText(line, tx, cur.y + 18);
          cur.y += 30;
        }
        cur.y += 6;
      }

      // Divider
      cur.ctx.strokeStyle = palette.border;
      cur.ctx.lineWidth = 1;
      cur.ctx.beginPath();
      cur.ctx.moveTo(padX, cur.y + 6);
      cur.ctx.lineTo(width - padX, cur.y + 6);
      cur.ctx.stroke();
      cur.y += 22;
    }
  }

  return pages;
}

export function ExportView() {
  const { surahs, settings, t, showToast } = useIbadia();

  const [scope, setScope] = useState<ExportScope>('surah');
  const [selectedSurah, setSelectedSurah] = useState(1);
  const [selectedJuz, setSelectedJuz] = useState(1);
  const [fromAyah, setFromAyah] = useState(1);
  const [toAyah, setToAyah] = useState(7);
  const [format, setFormat] = useState<ExportFormat>('pdf');
  const [pageSize, setPageSize] = useState<ExportPageSize>('a4');
  const [includeTranslation, setIncludeTranslation] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [previewUrls, setPreviewUrls] = useState<string[]>([]);
  const [generatedFile, setGeneratedFile] = useState<{
    blob: Blob;
    filename: string;
    mime: string;
  } | null>(null);

  const surahObj = useMemo(
    () => surahs.find((s) => s.number === selectedSurah) ?? surahs[0],
    [surahs, selectedSurah]
  );

  const handleSurahChange = (num: number) => {
    setSelectedSurah(num);
    const s = surahs.find((x) => x.number === num);
    setFromAyah(1);
    setToAyah(Math.min(s?.numberOfAyahs ?? 7, scope === 'range' ? 10 : s?.numberOfAyahs ?? 7));
    setPreviewUrls([]);
    setGeneratedFile(null);
  };

  const handleGenerate = async () => {
    if (scope === 'range') {
      const maxAyah = surahObj?.numberOfAyahs ?? 286;
      if (fromAyah < 1 || toAyah < fromAyah || toAyah > maxAyah) {
        showToast(t.invalidAyahRange);
        return;
      }
    }

    setGenerating(true);
    try {
      const trCodes = includeTranslation ? settings.selectedTranslations : [];
      const sections: ExportSurahSection[] = [];
      let headerTitle = '';
      let baseFilename = '';

      if (scope === 'juz') {
        const detail = await fetchJuzDetail(selectedJuz, trCodes);
        headerTitle = `${t.juzLabel} ${selectedJuz}`;
        baseFilename = `Ibadia_Juz_${selectedJuz}`;

        const grouped = new Map<number, ExportSurahSection>();
        detail.entries.forEach((entry, idx) => {
          const sNum = entry.surah.number;
          if (!grouped.has(sNum)) {
            grouped.set(sNum, {
              summary: entry.surah,
              showBanner: entry.ayah.numberInSurah === 1,
              showBismillah: entry.ayah.numberInSurah === 1 && sNum !== 1 && sNum !== 9,
              ayahs: [],
            });
          }
          const trMap: Partial<Record<TranslationCode, string>> = {};
          for (const c of trCodes) {
            const list = detail.translations[c];
            if (list && list[idx]) trMap[c] = list[idx];
          }
          grouped.get(sNum)!.ayahs.push({
            numberInSurah: entry.ayah.numberInSurah,
            arabicText: entry.ayah.arabicText,
            translations: trMap,
          });
        });
        sections.push(...grouped.values());
      } else {
        const detail = await fetchSurahDetail(selectedSurah, trCodes);
        const start = scope === 'range' ? fromAyah : 1;
        const end = scope === 'range' ? toAyah : detail.summary.numberOfAyahs;
        headerTitle =
          scope === 'range'
            ? `${detail.summary.englishName} (${start}-${end})`
            : `Surah ${detail.summary.englishName}`;
        baseFilename =
          scope === 'range'
            ? `Ibadia_${detail.summary.englishName}_${start}-${end}`
            : `Ibadia_Surah_${detail.summary.number}_${detail.summary.englishName}`;

        const blocks = detail.ayahs
          .filter((a) => a.numberInSurah >= start && a.numberInSurah <= end)
          .map((a) => {
            const trMap: Partial<Record<TranslationCode, string>> = {};
            for (const c of trCodes) {
              const list = detail.translations[c];
              if (list && list[a.numberInSurah - 1]) {
                trMap[c] = list[a.numberInSurah - 1];
              }
            }
            return {
              numberInSurah: a.numberInSurah,
              arabicText: a.arabicText,
              translations: trMap,
            };
          });

        sections.push({
          summary: detail.summary,
          showBanner: true,
          showBismillah: start === 1 && selectedSurah !== 1 && selectedSurah !== 9,
          ayahs: blocks,
        });
      }

      const canvases = renderSectionsToCanvases(sections, {
        pageSize,
        theme: settings.themeMode,
        includeTranslation,
        translationCodes: trCodes,
        headerTitle,
      });

      const urls = canvases.slice(0, 6).map((c) => c.toDataURL('image/png'));
      setPreviewUrls(urls);

      if (format === 'image') {
        const firstCanvas = canvases[0];
        const blob = await new Promise<Blob>((resolve, reject) =>
          firstCanvas.toBlob(
            (b) => (b ? resolve(b) : reject(new Error('PNG creation failed'))),
            'image/png'
          )
        );
        setGeneratedFile({
          blob,
          filename: `${baseFilename}.png`,
          mime: 'image/png',
        });
      } else {
        const orientation = 'portrait';
        const unit = 'pt';
        const first = canvases[0];
        const pdf = new jsPDF({
          orientation,
          unit,
          format: pageSize === 'a4' ? 'a4' : [first.width * 0.75, first.height * 0.75],
        });
        canvases.forEach((canvas, idx) => {
          if (idx > 0) pdf.addPage();
          const pw = pdf.internal.pageSize.getWidth();
          const ph = pdf.internal.pageSize.getHeight();
          const imgData = canvas.toDataURL('image/jpeg', 0.92);
          pdf.addImage(imgData, 'JPEG', 0, 0, pw, ph);
        });
        const blob = pdf.output('blob');
        setGeneratedFile({
          blob,
          filename: `${baseFilename}.pdf`,
          mime: 'application/pdf',
        });
      }
      showToast(t.exportSuccess);
    } catch {
      showToast(t.loadError);
    } finally {
      setGenerating(false);
    }
  };

  const triggerDownload = () => {
    if (!generatedFile) return;
    const url = URL.createObjectURL(generatedFile.blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = generatedFile.filename;
    a.click();
    setTimeout(() => URL.revokeObjectURL(url), 4000);
  };

  const triggerShare = async () => {
    if (!generatedFile) return;
    const file = new File([generatedFile.blob], generatedFile.filename, {
      type: generatedFile.mime,
    });
    if (navigator.canShare && navigator.canShare({ files: [file] })) {
      try {
        await navigator.share({
          title: generatedFile.filename,
          files: [file],
        });
        return;
      } catch {
        // user cancelled or unsupported
      }
    }
    triggerDownload();
  };

  return (
    <div className="mx-auto max-w-4xl px-4 pb-28 space-y-4">
      <div className="rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-5 shadow-sm space-y-4">
        <div className="flex items-center gap-2.5">
          <div className="w-10 h-10 rounded-xl bg-[var(--emerald-soft)] text-[var(--emerald-primary)] flex items-center justify-center">
            <FileText className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-[var(--text-primary)]">{t.exportTitle}</h2>
            <p className="text-xs text-[var(--text-muted)]">
              PDF & High-DPI PNG Cards with Arabic & Translations
            </p>
          </div>
        </div>

        {/* Scope Picker */}
        <div>
          <label className="text-xs font-bold text-[var(--text-muted)]">{t.exportScope}</label>
          <div className="mt-1.5 grid grid-cols-3 gap-1.5 rounded-xl bg-[var(--bg-elevated)] p-1">
            {(['surah', 'range', 'juz'] as ExportScope[]).map((sc) => (
              <button
                key={sc}
                type="button"
                onClick={() => {
                  setScope(sc);
                  setPreviewUrls([]);
                  setGeneratedFile(null);
                }}
                className={`rounded-lg py-2 text-xs font-bold transition ${
                  scope === sc
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {sc === 'surah'
                  ? t.scopeSurah
                  : sc === 'range'
                  ? t.scopeRange
                  : t.scopeJuz}
              </button>
            ))}
          </div>
        </div>

        {/* Surah or Juz selector */}
        {scope === 'juz' ? (
          <div>
            <label className="text-xs font-bold text-[var(--text-muted)]">{t.selectJuz}</label>
            <select
              value={selectedJuz}
              onChange={(e) => setSelectedJuz(Number(e.target.value))}
              className="mt-1 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2.5 text-sm font-semibold"
            >
              {JUZ_CATALOG.map((j) => (
                <option key={j.number} value={j.number}>
                  {t.juzLabel} {j.number} — {j.arabicName}
                </option>
              ))}
            </select>
          </div>
        ) : (
          <div className="space-y-3">
            <div>
              <label className="text-xs font-bold text-[var(--text-muted)]">
                {t.selectSurah}
              </label>
              <select
                value={selectedSurah}
                onChange={(e) => handleSurahChange(Number(e.target.value))}
                className="mt-1 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2.5 text-sm font-semibold"
              >
                {surahs.map((s) => (
                  <option key={s.number} value={s.number}>
                    {s.number}. {s.englishName} ({s.numberOfAyahs} {t.ayahsLabel})
                  </option>
                ))}
              </select>
            </div>

            {scope === 'range' && (
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-xs font-bold text-[var(--text-muted)]">
                    {t.fromAyah}
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={surahObj?.numberOfAyahs ?? 286}
                    value={fromAyah}
                    onChange={(e) => setFromAyah(Number(e.target.value))}
                    className="mt-1 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-sm font-bold tabular-nums"
                  />
                </div>
                <div>
                  <label className="text-xs font-bold text-[var(--text-muted)]">
                    {t.toAyah}
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={surahObj?.numberOfAyahs ?? 286}
                    value={toAyah}
                    onChange={(e) => setToAyah(Number(e.target.value))}
                    className="mt-1 w-full rounded-xl border border-[var(--border-color)] bg-[var(--bg-elevated)] px-3 py-2 text-sm font-bold tabular-nums"
                  />
                </div>
              </div>
            )}
          </div>
        )}

        {/* Format & Page Size */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="text-xs font-bold text-[var(--text-muted)]">
              {t.exportFormat}
            </label>
            <div className="mt-1.5 grid grid-cols-2 gap-1.5 rounded-xl bg-[var(--bg-elevated)] p-1">
              <button
                type="button"
                onClick={() => setFormat('pdf')}
                className={`inline-flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-bold ${
                  format === 'pdf'
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                <FileText className="w-3.5 h-3.5" />
                <span>{t.formatPdf}</span>
              </button>
              <button
                type="button"
                onClick={() => setFormat('image')}
                className={`inline-flex items-center justify-center gap-1.5 rounded-lg py-2 text-xs font-bold ${
                  format === 'image'
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                <ImageIcon className="w-3.5 h-3.5" />
                <span>{t.formatImage}</span>
              </button>
            </div>
          </div>

          <div>
            <label className="text-xs font-bold text-[var(--text-muted)]">
              {t.pageSize}
            </label>
            <div className="mt-1.5 grid grid-cols-2 gap-1.5 rounded-xl bg-[var(--bg-elevated)] p-1">
              <button
                type="button"
                onClick={() => setPageSize('a4')}
                className={`rounded-lg py-2 text-xs font-bold ${
                  pageSize === 'a4'
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {t.sizeA4}
              </button>
              <button
                type="button"
                onClick={() => setPageSize('automatic')}
                className={`rounded-lg py-2 text-xs font-bold ${
                  pageSize === 'automatic'
                    ? 'bg-[var(--bg-card)] text-[var(--emerald-primary)] shadow-sm'
                    : 'text-[var(--text-secondary)]'
                }`}
              >
                {t.sizeAutomatic}
              </button>
            </div>
          </div>
        </div>

        {/* Translation toggle */}
        <label className="flex items-center justify-between rounded-2xl border border-[var(--border-color)] bg-[var(--bg-elevated)]/60 px-4 py-3 cursor-pointer">
          <span className="text-xs sm:text-sm font-bold text-[var(--text-primary)]">
            {t.includeTranslation}
          </span>
          <input
            type="checkbox"
            checked={includeTranslation}
            onChange={(e) => setIncludeTranslation(e.target.checked)}
            className="w-4 h-4 accent-emerald-700"
          />
        </label>

        <button
          type="button"
          disabled={generating || surahs.length === 0}
          onClick={handleGenerate}
          className="w-full rounded-2xl bg-emerald-700 hover:bg-emerald-800 py-3 px-4 text-sm font-bold text-white inline-flex items-center justify-center gap-2 shadow-sm disabled:opacity-60"
        >
          {generating ? (
            <Loader2 className="w-4 h-4 animate-spin" />
          ) : (
            <Sparkles className="w-4 h-4" />
          )}
          <span>{t.generatePreview}</span>
        </button>
      </div>

      {/* Preview & Download Card */}
      {generatedFile && previewUrls.length > 0 && (
        <div className="rounded-3xl border border-[var(--border-color)] bg-[var(--bg-card)] p-5 shadow-sm space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <p className="text-xs font-bold text-[var(--text-primary)] truncate">
              {generatedFile.filename}
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={triggerDownload}
                className="inline-flex items-center gap-1.5 rounded-xl bg-emerald-700 px-3.5 py-2 text-xs font-bold text-white hover:bg-emerald-800"
              >
                <Download className="w-3.5 h-3.5" />
                <span>{t.download}</span>
              </button>
              <button
                type="button"
                onClick={triggerShare}
                className="inline-flex items-center gap-1.5 rounded-xl border border-[var(--border-color)] px-3.5 py-2 text-xs font-bold hover:bg-[var(--bg-elevated)]"
              >
                <Share2 className="w-3.5 h-3.5" />
                <span>{t.share}</span>
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {previewUrls.map((url, idx) => (
              <div
                key={idx}
                className="rounded-2xl overflow-hidden border border-[var(--border-color)] bg-[var(--bg-elevated)]"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={url}
                  alt={`Export preview page ${idx + 1}`}
                  className="w-full h-auto block"
                />
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
