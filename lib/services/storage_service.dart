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

  // Prayer Times, Qibla & Hijri Calendar settings
  final String prayerLocationMode; // 'city' | 'gps'
  final String prayerCity;
  final String prayerCountry;
  final double prayerLat;
  final double prayerLon;
  final String? gpsLocalityLabel;
  final int prayerMethod; // default 1 = Karachi (UISK)
  final int prayerSchool; // default 0 = Shafi / Standard, 1 = Hanafi
  final int prayerTuneFajr;
  final int prayerTuneDhuhr;
  final int prayerTuneAsr;
  final int prayerTuneMaghrib;
  final int prayerTuneIsha;
  final int hijriAdjustment; // -1, 0, +1

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
    this.prayerLocationMode = 'city',
    this.prayerCity = 'Kochi',
    this.prayerCountry = 'India',
    this.prayerLat = 9.9312,
    this.prayerLon = 76.2673,
    this.gpsLocalityLabel,
    this.prayerMethod = 1,
    this.prayerSchool = 0,
    this.prayerTuneFajr = 0,
    this.prayerTuneDhuhr = 0,
    this.prayerTuneAsr = 0,
    this.prayerTuneMaghrib = 0,
    this.prayerTuneIsha = 0,
    this.hijriAdjustment = 0,
  });

  int tuneFor(String prayerKey) {
    switch (prayerKey) {
      case 'fajr':
        return prayerTuneFajr;
      case 'dhuhr':
        return prayerTuneDhuhr;
      case 'asr':
        return prayerTuneAsr;
      case 'maghrib':
        return prayerTuneMaghrib;
      case 'isha':
        return prayerTuneIsha;
      default:
        return 0;
    }
  }

  bool get hasAnyTune =>
      prayerTuneFajr != 0 ||
      prayerTuneDhuhr != 0 ||
      prayerTuneAsr != 0 ||
      prayerTuneMaghrib != 0 ||
      prayerTuneIsha != 0;

  String get displayLocationLabel {
    if (prayerLocationMode == 'gps') {
      if (gpsLocalityLabel != null && gpsLocalityLabel!.trim().isNotEmpty) {
        return gpsLocalityLabel!.trim();
      }
      return '${prayerLat.toStringAsFixed(2)}°, ${prayerLon.toStringAsFixed(2)}°';
    }
    return '$prayerCity, $prayerCountry';
  }

  AppSettings copyWithTune(String prayerKey, int minutes) {
    final clamped = minutes.clamp(-60, 60);
    switch (prayerKey) {
      case 'fajr':
        return copyWith(prayerTuneFajr: clamped);
      case 'dhuhr':
        return copyWith(prayerTuneDhuhr: clamped);
      case 'asr':
        return copyWith(prayerTuneAsr: clamped);
      case 'maghrib':
        return copyWith(prayerTuneMaghrib: clamped);
      case 'isha':
        return copyWith(prayerTuneIsha: clamped);
      default:
        return this;
    }
  }

  AppSettings clearTunes() => copyWith(
        prayerTuneFajr: 0,
        prayerTuneDhuhr: 0,
        prayerTuneAsr: 0,
        prayerTuneMaghrib: 0,
        prayerTuneIsha: 0,
      );

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
    String? prayerLocationMode,
    String? prayerCity,
    String? prayerCountry,
    double? prayerLat,
    double? prayerLon,
    String? gpsLocalityLabel,
    bool clearGpsLocality = false,
    int? prayerMethod,
    int? prayerSchool,
    int? prayerTuneFajr,
    int? prayerTuneDhuhr,
    int? prayerTuneAsr,
    int? prayerTuneMaghrib,
    int? prayerTuneIsha,
    int? hijriAdjustment,
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
      prayerLocationMode: prayerLocationMode ?? this.prayerLocationMode,
      prayerCity: prayerCity ?? this.prayerCity,
      prayerCountry: prayerCountry ?? this.prayerCountry,
      prayerLat: prayerLat ?? this.prayerLat,
      prayerLon: prayerLon ?? this.prayerLon,
      gpsLocalityLabel: clearGpsLocality
          ? null
          : (gpsLocalityLabel ?? this.gpsLocalityLabel),
      prayerMethod: prayerMethod ?? this.prayerMethod,
      prayerSchool: prayerSchool ?? this.prayerSchool,
      prayerTuneFajr: prayerTuneFajr ?? this.prayerTuneFajr,
      prayerTuneDhuhr: prayerTuneDhuhr ?? this.prayerTuneDhuhr,
      prayerTuneAsr: prayerTuneAsr ?? this.prayerTuneAsr,
      prayerTuneMaghrib: prayerTuneMaghrib ?? this.prayerTuneMaghrib,
      prayerTuneIsha: prayerTuneIsha ?? this.prayerTuneIsha,
      hijriAdjustment: (hijriAdjustment ?? this.hijriAdjustment).clamp(-1, 1),
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
  final int homeTabIndex; // 0: Quran, 1: Features, 2: Settings
  final int quranSubTabIndex; // 0: Surah, 1: Juz, 2: Bookmarks, 3: Export
  final int featuresSubTabIndex; // 0: Prayer Times, 1: Qibla, 2: Hijri
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
    this.featuresSubTabIndex = 0,
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
    int? featuresSubTabIndex,
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
      featuresSubTabIndex: featuresSubTabIndex ?? this.featuresSubTabIndex,
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
        featuresSubTabIndex: (json['featuresSubTabIndex'] as num?)?.toInt() ?? 0,
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
        'featuresSubTabIndex': featuresSubTabIndex,
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

  // Islamic Features preferences
  static const _prayerLocModeKey = 'pref_prayer_loc_mode_v1';
  static const _prayerCityKey = 'pref_prayer_city_v1';
  static const _prayerCountryKey = 'pref_prayer_country_v1';
  static const _prayerLatKey = 'pref_prayer_lat_v1';
  static const _prayerLonKey = 'pref_prayer_lon_v1';
  static const _gpsLocalityKey = 'pref_gps_locality_v1';
  static const _prayerMethodKey = 'pref_prayer_method_v1';
  static const _prayerSchoolKey = 'pref_prayer_school_v1';
  static const _tuneFajrKey = 'pref_tune_fajr_v1';
  static const _tuneDhuhrKey = 'pref_tune_dhuhr_v1';
  static const _tuneAsrKey = 'pref_tune_asr_v1';
  static const _tuneMaghribKey = 'pref_tune_maghrib_v1';
  static const _tuneIshaKey = 'pref_tune_isha_v1';
  static const _hijriAdjKey = 'pref_hijri_adj_v1';

  // Offline API caches
  static const _dailyPrayerCacheKey = 'prayer_daily_cache_v1';
  static const _hijriCalCachePrefix = 'hijri_cal_cache_v1_';

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
      prayerLocationMode: prefs.getString(_prayerLocModeKey) ?? 'city',
      prayerCity: prefs.getString(_prayerCityKey) ?? 'Kochi',
      prayerCountry: prefs.getString(_prayerCountryKey) ?? 'India',
      prayerLat: prefs.getDouble(_prayerLatKey) ?? 9.9312,
      prayerLon: prefs.getDouble(_prayerLonKey) ?? 76.2673,
      gpsLocalityLabel: prefs.getString(_gpsLocalityKey),
      prayerMethod: prefs.getInt(_prayerMethodKey) ?? 1,
      prayerSchool: prefs.getInt(_prayerSchoolKey) ?? 0,
      prayerTuneFajr: prefs.getInt(_tuneFajrKey) ?? 0,
      prayerTuneDhuhr: prefs.getInt(_tuneDhuhrKey) ?? 0,
      prayerTuneAsr: prefs.getInt(_tuneAsrKey) ?? 0,
      prayerTuneMaghrib: prefs.getInt(_tuneMaghribKey) ?? 0,
      prayerTuneIsha: prefs.getInt(_tuneIshaKey) ?? 0,
      hijriAdjustment: (prefs.getInt(_hijriAdjKey) ?? 0).clamp(-1, 1),
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

    await prefs.setString(_prayerLocModeKey, settings.prayerLocationMode);
    await prefs.setString(_prayerCityKey, settings.prayerCity);
    await prefs.setString(_prayerCountryKey, settings.prayerCountry);
    await prefs.setDouble(_prayerLatKey, settings.prayerLat);
    await prefs.setDouble(_prayerLonKey, settings.prayerLon);
    if (settings.gpsLocalityLabel != null) {
      await prefs.setString(_gpsLocalityKey, settings.gpsLocalityLabel!);
    } else {
      await prefs.remove(_gpsLocalityKey);
    }
    await prefs.setInt(_prayerMethodKey, settings.prayerMethod);
    await prefs.setInt(_prayerSchoolKey, settings.prayerSchool);
    await prefs.setInt(_tuneFajrKey, settings.prayerTuneFajr);
    await prefs.setInt(_tuneDhuhrKey, settings.prayerTuneDhuhr);
    await prefs.setInt(_tuneAsrKey, settings.prayerTuneAsr);
    await prefs.setInt(_tuneMaghribKey, settings.prayerTuneMaghrib);
    await prefs.setInt(_tuneIshaKey, settings.prayerTuneIsha);
    await prefs.setInt(_hijriAdjKey, settings.hijriAdjustment);
  }

  Future<Map<String, dynamic>?> loadDailyPrayerCache() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_dailyPrayerCacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyPrayerCache(Map<String, dynamic> payload) async {
    final prefs = await _prefs;
    await prefs.setString(_dailyPrayerCacheKey, jsonEncode(payload));
  }

  Future<List<dynamic>?> loadHijriCalendarCache(
    int year,
    int month,
    int adjustment,
  ) async {
    final prefs = await _prefs;
    final raw =
        prefs.getString('$_hijriCalCachePrefix${year}_${month}_adj$adjustment');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHijriCalendarCache(
    int year,
    int month,
    int adjustment,
    List<Map<String, dynamic>> entries,
  ) async {
    final prefs = await _prefs;
    await prefs.setString(
      '$_hijriCalCachePrefix${year}_${month}_adj$adjustment',
      jsonEncode(entries),
    );
  }
}
