class PrayerCalculationMethod {
  final int id;
  final String englishName;
  final String malayalamName;
  final String arabicName;

  const PrayerCalculationMethod({
    required this.id,
    required this.englishName,
    required this.malayalamName,
    required this.arabicName,
  });

  String displayName(String lang) {
    switch (lang) {
      case 'ml':
        return malayalamName;
      case 'ar':
        return arabicName;
      default:
        return englishName;
    }
  }
}

class CityPreset {
  final String city;
  final String country;
  final double latitude;
  final double longitude;

  const CityPreset({
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  String get label => '$city, $country';
}

class AlarmSoundOption {
  final String id;
  final String englishName;
  final String malayalamName;
  final String arabicName;
  final String? remoteUrl;

  const AlarmSoundOption({
    required this.id,
    required this.englishName,
    required this.malayalamName,
    required this.arabicName,
    this.remoteUrl,
  });

  String displayName(String lang) {
    switch (lang) {
      case 'ml':
        return malayalamName;
      case 'ar':
        return arabicName;
      default:
        return englishName;
    }
  }
}

enum PrayerAlarmRef {
  beforeAdhan,
  relativeToIqamah,
}

class PrayerAlarmConfig {
  final String prayerKey; // 'fajr' | 'dhuhr' | 'asr' | 'maghrib' | 'isha'
  final bool enabled;
  final int iqamahGapMinutes; // 0..120 min after Adhan (default 15)
  final PrayerAlarmRef alarmRef;
  /// When [alarmRef] == beforeAdhan: minutes BEFORE Adhan (default 10, range 0..120).
  /// When [alarmRef] == relativeToIqamah: signed offset from Iqamah (-60..+60).
  final int alarmOffsetMinutes;

  const PrayerAlarmConfig({
    required this.prayerKey,
    this.enabled = true,
    this.iqamahGapMinutes = 15,
    this.alarmRef = PrayerAlarmRef.beforeAdhan,
    this.alarmOffsetMinutes = 10,
  });

  PrayerAlarmConfig copyWith({
    bool? enabled,
    int? iqamahGapMinutes,
    PrayerAlarmRef? alarmRef,
    int? alarmOffsetMinutes,
  }) {
    return PrayerAlarmConfig(
      prayerKey: prayerKey,
      enabled: enabled ?? this.enabled,
      iqamahGapMinutes: (iqamahGapMinutes ?? this.iqamahGapMinutes).clamp(0, 120),
      alarmRef: alarmRef ?? this.alarmRef,
      alarmOffsetMinutes: alarmOffsetMinutes ?? this.alarmOffsetMinutes,
    );
  }

  factory PrayerAlarmConfig.fromJson(String key, Map<String, dynamic> json) {
    final refStr = (json['alarmRef'] ?? 'beforeAdhan').toString();
    final ref = refStr == 'relativeToIqamah'
        ? PrayerAlarmRef.relativeToIqamah
        : PrayerAlarmRef.beforeAdhan;
    return PrayerAlarmConfig(
      prayerKey: key,
      enabled: json['enabled'] as bool? ?? true,
      iqamahGapMinutes:
          ((json['iqamahGapMinutes'] as num?)?.toInt() ?? 15).clamp(0, 120),
      alarmRef: ref,
      alarmOffsetMinutes: (json['alarmOffsetMinutes'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'iqamahGapMinutes': iqamahGapMinutes,
        'alarmRef': alarmRef == PrayerAlarmRef.relativeToIqamah
            ? 'relativeToIqamah'
            : 'beforeAdhan',
        'alarmOffsetMinutes': alarmOffsetMinutes,
      };
}

class ComputedPrayerSlot {
  final String prayerKey;
  final DateTime adhanTime;
  final DateTime iqamahTime;
  final DateTime? alarmTime;
  final DateTime nextBoundaryAdhan;
  final DateTime safetyLimitTime; // nextBoundaryAdhan - 10 minutes
  final String nextBoundaryKey;
  final bool masterEnabled;
  final bool prayerAlarmEnabled;
  final bool dismissedToday;
  final int tuneMinutes;
  final int effectiveIqamahGap;
  final int maxAllowedIqamahGap;

  const ComputedPrayerSlot({
    required this.prayerKey,
    required this.adhanTime,
    required this.iqamahTime,
    required this.alarmTime,
    required this.nextBoundaryAdhan,
    required this.safetyLimitTime,
    required this.nextBoundaryKey,
    required this.masterEnabled,
    required this.prayerAlarmEnabled,
    required this.dismissedToday,
    required this.tuneMinutes,
    required this.effectiveIqamahGap,
    required this.maxAllowedIqamahGap,
  });

  bool get isAlarmActive =>
      masterEnabled && prayerAlarmEnabled && alarmTime != null;
}

class AlAdhanCatalog {
  static const int defaultMethodId = 1; // Karachi (UISK)
  static const int defaultSchool = 0; // Shafi
  static const String defaultCity = 'Kochi';
  static const String defaultCountry = 'India';
  static const double defaultLat = 9.9312;
  static const double defaultLon = 76.2673;

  static const List<String> fivePrayerKeys = [
    'fajr',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];

  static const List<AlarmSoundOption> alarmSounds = [
    AlarmSoundOption(
      id: 'adhan_alafasy',
      englishName: 'Adhan — Mishary Alafasy',
      malayalamName: 'ബാങ്ക് — മിശാരി അൽ-അഫാസി',
      arabicName: 'الأذان — مشاري العفاسي',
      remoteUrl: 'https://cdn.aladhan.com/audio/adhans/a4.mp3',
    ),
    AlarmSoundOption(
      id: 'adhan_nafees',
      englishName: 'Adhan — Ahmad al-Nafees',
      malayalamName: 'ബാങ്ക് — അഹ്‌മദ് അൽ-നഫീസ്',
      arabicName: 'الأذان — أحمد النفيس',
      remoteUrl: 'https://cdn.aladhan.com/audio/adhans/a1.mp3',
    ),
    AlarmSoundOption(
      id: 'alarm_tone',
      englishName: 'Alarm Tone (Device / Chime)',
      malayalamName: 'അലാറം ടോൺ (സാധാരണ ശബ്ദം)',
      arabicName: 'نغمة منبه',
    ),
  ];

  static AlarmSoundOption soundById(String id) {
    for (final s in alarmSounds) {
      if (s.id == id) return s;
    }
    return alarmSounds.first;
  }

  static const List<PrayerCalculationMethod> methods = [
    PrayerCalculationMethod(
      id: 1,
      englishName: 'Karachi (UISK)',
      malayalamName: 'കറാച്ചി (UISK)',
      arabicName: 'جامعة العلوم الإسلامية بكراتشي',
    ),
    PrayerCalculationMethod(
      id: 3,
      englishName: 'Muslim World League (MWL)',
      malayalamName: 'മുസ്‌ലിം വേൾഡ് ലീഗ് (MWL)',
      arabicName: 'رابطة العالم الإسلامي',
    ),
    PrayerCalculationMethod(
      id: 4,
      englishName: 'Umm Al-Qura, Makkah',
      malayalamName: 'ഉമ്മുൽ ഖുറ, മക്ക',
      arabicName: 'أم القرى، مكة المكرمة',
    ),
    PrayerCalculationMethod(
      id: 2,
      englishName: 'ISNA (North America)',
      malayalamName: 'ISNA (വടക്കേ അമേരിക്ക)',
      arabicName: 'الجمعية الإسلامية لأمريكا الشمالية',
    ),
    PrayerCalculationMethod(
      id: 5,
      englishName: 'Egyptian General Authority',
      malayalamName: 'ഈജിപ്ഷ്യൻ അതോറിറ്റി',
      arabicName: 'الهيئة المصرية العامة للمساحة',
    ),
    PrayerCalculationMethod(
      id: 11,
      englishName: 'MUIS (Singapore)',
      malayalamName: 'MUIS (സിംഗപ്പൂർ)',
      arabicName: 'مجلس الشؤون الإسلامية في سنغافورة',
    ),
    PrayerCalculationMethod(
      id: 15,
      englishName: 'Moonsighting Committee',
      malayalamName: 'മൂൺസൈറ്റിംഗ് കമ്മിറ്റി',
      arabicName: 'لجنة تحري الهلال',
    ),
  ];

  static PrayerCalculationMethod methodById(int id) {
    for (final m in methods) {
      if (m.id == id) return m;
    }
    return methods.first;
  }

  static const List<CityPreset> quickCities = [
    CityPreset(city: 'Kochi', country: 'India', latitude: 9.9312, longitude: 76.2673),
    CityPreset(city: 'Kozhikode', country: 'India', latitude: 11.2588, longitude: 75.7804),
    CityPreset(city: 'Malappuram', country: 'India', latitude: 11.0510, longitude: 76.0711),
    CityPreset(city: 'Thiruvananthapuram', country: 'India', latitude: 8.5241, longitude: 76.9366),
    CityPreset(city: 'Thrissur', country: 'India', latitude: 10.5276, longitude: 76.2144),
    CityPreset(city: 'Kannur', country: 'India', latitude: 11.8745, longitude: 75.3704),
    CityPreset(city: 'Bengaluru', country: 'India', latitude: 12.9716, longitude: 77.5946),
    CityPreset(city: 'Chennai', country: 'India', latitude: 13.0827, longitude: 80.2707),
    CityPreset(city: 'Mumbai', country: 'India', latitude: 19.0760, longitude: 72.8777),
    CityPreset(city: 'Makkah', country: 'Saudi Arabia', latitude: 21.3891, longitude: 39.8579),
    CityPreset(city: 'Madinah', country: 'Saudi Arabia', latitude: 24.5247, longitude: 39.5692),
    CityPreset(city: 'Dubai', country: 'UAE', latitude: 25.2048, longitude: 55.2708),
    CityPreset(city: 'Doha', country: 'Qatar', latitude: 25.2854, longitude: 51.5310),
    CityPreset(city: 'Riyadh', country: 'Saudi Arabia', latitude: 24.7136, longitude: 46.6753),
  ];

  static Map<String, PrayerAlarmConfig> defaultPrayerConfigs() => {
        for (final key in fivePrayerKeys)
          key: PrayerAlarmConfig(
            prayerKey: key,
            enabled: true,
            iqamahGapMinutes: 15,
            alarmRef: PrayerAlarmRef.beforeAdhan,
            alarmOffsetMinutes: 10,
          ),
      };
}

class HijriMonthCatalog {
  static const List<String> englishMonths = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhirah',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  static const List<String> arabicMonths = [
    'مُحَرَّم',
    'صَفَر',
    'رَبِيع الأَوَّل',
    'رَبِيع الثَّانِي',
    'جُمَادَى الأُولَى',
    'جُمَادَى الآخِرَة',
    'رَجَب',
    'شَعْبَان',
    'رَمَضَان',
    'شَوَّال',
    'ذُو القَعْدَة',
    'ذُو الحِجَّة',
  ];

  static String monthName(int month, String lang) {
    final idx = (month - 1).clamp(0, 11);
    return lang == 'ar' ? arabicMonths[idx] : englishMonths[idx];
  }
}

class DailyPrayerData {
  final String dateKey; // YYYY-MM-DD
  final String locationLabel;
  final double latitude;
  final double longitude;
  final String timezone;
  final int methodId;
  final int school;
  final int hijriAdjustment;
  final String gregorianReadable;
  final String hijriDay;
  final int hijriMonthNumber;
  final String hijriMonthEn;
  final String hijriMonthAr;
  final String hijriYear;
  final String weekdayEn;
  final String weekdayAr;
  /// Base timings in 24h 'HH:mm' format from AlAdhan (fajr, sunrise, dhuhr, asr, maghrib, isha)
  final Map<String, String> baseTimings;
  final bool loadedFromCache;

  const DailyPrayerData({
    required this.dateKey,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.methodId,
    required this.school,
    required this.hijriAdjustment,
    required this.gregorianReadable,
    required this.hijriDay,
    required this.hijriMonthNumber,
    required this.hijriMonthEn,
    required this.hijriMonthAr,
    required this.hijriYear,
    required this.weekdayEn,
    required this.weekdayAr,
    required this.baseTimings,
    this.loadedFromCache = false,
  });

  DailyPrayerData copyWith({bool? loadedFromCache}) => DailyPrayerData(
        dateKey: dateKey,
        locationLabel: locationLabel,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        methodId: methodId,
        school: school,
        hijriAdjustment: hijriAdjustment,
        gregorianReadable: gregorianReadable,
        hijriDay: hijriDay,
        hijriMonthNumber: hijriMonthNumber,
        hijriMonthEn: hijriMonthEn,
        hijriMonthAr: hijriMonthAr,
        hijriYear: hijriYear,
        weekdayEn: weekdayEn,
        weekdayAr: weekdayAr,
        baseTimings: baseTimings,
        loadedFromCache: loadedFromCache ?? this.loadedFromCache,
      );

  factory DailyPrayerData.fromAlAdhanJson(
    Map<String, dynamic> data, {
    required String dateKey,
    required String locationLabel,
    required int methodId,
    required int school,
    required int hijriAdjustment,
  }) {
    final timings = (data['timings'] as Map<String, dynamic>? ?? const {});
    final date = (data['date'] as Map<String, dynamic>? ?? const {});
    final meta = (data['meta'] as Map<String, dynamic>? ?? const {});
    final hijri = (date['hijri'] as Map<String, dynamic>? ?? const {});
    final gregorian = (date['gregorian'] as Map<String, dynamic>? ?? const {});
    final hMonth = (hijri['month'] as Map<String, dynamic>? ?? const {});
    final hWeekday = (hijri['weekday'] as Map<String, dynamic>? ?? const {});
    final gWeekday = (gregorian['weekday'] as Map<String, dynamic>? ?? const {});

    String cleanTime(String key) {
      final raw = (timings[key] ?? '00:00').toString();
      final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(raw);
      return match?.group(1) ?? '00:00';
    }

    return DailyPrayerData(
      dateKey: dateKey,
      locationLabel: locationLabel,
      latitude: (meta['latitude'] as num?)?.toDouble() ?? AlAdhanCatalog.defaultLat,
      longitude: (meta['longitude'] as num?)?.toDouble() ?? AlAdhanCatalog.defaultLon,
      timezone: (meta['timezone'] ?? 'Asia/Kolkata').toString(),
      methodId: methodId,
      school: school,
      hijriAdjustment: hijriAdjustment,
      gregorianReadable: (date['readable'] ?? dateKey).toString(),
      hijriDay: (hijri['day'] ?? '1').toString(),
      hijriMonthNumber: (hMonth['number'] as num?)?.toInt() ?? 1,
      hijriMonthEn: (hMonth['en'] ?? '').toString(),
      hijriMonthAr: (hMonth['ar'] ?? '').toString(),
      hijriYear: (hijri['year'] ?? '').toString(),
      weekdayEn: (gWeekday['en'] ?? hWeekday['en'] ?? '').toString(),
      weekdayAr: (hWeekday['ar'] ?? '').toString(),
      baseTimings: {
        'fajr': cleanTime('Fajr'),
        'sunrise': cleanTime('Sunrise'),
        'dhuhr': cleanTime('Dhuhr'),
        'asr': cleanTime('Asr'),
        'maghrib': cleanTime('Maghrib'),
        'isha': cleanTime('Isha'),
      },
    );
  }

  factory DailyPrayerData.fromCacheJson(Map<String, dynamic> json) {
    final rawMap = (json['baseTimings'] as Map<String, dynamic>? ?? const {});
    return DailyPrayerData(
      dateKey: (json['dateKey'] ?? '').toString(),
      locationLabel: (json['locationLabel'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? AlAdhanCatalog.defaultLat,
      longitude: (json['longitude'] as num?)?.toDouble() ?? AlAdhanCatalog.defaultLon,
      timezone: (json['timezone'] ?? 'Asia/Kolkata').toString(),
      methodId: (json['methodId'] as num?)?.toInt() ?? 1,
      school: (json['school'] as num?)?.toInt() ?? 0,
      hijriAdjustment: (json['hijriAdjustment'] as num?)?.toInt() ?? 0,
      gregorianReadable: (json['gregorianReadable'] ?? '').toString(),
      hijriDay: (json['hijriDay'] ?? '1').toString(),
      hijriMonthNumber: (json['hijriMonthNumber'] as num?)?.toInt() ?? 1,
      hijriMonthEn: (json['hijriMonthEn'] ?? '').toString(),
      hijriMonthAr: (json['hijriMonthAr'] ?? '').toString(),
      hijriYear: (json['hijriYear'] ?? '').toString(),
      weekdayEn: (json['weekdayEn'] ?? '').toString(),
      weekdayAr: (json['weekdayAr'] ?? '').toString(),
      baseTimings: {
        for (final e in rawMap.entries) e.key: e.value.toString(),
      },
      loadedFromCache: true,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'dateKey': dateKey,
        'locationLabel': locationLabel,
        'latitude': latitude,
        'longitude': longitude,
        'timezone': timezone,
        'methodId': methodId,
        'school': school,
        'hijriAdjustment': hijriAdjustment,
        'gregorianReadable': gregorianReadable,
        'hijriDay': hijriDay,
        'hijriMonthNumber': hijriMonthNumber,
        'hijriMonthEn': hijriMonthEn,
        'hijriMonthAr': hijriMonthAr,
        'hijriYear': hijriYear,
        'weekdayEn': weekdayEn,
        'weekdayAr': weekdayAr,
        'baseTimings': baseTimings,
      };

  /// Computes a tuned DateTime on [referenceDay] for [prayerKey] with [offsetMinutes].
  DateTime tunedTimeFor(
    String prayerKey,
    int offsetMinutes,
    DateTime referenceDay,
  ) {
    final raw = baseTimings[prayerKey] ?? '00:00';
    final parts = raw.split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return DateTime(
      referenceDay.year,
      referenceDay.month,
      referenceDay.day,
      h,
      m,
    ).add(Duration(minutes: offsetMinutes));
  }

  /// Computes all 5 daily prayer slots enforcing a strict >= 10-minute safety buffer
  /// before the next prayer's Adhan (or Sunrise for Fajr).
  List<ComputedPrayerSlot> computeDailySlots({
    required DateTime referenceDay,
    required int Function(String prayerKey) tuneFor,
    required Map<String, PrayerAlarmConfig> configs,
    required bool masterAlarmEnabled,
    required Set<String> dismissedTodayKeys,
  }) {
    final fajrAdhan = tunedTimeFor('fajr', tuneFor('fajr'), referenceDay);
    final sunriseTime = tunedTimeFor('sunrise', 0, referenceDay);
    final dhuhrAdhan = tunedTimeFor('dhuhr', tuneFor('dhuhr'), referenceDay);
    final asrAdhan = tunedTimeFor('asr', tuneFor('asr'), referenceDay);
    final maghribAdhan =
        tunedTimeFor('maghrib', tuneFor('maghrib'), referenceDay);
    final ishaAdhan = tunedTimeFor('isha', tuneFor('isha'), referenceDay);
    final tomorrowFajr = tunedTimeFor(
      'fajr',
      tuneFor('fajr'),
      referenceDay.add(const Duration(days: 1)),
    );

    final adhans = {
      'fajr': fajrAdhan,
      'dhuhr': dhuhrAdhan,
      'asr': asrAdhan,
      'maghrib': maghribAdhan,
      'isha': ishaAdhan,
    };

    final boundaries = {
      'fajr': ('sunrise', sunriseTime),
      'dhuhr': ('asr', asrAdhan),
      'asr': ('maghrib', maghribAdhan),
      'maghrib': ('isha', ishaAdhan),
      'isha': ('fajr', tomorrowFajr),
    };

    final dateStr =
        '${referenceDay.year.toString().padLeft(4, '0')}-${referenceDay.month.toString().padLeft(2, '0')}-${referenceDay.day.toString().padLeft(2, '0')}';

    return AlAdhanCatalog.fivePrayerKeys.map((key) {
      final adhan = adhans[key]!;
      final boundary = boundaries[key]!;
      final nextAdhan = boundary.$2;
      final safetyLimit = nextAdhan.subtract(const Duration(minutes: 10));
      final maxGap =
          mathMax0(safetyLimit.difference(adhan).inMinutes);

      final cfg = configs[key] ?? PrayerAlarmConfig(prayerKey: key);
      final clampedGap = cfg.iqamahGapMinutes.clamp(0, maxGap);
      final iqamah = adhan.add(Duration(minutes: clampedGap));

      DateTime? rawAlarm;
      if (cfg.enabled) {
        if (cfg.alarmRef == PrayerAlarmRef.beforeAdhan) {
          final minsBefore = cfg.alarmOffsetMinutes.clamp(0, 120);
          rawAlarm = adhan.subtract(Duration(minutes: minsBefore));
        } else {
          final signedOffset = cfg.alarmOffsetMinutes.clamp(-60, 60);
          rawAlarm = iqamah.add(Duration(minutes: signedOffset));
        }
        // Hard safety clamp: alarm never approaches within 10 minutes of next prayer's Adhan
        if (rawAlarm.isAfter(safetyLimit)) {
          rawAlarm = safetyLimit;
        }
      }

      return ComputedPrayerSlot(
        prayerKey: key,
        adhanTime: adhan,
        iqamahTime: iqamah,
        alarmTime: rawAlarm,
        nextBoundaryAdhan: nextAdhan,
        safetyLimitTime: safetyLimit,
        nextBoundaryKey: boundary.$1,
        masterEnabled: masterAlarmEnabled,
        prayerAlarmEnabled: cfg.enabled,
        dismissedToday: dismissedTodayKeys.contains('$dateStr|$key'),
        tuneMinutes: tuneFor(key),
        effectiveIqamahGap: clampedGap,
        maxAllowedIqamahGap: maxGap,
      );
    }).toList();
  }

  static int mathMax0(int v) => v < 0 ? 0 : v;

  static String format12Hour(DateTime dt) {
    final hour24 = dt.hour;
    final amPm = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour12:$min $amPm';
  }
}

class CalendarDayEntry {
  final int gregorianDay;
  final int gregorianMonth;
  final int gregorianYear;
  final String gregorianMonthEn;
  final String weekdayEn;
  final int hijriDay;
  final int hijriMonthNumber;
  final String hijriMonthEn;
  final String hijriMonthAr;
  final int hijriYear;
  final List<String> holidays;

  const CalendarDayEntry({
    required this.gregorianDay,
    required this.gregorianMonth,
    required this.gregorianYear,
    this.gregorianMonthEn = '',
    required this.weekdayEn,
    required this.hijriDay,
    required this.hijriMonthNumber,
    required this.hijriMonthEn,
    required this.hijriMonthAr,
    required this.hijriYear,
    this.holidays = const [],
  });

  DateTime get gregorianDate =>
      DateTime(gregorianYear, gregorianMonth, gregorianDay);

  static const _shortGregMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get shortGregorianLabel {
    final m = _shortGregMonths[(gregorianMonth - 1).clamp(0, 11)];
    return '$gregorianDay $m';
  }

  factory CalendarDayEntry.fromAlAdhanJson(Map<String, dynamic> item) {
    final greg = (item['gregorian'] as Map<String, dynamic>? ?? const {});
    final hijri = (item['hijri'] as Map<String, dynamic>? ?? const {});
    final gMonth = (greg['month'] as Map<String, dynamic>? ?? const {});
    final gWeekday = (greg['weekday'] as Map<String, dynamic>? ?? const {});
    final hMonth = (hijri['month'] as Map<String, dynamic>? ?? const {});
    final rawHolidays = (hijri['holidays'] as List<dynamic>? ?? const []);

    return CalendarDayEntry(
      gregorianDay: int.tryParse((greg['day'] ?? '1').toString()) ?? 1,
      gregorianMonth: (gMonth['number'] as num?)?.toInt() ?? 1,
      gregorianYear: int.tryParse((greg['year'] ?? '2026').toString()) ?? 2026,
      gregorianMonthEn: (gMonth['en'] ?? '').toString(),
      weekdayEn: (gWeekday['en'] ?? '').toString(),
      hijriDay: int.tryParse((hijri['day'] ?? '1').toString()) ?? 1,
      hijriMonthNumber: (hMonth['number'] as num?)?.toInt() ?? 1,
      hijriMonthEn: (hMonth['en'] ?? '').toString(),
      hijriMonthAr: (hMonth['ar'] ?? '').toString(),
      hijriYear: int.tryParse((hijri['year'] ?? '1448').toString()) ?? 1448,
      holidays: rawHolidays.map((e) => e.toString()).toList(),
    );
  }

  factory CalendarDayEntry.fromCacheJson(Map<String, dynamic> json) =>
      CalendarDayEntry(
        gregorianDay: (json['gd'] as num?)?.toInt() ?? 1,
        gregorianMonth: (json['gm'] as num?)?.toInt() ?? 1,
        gregorianYear: (json['gy'] as num?)?.toInt() ?? 2026,
        gregorianMonthEn: (json['gme'] ?? '').toString(),
        weekdayEn: (json['wd'] ?? '').toString(),
        hijriDay: (json['hd'] as num?)?.toInt() ?? 1,
        hijriMonthNumber: (json['hm'] as num?)?.toInt() ?? 1,
        hijriMonthEn: (json['hme'] ?? '').toString(),
        hijriMonthAr: (json['hma'] ?? '').toString(),
        hijriYear: (json['hy'] as num?)?.toInt() ?? 1448,
        holidays: (json['hol'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toCacheJson() => {
        'gd': gregorianDay,
        'gm': gregorianMonth,
        'gy': gregorianYear,
        if (gregorianMonthEn.isNotEmpty) 'gme': gregorianMonthEn,
        'wd': weekdayEn,
        'hd': hijriDay,
        'hm': hijriMonthNumber,
        'hme': hijriMonthEn,
        'hma': hijriMonthAr,
        'hy': hijriYear,
        if (holidays.isNotEmpty) 'hol': holidays,
      };
}
