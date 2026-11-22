import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String appLanguage; // 'en' (default) | 'ml' | 'ar'
  final String readingMode; // 'mushaf' | 'verse'
  final String themeMode; // 'light' | 'sepia' | 'dark'
  final double arabicFontSize;
  final double translationFontSize;
  final bool showTranslation;
  final List<String> selectedTranslations; // any subset of ['en', 'ml', 'ar']
  final double autoScrollSpeed; // 0.25x to 4.0x
  final String reciterId;
  /// Normalized relative position (0.0 .. 1.0) inside safe viewport
  final double? fabRelX;
  final double? fabRelY;

  const AppSettings({
    this.appLanguage = 'en',
    this.readingMode = 'mushaf',
    this.themeMode = 'sepia',
    this.arabicFontSize = 27.0,
    this.translationFontSize = 15.0,
    this.showTranslation = false,
    this.selectedTranslations = const ['en'],
    this.autoScrollSpeed = 1.0,
    this.reciterId = 'ar.alafasy',
    this.fabRelX,
    this.fabRelY,
  });

  AppSettings copyWith({
    String? appLanguage,
    String? readingMode,
    String? themeMode,
    double? arabicFontSize,
    double? translationFontSize,
    bool? showTranslation,
    List<String>? selectedTranslations,
    double? autoScrollSpeed,
    String? reciterId,
    double? fabRelX,
    double? fabRelY,
    bool clearFabPos = false,
  }) {
    return AppSettings(
      appLanguage: appLanguage ?? this.appLanguage,
      readingMode: readingMode ?? this.readingMode,
      themeMode: themeMode ?? this.themeMode,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      selectedTranslations: selectedTranslations ?? this.selectedTranslations,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      reciterId: reciterId ?? this.reciterId,
      fabRelX: clearFabPos ? null : (fabRelX ?? this.fabRelX),
      fabRelY: clearFabPos ? null : (fabRelY ?? this.fabRelY),
    );
  }
}

class LastReadPosition {
  final int surahNumber;
  final String surahName;
  final String surahArabicName;
  final int ayahNumber;
  final int? pageNumber;
  final double anchorOffsetPx;
  final String readingMode;

  const LastReadPosition({
    required this.surahNumber,
    required this.surahName,
    this.surahArabicName = '',
    required this.ayahNumber,
    this.pageNumber,
    this.anchorOffsetPx = 0.0,
    this.readingMode = 'mushaf',
  });

  factory LastReadPosition.fromJson(Map<String, dynamic> json) =>
      LastReadPosition(
        surahNumber: json['surahNumber'] as int,
        surahName: (json['surahName'] ?? '') as String,
        surahArabicName: (json['surahArabicName'] ?? '') as String,
        ayahNumber: (json['ayahNumber'] ?? 1) as int,
        pageNumber: json['pageNumber'] as int?,
        anchorOffsetPx: (json['anchorOffsetPx'] as num?)?.toDouble() ?? 0.0,
        readingMode: (json['readingMode'] ?? 'mushaf') as String,
      );

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'surahArabicName': surahArabicName,
        'ayahNumber': ayahNumber,
        if (pageNumber != null) 'pageNumber': pageNumber,
        'anchorOffsetPx': anchorOffsetPx,
        'readingMode': readingMode,
      };
}

class AppResumeState {
  final String lastScreen; // 'home' | 'reader'
  final int homeTabIndex; // 0: Surahs, 1: Bookmarks, 2: Export
  final int quranSubTabIndex; // 0: Surah, 1: Juz
  final double surahListScrollOffset;
  final double juzListScrollOffset;
  final double bookmarksScrollOffset;
  final int? activeSurahNumber;
  final int? activeAyahNumber;
  final int? activePageNumber;
  final double activeAnchorOffsetPx;
  final String activeReadingMode;

