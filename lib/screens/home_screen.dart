import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config/api_config.dart';
import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../models/recent_activity_model.dart';
import '../models/surah_model.dart';
import '../providers/islamic_features_providers.dart';
import '../providers/quran_providers.dart';
import '../providers/update_provider.dart';
import '../services/hive_db.dart';
import '../services/prayer_alarm_bridge.dart';
import '../services/storage_service.dart';
import '../widgets/tv_mode_widgets.dart';
import '../widgets/update_dialog.dart';
import '../widgets/web_pwa_widgets.dart';
import 'adhkar_tasbih_views.dart';
import 'asmaul_husna_view.dart';
import 'dashboard_view.dart';
import 'export_screen.dart';
import 'features_views.dart';
import 'ibadah_guide_screen.dart';
import 'settings_screen.dart';
import 'surah_reader_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  TabController? _quranTabCtrl;
  TabController get _quranTabController => _ensureQuranTabController();
  ScrollController? _surahScrollCtrl;
  ScrollController? _juzScrollCtrl;
  ScrollController? _bookmarksScrollCtrl;

  ScrollController get _surahScrollController =>
      _surahScrollCtrl ??= ScrollController()..addListener(_onHomeListScrolled);
  ScrollController get _juzScrollController =>
      _juzScrollCtrl ??= ScrollController()..addListener(_onHomeListScrolled);
  ScrollController get _bookmarksScrollController => _bookmarksScrollCtrl ??=
      ScrollController()..addListener(_onHomeListScrolled);

  int _tabIndex = 0; // 0: Home, 1: Quran, 2: Settings
  bool _shownStartupUpdatePrompt = false;
  bool? _hasRestoredStartupStateBacking;
  bool get _hasRestoredStartupState => _hasRestoredStartupStateBacking ?? false;
  set _hasRestoredStartupState(bool v) => _hasRestoredStartupStateBacking = v;

  bool? _isReaderOpenBacking;
  bool get _isReaderOpen => _isReaderOpenBacking ?? false;
  set _isReaderOpen(bool v) => _isReaderOpenBacking = v;

  double? _pendingSurahScrollOffset;
  double? _pendingJuzScrollOffset;
  double? _pendingBookmarksScrollOffset;
  Timer? _homeScrollDebounce;

  TabController _ensureQuranTabController() {
    final existing = _quranTabCtrl;
    if (existing != null && existing.length == 4) {
      return existing;
    }
    if (existing != null) {
      existing.removeListener(_onQuranSubTabChanged);
      existing.dispose();
    }
    final ctrl = TabController(length: 4, vsync: this);
    ctrl.addListener(_onQuranSubTabChanged);
    _quranTabCtrl = ctrl;
    return ctrl;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureQuranTabController();
    // Initialize lazy scroll controllers
    _surahScrollController;
    _juzScrollController;
    _bookmarksScrollController;

    PrayerAlarmBridge.instance.setOnOpenSurahHandler((surahNo) {
      if (!mounted) return;
      _openSurah(context, surahNo);
    });
    PrayerAlarmBridge.instance.setOnOpenPrayerTabHandler(() {
      if (!mounted) return;
      setState(() => _tabIndex = 0);
      _persistHomeState(forceHomeActive: true);
      _openStandaloneFeature('prayer_times');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(prayerAlarmProvider);
      ref.read(updateProvider.notifier).checkForUpdates(silent: true);
      _restoreAppResumeState();
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    _ensureQuranTabController();
  }

  @override
  void dispose() {
    PrayerAlarmBridge.instance.setOnOpenSurahHandler(null);
    PrayerAlarmBridge.instance.setOnOpenPrayerTabHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    _homeScrollDebounce?.cancel();
    _quranTabCtrl?.removeListener(_onQuranSubTabChanged);
    _quranTabCtrl?.dispose();
    _surahScrollCtrl?.removeListener(_onHomeListScrolled);
    _juzScrollCtrl?.removeListener(_onHomeListScrolled);
    _bookmarksScrollCtrl?.removeListener(_onHomeListScrolled);
    _surahScrollCtrl?.dispose();
    _juzScrollCtrl?.dispose();
    _bookmarksScrollCtrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(prayerAlarmProvider.notifier).syncWithNative();
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      if (!_isReaderOpen) {
        _persistHomeState(forceHomeActive: true);
      }
      HiveDb.instance.flushAll();
    }
  }

  void _onQuranSubTabChanged() {
    if (mounted) {
      setState(() {});
    }
    if (_quranTabController.indexIsChanging) return;
    _persistHomeState(forceHomeActive: !_isReaderOpen);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingHomeScrollOffsets();
    });
  }

  void _onHomeListScrolled() {
    _homeScrollDebounce?.cancel();
    _homeScrollDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted && !_isReaderOpen) {
        _persistHomeState(forceHomeActive: true);
      }
    });
  }

  void _persistHomeState({bool forceHomeActive = false}) {
    ref.read(appResumeProvider.notifier).updateHomeTabsAndScroll(
          lastScreen: forceHomeActive ? 'home' : null,
          homeTabIndex: _tabIndex.clamp(0, 2),
          quranSubTabIndex: _quranTabController.index,
          surahListScrollOffset: _surahScrollController.hasClients
              ? _surahScrollController.offset
              : null,
          juzListScrollOffset: _juzScrollController.hasClients
              ? _juzScrollController.offset
              : null,
          bookmarksScrollOffset: _bookmarksScrollController.hasClients
              ? _bookmarksScrollController.offset
              : null,
        );
  }

  void _applyPendingHomeScrollOffsets() {
    if (!mounted) return;
    if (_pendingSurahScrollOffset != null &&
        _surahScrollController.hasClients) {
      final maxExt = _surahScrollController.position.maxScrollExtent;
      if (maxExt > 0 || _pendingSurahScrollOffset == 0) {
        _surahScrollController.jumpTo(
          _pendingSurahScrollOffset!.clamp(0.0, maxExt),
        );
        _pendingSurahScrollOffset = null;
      }
    }
    if (_pendingJuzScrollOffset != null && _juzScrollController.hasClients) {
      final maxExt = _juzScrollController.position.maxScrollExtent;
      if (maxExt > 0 || _pendingJuzScrollOffset == 0) {
        _juzScrollController.jumpTo(
          _pendingJuzScrollOffset!.clamp(0.0, maxExt),
        );
        _pendingJuzScrollOffset = null;
      }
    }
    if (_pendingBookmarksScrollOffset != null &&
        _bookmarksScrollController.hasClients) {
      final maxExt = _bookmarksScrollController.position.maxScrollExtent;
      if (maxExt > 0 || _pendingBookmarksScrollOffset == 0) {
        _bookmarksScrollController.jumpTo(
          _pendingBookmarksScrollOffset!.clamp(0.0, maxExt),
        );
        _pendingBookmarksScrollOffset = null;
      }
    }
  }

  Future<void> _openStandaloneFeature(String featureId) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StandaloneFeatureScreen(
          featureId: featureId,
          onOpenSurah: (surahNo, {ayahNo}) =>
              _openSurah(context, surahNo, ayahNo: ayahNo),
        ),
      ),
    );
  }

  Future<void> _restoreAppResumeState() async {
    if (_hasRestoredStartupState) return;
    _hasRestoredStartupState = true;

    final resume = await ref.read(appResumeProvider.notifier).ensureLoaded();
    final lastRead = await ref.read(lastReadProvider.notifier).ensureLoaded();
    await ref.read(settingsProvider.notifier).ensureLoaded();
    if (!mounted) return;

    final restoredTab = resume.homeTabIndex.clamp(0, 2);
    final restoredSubTab = resume.quranSubTabIndex.clamp(0, 3);

    final launchAction =
        await PrayerAlarmBridge.instance.getInitialLaunchAction();
    if (!mounted) return;

    setState(() {
      _tabIndex = (launchAction?.openPrayerTab == true) ? 0 : restoredTab;
      if (_quranTabController.index != restoredSubTab) {
        _quranTabController.index = restoredSubTab;
      }
      _pendingSurahScrollOffset = resume.surahListScrollOffset;
      _pendingJuzScrollOffset = resume.juzListScrollOffset;
      _pendingBookmarksScrollOffset = resume.bookmarksScrollOffset;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingHomeScrollOffsets();
    });

    if (launchAction?.openPrayerTab == true) {
      await _openStandaloneFeature('prayer_times');
      return;
    }

    if (launchAction?.openSurah != null && launchAction!.openSurah! > 0) {
      await _openSurah(
        context,
        launchAction.openSurah!,
        instantTransition: true,
      );
      return;
    }

    if (launchAction?.openPrayerTab != true && resume.lastScreen == 'reader') {
      final targetSurah = resume.activeSurahNumber ?? lastRead?.surahNumber;
      if (targetSurah != null) {
        final targetAyah = resume.activeAyahNumber ?? lastRead?.ayahNumber;
        final targetAnchorPx = resume.activeSurahNumber != null
            ? resume.activeAnchorOffsetPx
            : lastRead?.anchorOffsetPx;
        final targetMode = resume.activeSurahNumber != null
            ? resume.activeReadingMode
            : lastRead?.readingMode;

        await _openSurah(
          context,
          targetSurah,
          ayahNo: targetAyah,
          anchorOffsetPx: targetAnchorPx,
          savedReadingMode: targetMode,
          instantTransition: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(surahListProvider);
    final lastRead = ref.watch(lastReadProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final updateState = ref.watch(updateProvider);
    ref.listen<AsyncValue<List<SurahSummary>>>(surahListProvider, (_, next) {
      if (next.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _applyPendingHomeScrollOffsets();
        });
      }
    });
    ref.listen<AppUpdateState>(updateProvider, (prev, next) {
      if (!_shownStartupUpdatePrompt &&
          next.updateAvailable &&
          prev?.updateAvailable != true &&
          mounted) {
        _shownStartupUpdatePrompt = true;
        showAppUpdateDialog(context);
      }
    });
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';

    final Color headerBg =
        isDark ? AppBranding.darkEmerald : AppBranding.headerEmerald;
    final Color canvasBg = isDark
        ? const Color(0xFF0A0D0C)
        : (isSepia ? const Color(0xFFFBF6E9) : const Color(0xFFF3F6F4));
    final Color cardBg = isDark
        ? const Color(0xFF141A17)
        : (isSepia ? const Color(0xFFFFFDF7) : Colors.white);
    final Color cardBorder = isDark
        ? const Color(0xFF23302A)
        : (isSepia ? const Color(0xFFE7DEC9) : const Color(0xFFE2EBE6));

    return Directionality(
      textDirection: t.textDirection,
      child: Scaffold(
        backgroundColor: canvasBg,
        appBar: _tabIndex == 1
            ? null
              : AppBar(
                centerTitle: !settings.tvModeEnabled,
                titleSpacing: settings.tvModeEnabled ? 12 : null,
                backgroundColor: headerBg,
                foregroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                scrolledUnderElevation: 0,
                elevation: 0,
                title: settings.tvModeEnabled
                    ? Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              AppBranding.logoAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 9),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 165),
                            child: Text(
                              _tabIndex == 0 ? t.appTitle : t.settingsTab,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
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
                                  onOpenSettings: _tabIndex == 2
                                      ? null
                                      : () => Scaffold.of(drawerCtx)
                                          .openEndDrawer(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              AppBranding.logoAsset,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            _tabIndex == 0 ? t.appTitle : t.settingsTab,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                actions: settings.tvModeEnabled
                    ? const []
                    : (_tabIndex == 2
                        ? const [TvModeActionButton(), SizedBox(width: 6)]
                        : [
                            const TvModeActionButton(),
                            Builder(
                              builder: (drawerCtx) => IconButton(
                                tooltip: t.settings,
                                icon: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.settings_rounded,
                                        color: Colors.white),
                                    if (updateState.updateAvailable)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: AppBranding.accentGold,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: headerBg,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onPressed: () =>
                                    Scaffold.of(drawerCtx).openEndDrawer(),
                              ),
                            ),
                          ]),
              ),
        endDrawer: _tabIndex == 2
            ? null
            : CompactSettingsDrawer(
                scope:
                    _tabIndex == 1 ? SettingsScope.quran : SettingsScope.all,
              ),
        body: Column(
          children: [
            if (_tabIndex == 1)
              Container(
                width: double.infinity,
                color: headerBg,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      8,
                      settings.tvModeEnabled ? 12 : 6,
                      8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: settings.tvModeEnabled ? 2 : 1,
                          child: _buildQuranSubTabBar(
                            controller: _quranTabController,
                            tabs: [
                              _HeaderIconTab(
                                icon: Icons.menu_book_rounded,
                                label: t.surahTabLabel,
                              ),
                              _HeaderIconTab(
                                icon: Icons.grid_view_rounded,
                                label: t.juzTabLabel,
                              ),
                              _HeaderIconTab(
                                icon: Icons.bookmark_rounded,
                                label: t.bookmarksTab,
                              ),
                              _HeaderIconTab(
                                icon: Icons.ios_share_rounded,
                                label: t.exportTab,
                              ),
                            ],
                          ),
                        ),
                        if (settings.tvModeEnabled) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: Builder(
                                builder: (drawerCtx) => TvHeaderControlsInline(
                                  onOpenSettings: () =>
                                      Scaffold.of(drawerCtx).openEndDrawer(),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 6),
                          const TvModeActionButton(),
                          Builder(
                            builder: (drawerCtx) => IconButton(
                              tooltip: t.quranSettingsTitle,
                              icon: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.settings_rounded,
                                      color: Colors.white),
                                  if (updateState.updateAvailable)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: AppBranding.accentGold,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: headerBg,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onPressed: () =>
                                  Scaffold.of(drawerCtx).openEndDrawer(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            OfflineStatusBanner(strings: t),
            Expanded(
              child: _tabIndex == 0
                  ? DashboardView(
                      onNavigateTab: (tabIdx, {int? subTab}) {
                        setState(() {
                          _tabIndex = tabIdx.clamp(0, 2);
                          if (_tabIndex == 1 && subTab != null) {
                            _quranTabController.index = subTab.clamp(0, 3);
                          }
                        });
                        _persistHomeState(forceHomeActive: true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _applyPendingHomeScrollOffsets();
                        });
                      },
                      onOpenFeature: _openStandaloneFeature,
                      onOpenSurah: (
                        surahNo, {
                        int? ayahNo,
                        double? anchorOffsetPx,
                        String? savedReadingMode,
                      }) =>
                          _openSurah(
                        context,
                        surahNo,
                        ayahNo: ayahNo,
                        anchorOffsetPx: anchorOffsetPx,
                        savedReadingMode: savedReadingMode,
                      ),
                    )
                  : _tabIndex == 1
                      ? Stack(
                          children: [
                            TabBarView(
                              controller: _quranTabController,
                              children: [
                                // 1. Surah Tab View
                                _SurahTabView(
                                  scrollController: _surahScrollController,
                                  surahsAsync: surahsAsync,
                                  lastRead: lastRead,
                                  appLanguage: settings.appLanguage,
                                  tvModeEnabled: settings.tvModeEnabled,
                                  strings: t,
                                  cs: cs,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  onRetry: () =>
                                      ref.invalidate(surahListProvider),
                                  onOpenSurah: (
                                    surahNo, {
                                    int? ayahNo,
                                    double? anchorOffsetPx,
                                    String? savedReadingMode,
                                  }) =>
                                      _openSurah(
                                    context,
                                    surahNo,
                                    ayahNo: ayahNo,
                                    anchorOffsetPx: anchorOffsetPx,
                                    savedReadingMode: savedReadingMode,
                                  ),
                                ),

                                // 2. Juz Tab View
                                _JuzTabView(
                                  scrollController: _juzScrollController,
                                  tvModeEnabled: settings.tvModeEnabled,
                                  strings: t,
                                  cs: cs,
                                  cardBg: cardBg,
                                  cardBorder: cardBorder,
                                  onOpenJuz: (juz) {
                                    ref
                                        .read(recentActivityProvider.notifier)
                                        .record(
                                          RecentActivityEntry(
                                            id: 'juz:${juz.number}',
                                            type: RecentActivityType.juz,
                                            titleEn:
                                                '${t.juzLabel} ${juz.number}',
                                            titleMl:
                                                '${t.juzLabel} ${juz.number}',
                                            titleAr: juz.arabicName,
                                            subtitleEn: juz.openingCue,
                                            subtitleMl: juz.openingCue,
                                            subtitleAr:
                                                'الصفحة ${juz.startPage}',
                                            timestampMs: DateTime.now()
                                                .millisecondsSinceEpoch,
                                            surahNumber: juz.startSurah,
                                            ayahNumber: juz.startAyah,
                                            quranSubTab: 1,
                                          ),
                                        );
                                    _openSurah(
                                      context,
                                      juz.startSurah,
                                      initialAyah: juz.startAyah,
                                      ayahNo: juz.startAyah,
                                    );
                                  },
                                ),

                                // 3. Bookmarks Tab View
                                BookmarksListView(
                                  scrollController: _bookmarksScrollController,
                                  bookmarks: bookmarks,
                                  surahs: surahsAsync.valueOrNull ?? const [],
                                  strings: t,
                                  tvModeEnabled: settings.tvModeEnabled,
                                  onOpenSurah: (surahNo, {int? ayahNo}) =>
                                      _openSurah(context, surahNo,
                                          ayahNo: ayahNo),
                                ),

                                // 4. Export Tab View
                                const ExportScreen(),
                              ],
                            ),

                            // Floating Search Surah Pill (only on Surah & Juz sub-tabs)
                            if (_quranTabController.index <= 1)
                              PositionedDirectional(
                                end: responsivePageHorizontalPadding(
                                  context,
                                  tvModeEnabled: settings.tvModeEnabled,
                                  normalMaxWidth: 860,
                                ),
                                bottom: 16,
                                child: FloatingActionButton.extended(
                                  heroTag: 'search_surah_pill',
                                  backgroundColor: headerBg,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  icon: const Icon(Icons.search_rounded),
                                  label: Text(
                                    t.searchSurah,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  onPressed: () {
                                    final list = surahsAsync.valueOrNull;
                                    if (list == null || list.isEmpty) return;
                                    _showSurahSearchSheet(
                                      context: context,
                                      surahs: list,
                                      strings: t,
                                      cs: cs,
                                      cardBg: cardBg,
                                      cardBorder: cardBorder,
                                    );
                                  },
                                ),
                              ),
                          ],
                        )
                      : const SettingsTabView(),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex.clamp(0, 2),
          onDestinationSelected: (i) {
            setState(() => _tabIndex = i);
            _persistHomeState(forceHomeActive: true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _applyPendingHomeScrollOffsets();
            });
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: t.homeTab,
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              selectedIcon: const Icon(Icons.auto_stories_rounded),
              label: t.quranTab,
            ),
            NavigationDestination(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.settings_outlined),
                  if (updateState.updateAvailable)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppBranding.accentGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: t.settingsTab,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSurah(
    BuildContext context,
    int surahNumber, {
    int? initialAyah,
    int? ayahNo,
    double? anchorOffsetPx,
    String? savedReadingMode,
    bool instantTransition = false,
  }) async {
    final resolvedAyah = ayahNo ?? initialAyah;
    _persistHomeState();
    _isReaderOpen = true;
    final currentMode = ref.read(settingsProvider).readingMode;
    await ref.read(appResumeProvider.notifier).setReaderActive(
          surahNumber: surahNumber,
          ayahNumber: resolvedAyah ?? 1,
          anchorOffsetPx: anchorOffsetPx ?? 0.0,
          readingMode: savedReadingMode ?? currentMode,
        );
    if (!context.mounted) {
      _isReaderOpen = false;
      return;
    }

    final Route<void> route = instantTransition
        ? PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: const Duration(milliseconds: 220),
            pageBuilder: (_, __, ___) => SurahReaderScreen(
              initialSurahNumber: surahNumber,
              initialAyahNumber: resolvedAyah,
              initialAnchorOffsetPx: anchorOffsetPx,
              initialSavedReadingMode: savedReadingMode,
            ),
          )
        : MaterialPageRoute<void>(
            builder: (_) => SurahReaderScreen(
              initialSurahNumber: surahNumber,
              initialAyahNumber: resolvedAyah,
              initialAnchorOffsetPx: anchorOffsetPx,
              initialSavedReadingMode: savedReadingMode,
            ),
          );

    await Navigator.push<void>(context, route);
    _isReaderOpen = false;
    if (!mounted) return;
    ref.read(appResumeProvider.notifier).markReturnedHome();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyPendingHomeScrollOffsets();
    });
  }

  void _showSurahSearchSheet({
    required BuildContext context,
    required List<SurahSummary> surahs,
    required AppStrings strings,
    required ColorScheme cs,
    required Color cardBg,
    required Color cardBorder,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final filtered = surahs.where((s) {
              if (query.isEmpty) return true;
              return s.englishName.toLowerCase().contains(query) ||
                  s.nameArabic.contains(query) ||
                  s.number.toString() == query;
            }).toList();

            return Directionality(
              textDirection: strings.textDirection,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.78,
                minChildSize: 0.5,
                maxChildSize: 0.94,
                builder: (_, scrollCtrl) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: strings.searchHint,
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) => setSheetState(
                            () => query = v.trim().toLowerCase(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: filtered.length,
                          itemBuilder: (_, idx) {
                            final surah = filtered[idx];
                            return _SurahCardTile(
                              key: ValueKey('search_${surah.number}'),
                              surah: surah,
                              strings: strings,
                              cs: cs,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              onTap: () {
                                Navigator.pop(ctx);
                                _openSurah(context, surah.number);
                              },
                            );
                          },
                        ),
                      ),
                    ],
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

class _SurahTabView extends StatelessWidget {
  final ScrollController scrollController;
  final AsyncValue<List<SurahSummary>> surahsAsync;
  final LastReadPosition? lastRead;
  final String appLanguage;
  final bool tvModeEnabled;
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onRetry;
  final void Function(
    int surahNo, {
    int? ayahNo,
    double? anchorOffsetPx,
    String? savedReadingMode,
  }) onOpenSurah;

  const _SurahTabView({
    required this.scrollController,
    required this.surahsAsync,
    required this.lastRead,
    required this.appLanguage,
    required this.tvModeEnabled,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    required this.onRetry,
    required this.onOpenSurah,
  });

  @override
  Widget build(BuildContext context) {
    return surahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 42),
              const SizedBox(height: 12),
              Text(strings.loadError, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: Text(strings.retry)),
            ],
          ),
        ),
      ),
      data: (surahs) {
        final hPad = responsivePageHorizontalPadding(
          context,
          tvModeEnabled: tvModeEnabled,
          normalMaxWidth: 860,
        );
        final currentLastRead = lastRead;
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 92),
          itemCount: surahs.length + 2,
          itemBuilder: (context, index) {
            // Item 0: Optional Last Read resume banner
            if (index == 0) {
              if (currentLastRead == null) return const SizedBox.shrink();
              final surahLabel = appLanguage == 'ar' &&
                      currentLastRead.surahArabicName.isNotEmpty
                  ? currentLastRead.surahArabicName
                  : currentLastRead.surahName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => onOpenSurah(
                      currentLastRead.surahNumber,
                      ayahNo: currentLastRead.ayahNumber,
                      anchorOffsetPx: currentLastRead.anchorOffsetPx,
                      savedReadingMode: currentLastRead.readingMode,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: cs.onPrimaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.lastRead,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onPrimaryContainer
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                                Text(
                                  '$surahLabel — ${strings.ayahLabel} ${currentLastRead.ayahNumber}',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: cs.onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            // Item 1: Commonly Recited Calligraphy Card Section
            if (index == 1) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.commonlyRecited,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 98,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: ApiConfig.featuredSurahs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, idx) {
                          final item = ApiConfig.featuredSurahs[idx];
                          final surahNo = item['number'] as int;
                          final label =
                              (item[appLanguage] ?? item['en']) as String;
                          final arabicCalligraphy = item['ar'] as String;

                          return Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => onOpenSurah(surahNo),
                              child: Container(
                                width: 104,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      arabicCalligraphy,
                                      textDirection: TextDirection.rtl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.amiri(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        height: 1.25,
                                        color: cs.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }

            // Items 2..115: 114 Surah Cards
            final surah = surahs[index - 2];
            return RepaintBoundary(
              child: _SurahCardTile(
                key: ValueKey(surah.number),
                surah: surah,
                strings: strings,
                cs: cs,
                cardBg: cardBg,
                cardBorder: cardBorder,
                onTap: () => onOpenSurah(surah.number),
              ),
            );
          },
        );
      },
    );
  }
}

class _JuzTabView extends StatelessWidget {
  final ScrollController scrollController;
  final bool tvModeEnabled;
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final ValueChanged<JuzInfo> onOpenJuz;

  const _JuzTabView({
    required this.scrollController,
    required this.tvModeEnabled,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    required this.onOpenJuz,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: tvModeEnabled,
      normalMaxWidth: 860,
    );
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 92),
      itemCount: ApiConfig.juzCatalog.length,
      itemBuilder: (context, index) {
        final juz = ApiConfig.juzCatalog[index];
        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
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
                onTap: () => onOpenJuz(juz),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Leading solid emerald circle with Arabic-Indic Juz numeral
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          ApiConfig.toArabicNumber(juz.number),
                          style: GoogleFonts.amiri(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Middle Arabic Juz title + Opening cue
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              juz.arabicName,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            Text(
                              juz.openingCue,
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.amiri(
                                fontSize: 14.5,
                                color: cs.onSurfaceVariant,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Trailing starting Mushaf Page badge
                      Container(
                        constraints: const BoxConstraints(minWidth: 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${juz.startPage}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SurahCardTile extends StatelessWidget {
  final SurahSummary surah;
  final AppStrings strings;
  final ColorScheme cs;
  final Color cardBg;
  final Color cardBorder;
  final VoidCallback onTap;

  const _SurahCardTile({
    super.key,
    required this.surah,
    required this.strings,
    required this.cs,
    required this.cardBg,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                _IslamicStarNumberBadge(
                  numberText: ApiConfig.toArabicNumber(surah.number),
                  color: cs.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.lang == 'ar'
                            ? surah.nameArabic
                            : surah.englishName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${strings.revelationLabel(surah.revelationType)} • ${surah.numberOfAyahs} ${strings.ayahsLabel}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.amiri(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 8-pointed Rub el Hizb Islamic star outline with centered Arabic-Indic Surah numeral.
class _IslamicStarNumberBadge extends StatelessWidget {
  final String numberText;
  final Color color;

  const _IslamicStarNumberBadge({
    required this.numberText,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: CustomPaint(
        painter: _RubElHizbPainter(color: color),
        child: Center(
          child: Text(
            numberText,
            style: GoogleFonts.amiri(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _RubElHizbPainter extends CustomPainter {
  final Color color;

  const _RubElHizbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final side = size.width * 0.62;
    final half = side / 2;

    final stroke = Paint()
      ..color = color.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final rect = Rect.fromCenter(center: Offset.zero, width: side, height: side);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawRect(rect, stroke);
    canvas.rotate(math.pi / 4);
    canvas.drawRect(rect, stroke);
    canvas.restore();

    // Inner subtle circle accent
    canvas.drawCircle(
      center,
      half * 0.88,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _RubElHizbPainter oldDelegate) =>
      oldDelegate.color != color;
}

class StandaloneFeatureScreen extends ConsumerStatefulWidget {
  final String featureId;
  final void Function(int surahNo, {int? ayahNo}) onOpenSurah;

  const StandaloneFeatureScreen({
    super.key,
    required this.featureId,
    required this.onOpenSurah,
  });

  @override
  ConsumerState<StandaloneFeatureScreen> createState() =>
      _StandaloneFeatureScreenState();
}

class _StandaloneFeatureScreenState
    extends ConsumerState<StandaloneFeatureScreen> {
  final ScrollController _bookmarksScrollCtrl = ScrollController();

  @override
  void dispose() {
    _bookmarksScrollCtrl.dispose();
    super.dispose();
  }

  String _titleFor(AppStrings t) {
    switch (widget.featureId) {
      case 'prayer_times':
        return t.actionPrayer;
      case 'hijri_calendar':
        return t.hijriCalendarTitle;
      case 'adhkar':
        return t.actionAdhkar;
      case 'tasbih':
        return t.tasbihTitle;
      case 'names_99':
        return t.names99Title;
      case 'bookmarks':
        return t.bookmarksTab;
      case 'export':
        return t.exportTitle;
      case 'ibadah_niyyah':
        return t.actionNiyyah;
      case 'ibadah_salah':
        return t.actionSalahGuide;
      case 'ibadah_rawatib':
        return t.actionRawatibSurahs;
      case 'ibadah_mayyith':
        return t.actionMayyithGuide;
      case 'ibadah_guide':
        return t.ibadahGuideTitle;
      default:
        return t.appTitle;
    }
  }

  SettingsScope? _settingsScopeFor() {
    switch (widget.featureId) {
      case 'prayer_times':
      case 'hijri_calendar':
        return SettingsScope.features;
      case 'bookmarks':
      case 'export':
        return SettingsScope.quran;
      case 'ibadah_niyyah':
      case 'ibadah_salah':
      case 'ibadah_rawatib':
      case 'ibadah_mayyith':
      case 'ibadah_guide':
        return SettingsScope.ibadah;
      case 'adhkar':
        return SettingsScope.all;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final settings = ref.watch(settingsProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final surahs = ref.watch(surahListProvider).valueOrNull ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSepia = settings.themeMode == 'sepia';
    final Color headerBg =
        isDark ? AppBranding.darkEmerald : AppBranding.headerEmerald;
    final Color canvasBg = isDark
        ? const Color(0xFF0A0D0C)
        : (isSepia ? const Color(0xFFFBF6E9) : const Color(0xFFF3F6F4));
    final SettingsScope? scope = _settingsScopeFor();

    Widget body;
    switch (widget.featureId) {
      case 'prayer_times':
        body = PrayerTimesView(
          onOpenSurah: (surahNo) => widget.onOpenSurah(surahNo),
        );
        break;
      case 'hijri_calendar':
        body = const HijriCalendarView();
        break;
      case 'adhkar':
        body = const AdhkarDuasView();
        break;
      case 'tasbih':
        body = const DigitalTasbihView();
        break;
      case 'names_99':
        body = const AsmaulHusnaView();
        break;
      case 'bookmarks':
        body = BookmarksListView(
          scrollController: _bookmarksScrollCtrl,
          bookmarks: bookmarks,
          surahs: surahs,
          strings: t,
          tvModeEnabled: settings.tvModeEnabled,
          onOpenSurah: widget.onOpenSurah,
        );
        break;
      case 'export':
        body = const ExportScreen(showHeader: false);
        break;
      case 'ibadah_niyyah':
        body = IbadahGuideScreen(
          section: IbadahSection.niyyah,
          onOpenSurah: (surahNo) => widget.onOpenSurah(surahNo),
        );
        break;
      case 'ibadah_salah':
      case 'ibadah_guide':
        body = IbadahGuideScreen(
          section: IbadahSection.salah,
          onOpenSurah: (surahNo) => widget.onOpenSurah(surahNo),
        );
        break;
      case 'ibadah_rawatib':
        body = IbadahGuideScreen(
          section: IbadahSection.rawatib,
          onOpenSurah: (surahNo) => widget.onOpenSurah(surahNo),
        );
        break;
      case 'ibadah_mayyith':
        body = IbadahGuideScreen(
          section: IbadahSection.mayyith,
          onOpenSurah: (surahNo) => widget.onOpenSurah(surahNo),
        );
        break;
      default:
        body = const SizedBox.shrink();
    }

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
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        _titleFor(t),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18.5,
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
                            onOpenSettings: scope == null
                                ? null
                                : () => Scaffold.of(drawerCtx).openEndDrawer(),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  _titleFor(t),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18.5,
                    color: Colors.white,
                  ),
                ),
          actions: settings.tvModeEnabled
              ? const []
              : [
                  const TvModeActionButton(),
                  if (scope != null)
                    Builder(
                      builder: (drawerCtx) => IconButton(
                        tooltip: t.settings,
                        icon: const Icon(Icons.settings_rounded,
                            color: Colors.white),
                        onPressed: () =>
                            Scaffold.of(drawerCtx).openEndDrawer(),
                      ),
                    )
                  else
                    const SizedBox(width: 6),
                ],
        ),
        endDrawer: scope == null ? null : CompactSettingsDrawer(scope: scope),
        body: Column(
          children: [
            OfflineStatusBanner(strings: t),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class BookmarksListView extends StatelessWidget {
  final ScrollController scrollController;
  final List<String> bookmarks;
  final List<SurahSummary> surahs;
  final AppStrings strings;
  final bool tvModeEnabled;
  final void Function(int surahNo, {int? ayahNo}) onOpenSurah;

  const BookmarksListView({
    super.key,
    required this.scrollController,
    required this.bookmarks,
    required this.surahs,
    required this.strings,
    this.tvModeEnabled = false,
    required this.onOpenSurah,
  });

  SurahSummary? _findSurah(int surahNo) {
    for (final s in surahs) {
      if (s.number == surahNo) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            strings.noBookmarks,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final cs = Theme.of(context).colorScheme;
    final hPad = responsivePageHorizontalPadding(
      context,
      tvModeEnabled: tvModeEnabled,
      normalMaxWidth: 860,
    );

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      itemCount: bookmarks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = bookmarks[index];
        final isFullSurah = key.startsWith('surah:');
        if (isFullSurah) {
          final surahNo = int.tryParse(key.substring(6)) ?? 1;
          final summary = _findSurah(surahNo);
          final title = summary == null
              ? '${strings.surahLabel} $surahNo'
              : (strings.lang == 'ar'
                  ? '${summary.number}. ${summary.nameArabic}'
                  : '${summary.number}. ${summary.englishName}');

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              foregroundColor: cs.onPrimaryContainer,
              child: const Icon(Icons.menu_book_rounded, size: 20),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    strings.fullSurahBadge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: summary != null
                ? Text(
                    '${summary.numberOfAyahs} ${strings.ayahsLabel} • ${summary.nameArabic}',
                    style: const TextStyle(fontSize: 12.5),
                  )
                : null,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => onOpenSurah(surahNo),
          );
        }

        final parts = key.split(':');
        final surahNo = int.tryParse(parts.first) ?? 1;
        final ayahNo = parts.length > 1 ? parts[1] : '1';
        final summary = _findSurah(surahNo);
        final surahTitle = summary == null
            ? '${strings.surahLabel} $surahNo'
            : (strings.lang == 'ar'
                ? summary.nameArabic
                : '${summary.number}. ${summary.englishName}');

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: cs.surfaceContainerHighest,
            foregroundColor: cs.primary,
            child: const Icon(Icons.bookmark_rounded, size: 20),
          ),
          title: Text(
            '$surahTitle — ${strings.ayahLabel} $ayahNo',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onOpenSurah(
            surahNo,
            ayahNo: int.tryParse(ayahNo),
          ),
        );
      },
    );
  }
}

Widget _buildQuranSubTabBar({
  required TabController controller,
  required List<Widget> tabs,
}) {
  return Container(
    height: 44,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.14),
      ),
    ),
    child: TabBar(
      controller: controller,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      indicator: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      labelColor: AppBranding.darkEmerald,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.90),
      labelPadding: EdgeInsets.zero,
      splashBorderRadius: BorderRadius.circular(10),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12.5,
      ),
      tabs: tabs,
    ),
  );
}

class _HeaderIconTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeaderIconTab({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 36,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 3),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
