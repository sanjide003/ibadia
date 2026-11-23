enum ReadingMode { mushaf, verse }

enum AppThemeMode { light, sepia, dark }

class SurahSummary {
  final int number;
  final String nameArabic;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  const SurahSummary({
    required this.number,
    required this.nameArabic,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahSummary.fromJson(Map<String, dynamic> json) {
    return SurahSummary(
      number: (json['number'] as num?)?.toInt() ?? 1,
      nameArabic: (json['nameArabic'] ?? json['name'] ?? '').toString(),
      englishName: (json['englishName'] ?? '').toString(),
      englishNameTranslation: (json['englishNameTranslation'] ?? '').toString(),
      numberOfAyahs: (json['numberOfAyahs'] as num?)?.toInt() ?? 0,
      revelationType: (json['revelationType'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'nameArabic': nameArabic,
        'englishName': englishName,
        'englishNameTranslation': englishNameTranslation,
        'numberOfAyahs': numberOfAyahs,
        'revelationType': revelationType,
      };
}

class AyahItem {
  final int numberInSurah;
  final int globalNumber;
  final String arabicText;
  final int juz;
  final int page;

  const AyahItem({
    required this.numberInSurah,
    required this.globalNumber,
    required this.arabicText,
    required this.juz,
    required this.page,
  });

  factory AyahItem.fromJson(Map<String, dynamic> json) {
    return AyahItem(
      numberInSurah: (json['numberInSurah'] as num?)?.toInt() ?? 1,
      globalNumber: (json['globalNumber'] ?? json['number'] as num?)?.toInt() ?? 1,
      arabicText: (json['arabicText'] ?? json['text'] ?? '').toString(),
      juz: (json['juz'] as num?)?.toInt() ?? 1,
      page: (json['page'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'numberInSurah': numberInSurah,
        'globalNumber': globalNumber,
        'arabicText': arabicText,
        'juz': juz,
        'page': page,
      };
}

class SurahDetail {
  final SurahSummary summary;
  final List<AyahItem> ayahs;
  final Map<String, List<String>> translations;

  const SurahDetail({
    required this.summary,
    required this.ayahs,
    required this.translations,
  });
}

class JuzAyahEntry {
  final SurahSummary surah;
  final AyahItem ayah;

  const JuzAyahEntry({required this.surah, required this.ayah});

  factory JuzAyahEntry.fromJson(Map<String, dynamic> json) {
    return JuzAyahEntry(
      surah: SurahSummary.fromJson(Map<String, dynamic>.from(json['surah'] as Map)),
      ayah: AyahItem.fromJson(Map<String, dynamic>.from(json['ayah'] as Map)),
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah.toJson(),
        'ayah': ayah.toJson(),
      };
}

class JuzDetail {
  final int juzNumber;
  final List<JuzAyahEntry> entries;
  final Map<String, List<String>> translations;

  const JuzDetail({
    required this.juzNumber,
    required this.entries,
    required this.translations,
  });
}

class BookmarkItem {
  final String id;
  final int surahNumber;
  final String surahNameEn;
  final String surahNameAr;
  final int ayahNumber;
  final int ayahCount;
  final String previewArabic;
  final bool isWholeSurah;
  final int createdAtMs;

  const BookmarkItem({
    required this.id,
    required this.surahNumber,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.ayahNumber,
    required this.ayahCount,
    required this.previewArabic,
    required this.isWholeSurah,
    required this.createdAtMs,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      id: (json['id'] ?? '').toString(),
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
      surahNameEn: (json['surahNameEn'] ?? '').toString(),
      surahNameAr: (json['surahNameAr'] ?? '').toString(),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      ayahCount: (json['ayahCount'] as num?)?.toInt() ?? 1,
      previewArabic: (json['previewArabic'] ?? '').toString(),
      isWholeSurah: json['isWholeSurah'] == true,
      createdAtMs: (json['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'surahNumber': surahNumber,
        'surahNameEn': surahNameEn,
        'surahNameAr': surahNameAr,
        'ayahNumber': ayahNumber,
        'ayahCount': ayahCount,
        'previewArabic': previewArabic,
        'isWholeSurah': isWholeSurah,
        'createdAtMs': createdAtMs,
      };
}

class LastReadState {
  final int surahNumber;
  final String surahNameEn;
  final String surahNameAr;
  final int ayahNumber;
  final int pageNumber;
  final double? scrollOffset;
  final int updatedAtMs;

  const LastReadState({
    required this.surahNumber,
    required this.surahNameEn,
    required this.surahNameAr,
    required this.ayahNumber,
    required this.pageNumber,
    this.scrollOffset,
    required this.updatedAtMs,
  });

  factory LastReadState.fromJson(Map<String, dynamic> json) {
    return LastReadState(
      surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
      surahNameEn: (json['surahNameEn'] ?? '').toString(),
      surahNameAr: (json['surahNameAr'] ?? '').toString(),
      ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
      scrollOffset: (json['scrollOffset'] as num?)?.toDouble(),
      updatedAtMs: (json['updatedAtMs'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahNameEn': surahNameEn,
        'surahNameAr': surahNameAr,
        'ayahNumber': ayahNumber,
        'pageNumber': pageNumber,
        'scrollOffset': scrollOffset,
        'updatedAtMs': updatedAtMs,
      };
}

class AppSettings {
  final String appLanguage; // en | ml | ar
  final ReadingMode readingMode;
  final AppThemeMode themeMode;
  final bool showTranslation;
  final List<String> selectedTranslations; // ['ml', 'en', 'ar']
  final double arabicFontSize;
  final double translationFontSize;
  final double autoScrollSpeed;
  final bool tajweedEnabled;
  final String reciterId;
  final double? fabX;
  final double? fabY;
  final String prayerLocationMode; // 'city' | 'gps'
  final String prayerCity;
  final String prayerCountry;
  final double prayerLat;
  final double prayerLon;
  final int prayerMethod;
  final int prayerSchool;
  final int hijriAdjustment;
  final Map<String, int> prayerTunes;
  final bool masterAlarmEnabled;
  final String alarmSoundType;
  final double alarmVolume;
  final bool alarmVibrate;
  final Map<String, PrayerAlarmConfig> prayerConfigs;
  final bool autoSilentEnabled;
  final int autoSilentDurationMinutes;
  final Map<String, bool> autoSilentPrayers;
  final bool kahfThursdayEnabled;
  final int kahfThuHour;
  final int kahfThuMinute;
  final bool kahfFridayEnabled;
  final int kahfFriHour;
  final int kahfFriMinute;
  final String names99ViewMode; // 'grid' | 'list'
  final List<int> studiedNames99;

  const AppSettings({
    required this.appLanguage,
    required this.readingMode,
    required this.themeMode,
    required this.showTranslation,
    required this.selectedTranslations,
    required this.arabicFontSize,
    required this.translationFontSize,
    required this.autoScrollSpeed,
    required this.tajweedEnabled,
    required this.reciterId,
    required this.fabX,
    required this.fabY,
    required this.prayerLocationMode,
    required this.prayerCity,
    required this.prayerCountry,
    required this.prayerLat,
    required this.prayerLon,
    required this.prayerMethod,
    required this.prayerSchool,
    required this.hijriAdjustment,
    required this.prayerTunes,
    required this.masterAlarmEnabled,
    required this.alarmSoundType,
    required this.alarmVolume,
    required this.alarmVibrate,
    required this.prayerConfigs,
    required this.autoSilentEnabled,
    required this.autoSilentDurationMinutes,
    required this.autoSilentPrayers,
    required this.kahfThursdayEnabled,
    required this.kahfThuHour,
    required this.kahfThuMinute,
    required this.kahfFridayEnabled,
    required this.kahfFriHour,
    required this.kahfFriMinute,
    required this.names99ViewMode,
    required this.studiedNames99,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      appLanguage: 'en',
      readingMode: ReadingMode.mushaf,
      themeMode: AppThemeMode.light,
      showTranslation: true,
      selectedTranslations: const ['ml'],
      arabicFontSize: 28,
      translationFontSize: 15,
      autoScrollSpeed: 1.0,
      tajweedEnabled: true,
      reciterId: 'ar.alafasy',
      fabX: null,
      fabY: null,
      prayerLocationMode: 'city',
      prayerCity: 'Kochi',
      prayerCountry: 'India',
      prayerLat: 9.9312,
      prayerLon: 76.2673,
      prayerMethod: 1,
      prayerSchool: 0,
      hijriAdjustment: 0,
      prayerTunes: const {'fajr': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0},
      masterAlarmEnabled: true,
      alarmSoundType: 'adhan_alafasy',
      alarmVolume: 0.85,
      alarmVibrate: true,
      prayerConfigs: {
        for (final k in const ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'])
          k: PrayerAlarmConfig(
            prayerKey: k,
            enabled: true,
            iqamahGapMinutes: 15,
            alarmRef: 'beforeAdhan',
            alarmOffsetMinutes: 10,
          ),
      },
      autoSilentEnabled: false,
      autoSilentDurationMinutes: 15,
      autoSilentPrayers: const {
        'fajr': true,
        'dhuhr': true,
        'asr': true,
        'maghrib': true,
        'isha': true,
      },
      kahfThursdayEnabled: true,
      kahfThuHour: 20,
      kahfThuMinute: 0,
      kahfFridayEnabled: true,
      kahfFriHour: 8,
      kahfFriMinute: 0,
      names99ViewMode: 'grid',
      studiedNames99: const [],
    );
  }

  AppSettings copyWith({
    String? appLanguage,
    ReadingMode? readingMode,
    AppThemeMode? themeMode,
    bool? showTranslation,
    List<String>? selectedTranslations,
    double? arabicFontSize,
    double? translationFontSize,
    double? autoScrollSpeed,
    bool? tajweedEnabled,
    String? reciterId,
    double? fabX,
    double? fabY,
    bool clearFabPos = false,
    String? prayerLocationMode,
    String? prayerCity,
    String? prayerCountry,
    double? prayerLat,
    double? prayerLon,
    int? prayerMethod,
    int? prayerSchool,
    int? hijriAdjustment,
    Map<String, int>? prayerTunes,
    bool? masterAlarmEnabled,
    String? alarmSoundType,
    double? alarmVolume,
    bool? alarmVibrate,
    Map<String, PrayerAlarmConfig>? prayerConfigs,
    bool? autoSilentEnabled,
    int? autoSilentDurationMinutes,
    Map<String, bool>? autoSilentPrayers,
    bool? kahfThursdayEnabled,
    int? kahfThuHour,
    int? kahfThuMinute,
    bool? kahfFridayEnabled,
    int? kahfFriHour,
    int? kahfFriMinute,
    String? names99ViewMode,
    List<int>? studiedNames99,
  }) {
    return AppSettings(
      appLanguage: appLanguage ?? this.appLanguage,
      readingMode: readingMode ?? this.readingMode,
      themeMode: themeMode ?? this.themeMode,
      showTranslation: showTranslation ?? this.showTranslation,
      selectedTranslations: selectedTranslations ?? this.selectedTranslations,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      tajweedEnabled: tajweedEnabled ?? this.tajweedEnabled,
      reciterId: reciterId ?? this.reciterId,
      fabX: clearFabPos ? null : (fabX ?? this.fabX),
      fabY: clearFabPos ? null : (fabY ?? this.fabY),
      prayerLocationMode: prayerLocationMode ?? this.prayerLocationMode,
      prayerCity: prayerCity ?? this.prayerCity,
      prayerCountry: prayerCountry ?? this.prayerCountry,
      prayerLat: prayerLat ?? this.prayerLat,
      prayerLon: prayerLon ?? this.prayerLon,
      prayerMethod: prayerMethod ?? this.prayerMethod,
      prayerSchool: prayerSchool ?? this.prayerSchool,
      hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
      prayerTunes: prayerTunes ?? this.prayerTunes,
      masterAlarmEnabled: masterAlarmEnabled ?? this.masterAlarmEnabled,
      alarmSoundType: alarmSoundType ?? this.alarmSoundType,
      alarmVolume: alarmVolume ?? this.alarmVolume,
      alarmVibrate: alarmVibrate ?? this.alarmVibrate,
      prayerConfigs: prayerConfigs ?? this.prayerConfigs,
      autoSilentEnabled: autoSilentEnabled ?? this.autoSilentEnabled,
      autoSilentDurationMinutes: autoSilentDurationMinutes ?? this.autoSilentDurationMinutes,
      autoSilentPrayers: autoSilentPrayers ?? this.autoSilentPrayers,
      kahfThursdayEnabled: kahfThursdayEnabled ?? this.kahfThursdayEnabled,
      kahfThuHour: kahfThuHour ?? this.kahfThuHour,
      kahfThuMinute: kahfThuMinute ?? this.kahfThuMinute,
      kahfFridayEnabled: kahfFridayEnabled ?? this.kahfFridayEnabled,
      kahfFriHour: kahfFriHour ?? this.kahfFriHour,
      kahfFriMinute: kahfFriMinute ?? this.kahfFriMinute,
      names99ViewMode: names99ViewMode ?? this.names99ViewMode,
      studiedNames99: studiedNames99 ?? this.studiedNames99,
    );
  }

  Map<String, dynamic> toJson() => {
        'appLanguage': appLanguage,
        'readingMode': readingMode.name,
        'themeMode': themeMode.name,
        'showTranslation': showTranslation,
        'selectedTranslations': selectedTranslations,
        'arabicFontSize': arabicFontSize,
        'translationFontSize': translationFontSize,
        'autoScrollSpeed': autoScrollSpeed,
        'tajweedEnabled': tajweedEnabled,
        'reciterId': reciterId,
        'fabX': fabX,
        'fabY': fabY,
        'prayerLocationMode': prayerLocationMode,
        'prayerCity': prayerCity,
        'prayerCountry': prayerCountry,
        'prayerLat': prayerLat,
        'prayerLon': prayerLon,
        'prayerMethod': prayerMethod,
        'prayerSchool': prayerSchool,
        'hijriAdjustment': hijriAdjustment,
        'prayerTunes': prayerTunes,
        'masterAlarmEnabled': masterAlarmEnabled,
        'alarmSoundType': alarmSoundType,
        'alarmVolume': alarmVolume,
        'alarmVibrate': alarmVibrate,
        'prayerConfigs': prayerConfigs.map((k, v) => MapEntry(k, v.toJson())),
        'autoSilentEnabled': autoSilentEnabled,
        'autoSilentDurationMinutes': autoSilentDurationMinutes,
        'autoSilentPrayers': autoSilentPrayers,
        'kahfThursdayEnabled': kahfThursdayEnabled,
        'kahfThuHour': kahfThuHour,
        'kahfThuMinute': kahfThuMinute,
        'kahfFridayEnabled': kahfFridayEnabled,
        'kahfFriHour': kahfFriHour,
        'kahfFriMinute': kahfFriMinute,
        'names99ViewMode': names99ViewMode,
        'studiedNames99': studiedNames99,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final def = AppSettings.defaults();
    final modeStr = (json['readingMode'] ?? 'mushaf').toString();
    final themeStr = (json['themeMode'] ?? 'light').toString();

    final rawTunes = (json['prayerTunes'] as Map?) ?? {};
    final tunes = Map<String, int>.from(def.prayerTunes);
    rawTunes.forEach((k, v) {
      if (v is num) tunes[k.toString()] = v.toInt();
    });

    final rawSilent = (json['autoSilentPrayers'] as Map?) ?? {};
    final silentMap = Map<String, bool>.from(def.autoSilentPrayers);
    rawSilent.forEach((k, v) {
      if (v is bool) silentMap[k.toString()] = v;
    });

    final rawConfigs = (json['prayerConfigs'] as Map?) ?? {};
    final configs = Map<String, PrayerAlarmConfig>.from(def.prayerConfigs);
    rawConfigs.forEach((k, v) {
      if (v is Map) {
        configs[k.toString()] = PrayerAlarmConfig.fromJson(Map<String, dynamic>.from(v));
      }
    });

    final rawTrans = (json['selectedTranslations'] as List?)?.map((e) => e.toString()).toList();
    final rawStudied = (json['studiedNames99'] as List?)
            ?.whereType<num>()
            .map((e) => e.toInt())
            .toList() ??
        const <int>[];

    return AppSettings(
      appLanguage: (json['appLanguage'] ?? def.appLanguage).toString(),
      readingMode: modeStr == 'verse' ? ReadingMode.verse : ReadingMode.mushaf,
      themeMode: themeStr == 'dark'
          ? AppThemeMode.dark
          : themeStr == 'sepia'
              ? AppThemeMode.sepia
              : AppThemeMode.light,
      showTranslation: json['showTranslation'] is bool ? json['showTranslation'] as bool : def.showTranslation,
      selectedTranslations: (rawTrans != null && rawTrans.isNotEmpty) ? rawTrans : def.selectedTranslations,
      arabicFontSize: (json['arabicFontSize'] as num?)?.toDouble() ?? def.arabicFontSize,
      translationFontSize: (json['translationFontSize'] as num?)?.toDouble() ?? def.translationFontSize,
      autoScrollSpeed: (json['autoScrollSpeed'] as num?)?.toDouble() ?? def.autoScrollSpeed,
      tajweedEnabled: json['tajweedEnabled'] is bool ? json['tajweedEnabled'] as bool : def.tajweedEnabled,
      reciterId: (json['reciterId'] ?? def.reciterId).toString(),
      fabX: (json['fabX'] as num?)?.toDouble(),
      fabY: (json['fabY'] as num?)?.toDouble(),
      prayerLocationMode: (json['prayerLocationMode'] ?? def.prayerLocationMode).toString(),
      prayerCity: (json['prayerCity'] ?? def.prayerCity).toString(),
      prayerCountry: (json['prayerCountry'] ?? def.prayerCountry).toString(),
      prayerLat: (json['prayerLat'] as num?)?.toDouble() ?? def.prayerLat,
      prayerLon: (json['prayerLon'] as num?)?.toDouble() ?? def.prayerLon,
      prayerMethod: (json['prayerMethod'] as num?)?.toInt() ?? def.prayerMethod,
      prayerSchool: (json['prayerSchool'] as num?)?.toInt() ?? def.prayerSchool,
      hijriAdjustment: (json['hijriAdjustment'] as num?)?.toInt() ?? def.hijriAdjustment,
      prayerTunes: tunes,
      masterAlarmEnabled: json['masterAlarmEnabled'] is bool ? json['masterAlarmEnabled'] as bool : def.masterAlarmEnabled,
      alarmSoundType: (json['alarmSoundType'] ?? def.alarmSoundType).toString(),
      alarmVolume: (json['alarmVolume'] as num?)?.toDouble() ?? def.alarmVolume,
      alarmVibrate: json['alarmVibrate'] is bool ? json['alarmVibrate'] as bool : def.alarmVibrate,
      prayerConfigs: configs,
      autoSilentEnabled: json['autoSilentEnabled'] is bool ? json['autoSilentEnabled'] as bool : def.autoSilentEnabled,
      autoSilentDurationMinutes: (json['autoSilentDurationMinutes'] as num?)?.toInt() ?? def.autoSilentDurationMinutes,
      autoSilentPrayers: silentMap,
      kahfThursdayEnabled: json['kahfThursdayEnabled'] is bool ? json['kahfThursdayEnabled'] as bool : def.kahfThursdayEnabled,
      kahfThuHour: (json['kahfThuHour'] as num?)?.toInt() ?? def.kahfThuHour,
      kahfThuMinute: (json['kahfThuMinute'] as num?)?.toInt() ?? def.kahfThuMinute,
      kahfFridayEnabled: json['kahfFridayEnabled'] is bool ? json['kahfFridayEnabled'] as bool : def.kahfFridayEnabled,
      kahfFriHour: (json['kahfFriHour'] as num?)?.toInt() ?? def.kahfFriHour,
      kahfFriMinute: (json['kahfFriMinute'] as num?)?.toInt() ?? def.kahfFriMinute,
      names99ViewMode: (json['names99ViewMode'] ?? def.names99ViewMode).toString(),
      studiedNames99: rawStudied,
    );
  }
}