  const AppResumeState({
    this.lastScreen = 'home',
    this.homeTabIndex = 0,
    this.quranSubTabIndex = 0,
    this.surahListScrollOffset = 0.0,
    this.juzListScrollOffset = 0.0,
    this.bookmarksScrollOffset = 0.0,
    this.activeSurahNumber,
    this.activeAyahNumber,
    this.activePageNumber,
    this.activeAnchorOffsetPx = 0.0,
    this.activeReadingMode = 'mushaf',
  });

  AppResumeState copyWith({
    String? lastScreen,
    int? homeTabIndex,
    int? quranSubTabIndex,
    double? surahListScrollOffset,
    double? juzListScrollOffset,
    double? bookmarksScrollOffset,
    int? activeSurahNumber,
    int? activeAyahNumber,
    int? activePageNumber,
    double? activeAnchorOffsetPx,
    String? activeReadingMode,
  }) {
    return AppResumeState(
      lastScreen: lastScreen ?? this.lastScreen,
      homeTabIndex: homeTabIndex ?? this.homeTabIndex,
      quranSubTabIndex: quranSubTabIndex ?? this.quranSubTabIndex,
      surahListScrollOffset:
          surahListScrollOffset ?? this.surahListScrollOffset,
      juzListScrollOffset: juzListScrollOffset ?? this.juzListScrollOffset,
      bookmarksScrollOffset:
          bookmarksScrollOffset ?? this.bookmarksScrollOffset,
      activeSurahNumber: activeSurahNumber ?? this.activeSurahNumber,
      activeAyahNumber: activeAyahNumber ?? this.activeAyahNumber,
      activePageNumber: activePageNumber ?? this.activePageNumber,
      activeAnchorOffsetPx: activeAnchorOffsetPx ?? this.activeAnchorOffsetPx,
      activeReadingMode: activeReadingMode ?? this.activeReadingMode,
    );
  }

  factory AppResumeState.fromJson(Map<String, dynamic> json) => AppResumeState(
        lastScreen: (json['lastScreen'] ?? 'home') as String,
        homeTabIndex: (json['homeTabIndex'] as num?)?.toInt() ?? 0,
        quranSubTabIndex: (json['quranSubTabIndex'] as num?)?.toInt() ?? 0,
        surahListScrollOffset:
            (json['surahListScrollOffset'] as num?)?.toDouble() ?? 0.0,
        juzListScrollOffset:
            (json['juzListScrollOffset'] as num?)?.toDouble() ?? 0.0,
        bookmarksScrollOffset:
            (json['bookmarksScrollOffset'] as num?)?.toDouble() ?? 0.0,
        activeSurahNumber: (json['activeSurahNumber'] as num?)?.toInt(),
        activeAyahNumber: (json['activeAyahNumber'] as num?)?.toInt(),
        activePageNumber: (json['activePageNumber'] as num?)?.toInt(),
        activeAnchorOffsetPx:
            (json['activeAnchorOffsetPx'] as num?)?.toDouble() ?? 0.0,
        activeReadingMode: (json['activeReadingMode'] ?? 'mushaf') as String,
      );

  Map<String, dynamic> toJson() => {
        'lastScreen': lastScreen,
        'homeTabIndex': homeTabIndex,
        'quranSubTabIndex': quranSubTabIndex,
        'surahListScrollOffset': surahListScrollOffset,
        'juzListScrollOffset': juzListScrollOffset,
        'bookmarksScrollOffset': bookmarksScrollOffset,
        if (activeSurahNumber != null) 'activeSurahNumber': activeSurahNumber,
        if (activeAyahNumber != null) 'activeAyahNumber': activeAyahNumber,
        if (activePageNumber != null) 'activePageNumber': activePageNumber,
        'activeAnchorOffsetPx': activeAnchorOffsetPx,
        'activeReadingMode': activeReadingMode,
      };
}

