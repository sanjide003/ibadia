import '../core/config/api_config.dart';

export '../core/config/api_config.dart'
    show AlarmSoundOption, CityPreset, PrayerCalculationMethod;

enum PrayerAlarmRef {
  beforeAdhan,
  relativeToIqamah;

  static PrayerAlarmRef fromRaw(dynamic raw) {
    final s = (raw ?? '').toString();
    if (s == 'relativeToIqamah') return PrayerAlarmRef.relativeToIqamah;
    return PrayerAlarmRef.beforeAdhan;
  }
}

class PrayerAlarmConfig {
  final String prayerKey;
  final bool enabled;
  final int iqamahGapMinutes;
  final PrayerAlarmRef alarmRef;
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
      iqamahGapMinutes: iqamahGapMinutes ?? this.iqamahGapMinutes,
      alarmRef: alarmRef ?? this.alarmRef,
      alarmOffsetMinutes: alarmOffsetMinutes ?? this.alarmOffsetMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'prayerKey': prayerKey,
        'enabled': enabled,
        'iqamahGapMinutes': iqamahGapMinutes,
        'alarmRef': alarmRef.name,
        'alarmOffsetMinutes': alarmOffsetMinutes,
      };

  factory PrayerAlarmConfig.fromJson(
    String prayerKey,
    Map<String, dynamic> json,
  ) {
    return PrayerAlarmConfig(
      prayerKey: (json['prayerKey'] ?? prayerKey).toString(),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      iqamahGapMinutes: (json['iqamahGapMinutes'] as num?)?.toInt() ?? 15,
      alarmRef: PrayerAlarmRef.fromRaw(json['alarmRef']),
      alarmOffsetMinutes: (json['alarmOffsetMinutes'] as num?)?.toInt() ?? 10,
    );
  }
}

class ComputedPrayerSlot {
  final String prayerKey;
  final DateTime adhanTime;
  final DateTime iqamahTime;
  final DateTime? alarmTime;
  final DateTime nextBoundaryAdhan;
  final DateTime safetyLimitTime;
  final String nextBoundaryKey;
  final bool masterEnabled;
  final bool prayerAlarmEnabled;
  final bool dismissedToday;
  final int tuneMinutes;
  final int effectiveIqamahGap;
  final int maxAllowedIqamahGap;

  bool get isAlarmActive =>
      masterEnabled && prayerAlarmEnabled && alarmTime != null;

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
}

