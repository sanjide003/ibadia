import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../providers/quran_providers.dart';
import '../screens/settings_screen.dart';
import 'tv_mode_widgets.dart';

/// Clean top search input for Surah-style Index Lists.
class FeatureIndexSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String hintText;
  final String clearTooltip;
  final Color cardBg;
  final Color cardBorder;
  final double uiScale;

  const FeatureIndexSearchBar({
    super.key,
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.hintText,
    required this.clearTooltip,
    required this.cardBg,
    required this.cardBorder,
    this.uiScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardBorder),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: 14.5 * uiScale.clamp(1.0, 1.35),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14 * uiScale.clamp(1.0, 1.35),
            color: cs.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: cs.primary,
            size: 21,
          ),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: clearTooltip,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 19,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: onClear,
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

/// Surah-style numbered row for Ibadah & Adhkar Index Lists.
/// Uses quiet typographic metadata ('·') without static pill clutter.
class FeatureIndexTile extends StatelessWidget {
  final int indexNumber;
  final String title;
  final String? subtitleMeta;
  final String? trailingArabic;
  final String? trailingLabel;
  final bool isHighlighted;
  final Color cardBg;
  final Color cardBorder;
  final Color accentColor;
  final double uiScale;
  final VoidCallback onTap;

  const FeatureIndexTile({
    super.key,
    required this.indexNumber,
    required this.title,
    this.subtitleMeta,
    this.trailingArabic,
    this.trailingLabel,
    this.isHighlighted = false,
    required this.cardBg,
    required this.cardBorder,
    required this.accentColor,
    this.uiScale = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double titlePx = 15.5 * uiScale.clamp(1.0, 1.45);
    final double subPx = 12.2 * uiScale.clamp(1.0, 1.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Color.alphaBlend(
                accentColor.withValues(alpha: 0.06),
                cardBg,
              )
            : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? accentColor.withValues(alpha: 0.45)
              : cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Text(
                      '$indexNumber',
                      style: TextStyle(
                        fontSize: 13.5 * uiScale.clamp(1.0, 1.25),
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: titlePx,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: cs.onSurface,
                          ),
                        ),
                        if (subtitleMeta != null &&
                            subtitleMeta!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitleMeta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: subPx,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (trailingArabic != null &&
                      trailingArabic!.trim().isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 118),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          trailingArabic!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.amiri(
                            fontSize: 18.5 * uiScale.clamp(1.0, 1.3),
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    )
                  else if (trailingLabel != null &&
                      trailingLabel!.trim().isNotEmpty)
                    Text(
                      trailingLabel!,
                      style: TextStyle(
                        fontSize: 12.5 * uiScale.clamp(1.0, 1.25),
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Focused single-item scaffold with unified emerald TV header and
/// thumb-friendly bottom Previous / Next stepping controls.
class FocusedDetailPage extends ConsumerStatefulWidget {
  final int initialIndex;
  final int itemCount;
  final String Function(int index, AppStrings strings, String headingLang)
      titleBuilder;
  final Widget Function(
    BuildContext context,
    int index,
    AppStrings strings,
    String headingLang,
    String expLang,
  ) itemBuilder;
  final SettingsScope? settingsScope;
  final List<Widget> Function(BuildContext context, int index)? extraActions;
  final ValueChanged<int>? onIndexChanged;

  const FocusedDetailPage({
    super.key,
    required this.initialIndex,
    required this.itemCount,
    required this.titleBuilder,
    required this.itemBuilder,
    this.settingsScope,
    this.extraActions,
    this.onIndexChanged,
  });

  static bool jumpTo(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_FocusedDetailPageState>();
    if (state == null) return false;
    state._stepTo(index);
    return true;
  }

  @override
  ConsumerState<FocusedDetailPage> createState() => _FocusedDetailPageState();
}

class _FocusedDetailPageState extends ConsumerState<FocusedDetailPage> {
  late int _currentIndex;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final maxIdx = widget.itemCount > 0 ? widget.itemCount - 1 : 0;
    _currentIndex = widget.initialIndex.clamp(0, maxIdx);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _stepTo(int nextIndex) {
    if (nextIndex < 0 || nextIndex >= widget.itemCount) return;
    if (nextIndex == _currentIndex) return;
    widget.onIndexChanged?.call(nextIndex);
    setState(() => _currentIndex = nextIndex);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.appLanguage;
    final expLang = explanationLangFor(lang);
    final headingLang =
        settings.ibadahMalayalamHeadings ? 'ml' : contentLangFor(lang);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';
    final cs = Theme.of(context).colorScheme;

    final Color headerBg =
        isDark ? AppBranding.darkEmerald : AppBranding.headerEmerald;
    final Color canvasBg = isDark
        ? const Color(0xFF0A0D0C)
        : (isSepia ? const Color(0xFFFBF6E9) : const Color(0xFFF3F6F4));
    final Color navBarBg = isDark
        ? const Color(0xFF121815)
        : (isSepia ? const Color(0xFFF6EFE0) : Colors.white);
    final Color navBarBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFDDE7E1));

    final String itemTitle = widget.itemCount > 0
        ? widget.titleBuilder(_currentIndex, t, headingLang)
        : t.appTitle;
    final double hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: settings.tvModeEnabled,
      normalMaxWidth: 880,
      minPad: 14.0,
    );
    final bool hasPrev = _currentIndex > 0;
    final bool hasNext = _currentIndex < widget.itemCount - 1;
    final double uiScale =
        settings.tvModeEnabled ? settings.tvFontScale.clamp(1.0, 1.4) : 1.0;

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: canvasBg,
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: settings.tvModeEnabled ? 4 : null,
          backgroundColor: headerBg,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: IconButton(
            tooltip: t.backToHome,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: settings.tvModeEnabled
              ? Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 210),
                      child: Text(
                        itemTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Builder(
                          builder: (drawerCtx) => TvHeaderControlsInline(
                            onOpenSettings: widget.settingsScope == null
                                ? null
                                : () => Scaffold.of(drawerCtx).openEndDrawer(),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  itemTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
          actions: settings.tvModeEnabled
              ? const []
              : [
                  if (widget.extraActions != null && widget.itemCount > 0)
                    ...widget.extraActions!(context, _currentIndex),
                  const TvModeActionButton(),
                  if (widget.settingsScope != null)
                    Builder(
                      builder: (drawerCtx) => IconButton(
                        tooltip: t.settings,
                        icon: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            Scaffold.of(drawerCtx).openEndDrawer(),
                      ),
                    )
                  else
                    const SizedBox(width: 6),
                ],
        ),
        endDrawer: widget.settingsScope == null
            ? null
            : CompactSettingsDrawer(scope: widget.settingsScope!),
        body: Column(
          children: [
            Expanded(
              child: widget.itemCount == 0
                  ? Center(child: Text(t.noMatchingItems))
                  : SingleChildScrollView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(_currentIndex),
                          child: widget.itemBuilder(
                            context,
                            _currentIndex,
                            t,
                            headingLang,
                            expLang,
                          ),
                        ),
                      ),
                    ),
            ),
            if (widget.itemCount > 1)
              Container(
                decoration: BoxDecoration(
                  color: navBarBg,
                  border: Border(top: BorderSide(color: navBarBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: hasPrev
                                  ? () => _stepTo(_currentIndex - 1)
                                  : null,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                              ),
                              label: Text(
                                t.previousLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5 * uiScale.clamp(1.0, 1.15),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '${_currentIndex + 1} / ${widget.itemCount}',
                            style: TextStyle(
                              fontSize: 13.5 * uiScale.clamp(1.0, 1.2),
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: FilledButton.icon(
                              onPressed: hasNext
                                  ? () => _stepTo(_currentIndex + 1)
                                  : null,
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                              iconAlignment: IconAlignment.end,
                              label: Text(
                                t.nextLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5 * uiScale.clamp(1.0, 1.15),
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