class StorageService {
  static const _bookmarksKey = 'user_bookmarks_v3';
  static const _lastReadKey = 'user_last_read_v3';
  static const _resumeStateKey = 'user_resume_state_v4';
  static const _appLangKey = 'pref_app_lang_v3';
  static const _readModeKey = 'pref_read_mode_v3';
  static const _themeKey = 'pref_theme_mode_v3';
  static const _arSizeKey = 'pref_arabic_size_v3';
  static const _trSizeKey = 'pref_trans_size_v3';
  static const _showTransKey = 'pref_show_trans_v3';
  static const _selTransKey = 'pref_selected_trans_v3';
  static const _scrollSpeedKey = 'pref_scroll_speed_v3';
  static const _reciterIdKey = 'pref_reciter_id_v4';
  static const _fabRelXKey = 'pref_fab_rel_x_v4';
  static const _fabRelYKey = 'pref_fab_rel_y_v4';

  Future<SharedPreferences>? _prefsFuture;
  Future<SharedPreferences> get _prefs =>
      _prefsFuture ??= SharedPreferences.getInstance();

  Future<List<String>> loadBookmarks() async {
    final prefs = await _prefs;
    return prefs.getStringList(_bookmarksKey) ?? <String>[];
  }

  Future<void> saveBookmarks(List<String> keys) async {
    final prefs = await _prefs;
    await prefs.setStringList(_bookmarksKey, keys);
  }

  Future<LastReadPosition?> loadLastRead() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_lastReadKey);
    if (raw == null) return null;
    try {
      return LastReadPosition.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastRead(LastReadPosition pos) async {
    final prefs = await _prefs;
    await prefs.setString(_lastReadKey, jsonEncode(pos.toJson()));
  }

  Future<AppResumeState> loadResumeState() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_resumeStateKey);
    if (raw == null) return const AppResumeState();
    try {
      return AppResumeState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppResumeState();
    }
  }

  Future<void> saveResumeState(AppResumeState state) async {
    final prefs = await _prefs;
    await prefs.setString(_resumeStateKey, jsonEncode(state.toJson()));
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await _prefs;
    final savedTrans = prefs.getStringList(_selTransKey);
    return AppSettings(
      appLanguage: prefs.getString(_appLangKey) ?? 'en',
      readingMode: prefs.getString(_readModeKey) ?? 'mushaf',
      themeMode: prefs.getString(_themeKey) ?? 'sepia',
      arabicFontSize: prefs.getDouble(_arSizeKey) ?? 27.0,
      translationFontSize: prefs.getDouble(_trSizeKey) ?? 15.0,
      showTranslation: prefs.getBool(_showTransKey) ?? false,
      selectedTranslations:
          (savedTrans != null && savedTrans.isNotEmpty) ? savedTrans : ['en'],
      autoScrollSpeed: prefs.getDouble(_scrollSpeedKey) ?? 1.0,
      reciterId: prefs.getString(_reciterIdKey) ?? 'ar.alafasy',
      fabRelX: prefs.getDouble(_fabRelXKey),
      fabRelY: prefs.getDouble(_fabRelYKey),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString(_appLangKey, settings.appLanguage);
    await prefs.setString(_readModeKey, settings.readingMode);
    await prefs.setString(_themeKey, settings.themeMode);
    await prefs.setDouble(_arSizeKey, settings.arabicFontSize);
    await prefs.setDouble(_trSizeKey, settings.translationFontSize);
    await prefs.setBool(_showTransKey, settings.showTranslation);
    await prefs.setStringList(_selTransKey, settings.selectedTranslations);
    await prefs.setDouble(_scrollSpeedKey, settings.autoScrollSpeed);
    await prefs.setString(_reciterIdKey, settings.reciterId);
    if (settings.fabRelX != null && settings.fabRelY != null) {
      await prefs.setDouble(_fabRelXKey, settings.fabRelX!);
      await prefs.setDouble(_fabRelYKey, settings.fabRelY!);
    } else {
      await prefs.remove(_fabRelXKey);
      await prefs.remove(_fabRelYKey);
    }
  }
}
