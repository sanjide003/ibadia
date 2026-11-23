import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/ibadah_models.dart';
import '../providers/quran_providers.dart';
import '../services/ibadah_audio_controller.dart';
import '../services/ibadah_data_service.dart';
import '../widgets/ibadah_audio_card.dart';

class IbadahGuideScreen extends ConsumerStatefulWidget {
  final void Function(int surahNo)? onOpenSurah;

  const IbadahGuideScreen({
    super.key,
    this.onOpenSurah,
  });

  @override
  ConsumerState<IbadahGuideScreen> createState() => _IbadahGuideScreenState();
}

class _IbadahGuideScreenState extends ConsumerState<IbadahGuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPersistedSharts();
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
    IbadahAudioController.instance.stopOnDispose();
    _tabController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _palette(context, settings.themeMode);
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;
    final hPad = math.max(16.0, (MediaQuery.sizeOf(context).width - 960) / 2);

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

    return Column(
      children: [
        // Sub-header pill TabBar matching Ibadia Material 3 styling
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 10),
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
                      t.ibadahFiqhSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: palette.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.cardBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  labelStyle: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: t.niyyahTabLabel, height: 36),
                    Tab(text: t.salahGuideTabLabel, height: 36),
                    Tab(text: t.rawatibTabLabel, height: 36),
                    Tab(text: t.mayyithTabLabel, height: 36),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNiyyahTab(t, lang, palette, hPad, accentColor, cs),
              _buildSalahGuideTab(t, lang, palette, hPad, accentColor, cs),
              _buildRawatibAndSurahsTab(
                  t, lang, palette, hPad, accentColor, cs),
              _buildMayyithTab(t, lang, palette, hPad, accentColor, cs),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: NIYYAH (INTENTIONS)
  // ---------------------------------------------------------------------------
  Widget _buildNiyyahTab(
    AppStrings t,
    String lang,
    ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    double hPad,
    Color accentColor,
    ColorScheme cs,
  ) {
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

        return ListView(
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 28),
          children: [
            // Scope Filter Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: t.filterAll,
                    selected: _niyyahScope == 'all',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _niyyahScope = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: '${t.fardBadgeLabel} (5)',
                    selected: _niyyahScope == 'fard',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _niyyahScope = 'fard'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: '${t.sunnahBadgeLabel} (${bundle.sunnahPrayers.length})',
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
              _SectionTitleRow(
                icon: Icons.mosque_rounded,
                title: t.fardPrayersSection,
                accentColor: accentColor,
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
                      label: t.roleMunfarid,
                      selected: _selectedRole == 'munfarid',
                      accentColor: accentColor,
                      onTap: () => setState(() => _selectedRole = 'munfarid'),
                    ),
                    _RoleSegmentButton(
                      label: t.roleImam,
                      selected: _selectedRole == 'imam',
                      accentColor: accentColor,
                      onTap: () => setState(() => _selectedRole = 'imam'),
                    ),
                    _RoleSegmentButton(
                      label: t.roleMamoom,
                      selected: _selectedRole == 'mamoom',
                      accentColor: accentColor,
                      onTap: () => setState(() => _selectedRole = 'mamoom'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final prayer in bundle.fardPrayers)
                Builder(
                  builder: (_) {
                    final variant = prayer.variantForRole(_selectedRole);
                    return IbadahAudioCard(
                      title: prayer.titleFor(lang),
                      subtitle: variant.labelFor(lang),
                      badgeText: '${prayer.rakaat} Raka\'at',
                      badgeColor: accentColor,
                      isHighlighted: true,
                      arabicText: variant.arabic,
                      transliterationMl: variant.transliterationMl,
                      meaningText: variant.meaningFor(lang),
                      audioPath: variant.audioPath,
                      strings: t,
                      cardBg: palette.cardBg,
                      cardBorder: palette.cardBorder,
                    );
                  },
                ),
            ],

            if (showSunnah) ...[
              const SizedBox(height: 14),
              _SectionTitleRow(
                icon: Icons.auto_awesome_rounded,
                title: t.sunnahPrayersSection,
                accentColor: AppBranding.accentGold,
              ),
              const SizedBox(height: 10),
              for (final item in bundle.sunnahPrayers)
                IbadahAudioCard(
                  title: item.titleFor(lang),
                  badgeText: t.sunnahBadgeLabel,
                  badgeColor: AppBranding.accentGold,
                  arabicText: item.arabic,
                  transliterationMl: item.transliterationMl,
                  meaningText: item.meaningFor(lang),
                  noteText: item.noteFor(lang),
                  audioPath: item.audioPath,
                  strings: t,
                  cardBg: palette.cardBg,
                  cardBorder: palette.cardBorder,
                ),
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: COMPLETE SALAH GUIDE
  // ---------------------------------------------------------------------------
  Widget _buildSalahGuideTab(
    AppStrings t,
    String lang,
    ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    double hPad,
    Color accentColor,
    ColorScheme cs,
  ) {
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

        return ListView(
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 28),
          children: [
            // 1. Shart (Pre-Salah Conditions) Interactive Checklist
            Container(
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
                                  t.shartChecklistTitle,
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
                                t.resetChecklistLabel,
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
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            onChanged: (_) => _toggleShart(cond.id),
                            title: Text(
                              cond.titleFor(lang),
                              style: TextStyle(
                                fontSize: 13.5,
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
                              cond.descFor(lang),
                              style: TextStyle(
                                fontSize: 12,
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

            const SizedBox(height: 12),

            // 2. Arkan (13 Obligatory Pillars) Collapsible Card
            Container(
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
                              t.arkanSectionTitle,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(7),
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
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        rukn.titleFor(lang),
                                        style: const TextStyle(
                                          fontSize: 13.2,
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

            const SizedBox(height: 16),

            // 3. Step-by-Step Salah Order Header + Filter
            Row(
              children: [
                Expanded(
                  child: _SectionTitleRow(
                    icon: Icons.format_list_numbered_rounded,
                    title: t.stepByStepSalahTitle,
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _FilterChipButton(
                  label: '${t.filterAll} (${bundle.steps.length})',
                  selected: !_fardStepsOnly,
                  accentColor: accentColor,
                  cardBg: palette.cardBg,
                  cardBorder: palette.cardBorder,
                  onTap: () => setState(() => _fardStepsOnly = false),
                ),
                const SizedBox(width: 8),
                _FilterChipButton(
                  label:
                      '${t.fardBadgeLabel} (${bundle.steps.where((s) => s.isFard).length})',
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
              IbadahAudioCard(
                orderBadge: '${step.order}',
                title: step.titleFor(lang),
                subtitle: step.postureFor(lang),
                badgeText:
                    step.isFard ? t.fardBadgeLabel : t.sunnahBadgeLabel,
                badgeColor:
                    step.isFard ? accentColor : AppBranding.accentGold,
                isHighlighted: step.isFard,
                arabicText: step.arabic,
                transliterationMl: step.transliterationMl,
                meaningText: step.meaningFor(lang),
                noteText: step.noteFor(lang),
                audioPath: step.audioPath,
                strings: t,
                cardBg: palette.cardBg,
                cardBorder: palette.cardBorder,
              ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: RAWATIB SUNNAH & RECOMMENDED SURAHS
  // ---------------------------------------------------------------------------
  Widget _buildRawatibAndSurahsTab(
    AppStrings t,
    String lang,
    ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    double hPad,
    Color accentColor,
    ColorScheme cs,
  ) {
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

        return ListView(
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 28),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: t.filterAll,
                    selected: _rawatibSection == 'all',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _rawatibSection = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: t.rawatibScheduleTitle,
                    selected: _rawatibSection == 'rawatib',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _rawatibSection = 'rawatib'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: t.recommendedSurahsTitle,
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
              _SectionTitleRow(
                icon: Icons.schedule_rounded,
                title: t.rawatibScheduleTitle,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              for (final group in bundle.rawatib) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                              group.prayerFor(lang),
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
                              '${group.totalRakaat} Raka\'at',
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
                          t.beforePrayerLabel.toUpperCase(),
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
                            title: item.timingFor(lang),
                            badgeText: item.isMuakkadah
                                ? t.muakkadahBadgeLabel
                                : t.ghairMuakkadahBadgeLabel,
                            badgeColor: item.isMuakkadah
                                ? accentColor
                                : AppBranding.accentGold,
                            isHighlighted: item.isMuakkadah,
                            arabicText: item.arabic,
                            transliterationMl: item.transliterationMl,
                            meaningText: item.meaningMl,
                            noteText: item.noteFor(lang),
                            audioPath: item.audioPath,
                            strings: t,
                            cardBg: palette.cardBg,
                            cardBorder: palette.cardBorder,
                          ),
                      ],
                      if (group.after.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.afterPrayerLabel.toUpperCase(),
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
                            title: item.timingFor(lang),
                            badgeText: item.isMuakkadah
                                ? t.muakkadahBadgeLabel
                                : t.ghairMuakkadahBadgeLabel,
                            badgeColor: item.isMuakkadah
                                ? accentColor
                                : AppBranding.accentGold,
                            isHighlighted: item.isMuakkadah,
                            arabicText: item.arabic,
                            transliterationMl: item.transliterationMl,
                            meaningText: item.meaningMl,
                            noteText: item.noteFor(lang),
                            audioPath: item.audioPath,
                            strings: t,
                            cardBg: palette.cardBg,
                            cardBorder: palette.cardBorder,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],

            if (showSurahs) ...[
              const SizedBox(height: 8),
              _SectionTitleRow(
                icon: Icons.menu_book_rounded,
                title: t.recommendedSurahsTitle,
                accentColor: AppBranding.accentGold,
              ),
              const SizedBox(height: 10),
              for (final group in bundle.recommendedSurahs)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                        group.occasionFor(lang),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.reasonFor(lang),
                        style: TextStyle(
                          fontSize: 12.8,
                          height: 1.45,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final surah in group.surahs)
                            Material(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
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
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: accentColor.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${surah.surahNumber}. ${surah.nameFor(lang)}',
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
                                        '· ${surah.tagFor(lang)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      if (widget.onOpenSurah != null) ...[
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
            ],
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 4: MAYYITH (FUNERAL PRAYER & PREPARATION GUIDE)
  // ---------------------------------------------------------------------------
  Widget _buildMayyithTab(
    AppStrings t,
    String lang,
    ({Color cardBg, Color cardBorder, Color tabBarBg}) palette,
    double hPad,
    Color accentColor,
    ColorScheme cs,
  ) {
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

        return ListView(
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 28),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChipButton(
                    label: t.filterAll,
                    selected: _mayyithSection == 'all',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _mayyithSection = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: t.mayyithPrepTitle,
                    selected: _mayyithSection == 'prep',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _mayyithSection = 'prep'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: t.niyyahTabLabel,
                    selected: _mayyithSection == 'niyyah',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _mayyithSection = 'niyyah'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: t.mayyithTakbirsTitle,
                    selected: _mayyithSection == 'takbirs',
                    accentColor: accentColor,
                    cardBg: palette.cardBg,
                    cardBorder: palette.cardBorder,
                    onTap: () => setState(() => _mayyithSection = 'takbirs'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChipButton(
                    label: t.mayyithBurialTitle,
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
              _SectionTitleRow(
                icon: Icons.medical_services_outlined,
                title: t.mayyithPrepTitle,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              for (final stage in bundle.preparationStages)
                IbadahAudioCard(
                  title: stage.titleFor(lang),
                  badgeText: 'Shafi\'i',
                  badgeColor: accentColor,
                  arabicText: stage.arabic,
                  transliterationMl: stage.transliterationMl,
                  meaningText: stage.meaningMl,
                  audioPath: stage.audioPath,
                  strings: t,
                  cardBg: palette.cardBg,
                  cardBorder: palette.cardBorder,
                  footerExtra: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final pt in stage.pointsFor(lang))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
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
            ],

            if (showNiyyah) ...[
              const SizedBox(height: 12),
              _SectionTitleRow(
                icon: Icons.record_voice_over_rounded,
                title: t.mayyithNiyyahTitle,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              for (final item in bundle.niyyah)
                IbadahAudioCard(
                  title: item.titleFor(lang),
                  badgeText: t.fardBadgeLabel,
                  badgeColor: accentColor,
                  arabicText: item.arabic,
                  transliterationMl: item.transliterationMl,
                  meaningText: item.meaningFor(lang),
                  audioPath: item.audioPath,
                  strings: t,
                  cardBg: palette.cardBg,
                  cardBorder: palette.cardBorder,
                ),
            ],

            if (showTakbirs) ...[
              const SizedBox(height: 12),
              _SectionTitleRow(
                icon: Icons.looks_4_rounded,
                title: t.mayyithTakbirsTitle,
                accentColor: AppBranding.accentGold,
              ),
              const SizedBox(height: 10),
              for (final step in bundle.takbirs)
                IbadahAudioCard(
                  orderBadge: '${step.takbirNumber}',
                  title: step.titleFor(lang),
                  badgeText: 'Takbir ${step.takbirNumber}',
                  badgeColor: AppBranding.accentGold,
                  isHighlighted: true,
                  arabicText: step.arabic,
                  transliterationMl: step.transliterationMl,
                  meaningText: step.meaningFor(lang),
                  noteText: step.noteFor(lang),
                  audioPath: step.audioPath,
                  strings: t,
                  cardBg: palette.cardBg,
                  cardBorder: palette.cardBorder,
                ),
            ],

            if (showBurial) ...[
              const SizedBox(height: 12),
              _SectionTitleRow(
                icon: Icons.volunteer_activism_rounded,
                title: t.mayyithBurialTitle,
                accentColor: accentColor,
              ),
              const SizedBox(height: 10),
              for (final item in bundle.burialAndTalqeen)
                IbadahAudioCard(
                  title: item.titleFor(lang),
                  arabicText: item.arabic,
                  transliterationMl: item.transliterationMl,
                  meaningText: item.meaningMl,
                  noteText: item.noteFor(lang),
                  audioPath: item.audioPath,
                  strings: t,
                  cardBg: palette.cardBg,
                  cardBorder: palette.cardBorder,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;

  const _SectionTitleRow({
    required this.icon,
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: accentColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
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