class DailyPrayerData {
  final String dateKey;
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
  final Map<String, String> baseTimings;
  final bool loadedFromCache;
  final String cacheSig;

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
    this.cacheSig = '',
  });

  static String format12Hour(DateTime dt) {
    final h24 = dt.hour;
    final amPm = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h12:$m $amPm';
  }

  DateTime tunedTimeFor(
    String prayerKey,
    int tuneMinutes,
    DateTime referenceDay,
  ) {
    final raw = baseTimings[prayerKey] ?? '00:00';
    final parts = raw.split(':');
    final h = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 0) : 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final dt = DateTime(
      referenceDay.year,
      referenceDay.month,
      referenceDay.day,
      h,
      m,
    );
    return dt.add(Duration(minutes: tuneMinutes));
  }

  List<ComputedPrayerSlot> computeDailySlots({
    required DateTime referenceDay,
    required int Function(String prayerKey) tuneFor,
    required Map<String, PrayerAlarmConfig> configs,
    required bool masterAlarmEnabled,
    required Set<String> dismissedTodayKeys,
  }) {
    final fajrAdhan = tunedTimeFor('fajr', tuneFor('fajr'), referenceDay);
    final sunrise = tunedTimeFor('sunrise', 0, referenceDay);
    final dhuhrAdhan = tunedTimeFor('dhuhr', tuneFor('dhuhr'), referenceDay);
    final asrAdhan = tunedTimeFor('asr', tuneFor('asr'), referenceDay);
    final maghribAdhan =
        tunedTimeFor('maghrib', tuneFor('maghrib'), referenceDay);
    final ishaAdhan = tunedTimeFor('isha', tuneFor('isha'), referenceDay);
    final tomorrow = referenceDay.add(const Duration(days: 1));
    final tomorrowFajr = tunedTimeFor('fajr', tuneFor('fajr'), tomorrow);

    final adhans = <String, DateTime>{
      'fajr': fajrAdhan,
      'dhuhr': dhuhrAdhan,
      'asr': asrAdhan,
      'maghrib': maghribAdhan,
      'isha': ishaAdhan,
    };

    final boundaries = <String, ({String key, DateTime dt})>{
      'fajr': (key: 'sunrise', dt: sunrise),
      'dhuhr': (key: 'asr', dt: asrAdhan),
      'asr': (key: 'maghrib', dt: maghribAdhan),
      'maghrib': (key: 'isha', dt: ishaAdhan),
      'isha': (key: 'fajr', dt: tomorrowFajr),
    };

    final y = referenceDay.year.toString().padLeft(4, '0');
    final m = referenceDay.month.toString().padLeft(2, '0');
    final d = referenceDay.day.toString().padLeft(2, '0');
    final dateStr = '$y-$m-$d';

    return ApiConfig.fivePrayerKeys.map((key) {
      final adhan = adhans[key]!;
      final b = boundaries[key]!;
      final safetyLimit = b.dt.subtract(const Duration(minutes: 10));
      final maxGap = safetyLimit.difference(adhan).inMinutes < 0
          ? 0
          : safetyLimit.difference(adhan).inMinutes;

      final cfg = configs[key] ?? PrayerAlarmConfig(prayerKey: key);
      final clampedGap = cfg.iqamahGapMinutes.clamp(0, maxGap);
      final iqamah = adhan.add(Duration(minutes: clampedGap));

      DateTime? alarmTime;
      if (cfg.enabled) {
        if (cfg.alarmRef == PrayerAlarmRef.beforeAdhan) {
          final minsBefore = cfg.alarmOffsetMinutes.clamp(0, 120);
          alarmTime = adhan.subtract(Duration(minutes: minsBefore));
        } else {
          final signed = cfg.alarmOffsetMinutes.clamp(-60, 60);
          alarmTime = iqamah.add(Duration(minutes: signed));
        }
        if (alarmTime.isAfter(safetyLimit)) {
          alarmTime = safetyLimit;
        }
      }

      return ComputedPrayerSlot(
        prayerKey: key,
        adhanTime: adhan,
        iqamahTime: iqamah,
        alarmTime: alarmTime,
        nextBoundaryAdhan: b.dt,
        safetyLimitTime: safetyLimit,
        nextBoundaryKey: b.key,
        masterEnabled: masterAlarmEnabled,
        prayerAlarmEnabled: cfg.enabled,
        dismissedToday: dismissedTodayKeys.contains('$dateStr|$key'),
        tuneMinutes: tuneFor(key),
        effectiveIqamahGap: clampedGap,
        maxAllowedIqamahGap: maxGap,
      );
    }).toList();
  }

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
        cacheSig: cacheSig,
      );

  Map<String, dynamic> toJson() => {
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
        'cacheSig': cacheSig,
      };

  factory DailyPrayerData.fromJson(Map<String, dynamic> json) {
    final rawTimings = (json['baseTimings'] as Map?) ?? {};
    final timings = <String, String>{};
    rawTimings.forEach((k, v) => timings[k.toString()] = v.toString());

    return DailyPrayerData(
      dateKey: (json['dateKey'] ?? '').toString(),
      locationLabel: (json['locationLabel'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      timezone: (json['timezone'] ?? 'Asia/Kolkata').toString(),
      methodId: (json['methodId'] as num?)?.toInt() ?? 1,
      school: (json['school'] as num?)?.toInt() ?? 0,
      hijriAdjustment: (json['hijriAdjustment'] as num?)?.toInt() ?? 0,
      gregorianReadable: (json['gregorianReadable'] ?? '').toString(),
      hijriDay: (json['hijriDay'] ?? '1').toString(),
      hijriMonthNumber: (json['hijriMonthNumber'] as num?)?.toInt() ?? 1,
      hijriMonthEn: (json['hijriMonthEn'] ?? '').toString(),
      hijriMonthAr: (json['hijriMonthAr'] ?? '').toString(),
      hijriYear: (json['hijriYear'] ?? '1448').toString(),
      weekdayEn: (json['weekdayEn'] ?? '').toString(),
      weekdayAr: (json['weekdayAr'] ?? '').toString(),
      baseTimings: timings,
      loadedFromCache: json['loadedFromCache'] == true,
      cacheSig: (json['cacheSig'] ?? '').toString(),
    );
  }
}

class CalendarDayEntry {
  static const List<String> _shortGregMonths = [
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
    required this.gregorianMonthEn,
    required this.weekdayEn,
    required this.hijriDay,
    required this.hijriMonthNumber,
    required this.hijriMonthEn,
    required this.hijriMonthAr,
    required this.hijriYear,
    required this.holidays,
  });

  DateTime get gregorianDate =>
      DateTime(gregorianYear, gregorianMonth, gregorianDay);

  String get shortGregorianLabel {
    final m = _shortGregMonths[(gregorianMonth - 1).clamp(0, 11)];
    return '$gregorianDay $m';
  }

  Map<String, dynamic> toJson() => {
        'gregorianDay': gregorianDay,
        'gregorianMonth': gregorianMonth,
        'gregorianYear': gregorianYear,
        'gregorianMonthEn': gregorianMonthEn,
        'weekdayEn': weekdayEn,
        'hijriDay': hijriDay,
        'hijriMonthNumber': hijriMonthNumber,
        'hijriMonthEn': hijriMonthEn,
        'hijriMonthAr': hijriMonthAr,
        'hijriYear': hijriYear,
        'holidays': holidays,
      };

  factory CalendarDayEntry.fromJson(Map<String, dynamic> json) {
    return CalendarDayEntry(
      gregorianDay: (json['gregorianDay'] as num?)?.toInt() ?? 1,
      gregorianMonth: (json['gregorianMonth'] as num?)?.toInt() ?? 1,
      gregorianYear: (json['gregorianYear'] as num?)?.toInt() ?? 2026,
      gregorianMonthEn: (json['gregorianMonthEn'] ?? '').toString(),
      weekdayEn: (json['weekdayEn'] ?? '').toString(),
      hijriDay: (json['hijriDay'] as num?)?.toInt() ?? 1,
      hijriMonthNumber: (json['hijriMonthNumber'] as num?)?.toInt() ?? 1,
      hijriMonthEn: (json['hijriMonthEn'] ?? '').toString(),
      hijriMonthAr: (json['hijriMonthAr'] ?? '').toString(),
      hijriYear: (json['hijriYear'] as num?)?.toInt() ?? 1448,
      holidays:
          (json['holidays'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
    );
  }
}

class AlAdhanCatalog {
  static List<String> get fivePrayerKeys => ApiConfig.fivePrayerKeys;
  static List<PrayerCalculationMethod> get methods => ApiConfig.prayerMethods;
  static List<AlarmSoundOption> get alarmSounds => ApiConfig.alarmSounds;
  static List<CityPreset> get quickCities => ApiConfig.quickCities;

  static PrayerCalculationMethod methodById(int id) {
    return ApiConfig.prayerMethods.firstWhere(
      (m) => m.id == id,
      orElse: () => ApiConfig.prayerMethods.first,
    );
  }

  static AlarmSoundOption soundById(String id) => ApiConfig.alarmSoundById(id);

  static Map<String, PrayerAlarmConfig> defaultPrayerConfigs() =>
      ApiConfig.defaultPrayerConfigs();
}

class HijriMonthCatalog {
  static String monthName(int month, String lang) {
    final idx = (month - 1).clamp(0, 11);
    if (lang == 'ar') return ApiConfig.hijriMonthsAr[idx];
    return ApiConfig.hijriMonthsEn[idx];
  }
}
