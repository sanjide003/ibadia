import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../providers/quran_providers.dart';
import '../services/export_service.dart';
import '../services/ibadah_audio_controller.dart';
import '../services/ibadah_data_service.dart';
import '../services/ibadah_export_service.dart';
import '../widgets/ibadah_audio_card.dart';
import '../widgets/tv_mode_widgets.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _jumpKeys = <String, GlobalKey>{};
  String? _activeJumpKey;
  Timer? _jumpHighlightTimer;

  // Niyyah filters
  String _niyyahScope = 'all'; // 'all' | 'fard' | 'sunnah'
  String _selectedRole = 'munfarid'; // 'munfarid' | 'imam' | 'mamoom'

  // Salah state
  Set<String> _checkedSharts = {};
  bool _shartsExpanded = true;
  bool _arkanExpanded = false;
  bool _fardStepsOnly = false;

  // Rawatib / Surahs filter
  String _rawatibSection = 'all'; // 'all' | 'rawatib' | 'surahs'

  // Mayyith filter
  String _mayyithSection = 'all'; // 'all' | 'prep' | 'niyyah' | 'takbirs' | 'burial'
  bool _exportingPdf = false;

  Future<void> _exportSectionPdf({
    required List<IbadahExportItem> items,
    required String documentTitle,
    required bool showTransliteration,
    required bool showMeaning,
    required bool showNotes,
    required AppStrings strings,
  }) async {
    if (_exportingPdf || items.isEmpty) return;
    setState(() => _exportingPdf = true);
    try {
      final pdfBytes = await IbadahExportService.buildMultiCardPdf(
        items,
        documentTitle: documentTitle,
        includeTransliteration: showTransliteration,
        includeMeaning: showMeaning,
        includeNotes: showNotes,
      );
      final saved = await ExportService.savePdfBytes(
        bytes: pdfBytes,
        baseName: IbadahExportService.slugifyTitle(documentTitle),
      );
      if (!mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(strings.exportSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.exportError),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exportingPdf = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.section == IbadahSection.salah) {
      _loadPersistedSharts();
    }
  }

  GlobalKey _keyFor(String id) =>
      _jumpKeys.putIfAbsent(id, () => GlobalKey());

  void _jumpToKey(
    String id, {
    VoidCallback? beforeJumpStateChange,
  }) {
    final bool needsRebuild = beforeJumpStateChange != null;
    if (needsRebuild) {
      setState(() {
        beforeJumpStateChange();
        _activeJumpKey = id;
      });
    } else {
      setState(() => _activeJumpKey = id);
    }

    _jumpHighlightTimer?.cancel();
    _jumpHighlightTimer = Timer(const Duration(milliseconds: 1900), () {
      if (mounted && _activeJumpKey == id) {
        setState(() => _activeJumpKey = null);
      }
    });

    void scrollNow() {
      if (!mounted) return;
      final ctx = _jumpKeys[id]?.currentContext;
      if (ctx != null) {
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            alignment: 0.05,
          ),
        );
      }
    }

    if (needsRebuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) => scrollNow());
    } else {
      scrollNow();
    }
  }

  Future<void> _loadPersistedSharts() async {
    final loaded =
        await ref.read(storageServiceProvider).loadIbadahCheckedSharts();
    if (!mounted) return;
    setState(() => _checkedSharts = loaded);
  }

  Future<void> _toggleShart(String id) async {
    final next = Set<String>.from(_checkedSharts);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    setState(() => _checkedSharts = next);
    await ref.read(storageServiceProvider).saveIbadahCheckedSharts(next);
  }

  Future<void> _resetSharts() async {
    setState(() => _checkedSharts = {});
    await ref.read(storageServiceProvider).saveIbadahCheckedSharts(const {});
  }

  @override
  void dispose() {
    _jumpHighlightTimer?.cancel();
    _scrollController.dispose();
    IbadahAudioController.instance.stopOnDispose();
    super.dispose();
  }

  ({Color cardBg, Color cardBorder, Color tabBarBg}) _palette(
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
      tabBarBg: isDark
          ? const Color(0xFF0E1411)
          : (isSepia ? const Color(0xFFF3EBD8) : const Color(0xFFE9F2ED)),
    );
  }

  String _cleanStepShortLabel(String title) {
    final stripped = title.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim();
    final parenIdx = stripped.indexOf('(');
    final base = parenIdx > 4 ? stripped.substring(0, parenIdx).trim() : stripped;
    if (base.length <= 22) return base;
    return '${base.substring(0, 20).trim()}…';
  }

  Widget _highlightBox({
    required String keyId,
    required Color accentColor,
    required Widget child,
  }) {
    final focused = _activeJumpKey == keyId;
    return KeyedSubtree(
      key: _keyFor(keyId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        decoration: focused
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppBranding.accentGold, width: 2),
                color: accentColor.withValues(alpha: 0.05),
              )
            : null,
        child: child,
      ),
    );
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
      normalMaxWidth: 960,
    );
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.65) : 1.0;

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

    Widget sectionBody;
    switch (widget.section) {
      case IbadahSection.niyyah:
        sectionBody = _buildNiyyahView(
          t: t,
          hStrings: hStrings,
          lang: lang,
          headingLang: headingLang,
          showTransliteration: settings.ibadahShowTransliteration,
          showMeaning: settings.ibadahShowMeaning,
          showNotes: settings.ibadahShowNotes,
          showAudio: settings.ibadahShowAudio,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
        break;
      case IbadahSection.salah:
        sectionBody = _buildSalahGuideView(
          t: t,
          hStrings: hStrings,
          lang: lang,
          headingLang: headingLang,
          showTransliteration: settings.ibadahShowTransliteration,
          showMeaning: settings.ibadahShowMeaning,
          showNotes: settings.ibadahShowNotes,
          showAudio: settings.ibadahShowAudio,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
        break;
      case IbadahSection.rawatib:
        sectionBody = _buildRawatibAndSurahsView(
          t: t,
          hStrings: hStrings,
          lang: lang,
          headingLang: headingLang,
          showTransliteration: settings.ibadahShowTransliteration,
          showMeaning: settings.ibadahShowMeaning,
          showNotes: settings.ibadahShowNotes,
          showAudio: settings.ibadahShowAudio,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
        break;
      case IbadahSection.mayyith:
        sectionBody = _buildMayyithView(
          t: t,
          hStrings: hStrings,
          lang: lang,
          headingLang: headingLang,
          showTransliteration: settings.ibadahShowTransliteration,
          showMeaning: settings.ibadahShowMeaning,
          showNotes: settings.ibadahShowNotes,
          showAudio: settings.ibadahShowAudio,
          palette: palette,
          hPad: hPad,
          uiScale: uiScale,
          accentColor: accentColor,
          cs: cs,
        );
        break;
    }

    return Column(
      children: [
        // Compact header strip: Shafi'i Fiqh label + subtle Settings hint
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(hPad, 9, hPad, 9),
          decoration: BoxDecoration(
            color: palette.tabBarBg,
            border: Border(
              bottom: BorderSide(color: palette.cardBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, size: 15, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hStrings.ibadahFiqhSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 13.5, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      t.ibadahDisplayTip,
                      style: TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(child: sectionBody),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 1: NIYYAH (INTENTIONS)
  // ---------------------------------------------------------------------------
  Widget _buildNiyyahView({
    required AppStrings t,
    required AppStrings hStrings,
    required String lang,
    required String headingLang,
    required bool showTransliteration,
    required bool showMeaning,
    required bool showNotes,
    required bool showAudio,
    required ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahNiyyahProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahNiyyahProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final showFard = _niyyahScope == 'all' || _niyyahScope == 'fard';
        final showSunnah = _niyyahScope == 'all' || _niyyahScope == 'sunnah';

        final exportItems = <IbadahExportItem>[
          if (showFard)
            for (int i = 0; i < bundle.fardPrayers.length; i++)
              () {
                final p = bundle.fardPrayers[i];
                final v = p.variantForRole(_selectedRole);
                return IbadahExportItem(
                  orderBadge: '${i + 1}',
                  title: p.titleFor(headingLang),
                  subtitle: v.labelFor(headingLang),
                  badgeText: headingLang == 'ml'
                      ? '${p.rakaat} റക്അത്ത്'
                      : '${p.rakaat} Raka\'at',
                  arabicText: v.arabic,
                  transliterationMl: v.transliterationMl,
                  meaningText: v.meaningFor(lang),
                  footerSource: t.niyyahTabLabel,
                );
              }(),
          if (showSunnah)
            for (int i = 0; i < bundle.sunnahPrayers.length; i++)
              IbadahExportItem(
                orderBadge: '${bundle.fardPrayers.length + i + 1}',
                title: bundle.sunnahPrayers[i].titleFor(headingLang),
                badgeText: hStrings.sunnahBadgeLabel,
                arabicText: bundle.sunnahPrayers[i].arabic,
                transliterationMl: bundle.sunnahPrayers[i].transliterationMl,
                meaningText: bundle.sunnahPrayers[i].meaningFor(lang),
                noteText: bundle.sunnahPrayers[i].noteFor(lang),
                footerSource: t.niyyahTabLabel,
              ),
        ];

        final summaryRows = <_SummaryRowEntry>[
          _SummaryRowEntry(
            label: hStrings.fardPrayersSection,
            countText: '${bundle.fardPrayers.length}',
            icon: Icons.mosque_rounded,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'niyyah_fard_section',
              beforeJumpStateChange: _niyyahScope == 'sunnah'
                  ? () => _niyyahScope = 'all'
                  : null,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.sunnahPrayersSection,
            countText: '${bundle.sunnahPrayers.length}',
            icon: Icons.auto_awesome_rounded,
            accent: AppBranding.accentGold,
            onTap: () => _jumpToKey(
              'niyyah_sunnah_section',
              beforeJumpStateChange: _niyyahScope == 'fard'
                  ? () => _niyyahScope = 'all'
                  : null,
            ),
          ),
        ];

        final chainNodes = <_ChainNodeEntry>[
          for (int i = 0; i < bundle.fardPrayers.length; i++)
            _ChainNodeEntry(
              order: i + 1,
              label: _cleanStepShortLabel(
                bundle.fardPrayers[i].titleFor(headingLang),
              ),
              isPrimary: true,
              isActive:
                  _activeJumpKey == 'niyyah_fard_${bundle.fardPrayers[i].id}',
              onTap: () => _jumpToKey(
                'niyyah_fard_${bundle.fardPrayers[i].id}',
                beforeJumpStateChange: _niyyahScope == 'sunnah'
                    ? () => _niyyahScope = 'all'
                    : null,
              ),
            ),
          for (int i = 0; i < bundle.sunnahPrayers.length; i++)
            _ChainNodeEntry(
              order: bundle.fardPrayers.length + i + 1,
              label: _cleanStepShortLabel(
                bundle.sunnahPrayers[i].titleFor(headingLang),
              ),
              isPrimary: false,
              isActive: _activeJumpKey ==
                  'niyyah_sunnah_${bundle.sunnahPrayers[i].id}',
              onTap: () => _jumpToKey(
                'niyyah_sunnah_${bundle.sunnahPrayers[i].id}',
                beforeJumpStateChange: _niyyahScope == 'fard'
                    ? () => _niyyahScope = 'all'
                    : null,
              ),
            ),
        ];

        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IbadahSummaryTable(
                title: hStrings.summaryTableTitle,
                rows: summaryRows,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
                exportPdfLabel: t.exportGuidePdfBtn,
                isExporting: _exportingPdf,
                onExportPdf: () => _exportSectionPdf(
                  items: exportItems,
                  documentTitle: 'Ibadia ${t.niyyahTabLabel}',
                  showTransliteration: showTransliteration,
                  showMeaning: showMeaning,
                  showNotes: showNotes,
                  strings: t,
                ),
              ),
              const SizedBox(height: 12),
              _OrderedChainBar(
                title: hStrings.orderedChainTitle,
                nodes: chainNodes,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
              ),
              const SizedBox(height: 14),

              // Scope Filter Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipButton(
                      label: hStrings.filterAll,
                      selected: _niyyahScope == 'all',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _niyyahScope = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label:
                          '${hStrings.fardBadgeLabel} (${bundle.fardPrayers.length})',
                      selected: _niyyahScope == 'fard',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _niyyahScope = 'fard'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label:
                          '${hStrings.sunnahBadgeLabel} (${bundle.sunnahPrayers.length})',
                      selected: _niyyahScope == 'sunnah',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _niyyahScope = 'sunnah'),
                    ),
                  ],
                ),
              ),

              if (showFard) ...[
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _keyFor('niyyah_fard_section'),
                  child: _SectionTitleRow(
                    icon: Icons.mosque_rounded,
                    title: hStrings.fardPrayersSection,
                    accentColor: accentColor,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                // Role selector: Munfarid / Imam / Ma'moom
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Row(
                    children: [
                      _RoleSegmentButton(
                        label: hStrings.roleMunfarid,
                        selected: _selectedRole == 'munfarid',
                        accentColor: accentColor,
                        onTap: () => setState(() => _selectedRole = 'munfarid'),
                      ),
                      _RoleSegmentButton(
                        label: hStrings.roleImam,
                        selected: _selectedRole == 'imam',
                        accentColor: accentColor,
                        onTap: () => setState(() => _selectedRole = 'imam'),
                      ),
                      _RoleSegmentButton(
                        label: hStrings.roleMamoom,
                        selected: _selectedRole == 'mamoom',
                        accentColor: accentColor,
                        onTap: () => setState(() => _selectedRole = 'mamoom'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < bundle.fardPrayers.length; i++)
                  Builder(
                    builder: (_) {
                      final prayer = bundle.fardPrayers[i];
                      final variant = prayer.variantForRole(_selectedRole);
                      final keyId = 'niyyah_fard_${prayer.id}';
                      return KeyedSubtree(
                        key: _keyFor(keyId),
                        child: IbadahAudioCard(
                          orderBadge: '${i + 1}',
                          title: prayer.titleFor(headingLang),
                          subtitle: variant.labelFor(headingLang),
                          badgeText: headingLang == 'ml'
                              ? '${prayer.rakaat} റക്അത്ത്'
                              : '${prayer.rakaat} Raka\'at',
                          badgeColor: accentColor,
                          isHighlighted: true,
                          isJumpFocused: _activeJumpKey == keyId,
                          arabicText: variant.arabic,
                          transliterationMl: variant.transliterationMl,
                          meaningText: variant.meaningFor(lang),
                          audioPath: variant.audioPath,
                          showTransliteration: showTransliteration,
                          showMeaning: showMeaning,
                          showNotes: showNotes,
                          showAudio: showAudio,
                          strings: t,
                          cardBg: palette.cardBg,
                          cardBorder: palette.cardBorder,
                        ),
                      );
                    },
                  ),
              ],

              if (showSunnah) ...[
                const SizedBox(height: 14),
                KeyedSubtree(
                  key: _keyFor('niyyah_sunnah_section'),
                  child: _SectionTitleRow(
                    icon: Icons.auto_awesome_rounded,
                    title: hStrings.sunnahPrayersSection,
                    accentColor: AppBranding.accentGold,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < bundle.sunnahPrayers.length; i++)
                  Builder(
                    builder: (_) {
                      final item = bundle.sunnahPrayers[i];
                      final keyId = 'niyyah_sunnah_${item.id}';
                      return KeyedSubtree(
                        key: _keyFor(keyId),
                        child: IbadahAudioCard(
                          orderBadge: '${bundle.fardPrayers.length + i + 1}',
                          title: item.titleFor(headingLang),
                          badgeText: hStrings.sunnahBadgeLabel,
                          badgeColor: AppBranding.accentGold,
                          isJumpFocused: _activeJumpKey == keyId,
                          arabicText: item.arabic,
                          transliterationMl: item.transliterationMl,
                          meaningText: item.meaningFor(lang),
                          noteText: item.noteFor(lang),
                          audioPath: item.audioPath,
                          showTransliteration: showTransliteration,
                          showMeaning: showMeaning,
                          showNotes: showNotes,
                          showAudio: showAudio,
                          strings: t,
                          cardBg: palette.cardBg,
                          cardBorder: palette.cardBorder,
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 2: COMPLETE SALAH GUIDE
  // ---------------------------------------------------------------------------
  Widget _buildSalahGuideView({
    required AppStrings t,
    required AppStrings hStrings,
    required String lang,
    required String headingLang,
    required bool showTransliteration,
    required bool showMeaning,
    required bool showNotes,
    required bool showAudio,
    required ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahSalahGuideProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahSalahGuideProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final totalSharts = bundle.conditions.length;
        final checkedCount = bundle.conditions
            .where((c) => _checkedSharts.contains(c.id))
            .length;
        final stepsToShow = _fardStepsOnly
            ? bundle.steps.where((s) => s.isFard).toList()
            : bundle.steps;

        final exportItems = <IbadahExportItem>[
          if (bundle.conditions.isNotEmpty)
            IbadahExportItem(
              title: hStrings.shartChecklistTitle,
              badgeText: '$totalSharts',
              meaningText: bundle.conditions
                  .asMap()
                  .entries
                  .map((e) =>
                      '${e.key + 1}. ${e.value.titleFor(headingLang)} — ${e.value.descFor(headingLang)}')
                  .join('\n'),
              footerSource: t.salahGuideTabLabel,
            ),
          if (bundle.arkan.isNotEmpty)
            IbadahExportItem(
              title: hStrings.arkanSectionTitle,
              badgeText: '${bundle.arkan.length}',
              meaningText: bundle.arkan
                  .map((r) => '${r.order}. ${r.titleFor(headingLang)}')
                  .join('\n'),
              footerSource: t.salahGuideTabLabel,
            ),
          for (final step in stepsToShow)
            IbadahExportItem(
              orderBadge: '${step.order}',
              title: step.titleFor(headingLang),
              subtitle: step.postureFor(headingLang),
              badgeText: step.isFard
                  ? hStrings.fardBadgeLabel
                  : hStrings.sunnahBadgeLabel,
              arabicText: step.arabic,
              transliterationMl: step.transliterationMl,
              meaningText: step.meaningFor(lang),
              noteText: step.noteFor(lang),
              footerSource: t.salahGuideTabLabel,
            ),
        ];

        final summaryRows = <_SummaryRowEntry>[
          _SummaryRowEntry(
            label: hStrings.shartChecklistTitle,
            countText: '$totalSharts',
            icon: Icons.checklist_rounded,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'salah_shart',
              beforeJumpStateChange: () => _shartsExpanded = true,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.arkanSectionTitle,
            countText: '${bundle.arkan.length}',
            icon: Icons.foundation_rounded,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'salah_arkan',
              beforeJumpStateChange: () => _arkanExpanded = true,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.stepByStepSalahTitle,
            countText: '${bundle.steps.length}',
            icon: Icons.format_list_numbered_rounded,
            accent: AppBranding.accentGold,
            onTap: () => _jumpToKey(
              'salah_steps_header',
              beforeJumpStateChange:
                  _fardStepsOnly ? () => _fardStepsOnly = false : null,
            ),
          ),
        ];

        final chainNodes = <_ChainNodeEntry>[
          for (final step in bundle.steps)
            _ChainNodeEntry(
              order: step.order,
              label: _cleanStepShortLabel(step.titleFor(headingLang)),
              isPrimary: step.isFard,
              isActive: _activeJumpKey == 'salah_step_${step.order}',
              onTap: () => _jumpToKey(
                'salah_step_${step.order}',
                beforeJumpStateChange: (_fardStepsOnly && !step.isFard)
                    ? () => _fardStepsOnly = false
                    : null,
              ),
            ),
        ];

        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Overview Summary Table
              _IbadahSummaryTable(
                title: hStrings.summaryTableTitle,
                rows: summaryRows,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
                exportPdfLabel: t.exportGuidePdfBtn,
                isExporting: _exportingPdf,
                onExportPdf: () => _exportSectionPdf(
                  items: exportItems,
                  documentTitle: 'Ibadia ${t.salahGuideTabLabel}',
                  showTransliteration: showTransliteration,
                  showMeaning: showMeaning,
                  showNotes: showNotes,
                  strings: t,
                ),
              ),
              const SizedBox(height: 12),

              // Ordered Chain Stepper (1 -> 2 -> ... -> 14)
              _OrderedChainBar(
                title: hStrings.orderedChainTitle,
                nodes: chainNodes,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
              ),
              const SizedBox(height: 14),

              // 1. Shart (Pre-Salah Conditions) Interactive Checklist
              _highlightBox(
                keyId: 'salah_shart',
                accentColor: accentColor,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.cardBorder),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () =>
                            setState(() => _shartsExpanded = !_shartsExpanded),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.13),
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
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '$checkedCount / $totalSharts',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (checkedCount > 0)
                                TextButton(
                                  onPressed: _resetSharts,
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Text(
                                    hStrings.resetChecklistLabel,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              Icon(
                                _shartsExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_shartsExpanded) ...[
                        Divider(height: 1, color: palette.cardBorder),
                        for (int i = 0; i < bundle.conditions.length; i++)
                          Builder(
                            builder: (_) {
                              final cond = bundle.conditions[i];
                              final isChecked = _checkedSharts.contains(cond.id);
                              return CheckboxListTile(
                                value: isChecked,
                                activeColor: accentColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                onChanged: (_) => _toggleShart(cond.id),
                                title: Text(
                                  cond.titleFor(headingLang),
                                  style: TextStyle(
                                    fontSize: 13.5 * uiScale,
                                    fontWeight: FontWeight.w700,
                                    decoration: isChecked
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isChecked
                                        ? cs.onSurfaceVariant
                                        : cs.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  cond.descFor(headingLang),
                                  style: TextStyle(
                                    fontSize: 12 * uiScale,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 2. Arkan (14 Obligatory Pillars) Collapsible Card
              _highlightBox(
                keyId: 'salah_arkan',
                accentColor: accentColor,
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.32),
                    ),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () =>
                            setState(() => _arkanExpanded = !_arkanExpanded),
                        child: Padding(
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
                                  Icons.foundation_rounded,
                                  size: 19,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hStrings.arkanSectionTitle,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Icon(
                                _arkanExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_arkanExpanded) ...[
                        Divider(height: 1, color: palette.cardBorder),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              for (final rukn in bundle.arkan)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 7),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: accentColor
                                              .withValues(alpha: 0.14),
                                          borderRadius:
                                              BorderRadius.circular(7),
                                        ),
                                        child: Text(
                                          '${rukn.order}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            rukn.titleFor(headingLang),
                                            style: TextStyle(
                                              fontSize: 13.2 * uiScale,
                                              fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Step-by-Step Salah Order Header + Filter
              KeyedSubtree(
                key: _keyFor('salah_steps_header'),
                child: _SectionTitleRow(
                  icon: Icons.format_list_numbered_rounded,
                  title: hStrings.stepByStepSalahTitle,
                  accentColor: accentColor,
                  textScale: uiScale,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _FilterChipButton(
                    label: '${hStrings.filterAll} (${bundle.steps.length})',
                    selected: !_fardStepsOnly,
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _fardStepsOnly = false),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label:
                        '${hStrings.fardBadgeLabel} (${bundle.steps.where((s) => s.isFard).length})',
                    selected: _fardStepsOnly,
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _fardStepsOnly = true),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              for (final step in stepsToShow)
                KeyedSubtree(
                  key: _keyFor('salah_step_${step.order}'),
                  child: IbadahAudioCard(
                    orderBadge: '${step.order}',
                    title: step.titleFor(headingLang),
                    subtitle: step.postureFor(headingLang),
                    badgeText: step.isFard
                        ? hStrings.fardBadgeLabel
                        : hStrings.sunnahBadgeLabel,
                    badgeColor:
                        step.isFard ? accentColor : AppBranding.accentGold,
                    isHighlighted: step.isFard,
                    isJumpFocused:
                        _activeJumpKey == 'salah_step_${step.order}',
                    arabicText: step.arabic,
                    transliterationMl: step.transliterationMl,
                    meaningText: step.meaningFor(lang),
                    noteText: step.noteFor(lang),
                    audioPath: step.audioPath,
                    showTransliteration: showTransliteration,
                    showMeaning: showMeaning,
                    showNotes: showNotes,
                    showAudio: showAudio,
                    strings: t,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 3: RAWATIB SUNNAH & RECOMMENDED SURAHS
  // ---------------------------------------------------------------------------
  Widget _buildRawatibAndSurahsView({
    required AppStrings t,
    required AppStrings hStrings,
    required String lang,
    required String headingLang,
    required bool showTransliteration,
    required bool showMeaning,
    required bool showNotes,
    required bool showAudio,
    required ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahSunnahSurahsProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahSunnahSurahsProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final showRawatib =
            _rawatibSection == 'all' || _rawatibSection == 'rawatib';
        final showSurahs =
            _rawatibSection == 'all' || _rawatibSection == 'surahs';
        final totalRawatibRakaat = bundle.rawatib.fold<int>(
          0,
          (sum, g) => sum + g.totalRakaat,
        );

        final exportItems = <IbadahExportItem>[
          if (showRawatib)
            for (final g in bundle.rawatib) ...[
              for (final item in g.before)
                IbadahExportItem(
                  title: '${g.prayerFor(headingLang)} — ${item.timingFor(headingLang)}',
                  subtitle: hStrings.beforePrayerLabel,
                  badgeText: item.isMuakkadah
                      ? hStrings.muakkadahBadgeLabel
                      : hStrings.ghairMuakkadahBadgeLabel,
                  arabicText: item.arabic,
                  transliterationMl: item.transliterationMl,
                  meaningText: item.meaningMl,
                  noteText: item.noteFor(lang),
                  footerSource: t.rawatibTabLabel,
                ),
              for (final item in g.after)
                IbadahExportItem(
                  title: '${g.prayerFor(headingLang)} — ${item.timingFor(headingLang)}',
                  subtitle: hStrings.afterPrayerLabel,
                  badgeText: item.isMuakkadah
                      ? hStrings.muakkadahBadgeLabel
                      : hStrings.ghairMuakkadahBadgeLabel,
                  arabicText: item.arabic,
                  transliterationMl: item.transliterationMl,
                  meaningText: item.meaningMl,
                  noteText: item.noteFor(lang),
                  footerSource: t.rawatibTabLabel,
                ),
            ],
          if (showSurahs)
            for (final g in bundle.recommendedSurahs)
              IbadahExportItem(
                title: g.occasionFor(headingLang),
                badgeText: hStrings.recommendedSurahsTitle,
                meaningText: g.surahs
                    .map((s) =>
                        '${s.surahNumber}. ${s.nameFor(headingLang)} (${s.nameAr}) · ${s.tagFor(headingLang)}')
                    .join('\n'),
                noteText: g.reasonFor(lang),
                footerSource: t.rawatibTabLabel,
              ),
        ];

        final summaryRows = <_SummaryRowEntry>[
          _SummaryRowEntry(
            label: hStrings.rawatibScheduleTitle,
            countText: '${bundle.rawatib.length} ($totalRawatibRakaat R)',
            icon: Icons.schedule_rounded,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'rawatib_section',
              beforeJumpStateChange: _rawatibSection == 'surahs'
                  ? () => _rawatibSection = 'all'
                  : null,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.recommendedSurahsTitle,
            countText: '${bundle.recommendedSurahs.length}',
            icon: Icons.menu_book_rounded,
            accent: AppBranding.accentGold,
            onTap: () => _jumpToKey(
              'surahs_section',
              beforeJumpStateChange: _rawatibSection == 'rawatib'
                  ? () => _rawatibSection = 'all'
                  : null,
            ),
          ),
        ];

        final chainNodes = <_ChainNodeEntry>[
          for (int i = 0; i < bundle.rawatib.length; i++)
            _ChainNodeEntry(
              order: i + 1,
              label: _cleanStepShortLabel(
                bundle.rawatib[i].prayerFor(headingLang),
              ),
              isPrimary: true,
              isActive: _activeJumpKey ==
                  'rawatib_group_${bundle.rawatib[i].prayerId}',
              onTap: () => _jumpToKey(
                'rawatib_group_${bundle.rawatib[i].prayerId}',
                beforeJumpStateChange: _rawatibSection == 'surahs'
                    ? () => _rawatibSection = 'all'
                    : null,
              ),
            ),
          for (int i = 0; i < bundle.recommendedSurahs.length; i++)
            _ChainNodeEntry(
              order: bundle.rawatib.length + i + 1,
              label: _cleanStepShortLabel(
                bundle.recommendedSurahs[i].occasionFor(headingLang),
              ),
              isPrimary: false,
              isActive: _activeJumpKey == 'surah_group_$i',
              onTap: () => _jumpToKey(
                'surah_group_$i',
                beforeJumpStateChange: _rawatibSection == 'rawatib'
                    ? () => _rawatibSection = 'all'
                    : null,
              ),
            ),
        ];

        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IbadahSummaryTable(
                title: hStrings.summaryTableTitle,
                rows: summaryRows,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
                exportPdfLabel: t.exportGuidePdfBtn,
                isExporting: _exportingPdf,
                onExportPdf: () => _exportSectionPdf(
                  items: exportItems,
                  documentTitle: 'Ibadia ${t.rawatibTabLabel}',
                  showTransliteration: showTransliteration,
                  showMeaning: showMeaning,
                  showNotes: showNotes,
                  strings: t,
                ),
              ),
              const SizedBox(height: 12),
              _OrderedChainBar(
                title: hStrings.orderedChainTitle,
                nodes: chainNodes,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
              ),
              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipButton(
                      label: hStrings.filterAll,
                      selected: _rawatibSection == 'all',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _rawatibSection = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: hStrings.rawatibScheduleTitle,
                      selected: _rawatibSection == 'rawatib',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _rawatibSection = 'rawatib'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: hStrings.recommendedSurahsTitle,
                      selected: _rawatibSection == 'surahs',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _rawatibSection = 'surahs'),
                    ),
                  ],
                ),
              ),

              if (showRawatib) ...[
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _keyFor('rawatib_section'),
                  child: _SectionTitleRow(
                    icon: Icons.schedule_rounded,
                    title: hStrings.rawatibScheduleTitle,
                    accentColor: accentColor,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (final group in bundle.rawatib)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _highlightBox(
                      keyId: 'rawatib_group_${group.prayerId}',
                      accentColor: accentColor,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: palette.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.prayerFor(headingLang),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    headingLang == 'ml'
                                        ? '${group.totalRakaat} റക്അത്ത്'
                                        : '${group.totalRakaat} Raka\'at',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (group.before.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                hStrings.beforePrayerLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (final item in group.before)
                                IbadahAudioCard(
                                  title: item.timingFor(headingLang),
                                  badgeText: item.isMuakkadah
                                      ? hStrings.muakkadahBadgeLabel
                                      : hStrings.ghairMuakkadahBadgeLabel,
                                  badgeColor: item.isMuakkadah
                                      ? accentColor
                                      : AppBranding.accentGold,
                                  isHighlighted: item.isMuakkadah,
                                  arabicText: item.arabic,
                                  transliterationMl: item.transliterationMl,
                                  meaningText: item.meaningMl,
                                  noteText: item.noteFor(lang),
                                  audioPath: item.audioPath,
                                  showTransliteration: showTransliteration,
                                  showMeaning: showMeaning,
                                  showNotes: showNotes,
                                  showAudio: showAudio,
                                  strings: t,
                                  cardBg: palette.cardBg,
                                  cardBorder: palette.cardBorder,
                                ),
                            ],
                            if (group.after.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                hStrings.afterPrayerLabel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: AppBranding.accentGold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (final item in group.after)
                                IbadahAudioCard(
                                  title: item.timingFor(headingLang),
                                  badgeText: item.isMuakkadah
                                      ? hStrings.muakkadahBadgeLabel
                                      : hStrings.ghairMuakkadahBadgeLabel,
                                  badgeColor: item.isMuakkadah
                                      ? accentColor
                                      : AppBranding.accentGold,
                                  isHighlighted: item.isMuakkadah,
                                  arabicText: item.arabic,
                                  transliterationMl: item.transliterationMl,
                                  meaningText: item.meaningMl,
                                  noteText: item.noteFor(lang),
                                  audioPath: item.audioPath,
                                  showTransliteration: showTransliteration,
                                  showMeaning: showMeaning,
                                  showNotes: showNotes,
                                  showAudio: showAudio,
                                  strings: t,
                                  cardBg: palette.cardBg,
                                  cardBorder: palette.cardBorder,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],

              if (showSurahs) ...[
                const SizedBox(height: 8),
                KeyedSubtree(
                  key: _keyFor('surahs_section'),
                  child: _SectionTitleRow(
                    icon: Icons.menu_book_rounded,
                    title: hStrings.recommendedSurahsTitle,
                    accentColor: AppBranding.accentGold,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < bundle.recommendedSurahs.length; i++)
                  Builder(
                    builder: (_) {
                      final group = bundle.recommendedSurahs[i];
                      final keyId = 'surah_group_$i';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _highlightBox(
                          keyId: keyId,
                          accentColor: AppBranding.accentGold,
                          child: Container(
                            padding: const EdgeInsets.all(14),
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
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (showNotes) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    group.reasonFor(lang),
                                    style: TextStyle(
                                      fontSize: 12.8,
                                      height: 1.45,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final surah in group.surahs)
                                      Material(
                                        color:
                                            accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: widget.onOpenSurah == null
                                              ? null
                                              : () => widget.onOpenSurah!(
                                                  surah.surahNumber),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 11,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: accentColor.withValues(
                                                    alpha: 0.28),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${surah.surahNumber}. ${surah.nameFor(headingLang)}',
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: cs.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  surah.nameAr,
                                                  style: GoogleFonts.amiri(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '· ${surah.tagFor(headingLang)}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: cs.onSurfaceVariant,
                                                  ),
                                                ),
                                                if (widget.onOpenSurah !=
                                                    null) ...[
                                                  const SizedBox(width: 5),
                                                  Icon(
                                                    Icons.open_in_new_rounded,
                                                    size: 13.5,
                                                    color: accentColor,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 4: MAYYITH (FUNERAL PRAYER & PREPARATION GUIDE)
  // ---------------------------------------------------------------------------
  Widget _buildMayyithView({
    required AppStrings t,
    required AppStrings hStrings,
    required String lang,
    required String headingLang,
    required bool showTransliteration,
    required bool showMeaning,
    required bool showNotes,
    required bool showAudio,
    required ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    required double hPad,
    required double uiScale,
    required Color accentColor,
    required ColorScheme cs,
  }) {
    final asyncBundle = ref.watch(ibadahMayyithProvider);
    return asyncBundle.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _ErrorNotice(
        message: t.loadError,
        onRetry: () => ref.invalidate(ibadahMayyithProvider),
        retryLabel: t.retry,
      ),
      data: (bundle) {
        final showPrep = _mayyithSection == 'all' || _mayyithSection == 'prep';
        final showNiyyah =
            _mayyithSection == 'all' || _mayyithSection == 'niyyah';
        final showTakbirs =
            _mayyithSection == 'all' || _mayyithSection == 'takbirs';
        final showBurial =
            _mayyithSection == 'all' || _mayyithSection == 'burial';

        final exportItems = <IbadahExportItem>[
          if (showPrep)
            for (int i = 0; i < bundle.preparationStages.length; i++)
              IbadahExportItem(
                orderBadge: '${i + 1}',
                title: bundle.preparationStages[i].titleFor(headingLang),
                badgeText: headingLang == 'ml' ? 'ശാഫിഈ' : 'Shafi\'i',
                arabicText: bundle.preparationStages[i].arabic,
                transliterationMl: bundle.preparationStages[i].transliterationMl,
                meaningText: bundle.preparationStages[i].meaningMl,
                noteText: bundle.preparationStages[i]
                    .pointsFor(headingLang)
                    .map((p) => '• $p')
                    .join('\n'),
                footerSource: t.mayyithTabLabel,
              ),
          if (showNiyyah)
            for (int i = 0; i < bundle.niyyah.length; i++)
              IbadahExportItem(
                orderBadge: '${i + 1}',
                title: bundle.niyyah[i].titleFor(headingLang),
                badgeText: hStrings.fardBadgeLabel,
                arabicText: bundle.niyyah[i].arabic,
                transliterationMl: bundle.niyyah[i].transliterationMl,
                meaningText: bundle.niyyah[i].meaningFor(lang),
                footerSource: t.mayyithTabLabel,
              ),
          if (showTakbirs)
            for (final step in bundle.takbirs)
              IbadahExportItem(
                orderBadge: '${step.takbirNumber}',
                title: step.titleFor(headingLang),
                badgeText: headingLang == 'ml'
                    ? 'തക്ബീർ ${step.takbirNumber}'
                    : 'Takbir ${step.takbirNumber}',
                arabicText: step.arabic,
                transliterationMl: step.transliterationMl,
                meaningText: step.meaningFor(lang),
                noteText: step.noteFor(lang),
                footerSource: t.mayyithTabLabel,
              ),
          if (showBurial)
            for (int i = 0; i < bundle.burialAndTalqeen.length; i++)
              IbadahExportItem(
                orderBadge: '${i + 1}',
                title: bundle.burialAndTalqeen[i].titleFor(headingLang),
                arabicText: bundle.burialAndTalqeen[i].arabic,
                transliterationMl: bundle.burialAndTalqeen[i].transliterationMl,
                meaningText: bundle.burialAndTalqeen[i].meaningMl,
                noteText: bundle.burialAndTalqeen[i].noteFor(lang),
                footerSource: t.mayyithTabLabel,
              ),
        ];

        final summaryRows = <_SummaryRowEntry>[
          _SummaryRowEntry(
            label: hStrings.mayyithPrepTitle,
            countText: '${bundle.preparationStages.length}',
            icon: Icons.medical_services_outlined,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'mayyith_prep',
              beforeJumpStateChange: (_mayyithSection != 'all' &&
                      _mayyithSection != 'prep')
                  ? () => _mayyithSection = 'all'
                  : null,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.mayyithNiyyahTitle,
            countText: '${bundle.niyyah.length}',
            icon: Icons.record_voice_over_rounded,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'mayyith_niyyah',
              beforeJumpStateChange: (_mayyithSection != 'all' &&
                      _mayyithSection != 'niyyah')
                  ? () => _mayyithSection = 'all'
                  : null,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.mayyithTakbirsTitle,
            countText: '${bundle.takbirs.length}',
            icon: Icons.looks_4_rounded,
            accent: AppBranding.accentGold,
            onTap: () => _jumpToKey(
              'mayyith_takbirs',
              beforeJumpStateChange: (_mayyithSection != 'all' &&
                      _mayyithSection != 'takbirs')
                  ? () => _mayyithSection = 'all'
                  : null,
            ),
          ),
          _SummaryRowEntry(
            label: hStrings.mayyithBurialTitle,
            countText: '${bundle.burialAndTalqeen.length}',
            icon: Icons.volunteer_activism_rounded,
            accent: accentColor,
            onTap: () => _jumpToKey(
              'mayyith_burial',
              beforeJumpStateChange: (_mayyithSection != 'all' &&
                      _mayyithSection != 'burial')
                  ? () => _mayyithSection = 'all'
                  : null,
            ),
          ),
        ];

        final chainNodes = <_ChainNodeEntry>[];
        int nodeOrder = 1;
        for (final stage in bundle.preparationStages) {
          final id = 'mayyith_prep_${stage.id}';
          chainNodes.add(
            _ChainNodeEntry(
              order: nodeOrder++,
              label: _cleanStepShortLabel(stage.titleFor(headingLang)),
              isPrimary: true,
              isActive: _activeJumpKey == id,
              onTap: () => _jumpToKey(
                id,
                beforeJumpStateChange: (_mayyithSection != 'all' &&
                        _mayyithSection != 'prep')
                    ? () => _mayyithSection = 'all'
                    : null,
              ),
            ),
          );
        }
        if (bundle.niyyah.isNotEmpty) {
          chainNodes.add(
            _ChainNodeEntry(
              order: nodeOrder++,
              label: hStrings.niyyahTabLabel,
              isPrimary: true,
              isActive: _activeJumpKey == 'mayyith_niyyah',
              onTap: () => _jumpToKey(
                'mayyith_niyyah',
                beforeJumpStateChange: (_mayyithSection != 'all' &&
                        _mayyithSection != 'niyyah')
                    ? () => _mayyithSection = 'all'
                    : null,
              ),
            ),
          );
        }
        for (final step in bundle.takbirs) {
          final id = 'mayyith_takbir_${step.takbirNumber}';
          chainNodes.add(
            _ChainNodeEntry(
              order: nodeOrder++,
              label: _cleanStepShortLabel(step.titleFor(headingLang)),
              isPrimary: false,
              isActive: _activeJumpKey == id,
              onTap: () => _jumpToKey(
                id,
                beforeJumpStateChange: (_mayyithSection != 'all' &&
                        _mayyithSection != 'takbirs')
                    ? () => _mayyithSection = 'all'
                    : null,
              ),
            ),
          );
        }
        for (final item in bundle.burialAndTalqeen) {
          final id = 'mayyith_burial_${item.id}';
          chainNodes.add(
            _ChainNodeEntry(
              order: nodeOrder++,
              label: _cleanStepShortLabel(item.titleFor(headingLang)),
              isPrimary: true,
              isActive: _activeJumpKey == id,
              onTap: () => _jumpToKey(
                id,
                beforeJumpStateChange: (_mayyithSection != 'all' &&
                        _mayyithSection != 'burial')
                    ? () => _mayyithSection = 'all'
                    : null,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _IbadahSummaryTable(
                title: hStrings.summaryTableTitle,
                rows: summaryRows,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
                exportPdfLabel: t.exportGuidePdfBtn,
                isExporting: _exportingPdf,
                onExportPdf: () => _exportSectionPdf(
                  items: exportItems,
                  documentTitle: 'Ibadia ${t.mayyithTabLabel}',
                  showTransliteration: showTransliteration,
                  showMeaning: showMeaning,
                  showNotes: showNotes,
                  strings: t,
                ),
              ),
              const SizedBox(height: 12),
              _OrderedChainBar(
                title: hStrings.orderedChainTitle,
                nodes: chainNodes,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
                accentColor: accentColor,
                textScale: uiScale,
              ),
              const SizedBox(height: 14),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipButton(
                      label: hStrings.filterAll,
                      selected: _mayyithSection == 'all',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _mayyithSection = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: hStrings.mayyithPrepTitle,
                      selected: _mayyithSection == 'prep',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _mayyithSection = 'prep'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: hStrings.niyyahTabLabel,
                      selected: _mayyithSection == 'niyyah',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _mayyithSection = 'niyyah'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: hStrings.mayyithTakbirsTitle,
                      selected: _mayyithSection == 'takbirs',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _mayyithSection = 'takbirs'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChipButton(
                      label: hStrings.mayyithBurialTitle,
                      selected: _mayyithSection == 'burial',
                      accentColor: accentColor,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                      onTap: () => setState(() => _mayyithSection = 'burial'),
                    ),
                  ],
                ),
              ),

              if (showPrep) ...[
                const SizedBox(height: 16),
                KeyedSubtree(
                  key: _keyFor('mayyith_prep'),
                  child: _SectionTitleRow(
                    icon: Icons.medical_services_outlined,
                    title: hStrings.mayyithPrepTitle,
                    accentColor: accentColor,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < bundle.preparationStages.length; i++)
                  Builder(
                    builder: (_) {
                      final stage = bundle.preparationStages[i];
                      final keyId = 'mayyith_prep_${stage.id}';
                      return KeyedSubtree(
                        key: _keyFor(keyId),
                        child: IbadahAudioCard(
                          orderBadge: '${i + 1}',
                          title: stage.titleFor(headingLang),
                          badgeText: headingLang == 'ml' ? 'ശാഫിഈ' : 'Shafi\'i',
                          badgeColor: accentColor,
                          isJumpFocused: _activeJumpKey == keyId,
                          arabicText: stage.arabic,
                          transliterationMl: stage.transliterationMl,
                          meaningText: stage.meaningMl,
                          audioPath: stage.audioPath,
                          showTransliteration: showTransliteration,
                          showMeaning: showMeaning,
                          showNotes: showNotes,
                          showAudio: showAudio,
                          strings: t,
                          cardBg: palette.cardBg,
                          cardBorder: palette.cardBorder,
                          footerExtra: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final pt in stage.pointsFor(headingLang))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
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
                                            fontSize: 13.2,
                                            height: 1.5,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],

              if (showNiyyah) ...[
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _keyFor('mayyith_niyyah'),
                  child: _SectionTitleRow(
                    icon: Icons.record_voice_over_rounded,
                    title: hStrings.mayyithNiyyahTitle,
                    accentColor: accentColor,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < bundle.niyyah.length; i++)
                  Builder(
                    builder: (_) {
                      final item = bundle.niyyah[i];
                      final keyId = 'mayyith_niyyah_${item.id}';
                      return KeyedSubtree(
                        key: _keyFor(keyId),
                        child: IbadahAudioCard(
                          orderBadge: '${i + 1}',
                          title: item.titleFor(headingLang),
                          badgeText: hStrings.fardBadgeLabel,
                          badgeColor: accentColor,
                          isJumpFocused: _activeJumpKey == keyId,
                          arabicText: item.arabic,
                          transliterationMl: item.transliterationMl,
                          meaningText: item.meaningFor(lang),
                          audioPath: item.audioPath,
                          showTransliteration: showTransliteration,
                          showMeaning: showMeaning,
                          showNotes: showNotes,
                          showAudio: showAudio,
                          strings: t,
                          cardBg: palette.cardBg,
                          cardBorder: palette.cardBorder,
                        ),
                      );
                    },
                  ),
              ],

              if (showTakbirs) ...[
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _keyFor('mayyith_takbirs'),
                  child: _SectionTitleRow(
                    icon: Icons.looks_4_rounded,
                    title: hStrings.mayyithTakbirsTitle,
                    accentColor: AppBranding.accentGold,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (final step in bundle.takbirs)
                  Builder(
                    builder: (_) {
                      final keyId = 'mayyith_takbir_${step.takbirNumber}';
                      return KeyedSubtree(
                        key: _keyFor(keyId),
                        child: IbadahAudioCard(
                          orderBadge: '${step.takbirNumber}',
                          title: step.titleFor(headingLang),
                          badgeText: headingLang == 'ml'
                              ? 'തക്ബീർ ${step.takbirNumber}'
                              : 'Takbir ${step.takbirNumber}',
                          badgeColor: AppBranding.accentGold,
                          isHighlighted: true,
                          isJumpFocused: _activeJumpKey == keyId,
                          arabicText: step.arabic,
                          transliterationMl: step.transliterationMl,
                          meaningText: step.meaningFor(lang),
                          noteText: step.noteFor(lang),
                          audioPath: step.audioPath,
                          showTransliteration: showTransliteration,
                          showMeaning: showMeaning,
                          showNotes: showNotes,
                          showAudio: showAudio,
                          strings: t,
                          cardBg: palette.cardBg,
                          cardBorder: palette.cardBorder,
                        ),
                      );
                    },
                  ),
              ],

              if (showBurial) ...[
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: _keyFor('mayyith_burial'),
                  child: _SectionTitleRow(
                    icon: Icons.volunteer_activism_rounded,
                    title: hStrings.mayyithBurialTitle,
                    accentColor: accentColor,
                    textScale: uiScale,
                  ),
                ),
                const SizedBox(height: 10),
                for (int i = 0; i < bundle.burialAndTalqeen.length; i++)
                  Builder(
                    builder: (_) {
                      final item = bundle.burialAndTalqeen[i];
                      final keyId = 'mayyith_burial_${item.id}';
                      return KeyedSubtree(
                        key: _keyFor(keyId),
                        child: IbadahAudioCard(
                          orderBadge: '${i + 1}',
                          title: item.titleFor(headingLang),
                          isJumpFocused: _activeJumpKey == keyId,
                          arabicText: item.arabic,
                          transliterationMl: item.transliterationMl,
                          meaningText: item.meaningMl,
                          noteText: item.noteFor(lang),
                          audioPath: item.audioPath,
                          showTransliteration: showTransliteration,
                          showMeaning: showMeaning,
                          showNotes: showNotes,
                          showAudio: showAudio,
                          strings: t,
                          cardBg: palette.cardBg,
                          cardBorder: palette.cardBorder,
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRowEntry {
  final String label;
  final String countText;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _SummaryRowEntry({
    required this.label,
    required this.countText,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}

class _IbadahSummaryTable extends StatelessWidget {
  final String title;
  final List<_SummaryRowEntry> rows;
  final Color cardBg;
  final Color cardBorder;
  final Color accentColor;
  final double textScale;
  final VoidCallback? onExportPdf;
  final String? exportPdfLabel;
  final bool isExporting;

  const _IbadahSummaryTable({
    required this.title,
    required this.rows,
    required this.cardBg,
    required this.cardBorder,
    required this.accentColor,
    this.textScale = 1.0,
    this.onExportPdf,
    this.exportPdfLabel,
    this.isExporting = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.09),
              border: Border(bottom: BorderSide(color: cardBorder)),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart_rounded, size: 16 * textScale, color: accentColor),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.2 * textScale,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
                if (onExportPdf != null && exportPdfLabel != null)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isExporting ? null : onExportPdf,
                    icon: isExporting
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor,
                            ),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 15),
                    label: Text(
                      exportPdfLabel!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: cardBorder),
            InkWell(
              onTap: rows[i].onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(rows[i].icon, size: 17 * textScale, color: rows[i].accent),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        rows[i].label,
                        style: TextStyle(
                          fontSize: 12.8 * textScale,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rows[i].accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rows[i].countText,
                        style: TextStyle(
                          fontSize: 11.5 * textScale,
                          fontWeight: FontWeight.w800,
                          color: rows[i].accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChainNodeEntry {
  final int order;
  final String label;
  final bool isPrimary;
  final bool isActive;
  final VoidCallback onTap;

  const _ChainNodeEntry({
    required this.order,
    required this.label,
    required this.isPrimary,
    required this.isActive,
    required this.onTap,
  });
}

class _OrderedChainBar extends StatelessWidget {
  final String title;
  final List<_ChainNodeEntry> nodes;
  final Color cardBg;
  final Color cardBorder;
  final Color accentColor;
  final double textScale;

  const _OrderedChainBar({
    required this.title,
    required this.nodes,
    required this.cardBg,
    required this.cardBorder,
    required this.accentColor,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (nodes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.linear_scale_rounded, size: 16 * textScale, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12 * textScale,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < nodes.length; i++) ...[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                      ),
                    ),
                  Builder(
                    builder: (_) {
                      final node = nodes[i];
                      final nodeAccent = node.isPrimary
                          ? accentColor
                          : AppBranding.accentGold;
                      return Material(
                        color: node.isActive
                            ? nodeAccent
                            : nodeAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(11),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: node.onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: node.isActive
                                    ? nodeAccent
                                    : nodeAccent.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: node.isActive
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : nodeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${node.order}',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontFeatures: [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  node.label,
                                  style: TextStyle(
                                    fontSize: 11.5 * textScale,
                                    fontWeight: FontWeight.w700,
                                    color: node.isActive
                                        ? Colors.white
                                        : cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final double textScale;

  const _SectionTitleRow({
    required this.icon,
    required this.title,
    required this.accentColor,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19 * textScale, color: accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16 * textScale,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.cardBg,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? accentColor : cardBg,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? accentColor : cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

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
            padding: const EdgeInsets.symmetric(vertical: 8),
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
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
