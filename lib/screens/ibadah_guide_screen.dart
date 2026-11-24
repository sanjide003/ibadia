import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/ibadah_models.dart';
import '../providers/quran_providers.dart';
import '../services/ibadah_audio_controller.dart';
import '../services/ibadah_data_service.dart';
import '../widgets/focused_index_scaffold.dart';
import '../widgets/ibadah_audio_card.dart';
import '../widgets/tv_mode_widgets.dart';
import 'settings_screen.dart';

enum IbadahSection {
  niyyah,
  salah,
  rawatib,
  mayyith,
}

class IbadahGuideScreen extends ConsumerStatefulWidget {
  final IbadahSection section;
  final void Function(int surahNo)? onOpenSurah;

  const IbadahGuideScreen({
    super.key,
    this.section = IbadahSection.salah,
    this.onOpenSurah,
  });

  @override
  ConsumerState<IbadahGuideScreen> createState() => _IbadahGuideScreenState();
}

class _IbadahGuideScreenState extends ConsumerState<IbadahGuideScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Set<String> _checkedSharts = {};

  @override
  void initState() {
    super.initState();
    if (widget.section == IbadahSection.salah) {
      _loadPersistedSharts();
    }
  }

  Future<void> _loadPersistedSharts() async {
    final loaded =
        await ref.read(storageServiceProvider).loadIbadahCheckedSharts();
    if (!mounted) return;
    setState(() => _checkedSharts = loaded);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    IbadahAudioController.instance.stopOnDispose();
    super.dispose();
  }

  ({Color cardBg, Color cardBorder}) _palette(
    BuildContext context,
    String themeMode,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = themeMode == 'sepia';
    return (
      cardBg: isDark
          ? const Color(0xFF141A17)
          : (isSepia ? const Color(0xFFFFFDF7) : Colors.white),
      cardBorder: isDark
          ? const Color(0xFF23302A)
          : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6)),
    );
  }

  bool _matchesQuery(List<String> fields) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    for (final f in fields) {
      if (f.toLowerCase().contains(q)) return true;
    }
    return false;
  }

  Future<void> _openFocusedDetail({
    required int initialIndex,
    required int itemCount,
    required String Function(int index, AppStrings strings, String headingLang)
        titleBuilder,
    required Widget Function(
      BuildContext context,
      int index,
      AppStrings strings,
      String headingLang,
      String expLang,
    ) itemBuilder,
  }) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FocusedDetailPage(
          initialIndex: initialIndex,
          itemCount: itemCount,
          settingsScope: SettingsScope.ibadah,
          titleBuilder: titleBuilder,
          itemBuilder: itemBuilder,
          onIndexChanged: (_) {
            IbadahAudioController.instance.stopOnDispose();
          },
        ),
      ),
    );
    IbadahAudioController.instance.stopOnDispose();
    if (widget.section == IbadahSection.salah && mounted) {
      unawaited(_loadPersistedSharts());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final headingLang = settings.ibadahMalayalamHeadings ? 'ml' : lang;
    final hStrings = AppStrings(headingLang);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _palette(context, settings.themeMode);
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: settings.tvModeEnabled,
      normalMaxWidth: 880,
    );
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.5) : 1.0;

    // Stop playback automatically if audio bar visibility is toggled off in Settings.
    ref.listen<bool>(
      settingsProvider.select((s) => s.ibadahShowAudio),
      (prev, next) {
        if (prev == true && !next) {
          IbadahAudioController.instance.stopOnDispose();
        }
      },
    );

    // Show clean localized feedback when an offline audio asset is not bundled yet.
    ref.listen<int>(
      ibadahAudioProvider.select((s) => s.missingAssetTick),
      (prev, next) {
        if (prev != null && next > prev && mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.audioNotFoundMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    switch (widget.section) {
      case IbadahSection.niyyah:
        return _buildNiyyahIndex(
          t: t,
          hStrings: hStrings,
          headingLang: headingLang,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
      case IbadahSection.salah:
        return _buildSalahIndex(
          t: t,
          hStrings: hStrings,
          headingLang: headingLang,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
      case IbadahSection.rawatib:
        return _buildRawatibIndex(
          t: t,
          hStrings: hStrings,
          headingLang: headingLang,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
      case IbadahSection.mayyith:
        return _buildMayyithIndex(
          t: t,
          hStrings: hStrings,
          headingLang: headingLang,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
    }
  }

  Widget _buildSearchAndList({
    required AppStrings t,
    required ({Color cardBg, Color cardBorder}) palette,
    required double hPad,
    required double uiScale,
    required ColorScheme cs,
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 8),
          child: FeatureIndexSearchBar(
            controller: _searchCtrl,
            query: _query,
            onChanged: (v) => setState(() => _query = v),
            onClear: () {
              _searchCtrl.clear();
              setState(() => _query = '');
            },
            hintText: t.searchItemsHint,
            clearTooltip: t.clearSearchLabel,
            cardBg: palette.cardBg,
            cardBorder: palette.cardBorder,
            uiScale: uiScale,
          ),
        ),
        Expanded(
          child: itemCount == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.noMatchingItems,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.5 * uiScale.clamp(1.0, 1.3),
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 28),
                  itemCount: itemCount,
                  itemBuilder: itemBuilder,
                ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. NIYYAH INDEX -> SINGLE FOCUSED NIYYAH DETAIL
  // ---------------------------------------------------------------------------
  Widget _buildNiyyahIndex({
    required AppStrings t,
    required AppStrings hStrings,
    required String headingLang,
    required ({Color cardBg, Color cardBorder}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahNiyyahProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahNiyyahProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final entries = <_NiyyahIndexEntry>[
          for (final fard in bundle.fardPrayers)
            _NiyyahIndexEntry.fard(fard),
          for (final sunnah in bundle.sunnahPrayers)
            _NiyyahIndexEntry.sunnah(sunnah),
        ];

        final filteredIndices = <int>[
          for (int i = 0; i < entries.length; i++)
            if (_matchesQuery([
              entries[i].searchText,
            ]))
              i,
        ];

        return _buildSearchAndList(
          t: t,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          cs: cs,
          itemCount: filteredIndices.length,
          itemBuilder: (_, pos) {
            final fullIdx = filteredIndices[pos];
            final entry = entries[fullIdx];
            final String title = entry.fard != null
                ? entry.fard!.titleFor(headingLang)
                : entry.sunnah!.titleFor(headingLang);
            final String subtitle = entry.fard != null
                ? '${hStrings.fardBadgeLabel} · ${entry.fard!.rakaat} ${headingLang == 'ml' ? 'റക്അത്ത്' : "Raka'at"}'
                : hStrings.sunnahBadgeLabel;
            final String arabicPreview = entry.fard != null
                ? entry.fard!.titleAr
                : entry.sunnah!.titleAr;

            return FeatureIndexTile(
              indexNumber: fullIdx + 1,
              title: title,
              subtitleMeta: subtitle,
              trailingArabic: arabicPreview,
              isHighlighted: entry.fard != null,
              cardBg: palette.cardBg,
              cardBorder: palette.cardBorder,
              accentColor:
                  entry.fard != null ? accentColor : AppBranding.accentGold,
              uiScale: uiScale,
              onTap: () => _openFocusedDetail(
                initialIndex: fullIdx,
                itemCount: entries.length,
                titleBuilder: (idx, _, hLang) {
                  final e = entries[idx];
                  return e.fard != null
                      ? e.fard!.titleFor(hLang)
                      : e.sunnah!.titleFor(hLang);
                },
                itemBuilder: (_, idx, strings, hLang, eLang) {
                  final e = entries[idx];
                  return _NiyyahFocusedDetailBody(
                    entry: e,
                    orderNumber: idx + 1,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SALAH GUIDE INDEX -> SINGLE FOCUSED STEP / SHART / ARKAN DETAIL
  // ---------------------------------------------------------------------------
  Widget _buildSalahIndex({
    required AppStrings t,
    required AppStrings hStrings,
    required String headingLang,
    required ({Color cardBg, Color cardBorder}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahSalahGuideProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahSalahGuideProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final entries = <_SalahIndexEntry>[
          if (bundle.conditions.isNotEmpty)
            _SalahIndexEntry.shart(bundle.conditions),
          if (bundle.arkan.isNotEmpty) _SalahIndexEntry.arkan(bundle.arkan),
          for (final step in bundle.steps) _SalahIndexEntry.step(step),
        ];

        final filteredIndices = <int>[
          for (int i = 0; i < entries.length; i++)
            if (_matchesQuery([entries[i].searchText(hStrings)])) i,
        ];

        return _buildSearchAndList(
          t: t,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          cs: cs,
          itemCount: filteredIndices.length,
          itemBuilder: (_, pos) {
            final fullIdx = filteredIndices[pos];
            final entry = entries[fullIdx];
            late final String title;
            late final String subtitle;
            late final Color rowAccent;

            if (entry.conditions != null) {
              title = hStrings.shartChecklistTitle;
              subtitle =
                  '${_checkedSharts.length}/${entry.conditions!.length} · ${hStrings.fardBadgeLabel}';
              rowAccent = accentColor;
            } else if (entry.arkan != null) {
              title = hStrings.arkanSectionTitle;
              subtitle =
                  '${entry.arkan!.length} ${headingLang == 'ml' ? 'ഫർളുകൾ' : 'Pillars'} · ${hStrings.fardBadgeLabel}';
              rowAccent = accentColor;
            } else {
              final step = entry.step!;
              title = step.titleFor(headingLang);
              subtitle =
                  '${step.postureFor(headingLang)} · ${step.isFard ? hStrings.fardBadgeLabel : hStrings.sunnahBadgeLabel}';
              rowAccent =
                  step.isFard ? accentColor : AppBranding.accentGold;
            }

            return FeatureIndexTile(
              indexNumber: fullIdx + 1,
              title: title,
              subtitleMeta: subtitle,
              isHighlighted: entry.step?.isFard ?? true,
              cardBg: palette.cardBg,
              cardBorder: palette.cardBorder,
              accentColor: rowAccent,
              uiScale: uiScale,
              onTap: () => _openFocusedDetail(
                initialIndex: fullIdx,
                itemCount: entries.length,
                titleBuilder: (idx, _, hLang) {
                  final e = entries[idx];
                  final hs = AppStrings(hLang);
                  if (e.conditions != null) return hs.shartChecklistTitle;
                  if (e.arkan != null) return hs.arkanSectionTitle;
                  return e.step!.titleFor(hLang);
                },
                itemBuilder: (_, idx, __, ___, ____) {
                  final e = entries[idx];
                  if (e.conditions != null) {
                    return _SalahShartFocusedBody(conditions: e.conditions!);
                  }
                  if (e.arkan != null) {
                    return _SalahArkanFocusedBody(arkan: e.arkan!);
                  }
                  return _SalahStepFocusedBody(step: e.step!);
                },
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. RAWATIB & RECOMMENDED SURAHS INDEX -> SINGLE ITEM DETAIL
  // ---------------------------------------------------------------------------
  Widget _buildRawatibIndex({
    required AppStrings t,
    required AppStrings hStrings,
    required String headingLang,
    required ({Color cardBg, Color cardBorder}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahSunnahSurahsProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahSunnahSurahsProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final entries = <_RawatibIndexEntry>[
          for (final g in bundle.rawatib) ...[
            for (final item in g.before)
              _RawatibIndexEntry.rawatib(
                prayerGroup: g,
                rawatibItem: item,
                isBefore: true,
              ),
            for (final item in g.after)
              _RawatibIndexEntry.rawatib(
                prayerGroup: g,
                rawatibItem: item,
                isBefore: false,
              ),
          ],
          for (final sGroup in bundle.recommendedSurahs)
            _RawatibIndexEntry.surahGroup(sGroup),
        ];

        final filteredIndices = <int>[
          for (int i = 0; i < entries.length; i++)
            if (_matchesQuery([entries[i].searchText])) i,
        ];

        return _buildSearchAndList(
          t: t,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          cs: cs,
          itemCount: filteredIndices.length,
          itemBuilder: (_, pos) {
            final fullIdx = filteredIndices[pos];
            final entry = entries[fullIdx];
            late final String title;
            late final String subtitle;
            late final Color rowAccent;

            if (entry.rawatibItem != null) {
              final g = entry.prayerGroup!;
              final item = entry.rawatibItem!;
              final timingBadge = entry.isBefore
                  ? hStrings.beforePrayerLabel
                  : hStrings.afterPrayerLabel;
              final muakkadahLabel = item.isMuakkadah
                  ? hStrings.muakkadahBadgeLabel
                  : hStrings.ghairMuakkadahBadgeLabel;
              title = '${g.prayerFor(headingLang)} — ${item.timingFor(headingLang)}';
              subtitle =
                  '$timingBadge · $muakkadahLabel · ${item.rakaat} ${headingLang == 'ml' ? 'റക്അത്ത്' : "Raka'at"}';
              rowAccent =
                  item.isMuakkadah ? accentColor : AppBranding.accentGold;
            } else {
              final sg = entry.surahGroup!;
              title = sg.occasionFor(headingLang);
              subtitle =
                  '${hStrings.recommendedSurahsTitle} · ${sg.surahs.length} ${headingLang == 'ml' ? 'സൂറത്തുകൾ' : 'Surahs'}';
              rowAccent = AppBranding.accentGold;
            }

            return FeatureIndexTile(
              indexNumber: fullIdx + 1,
              title: title,
              subtitleMeta: subtitle,
              isHighlighted: entry.rawatibItem?.isMuakkadah ?? false,
              cardBg: palette.cardBg,
              cardBorder: palette.cardBorder,
              accentColor: rowAccent,
              uiScale: uiScale,
              onTap: () => _openFocusedDetail(
                initialIndex: fullIdx,
                itemCount: entries.length,
                titleBuilder: (idx, _, hLang) {
                  final e = entries[idx];
                  if (e.rawatibItem != null) {
                    return '${e.prayerGroup!.prayerFor(hLang)} — ${e.rawatibItem!.timingFor(hLang)}';
                  }
                  return e.surahGroup!.occasionFor(hLang);
                },
                itemBuilder: (_, idx, __, ___, ____) {
                  final e = entries[idx];
                  if (e.rawatibItem != null) {
                    return _RawatibItemFocusedBody(
                      group: e.prayerGroup!,
                      item: e.rawatibItem!,
                      isBefore: e.isBefore,
                      orderNumber: idx + 1,
                    );
                  }
                  return _RecommendedSurahsFocusedBody(
                    group: e.surahGroup!,
                    onOpenSurah: widget.onOpenSurah,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 4. MAYYITH GUIDE INDEX -> SINGLE FOCUSED ITEM DETAIL
  // ---------------------------------------------------------------------------
  Widget _buildMayyithIndex({
    required AppStrings t,
    required AppStrings hStrings,
    required String headingLang,
    required ({Color cardBg, Color cardBorder}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahMayyithProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahMayyithProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final entries = <_MayyithIndexEntry>[
          for (final stage in bundle.preparationStages)
            _MayyithIndexEntry.prep(stage),
          for (final n in bundle.niyyah) _MayyithIndexEntry.niyyah(n),
          for (final tk in bundle.takbirs) _MayyithIndexEntry.takbir(tk),
          for (final b in bundle.burialAndTalqeen)
            _MayyithIndexEntry.burial(b),
        ];

        final filteredIndices = <int>[
          for (int i = 0; i < entries.length; i++)
            if (_matchesQuery([entries[i].searchText])) i,
        ];

        return _buildSearchAndList(
          t: t,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          cs: cs,
          itemCount: filteredIndices.length,
          itemBuilder: (_, pos) {
            final fullIdx = filteredIndices[pos];
            final entry = entries[fullIdx];
            late final String title;
            late final String subtitle;
            late final Color rowAccent;

            if (entry.prep != null) {
              title = entry.prep!.titleFor(headingLang);
              subtitle = hStrings.mayyithPrepTitle;
              rowAccent = accentColor;
            } else if (entry.niyyah != null) {
              title = entry.niyyah!.titleFor(headingLang);
              subtitle = '${hStrings.mayyithNiyyahTitle} · ${hStrings.fardBadgeLabel}';
              rowAccent = accentColor;
            } else if (entry.takbir != null) {
              title = entry.takbir!.titleFor(headingLang);
              subtitle =
                  '${hStrings.mayyithTakbirsTitle} · ${headingLang == 'ml' ? 'തക്ബീർ' : 'Takbir'} ${entry.takbir!.takbirNumber}';
              rowAccent = AppBranding.accentGold;
            } else {
              title = entry.burial!.titleFor(headingLang);
              subtitle = hStrings.mayyithBurialTitle;
              rowAccent = accentColor;
            }

            return FeatureIndexTile(
              indexNumber: fullIdx + 1,
              title: title,
              subtitleMeta: subtitle,
              isHighlighted: entry.takbir != null,
              cardBg: palette.cardBg,
              cardBorder: palette.cardBorder,
              accentColor: rowAccent,
              uiScale: uiScale,
              onTap: () => _openFocusedDetail(
                initialIndex: fullIdx,
                itemCount: entries.length,
                titleBuilder: (idx, _, hLang) {
                  final e = entries[idx];
                  if (e.prep != null) return e.prep!.titleFor(hLang);
                  if (e.niyyah != null) return e.niyyah!.titleFor(hLang);
                  if (e.takbir != null) return e.takbir!.titleFor(hLang);
                  return e.burial!.titleFor(hLang);
                },
                itemBuilder: (_, idx, __, ___, ____) {
                  final e = entries[idx];
                  return _MayyithFocusedBody(
                    entry: e,
                    orderNumber: idx + 1,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// INDEX ENTRY DESCRIPTORS
// =============================================================================

class _NiyyahIndexEntry {
  final FardNiyyahPrayer? fard;
  final SunnahNiyyahItem? sunnah;

  const _NiyyahIndexEntry.fard(this.fard) : sunnah = null;
  const _NiyyahIndexEntry.sunnah(this.sunnah) : fard = null;

  String get searchText {
    if (fard != null) {
      return '${fard!.titleEn} ${fard!.titleMl} ${fard!.titleAr}';
    }
    return '${sunnah!.titleEn} ${sunnah!.titleMl} ${sunnah!.titleAr}';
  }
}

class _SalahIndexEntry {
  final List<SalahCondition>? conditions;
  final List<SalahRukn>? arkan;
  final SalahStep? step;

  const _SalahIndexEntry.shart(this.conditions)
      : arkan = null,
        step = null;
  const _SalahIndexEntry.arkan(this.arkan)
      : conditions = null,
        step = null;
  const _SalahIndexEntry.step(this.step)
      : conditions = null,
        arkan = null;

  String searchText(AppStrings hStrings) {
    if (conditions != null) {
      return '${hStrings.shartChecklistTitle} shart conditions നിബന്ധനകൾ';
    }
    if (arkan != null) {
      return '${hStrings.arkanSectionTitle} arkan fard pillars അർക്കാൻ';
    }
    return '${step!.titleEn} ${step!.titleMl} ${step!.postureEn} ${step!.postureMl}';
  }
}

class _RawatibIndexEntry {
  final PrayerRawatibGroup? prayerGroup;
  final RawatibItem? rawatibItem;
  final bool isBefore;
  final RecommendedSurahGroup? surahGroup;

  const _RawatibIndexEntry.rawatib({
    required this.prayerGroup,
    required this.rawatibItem,
    required this.isBefore,
  }) : surahGroup = null;

  const _RawatibIndexEntry.surahGroup(this.surahGroup)
      : prayerGroup = null,
        rawatibItem = null,
        isBefore = false;

  String get searchText {
    if (rawatibItem != null) {
      return '${prayerGroup!.prayerEn} ${prayerGroup!.prayerMl} ${rawatibItem!.timingEn} ${rawatibItem!.timingMl}';
    }
    final surahNames = surahGroup!.surahs
        .map((s) => '${s.nameEn} ${s.nameMl} ${s.nameAr}')
        .join(' ');
    return '${surahGroup!.occasionEn} ${surahGroup!.occasionMl} $surahNames';
  }
}

class _MayyithIndexEntry {
  final MayyithPrepStage? prep;
  final MayyithNiyyahItem? niyyah;
  final MayyithTakbirStep? takbir;
  final MayyithBurialItem? burial;

  const _MayyithIndexEntry.prep(this.prep)
      : niyyah = null,
        takbir = null,
        burial = null;
  const _MayyithIndexEntry.niyyah(this.niyyah)
      : prep = null,
        takbir = null,
        burial = null;
  const _MayyithIndexEntry.takbir(this.takbir)
      : prep = null,
        niyyah = null,
        burial = null;
  const _MayyithIndexEntry.burial(this.burial)
      : prep = null,
        niyyah = null,
        takbir = null;

  String get searchText {
    if (prep != null) return '${prep!.titleEn} ${prep!.titleMl}';
    if (niyyah != null) return '${niyyah!.titleEn} ${niyyah!.titleMl}';
    if (takbir != null) return '${takbir!.titleEn} ${takbir!.titleMl}';
    return '${burial!.titleEn} ${burial!.titleMl}';
  }
}

// =============================================================================
// FOCUSED SINGLE-ITEM DETAIL BODIES
// =============================================================================

({Color cardBg, Color cardBorder}) _detailPalette(
  BuildContext context,
  String themeMode,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isSepia = themeMode == 'sepia';
  return (
    cardBg: isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white),
    cardBorder: isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6)),
  );
}

class _NiyyahFocusedDetailBody extends ConsumerStatefulWidget {
  final _NiyyahIndexEntry entry;
  final int orderNumber;

  const _NiyyahFocusedDetailBody({
    required this.entry,
    required this.orderNumber,
  });

  @override
  ConsumerState<_NiyyahFocusedDetailBody> createState() =>
      _NiyyahFocusedDetailBodyState();
}

class _NiyyahFocusedDetailBodyState
    extends ConsumerState<_NiyyahFocusedDetailBody> {
  String _selectedRole = 'munfarid';

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final expLang = explanationLangFor(settings.appLanguage);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final hStrings = AppStrings(headingLang);
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;

    if (widget.entry.fard != null) {
      final prayer = widget.entry.fard!;
      final variant = prayer.variantForRole(_selectedRole);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.cardBorder),
            ),
            child: Row(
              children: [
                _RoleSegmentButton(
                  label: hStrings.roleMunfarid,
                  selected: _selectedRole == 'munfarid',
                  accentColor: accentColor,
                  onTap: () {
                    IbadahAudioController.instance.stopOnDispose();
                    setState(() => _selectedRole = 'munfarid');
                  },
                ),
                _RoleSegmentButton(
                  label: hStrings.roleImam,
                  selected: _selectedRole == 'imam',
                  accentColor: accentColor,
                  onTap: () {
                    IbadahAudioController.instance.stopOnDispose();
                    setState(() => _selectedRole = 'imam');
                  },
                ),
                _RoleSegmentButton(
                  label: hStrings.roleMamoom,
                  selected: _selectedRole == 'mamoom',
                  accentColor: accentColor,
                  onTap: () {
                    IbadahAudioController.instance.stopOnDispose();
                    setState(() => _selectedRole = 'mamoom');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IbadahAudioCard(
            orderBadge: '${widget.orderNumber}',
            title: prayer.titleFor(headingLang),
            subtitle: variant.labelFor(headingLang),
            badgeText: headingLang == 'ml'
                ? '${prayer.rakaat} റക്അത്ത്'
                : '${prayer.rakaat} Raka\'at',
            badgeColor: accentColor,
            isHighlighted: true,
            arabicText: variant.arabic,
            transliterationMl: variant.transliterationMl,
            meaningText: variant.meaningFor(expLang),
            audioPath: variant.audioPath,
            showTransliteration: settings.ibadahShowTransliteration,
            showMeaning: settings.ibadahShowMeaning,
            showNotes: settings.ibadahShowNotes,
            showAudio: settings.ibadahShowAudio,
            strings: t,
            cardBg: palette.cardBg,
            cardBorder: palette.cardBorder,
          ),
        ],
      );
    }

    final item = widget.entry.sunnah!;
    return IbadahAudioCard(
      orderBadge: '${widget.orderNumber}',
      title: item.titleFor(headingLang),
      badgeText: hStrings.sunnahBadgeLabel,
      badgeColor: AppBranding.accentGold,
      arabicText: item.arabic,
      transliterationMl: item.transliterationMl,
      meaningText: item.meaningFor(expLang),
      noteText: item.noteFor(expLang),
      audioPath: item.audioPath,
      showTransliteration: settings.ibadahShowTransliteration,
      showMeaning: settings.ibadahShowMeaning,
      showNotes: settings.ibadahShowNotes,
      showAudio: settings.ibadahShowAudio,
      strings: t,
      cardBg: palette.cardBg,
      cardBorder: palette.cardBorder,
    );
  }
}

class _SalahShartFocusedBody extends ConsumerStatefulWidget {
  final List<SalahCondition> conditions;

  const _SalahShartFocusedBody({required this.conditions});

  @override
  ConsumerState<_SalahShartFocusedBody> createState() =>
      _SalahShartFocusedBodyState();
}

class _SalahShartFocusedBodyState
    extends ConsumerState<_SalahShartFocusedBody> {
  Set<String> _checkedSharts = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final loaded =
        await ref.read(storageServiceProvider).loadIbadahCheckedSharts();
    if (!mounted) return;
    setState(() => _checkedSharts = loaded);
  }

  Future<void> _toggle(String id) async {
    final next = Set<String>.from(_checkedSharts);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    setState(() => _checkedSharts = next);
    await ref.read(storageServiceProvider).saveIbadahCheckedSharts(next);
  }

  Future<void> _reset() async {
    setState(() => _checkedSharts = {});
    await ref.read(storageServiceProvider).saveIbadahCheckedSharts(const {});
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final expLang = explanationLangFor(settings.appLanguage);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final hStrings = AppStrings(headingLang);
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.65) : 1.0;

    final total = widget.conditions.length;
    final checkedCount =
        widget.conditions.where((c) => _checkedSharts.contains(c.id)).length;

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.checklist_rounded,
                    size: 19,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hStrings.shartChecklistTitle,
                        style: TextStyle(
                          fontSize: 15 * uiScale.clamp(1.0, 1.3),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$checkedCount / $total',
                        style: TextStyle(
                          fontSize: 12 * uiScale.clamp(1.0, 1.25),
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                if (checkedCount > 0)
                  TextButton(
                    onPressed: _reset,
                    child: Text(hStrings.resetChecklistLabel),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.cardBorder),
          for (final cond in widget.conditions)
            Builder(
              builder: (_) {
                final isChecked = _checkedSharts.contains(cond.id);
                return CheckboxListTile(
                  value: isChecked,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: accentColor,
                  onChanged: (_) => _toggle(cond.id),
                  title: Text(
                    cond.titleFor(headingLang),
                    style: TextStyle(
                      fontSize: 14 * uiScale,
                      fontWeight: FontWeight.w700,
                      decoration:
                          isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    cond.descFor(expLang),
                    style: TextStyle(
                      fontSize: 12.5 * uiScale,
                      height: 1.45,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SalahArkanFocusedBody extends ConsumerWidget {
  final List<SalahRukn> arkan;

  const _SalahArkanFocusedBody({required this.arkan});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final hStrings = AppStrings(headingLang);
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.65) : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.foundation_rounded,
                    size: 19,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hStrings.arkanSectionTitle,
                    style: TextStyle(
                      fontSize: 15 * uiScale.clamp(1.0, 1.3),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.cardBorder),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                for (final rukn in arkan)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rukn.order}',
                            style: TextStyle(
                              fontSize: 12.5 * uiScale.clamp(1.0, 1.2),
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              rukn.titleFor(headingLang),
                              style: TextStyle(
                                fontSize: 14 * uiScale,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalahStepFocusedBody extends ConsumerWidget {
  final SalahStep step;

  const _SalahStepFocusedBody({required this.step});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final expLang = explanationLangFor(settings.appLanguage);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final hStrings = AppStrings(headingLang);
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;

    return IbadahAudioCard(
      orderBadge: '${step.order}',
      title: step.titleFor(headingLang),
      subtitle: step.postureFor(headingLang),
      badgeText:
          step.isFard ? hStrings.fardBadgeLabel : hStrings.sunnahBadgeLabel,
      badgeColor: step.isFard ? accentColor : AppBranding.accentGold,
      isHighlighted: step.isFard,
      arabicText: step.arabic,
      transliterationMl: step.transliterationMl,
      meaningText: step.meaningFor(expLang),
      noteText: step.noteFor(expLang),
      audioPath: step.audioPath,
      showTransliteration: settings.ibadahShowTransliteration,
      showMeaning: settings.ibadahShowMeaning,
      showNotes: settings.ibadahShowNotes,
      showAudio: settings.ibadahShowAudio,
      strings: t,
      cardBg: palette.cardBg,
      cardBorder: palette.cardBorder,
    );
  }
}

class _RawatibItemFocusedBody extends ConsumerWidget {
  final PrayerRawatibGroup group;
  final RawatibItem item;
  final bool isBefore;
  final int orderNumber;

  const _RawatibItemFocusedBody({
    required this.group,
    required this.item,
    required this.isBefore,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final expLang = explanationLangFor(settings.appLanguage);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final hStrings = AppStrings(headingLang);
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;

    return IbadahAudioCard(
      orderBadge: '$orderNumber',
      title: item.timingFor(headingLang),
      subtitle:
          '${group.prayerFor(headingLang)} · ${isBefore ? hStrings.beforePrayerLabel : hStrings.afterPrayerLabel}',
      badgeText: item.isMuakkadah
          ? hStrings.muakkadahBadgeLabel
          : hStrings.ghairMuakkadahBadgeLabel,
      badgeColor: item.isMuakkadah ? accentColor : AppBranding.accentGold,
      isHighlighted: item.isMuakkadah,
      arabicText: item.arabic,
      transliterationMl: item.transliterationMl,
      meaningText: item.meaningMl,
      noteText: item.noteFor(expLang),
      audioPath: item.audioPath,
      showTransliteration: settings.ibadahShowTransliteration,
      showMeaning: settings.ibadahShowMeaning,
      showNotes: settings.ibadahShowNotes,
      showAudio: settings.ibadahShowAudio,
      strings: t,
      cardBg: palette.cardBg,
      cardBorder: palette.cardBorder,
    );
  }
}

class _RecommendedSurahsFocusedBody extends ConsumerWidget {
  final RecommendedSurahGroup group;
  final void Function(int surahNo)? onOpenSurah;

  const _RecommendedSurahsFocusedBody({
    required this.group,
    this.onOpenSurah,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final expLang = explanationLangFor(settings.appLanguage);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.5) : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.occasionFor(headingLang),
            style: TextStyle(
              fontSize: 17 * uiScale,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          if (settings.ibadahShowNotes) ...[
            const SizedBox(height: 8),
            Text(
              group.reasonFor(expLang),
              style: TextStyle(
                fontSize: 13.5 * uiScale,
                height: 1.55,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final surah in group.surahs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.25),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onOpenSurah == null
                      ? null
                      : () => onOpenSurah!(surah.surahNumber),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${surah.surahNumber}. ${surah.nameFor(headingLang)}',
                                style: TextStyle(
                                  fontSize: 14.5 * uiScale,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                surah.tagFor(headingLang),
                                style: TextStyle(
                                  fontSize: 12 * uiScale,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            surah.nameAr,
                            style: GoogleFonts.amiri(
                              fontSize: 20 * uiScale,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ),
                        if (onOpenSurah != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 17,
                            color: accentColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MayyithFocusedBody extends ConsumerWidget {
  final _MayyithIndexEntry entry;
  final int orderNumber;

  const _MayyithFocusedBody({
    required this.entry,
    required this.orderNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final expLang = explanationLangFor(settings.appLanguage);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : settings.appLanguage;
    final hStrings = AppStrings(headingLang);
    final palette = _detailPalette(context, settings.themeMode);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.5) : 1.0;

    if (entry.prep != null) {
      final stage = entry.prep!;
      return IbadahAudioCard(
        orderBadge: '$orderNumber',
        title: stage.titleFor(headingLang),
        badgeText: headingLang == 'ml' ? 'ശാഫിഈ' : 'Shafi\'i',
        badgeColor: accentColor,
        arabicText: stage.arabic,
        transliterationMl: stage.transliterationMl,
        meaningText: stage.meaningMl,
        audioPath: stage.audioPath,
        showTransliteration: settings.ibadahShowTransliteration,
        showMeaning: settings.ibadahShowMeaning,
        showNotes: settings.ibadahShowNotes,
        showAudio: settings.ibadahShowAudio,
        strings: t,
        cardBg: palette.cardBg,
        cardBorder: palette.cardBorder,
        footerExtra: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final pt in stage.pointsFor(expLang))
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        pt,
                        style: TextStyle(
                          fontSize: 13.5 * uiScale,
                          height: 1.55,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    if (entry.niyyah != null) {
      final item = entry.niyyah!;
      return IbadahAudioCard(
        orderBadge: '$orderNumber',
        title: item.titleFor(headingLang),
        badgeText: hStrings.fardBadgeLabel,
        badgeColor: accentColor,
        arabicText: item.arabic,
        transliterationMl: item.transliterationMl,
        meaningText: item.meaningFor(expLang),
        audioPath: item.audioPath,
        showTransliteration: settings.ibadahShowTransliteration,
        showMeaning: settings.ibadahShowMeaning,
        showNotes: settings.ibadahShowNotes,
        showAudio: settings.ibadahShowAudio,
        strings: t,
        cardBg: palette.cardBg,
        cardBorder: palette.cardBorder,
      );
    }

    if (entry.takbir != null) {
      final step = entry.takbir!;
      return IbadahAudioCard(
        orderBadge: '$orderNumber',
        title: step.titleFor(headingLang),
        badgeText: headingLang == 'ml'
            ? 'തക്ബീർ ${step.takbirNumber}'
            : 'Takbir ${step.takbirNumber}',
        badgeColor: AppBranding.accentGold,
        isHighlighted: true,
        arabicText: step.arabic,
        transliterationMl: step.transliterationMl,
        meaningText: step.meaningFor(expLang),
        noteText: step.noteFor(expLang),
        audioPath: step.audioPath,
        showTransliteration: settings.ibadahShowTransliteration,
        showMeaning: settings.ibadahShowMeaning,
        showNotes: settings.ibadahShowNotes,
        showAudio: settings.ibadahShowAudio,
        strings: t,
        cardBg: palette.cardBg,
        cardBorder: palette.cardBorder,
      );
    }

    final item = entry.burial!;
    return IbadahAudioCard(
      orderBadge: '$orderNumber',
      title: item.titleFor(headingLang),
      arabicText: item.arabic,
      transliterationMl: item.transliterationMl,
      meaningText: item.meaningMl,
      noteText: item.noteFor(expLang),
      audioPath: item.audioPath,
      showTransliteration: settings.ibadahShowTransliteration,
      showMeaning: settings.ibadahShowMeaning,
      showNotes: settings.ibadahShowNotes,
      showAudio: settings.ibadahShowAudio,
      strings: t,
      cardBg: palette.cardBg,
      cardBorder: palette.cardBorder,
    );
  }
}

// =============================================================================
// SMALL SHARED HELPERS
// =============================================================================

class _RoleSegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleSegmentButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Material(
        color: selected ? accentColor : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  const _ErrorNotice({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
