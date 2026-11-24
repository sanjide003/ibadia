import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../models/adhkar_tasbih_model.dart';
import '../models/islamic_features_model.dart';
import 'hive_db.dart';

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

  // Prayer Times & Hijri Calendar settings (nullable backing fields for DDC hot-reload safety)
  final String? _prayerLocationMode; // 'city' | 'gps'
  final String? _prayerCity;
  final String? _prayerCountry;
  final double? _prayerLat;
  final double? _prayerLon;
  final String? gpsLocalityLabel;
  final int? _prayerMethod; // default 1 = Karachi (UISK)
  final int? _prayerSchool; // default 0 = Shafi / Standard, 1 = Hanafi
  final int? _prayerTuneFajr;
  final int? _prayerTuneDhuhr;
  final int? _prayerTuneAsr;
  final int? _prayerTuneMaghrib;
  final int? _prayerTuneIsha;
  final int? _hijriAdjustment; // -1, 0, +1

  // Prayer Alarm & Sound settings
  final bool? _prayerAlarmMasterEnabled;
  final String? _alarmSoundType; // 'adhan_alafasy' | 'adhan_nafees' | 'alarm_tone'
  final double? _alarmVolume; // 0.1..1.0
  final bool? _alarmVibrate;
  final Map<String, PrayerAlarmConfig>? _prayerConfigs;

  // Surah Al-Kahf Reminder settings (Thursday 7:00 PM & Friday 8:00 AM)
  final bool? _kahfThursdayEnabled;
  final bool? _kahfFridayEnabled;
  final int? _kahfThuHour;
  final int? _kahfThuMinute;
  final int? _kahfFriHour;
  final int? _kahfFriMinute;

  String get prayerLocationMode => _prayerLocationMode ?? 'city';
  String get prayerCity => _prayerCity ?? 'Kochi';
  String get prayerCountry => _prayerCountry ?? 'India';
  double get prayerLat => _prayerLat ?? 9.9312;
  double get prayerLon => _prayerLon ?? 76.2673;
  int get prayerMethod => _prayerMethod ?? 1;
  int get prayerSchool => _prayerSchool ?? 0;
  int get prayerTuneFajr => _prayerTuneFajr ?? 0;
  int get prayerTuneDhuhr => _prayerTuneDhuhr ?? 0;
  int get prayerTuneAsr => _prayerTuneAsr ?? 0;
  int get prayerTuneMaghrib => _prayerTuneMaghrib ?? 0;
  int get prayerTuneIsha => _prayerTuneIsha ?? 0;
  int get hijriAdjustment => (_hijriAdjustment ?? 0).clamp(-1, 1);

  // Prayer Auto-Silent (DND) settings (Iqamah -> +N min, default 15 min)
  final bool? _autoSilentEnabled;
  final int? _autoSilentDurationMinutes;
  final Map<String, bool>? _autoSilentPrayers;

  bool get prayerAlarmMasterEnabled => _prayerAlarmMasterEnabled ?? false;
  String get alarmSoundType => _alarmSoundType ?? 'adhan_alafasy';
  double get alarmVolume => (_alarmVolume ?? 0.85).clamp(0.1, 1.0);
  bool get alarmVibrate => _alarmVibrate ?? true;
  Map<String, PrayerAlarmConfig> get prayerConfigs =>
      _prayerConfigs ?? AlAdhanCatalog.defaultPrayerConfigs();

  bool get kahfThursdayEnabled => _kahfThursdayEnabled ?? true;
  bool get kahfFridayEnabled => _kahfFridayEnabled ?? true;
  int get kahfThuHour => (_kahfThuHour ?? 19).clamp(0, 23);
  int get kahfThuMinute => (_kahfThuMinute ?? 0).clamp(0, 59);
  int get kahfFriHour => (_kahfFriHour ?? 8).clamp(0, 23);
  int get kahfFriMinute => (_kahfFriMinute ?? 0).clamp(0, 59);

  bool get autoSilentEnabled => _autoSilentEnabled ?? false;
  int get autoSilentDurationMinutes =>
      (_autoSilentDurationMinutes ?? 15).clamp(5, 60);
  Map<String, bool> get autoSilentPrayers =>
      _autoSilentPrayers ??
      const {
        'fajr': true,
        'dhuhr': true,
        'asr': true,
        'maghrib': true,
        'isha': true,
      };
  bool isAutoSilentEnabledFor(String prayerKey) =>
      autoSilentPrayers[prayerKey] ?? true;

  // 99 Names & Export persisted preferences (nullable backing fields for DDC safety)
  final String? _names99ViewMode; // 'grid' | 'list'
  final String? _exportScope; // 'range' | 'surah' | 'juz'
  final int? _exportSurahNo;
  final int? _exportJuzNo;
  final int? _exportFromAyah;
  final int? _exportToAyah;
  final String? _exportFormat; // 'pdf' | 'image'
  final bool? _exportIncludeTranslation;
  final List<String>? _exportTranslationCodes;

  String get names99ViewMode => _names99ViewMode == 'list' ? 'list' : 'grid';
  String get exportScope =>
      (_exportScope == 'surah' || _exportScope == 'juz') ? _exportScope! : 'range';
  int get exportSurahNo => (_exportSurahNo ?? 1).clamp(1, 114);
  int get exportJuzNo => (_exportJuzNo ?? 1).clamp(1, 30);
  int get exportFromAyah => (_exportFromAyah ?? 1).clamp(1, 286);
  int get exportToAyah => (_exportToAyah ?? 7).clamp(1, 286);
  String get exportFormat => _exportFormat == 'image' ? 'image' : 'pdf';
  bool? get exportIncludeTranslation => _exportIncludeTranslation;
  List<String>? get exportTranslationCodes => _exportTranslationCodes;

  // Ibadah & Salah Guide display preferences (nullable backing fields for DDC safety)
  final bool? _ibadahShowTransliteration;
  final bool? _ibadahShowMeaning;
  final bool? _ibadahShowNotes;
  final bool? _ibadahShowAudio;
  final bool? _ibadahMalayalamHeadings;

  bool get ibadahShowTransliteration => _ibadahShowTransliteration ?? false;
  bool get ibadahShowMeaning => _ibadahShowMeaning ?? false;
  bool get ibadahShowNotes => _ibadahShowNotes ?? false;
  bool get ibadahShowAudio => _ibadahShowAudio ?? false;
  bool get ibadahMalayalamHeadings => _ibadahMalayalamHeadings ?? true;

  // TV / Classroom Mode preferences (nullable backing fields for DDC safety)
  final bool? _tvModeEnabled;
  final double? _tvFontScale;

  bool get tvModeEnabled => _tvModeEnabled ?? false;
  double get tvFontScale => (_tvFontScale ?? 1.0).clamp(0.85, 2.2);

  PrayerAlarmConfig alarmConfigFor(String prayerKey) =>
      prayerConfigs[prayerKey] ?? PrayerAlarmConfig(prayerKey: prayerKey);

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
    String? prayerLocationMode = 'city',
    String? prayerCity = 'Kochi',
    String? prayerCountry = 'India',
    double? prayerLat = 9.9312,
    double? prayerLon = 76.2673,
    this.gpsLocalityLabel,
    int? prayerMethod = 1,
    int? prayerSchool = 0,
    int? prayerTuneFajr = 0,
    int? prayerTuneDhuhr = 0,
    int? prayerTuneAsr = 0,
    int? prayerTuneMaghrib = 0,
    int? prayerTuneIsha = 0,
    int? hijriAdjustment = 0,
    bool? prayerAlarmMasterEnabled = false,
    String? alarmSoundType = 'adhan_alafasy',
    double? alarmVolume = 0.85,
    bool? alarmVibrate = true,
    Map<String, PrayerAlarmConfig>? prayerConfigs,
    bool? kahfThursdayEnabled = true,
    bool? kahfFridayEnabled = true,
    int? kahfThuHour = 19,
    int? kahfThuMinute = 0,
    int? kahfFriHour = 8,
    int? kahfFriMinute = 0,
    bool? autoSilentEnabled = false,
    int? autoSilentDurationMinutes = 15,
    Map<String, bool>? autoSilentPrayers,
    String? names99ViewMode = 'grid',
    String? exportScope = 'range',
    int? exportSurahNo = 1,
    int? exportJuzNo = 1,
    int? exportFromAyah = 1,
    int? exportToAyah = 7,
    String? exportFormat = 'pdf',
    bool? exportIncludeTranslation,
    List<String>? exportTranslationCodes,
    bool? ibadahShowTransliteration = false,
    bool? ibadahShowMeaning = false,
    bool? ibadahShowNotes = false,
    bool? ibadahShowAudio = false,
    bool? ibadahMalayalamHeadings = true,
    bool? tvModeEnabled = false,
    double? tvFontScale = 1.0,
  })  : _prayerLocationMode = prayerLocationMode,
        _prayerCity = prayerCity,
        _prayerCountry = prayerCountry,
        _prayerLat = prayerLat,
        _prayerLon = prayerLon,
        _prayerMethod = prayerMethod,
        _prayerSchool = prayerSchool,
        _prayerTuneFajr = prayerTuneFajr,
        _prayerTuneDhuhr = prayerTuneDhuhr,
        _prayerTuneAsr = prayerTuneAsr,
        _prayerTuneMaghrib = prayerTuneMaghrib,
        _prayerTuneIsha = prayerTuneIsha,
        _hijriAdjustment = hijriAdjustment,
        _prayerAlarmMasterEnabled = prayerAlarmMasterEnabled,
        _alarmSoundType = alarmSoundType,
        _alarmVolume = alarmVolume,
        _alarmVibrate = alarmVibrate,
        _prayerConfigs = prayerConfigs,
        _kahfThursdayEnabled = kahfThursdayEnabled,
        _kahfFridayEnabled = kahfFridayEnabled,
        _kahfThuHour = kahfThuHour,
        _kahfThuMinute = kahfThuMinute,
        _kahfFriHour = kahfFriHour,
        _kahfFriMinute = kahfFriMinute,
        _autoSilentEnabled = autoSilentEnabled,
        _autoSilentDurationMinutes = autoSilentDurationMinutes,
        _autoSilentPrayers = autoSilentPrayers,
        _names99ViewMode = names99ViewMode,
        _exportScope = exportScope,
        _exportSurahNo = exportSurahNo,
        _exportJuzNo = exportJuzNo,
        _exportFromAyah = exportFromAyah,
        _exportToAyah = exportToAyah,
        _exportFormat = exportFormat,
        _exportIncludeTranslation = exportIncludeTranslation,
        _exportTranslationCodes = exportTranslationCodes,
        _ibadahShowTransliteration = ibadahShowTransliteration,
        _ibadahShowMeaning = ibadahShowMeaning,
        _ibadahShowNotes = ibadahShowNotes,
        _ibadahShowAudio = ibadahShowAudio,
        _ibadahMalayalamHeadings = ibadahMalayalamHeadings,
        _tvModeEnabled = tvModeEnabled,
        _tvFontScale = tvFontScale;

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

  AppSettings copyWithPrayerAlarmConfig(PrayerAlarmConfig nextConfig) {
    final updated = Map<String, PrayerAlarmConfig>.from(prayerConfigs);
    updated[nextConfig.prayerKey] = nextConfig;
    return copyWith(prayerConfigs: updated);
  }

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
    bool? prayerAlarmMasterEnabled,
    String? alarmSoundType,
    double? alarmVolume,
    bool? alarmVibrate,
    Map<String, PrayerAlarmConfig>? prayerConfigs,
    bool? kahfThursdayEnabled,
    bool? kahfFridayEnabled,
    int? kahfThuHour,
    int? kahfThuMinute,
    int? kahfFriHour,
    int? kahfFriMinute,
    bool? autoSilentEnabled,
    int? autoSilentDurationMinutes,
    Map<String, bool>? autoSilentPrayers,
    String? names99ViewMode,
    String? exportScope,
    int? exportSurahNo,
    int? exportJuzNo,
    int? exportFromAyah,
    int? exportToAyah,
    String? exportFormat,
    bool? exportIncludeTranslation,
    List<String>? exportTranslationCodes,
    bool? ibadahShowTransliteration,
    bool? ibadahShowMeaning,
    bool? ibadahShowNotes,
    bool? ibadahShowAudio,
    bool? ibadahMalayalamHeadings,
    bool? tvModeEnabled,
    double? tvFontScale,
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
      prayerAlarmMasterEnabled:
          prayerAlarmMasterEnabled ?? this.prayerAlarmMasterEnabled,
      alarmSoundType: alarmSoundType ?? this.alarmSoundType,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      alarmVibrate: alarmVibrate ?? this.alarmVibrate,
      prayerConfigs: prayerConfigs ?? this.prayerConfigs,
      kahfThursdayEnabled: kahfThursdayEnabled ?? this.kahfThursdayEnabled,
      kahfFridayEnabled: kahfFridayEnabled ?? this.kahfFridayEnabled,
      kahfThuHour: kahfThuHour ?? this.kahfThuHour,
      kahfThuMinute: kahfThuMinute ?? this.kahfThuMinute,
      kahfFriHour: kahfFriHour ?? this.kahfFriHour,
      kahfFriMinute: kahfFriMinute ?? this.kahfFriMinute,
      autoSilentEnabled: autoSilentEnabled ?? this.autoSilentEnabled,
      autoSilentDurationMinutes:
          autoSilentDurationMinutes ?? this.autoSilentDurationMinutes,
      autoSilentPrayers: autoSilentPrayers ?? this.autoSilentPrayers,
      names99ViewMode: names99ViewMode ?? this.names99ViewMode,
      exportScope: exportScope ?? this.exportScope,
      exportSurahNo: exportSurahNo ?? this.exportSurahNo,
      exportJuzNo: exportJuzNo ?? this.exportJuzNo,
      exportFromAyah: exportFromAyah ?? this.exportFromAyah,
      exportToAyah: exportToAyah ?? this.exportToAyah,
      exportFormat: exportFormat ?? this.exportFormat,
      exportIncludeTranslation:
          exportIncludeTranslation ?? this.exportIncludeTranslation,
      exportTranslationCodes:
          exportTranslationCodes ?? this.exportTranslationCodes,
      ibadahShowTransliteration:
          ibadahShowTransliteration ?? this.ibadahShowTransliteration,
      ibadahShowMeaning: ibadahShowMeaning ?? this.ibadahShowMeaning,
      ibadahShowNotes: ibadahShowNotes ?? this.ibadahShowNotes,
      ibadahShowAudio: ibadahShowAudio ?? this.ibadahShowAudio,
      ibadahMalayalamHeadings:
          ibadahMalayalamHeadings ?? this.ibadahMalayalamHeadings,
      tvModeEnabled: tvModeEnabled ?? this.tvModeEnabled,
      tvFontScale: (tvFontScale ?? this.tvFontScale).clamp(0.85, 2.2),
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
  final int homeTabIndex; // 0: Home, 1: Quran, 2: Settings
  final int quranSubTabIndex; // 0: Surah, 1: Juz, 2: Bookmarks, 3: Export
  final int? _featuresSubTabIndex; // Standalone feature history index if needed
  int get featuresSubTabIndex => _featuresSubTabIndex ?? 0;
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
    int? featuresSubTabIndex = 0,
    this.surahListScrollOffset = 0.0,
    this.juzListScrollOffset = 0.0,
    this.bookmarksScrollOffset = 0.0,
    this.activeSurahNumber,
    this.activeAyahNumber,
    this.activePageNumber,
    this.activeAnchorOffsetPx = 0.0,
    this.activeReadingMode = 'mushaf',
  }) : _featuresSubTabIndex = featuresSubTabIndex;

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

  // Prayer Alarm & Al-Kahf Reminder preferences
  static const _alarmMasterKey = 'pref_alarm_master_v1';
  static const _alarmSoundKey = 'pref_alarm_sound_v1';
  static const _alarmVolumeKey = 'pref_alarm_volume_v1';
  static const _alarmVibrateKey = 'pref_alarm_vibrate_v1';
  static const _prayerConfigsKey = 'pref_prayer_configs_v1';
  static const _dismissedAlarmsKey = 'prayer_alarm_dismissed_v1';
  static const _kahfThuEnabledKey = 'pref_kahf_thu_enabled_v1';
  static const _kahfFriEnabledKey = 'pref_kahf_fri_enabled_v1';
  static const _kahfThuHourKey = 'pref_kahf_thu_hour_v1';
  static const _kahfThuMinKey = 'pref_kahf_thu_min_v1';
  static const _kahfFriHourKey = 'pref_kahf_fri_hour_v1';
  static const _kahfFriMinKey = 'pref_kahf_fri_min_v1';
  static const _autoSilentEnabledKey = 'pref_auto_silent_enabled_v1';
  static const _autoSilentDurationKey = 'pref_auto_silent_duration_v1';
  static const _autoSilentPrayersKey = 'pref_auto_silent_prayers_v1';
  static const _recentActivityKey = 'user_recent_activity_v1';
  static const _names99ViewModeKey = 'pref_names99_view_mode_v1';
  static const _exportScopeKey = 'pref_export_scope_v1';
  static const _exportSurahKey = 'pref_export_surah_v1';
  static const _exportJuzKey = 'pref_export_juz_v1';
  static const _exportFromKey = 'pref_export_from_v1';
  static const _exportToKey = 'pref_export_to_v1';
  static const _exportFormatKey = 'pref_export_format_v1';
  static const _exportIncludeTransKey = 'pref_export_include_trans_v1';
  static const _exportTransCodesKey = 'pref_export_trans_codes_v1';
  static const _ibadahShowTranslitKey = 'pref_ibadah_show_translit_v1';
  static const _ibadahShowMeaningKey = 'pref_ibadah_show_meaning_v1';
  static const _ibadahShowNotesKey = 'pref_ibadah_show_notes_v1';
  static const _ibadahShowAudioKey = 'pref_ibadah_show_audio_v1';
  static const _ibadahMlHeadingsKey = 'pref_ibadah_ml_headings_v1';
  static const _tvModeEnabledKey = 'pref_tv_mode_enabled_v1';
  static const _tvFontScaleKey = 'pref_tv_font_scale_v1';

  // Offline API caches
  static const _dailyPrayerCacheKey = 'prayer_daily_cache_v1';
  static const _hijriCalCachePrefix = 'hijri_month_cal_v2_';

  // Adhkar & Tasbih Hive keys
  static const _adhkarDailyKeyPrefix = 'adhkar_daily_v1_';
  static const _adhkarFavoritesKey = 'adhkar_favorites_v1';
  static const _kahfBannerDismissedPrefix = 'kahf_banner_dismissed_v1_';
  static const _tasbihSnapshotKey = 'tasbih_snapshot_v1';
  static const _ibadahShartCheckedKey = 'ibadah_salah_shart_checked_v1';

  Future<Box<dynamic>> _prefsBox() async {
    await HiveDb.instance.ensureInitialized();
    return HiveDb.instance.appPrefsBox;
  }

  Future<Box<dynamic>> _islamicBox() async {
    await HiveDb.instance.ensureInitialized();
    return HiveDb.instance.islamicCacheBox;
  }

  Future<Box<dynamic>> _adhkarBox() async {
    await HiveDb.instance.ensureInitialized();
    return HiveDb.instance.adhkarProgressBox;
  }

  Future<Box<dynamic>> _tasbihBox() async {
    await HiveDb.instance.ensureInitialized();
    return HiveDb.instance.tasbihBox;
  }

  T? _readTyped<T>(Box<dynamic> box, String key) {
    final v = box.get(key);
    if (v is T) return v;
    return null;
  }

  int? _readInt(Box<dynamic> box, String key) {
    final v = box.get(key);
    if (v is num) return v.toInt();
    return null;
  }

  double? _readDouble(Box<dynamic> box, String key) {
    final v = box.get(key);
    if (v is num) return v.toDouble();
    return null;
  }

  List<String>? _readStringList(Box<dynamic> box, String key) {
    final v = box.get(key);
    if (v is List) return v.map((e) => e.toString()).toList();
    return null;
  }

  Future<List<String>> loadBookmarks() async {
    final box = await _prefsBox();
    return _readStringList(box, _bookmarksKey) ?? <String>[];
  }

  Future<void> saveBookmarks(List<String> keys) async {
    final box = await _prefsBox();
    await box.put(_bookmarksKey, keys);
  }

  Future<LastReadPosition?> loadLastRead() async {
    final box = await _prefsBox();
    final raw = _readTyped<String>(box, _lastReadKey);
    if (raw == null) return null;
    try {
      return LastReadPosition.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastRead(LastReadPosition pos) async {
    final box = await _prefsBox();
    await box.put(_lastReadKey, jsonEncode(pos.toJson()));
  }

  Future<AppResumeState> loadResumeState() async {
    final box = await _prefsBox();
    final raw = _readTyped<String>(box, _resumeStateKey);
    if (raw == null) return const AppResumeState();
    try {
      return AppResumeState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppResumeState();
    }
  }

  Future<void> saveResumeState(AppResumeState state) async {
    final box = await _prefsBox();
    await box.put(_resumeStateKey, jsonEncode(state.toJson()));
  }

  Future<AppSettings> loadSettings() async {
    final box = await _prefsBox();
    final savedTrans = _readStringList(box, _selTransKey);

    final configs = AlAdhanCatalog.defaultPrayerConfigs();
    final rawConfigs = _readTyped<String>(box, _prayerConfigsKey);
    if (rawConfigs != null) {
      try {
        final decoded = jsonDecode(rawConfigs) as Map<String, dynamic>;
        for (final key in AlAdhanCatalog.fivePrayerKeys) {
          final entry = decoded[key];
          if (entry is Map<String, dynamic>) {
            configs[key] = PrayerAlarmConfig.fromJson(key, entry);
          }
        }
      } catch (_) {}
    }

    final autoSilentPrayersMap = <String, bool>{
      'fajr': true,
      'dhuhr': true,
      'asr': true,
      'maghrib': true,
      'isha': true,
    };
    final rawAutoSilentPrayers = _readTyped<String>(box, _autoSilentPrayersKey);
    if (rawAutoSilentPrayers != null) {
      try {
        final dec = jsonDecode(rawAutoSilentPrayers) as Map<String, dynamic>;
        for (final key in AlAdhanCatalog.fivePrayerKeys) {
          if (dec[key] is bool) {
            autoSilentPrayersMap[key] = dec[key] as bool;
          }
        }
      } catch (_) {}
    }

    return AppSettings(
      appLanguage: _readTyped<String>(box, _appLangKey) ?? 'en',
      readingMode: _readTyped<String>(box, _readModeKey) ?? 'mushaf',
      themeMode: _readTyped<String>(box, _themeKey) ?? 'sepia',
      arabicFontSize: _readDouble(box, _arSizeKey) ?? 27.0,
      translationFontSize: _readDouble(box, _trSizeKey) ?? 15.0,
      showTranslation: _readTyped<bool>(box, _showTransKey) ?? false,
      selectedTranslations:
          (savedTrans != null && savedTrans.isNotEmpty) ? savedTrans : ['en'],
      autoScrollSpeed: _readDouble(box, _scrollSpeedKey) ?? 1.0,
      reciterId: _readTyped<String>(box, _reciterIdKey) ?? 'ar.alafasy',
      fabRelX: _readDouble(box, _fabRelXKey),
      fabRelY: _readDouble(box, _fabRelYKey),
      prayerLocationMode: _readTyped<String>(box, _prayerLocModeKey) ?? 'city',
      prayerCity: _readTyped<String>(box, _prayerCityKey) ?? 'Kochi',
      prayerCountry: _readTyped<String>(box, _prayerCountryKey) ?? 'India',
      prayerLat: _readDouble(box, _prayerLatKey) ?? 9.9312,
      prayerLon: _readDouble(box, _prayerLonKey) ?? 76.2673,
      gpsLocalityLabel: _readTyped<String>(box, _gpsLocalityKey),
      prayerMethod: _readInt(box, _prayerMethodKey) ?? 1,
      prayerSchool: _readInt(box, _prayerSchoolKey) ?? 0,
      prayerTuneFajr: _readInt(box, _tuneFajrKey) ?? 0,
      prayerTuneDhuhr: _readInt(box, _tuneDhuhrKey) ?? 0,
      prayerTuneAsr: _readInt(box, _tuneAsrKey) ?? 0,
      prayerTuneMaghrib: _readInt(box, _tuneMaghribKey) ?? 0,
      prayerTuneIsha: _readInt(box, _tuneIshaKey) ?? 0,
      hijriAdjustment: (_readInt(box, _hijriAdjKey) ?? 0).clamp(-1, 1),
      prayerAlarmMasterEnabled: _readTyped<bool>(box, _alarmMasterKey) ?? false,
      alarmSoundType:
          _readTyped<String>(box, _alarmSoundKey) ?? 'adhan_alafasy',
      alarmVolume: (_readDouble(box, _alarmVolumeKey) ?? 0.85).clamp(0.1, 1.0),
      alarmVibrate: _readTyped<bool>(box, _alarmVibrateKey) ?? true,
      prayerConfigs: configs,
      kahfThursdayEnabled: _readTyped<bool>(box, _kahfThuEnabledKey) ?? true,
      kahfFridayEnabled: _readTyped<bool>(box, _kahfFriEnabledKey) ?? true,
      kahfThuHour: _readInt(box, _kahfThuHourKey) ?? 19,
      kahfThuMinute: _readInt(box, _kahfThuMinKey) ?? 0,
      kahfFriHour: _readInt(box, _kahfFriHourKey) ?? 8,
      kahfFriMinute: _readInt(box, _kahfFriMinKey) ?? 0,
      autoSilentEnabled: _readTyped<bool>(box, _autoSilentEnabledKey) ?? false,
      autoSilentDurationMinutes:
          (_readInt(box, _autoSilentDurationKey) ?? 15).clamp(5, 60),
      autoSilentPrayers: autoSilentPrayersMap,
      names99ViewMode: _readTyped<String>(box, _names99ViewModeKey) ?? 'grid',
      exportScope: _readTyped<String>(box, _exportScopeKey) ?? 'range',
      exportSurahNo: (_readInt(box, _exportSurahKey) ?? 1).clamp(1, 114),
      exportJuzNo: (_readInt(box, _exportJuzKey) ?? 1).clamp(1, 30),
      exportFromAyah: (_readInt(box, _exportFromKey) ?? 1).clamp(1, 286),
      exportToAyah: (_readInt(box, _exportToKey) ?? 7).clamp(1, 286),
      exportFormat: _readTyped<String>(box, _exportFormatKey) ?? 'pdf',
      exportIncludeTranslation: _readTyped<bool>(box, _exportIncludeTransKey),
      exportTranslationCodes: _readStringList(box, _exportTransCodesKey),
      ibadahShowTransliteration:
          _readTyped<bool>(box, _ibadahShowTranslitKey) ?? false,
      ibadahShowMeaning:
          _readTyped<bool>(box, _ibadahShowMeaningKey) ?? false,
      ibadahShowNotes: _readTyped<bool>(box, _ibadahShowNotesKey) ?? false,
      ibadahShowAudio: _readTyped<bool>(box, _ibadahShowAudioKey) ?? false,
      ibadahMalayalamHeadings:
          _readTyped<bool>(box, _ibadahMlHeadingsKey) ?? true,
      tvModeEnabled: _readTyped<bool>(box, _tvModeEnabledKey) ?? false,
      tvFontScale:
          (_readDouble(box, _tvFontScaleKey) ?? 1.0).clamp(0.85, 2.2),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = await _prefsBox();
    await box.putAll({
      _appLangKey: settings.appLanguage,
      _readModeKey: settings.readingMode,
      _themeKey: settings.themeMode,
      _arSizeKey: settings.arabicFontSize,
      _trSizeKey: settings.translationFontSize,
      _showTransKey: settings.showTranslation,
      _selTransKey: settings.selectedTranslations,
      _scrollSpeedKey: settings.autoScrollSpeed,
      _reciterIdKey: settings.reciterId,
      _prayerLocModeKey: settings.prayerLocationMode,
      _prayerCityKey: settings.prayerCity,
      _prayerCountryKey: settings.prayerCountry,
      _prayerLatKey: settings.prayerLat,
      _prayerLonKey: settings.prayerLon,
      _prayerMethodKey: settings.prayerMethod,
      _prayerSchoolKey: settings.prayerSchool,
      _tuneFajrKey: settings.prayerTuneFajr,
      _tuneDhuhrKey: settings.prayerTuneDhuhr,
      _tuneAsrKey: settings.prayerTuneAsr,
      _tuneMaghribKey: settings.prayerTuneMaghrib,
      _tuneIshaKey: settings.prayerTuneIsha,
      _hijriAdjKey: settings.hijriAdjustment,
      _alarmMasterKey: settings.prayerAlarmMasterEnabled,
      _alarmSoundKey: settings.alarmSoundType,
      _alarmVolumeKey: settings.alarmVolume,
      _alarmVibrateKey: settings.alarmVibrate,
      _prayerConfigsKey: jsonEncode({
        for (final e in settings.prayerConfigs.entries) e.key: e.value.toJson(),
      }),
      _kahfThuEnabledKey: settings.kahfThursdayEnabled,
      _kahfFriEnabledKey: settings.kahfFridayEnabled,
      _kahfThuHourKey: settings.kahfThuHour,
      _kahfThuMinKey: settings.kahfThuMinute,
      _kahfFriHourKey: settings.kahfFriHour,
      _kahfFriMinKey: settings.kahfFriMinute,
      _autoSilentEnabledKey: settings.autoSilentEnabled,
      _autoSilentDurationKey: settings.autoSilentDurationMinutes,
      _autoSilentPrayersKey: jsonEncode(settings.autoSilentPrayers),
      _names99ViewModeKey: settings.names99ViewMode,
      _exportScopeKey: settings.exportScope,
      _exportSurahKey: settings.exportSurahNo,
      _exportJuzKey: settings.exportJuzNo,
      _exportFromKey: settings.exportFromAyah,
      _exportToKey: settings.exportToAyah,
      _exportFormatKey: settings.exportFormat,
      _ibadahShowTranslitKey: settings.ibadahShowTransliteration,
      _ibadahShowMeaningKey: settings.ibadahShowMeaning,
      _ibadahShowNotesKey: settings.ibadahShowNotes,
      _ibadahShowAudioKey: settings.ibadahShowAudio,
      _ibadahMlHeadingsKey: settings.ibadahMalayalamHeadings,
      _tvModeEnabledKey: settings.tvModeEnabled,
      _tvFontScaleKey: settings.tvFontScale,
    });

    if (settings.exportIncludeTranslation != null) {
      await box.put(_exportIncludeTransKey, settings.exportIncludeTranslation!);
    }
    if (settings.exportTranslationCodes != null) {
      await box.put(_exportTransCodesKey, settings.exportTranslationCodes!);
    }

    if (settings.fabRelX != null && settings.fabRelY != null) {
      await box.put(_fabRelXKey, settings.fabRelX!);
      await box.put(_fabRelYKey, settings.fabRelY!);
    } else {
      await box.delete(_fabRelXKey);
      await box.delete(_fabRelYKey);
    }

    if (settings.gpsLocalityLabel != null) {
      await box.put(_gpsLocalityKey, settings.gpsLocalityLabel!);
    } else {
      await box.delete(_gpsLocalityKey);
    }
  }

  Future<Set<String>> loadDismissedAlarmsForDate(String dateKey) async {
    final box = await _islamicBox();
    final list = _readStringList(box, _dismissedAlarmsKey) ?? const [];
    return list.where((k) => k.startsWith('$dateKey|')).toSet();
  }

  Future<void> saveDismissedAlarmsForDate(
    String dateKey,
    Set<String> keys,
  ) async {
    final box = await _islamicBox();
    final pruned = keys.where((k) => k.startsWith('$dateKey|')).toList();
    await box.put(_dismissedAlarmsKey, pruned);
  }

  Future<Map<String, dynamic>?> loadDailyPrayerCache() async {
    final box = await _islamicBox();
    final raw = _readTyped<String>(box, _dailyPrayerCacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDailyPrayerCache(Map<String, dynamic> payload) async {
    final box = await _islamicBox();
    await box.put(_dailyPrayerCacheKey, jsonEncode(payload));
  }

  Future<List<dynamic>?> loadHijriCalendarCache(
    int hijriYear,
    int hijriMonth,
    int adjustment,
  ) async {
    final box = await _islamicBox();
    final raw = _readTyped<String>(
      box,
      '$_hijriCalCachePrefix${hijriYear}_${hijriMonth}_adj$adjustment',
    );
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveHijriCalendarCache(
    int hijriYear,
    int hijriMonth,
    int adjustment,
    List<Map<String, dynamic>> entries,
  ) async {
    final box = await _islamicBox();
    await box.put(
      '$_hijriCalCachePrefix${hijriYear}_${hijriMonth}_adj$adjustment',
      jsonEncode(entries),
    );
  }

  // -------------------------------------------------------------------------
  // ADHKAR PROGRESS & FAVORITES (HIVE)
  // -------------------------------------------------------------------------

  Future<Map<String, int>> loadAdhkarCountsForDate(String dateKey) async {
    final box = await _adhkarBox();
    final raw = _readTyped<String>(box, '$_adhkarDailyKeyPrefix$dateKey');
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in decoded.entries) e.key: (e.value as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAdhkarCountsForDate(
    String dateKey,
    Map<String, int> counts,
  ) async {
    final box = await _adhkarBox();
    await box.put('$_adhkarDailyKeyPrefix$dateKey', jsonEncode(counts));
  }

  Future<Set<String>> loadFavoriteAdhkarIds() async {
    final box = await _adhkarBox();
    return (_readStringList(box, _adhkarFavoritesKey) ?? const []).toSet();
  }

  Future<void> saveFavoriteAdhkarIds(Set<String> ids) async {
    final box = await _adhkarBox();
    await box.put(_adhkarFavoritesKey, ids.toList());
  }

  // -------------------------------------------------------------------------
  // SURAH AL-KAHF BANNER DISMISSAL (WEB/IN-APP)
  // -------------------------------------------------------------------------

  Future<bool> isKahfBannerDismissed(String dateKey) async {
    final box = await _islamicBox();
    return _readTyped<bool>(box, '$_kahfBannerDismissedPrefix$dateKey') ??
        false;
  }

  Future<void> setKahfBannerDismissed(String dateKey) async {
    final box = await _islamicBox();
    await box.put('$_kahfBannerDismissedPrefix$dateKey', true);
  }

  // -------------------------------------------------------------------------
  // DIGITAL TASBIH STORE (HIVE)
  // -------------------------------------------------------------------------

  Future<Map<String, dynamic>?> loadTasbihSnapshot() async {
    final box = await _tasbihBox();
    final raw = _readTyped<String>(box, _tasbihSnapshotKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTasbihSnapshot({
    required String selectedId,
    required List<TasbihPreset> customPresets,
    required Map<String, int> targetsById,
    required Map<String, int> cycleCountsById,
    required Map<String, int> lifetimeCountsById,
    required String todayDateKey,
    required int todayTotal,
    required bool vibrateOnTap,
    bool tapAnywhere = false,
  }) async {
    final box = await _tasbihBox();
    await box.put(
      _tasbihSnapshotKey,
      jsonEncode({
        'selectedId': selectedId,
        'customPresets': customPresets.map((e) => e.toJson()).toList(),
        'targetsById': targetsById,
        'cycleCountsById': cycleCountsById,
        'lifetimeCountsById': lifetimeCountsById,
        'todayDateKey': todayDateKey,
        'todayTotal': todayTotal,
        'vibrateOnTap': vibrateOnTap,
        'tapAnywhere': tapAnywhere,
      }),
    );
  }

  // -------------------------------------------------------------------------
  // RECENT ACTIVITY STORE (HIVE - MAX 7 ITEMS)
  // -------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> loadRecentActivitiesRaw() async {
    final box = await _prefsBox();
    final raw = _readTyped<String>(box, _recentActivityKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRecentActivitiesRaw(List<Map<String, dynamic>> items) async {
    final box = await _prefsBox();
    await box.put(_recentActivityKey, jsonEncode(items));
  }

  // -------------------------------------------------------------------------
  // IBADAH SALAH SHART CHECKLIST (HIVE)
  // -------------------------------------------------------------------------

  Future<Set<String>> loadIbadahCheckedSharts() async {
    final box = await _prefsBox();
    return (_readStringList(box, _ibadahShartCheckedKey) ?? const []).toSet();
  }

  Future<void> saveIbadahCheckedSharts(Set<String> ids) async {
    final box = await _prefsBox();
    await box.put(_ibadahShartCheckedKey, ids.toList());
  }
}
