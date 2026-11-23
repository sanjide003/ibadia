class PrayerAlarmConfig {
  final String prayerKey;
  final bool enabled;
  final int iqamahGapMinutes;
  final String alarmRef; // 'beforeAdhan' | 'relativeToIqamah'
  final int alarmOffsetMinutes;

  const PrayerAlarmConfig({
    required this.prayerKey,
    required this.enabled,
    required this.iqamahGapMinutes,
    required this.alarmRef,
    required this.alarmOffsetMinutes,
  });

  PrayerAlarmConfig copyWith({
    bool? enabled,
    int? iqamahGapMinutes,
    String? alarmRef,
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
        'alarmRef': alarmRef,
        'alarmOffsetMinutes': alarmOffsetMinutes,
      };

  factory PrayerAlarmConfig.fromJson(Map<String, dynamic> json) {
    return PrayerAlarmConfig(
      prayerKey: (json['prayerKey'] ?? 'fajr').toString(),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      iqamahGapMinutes: (json['iqamahGapMinutes'] as num?)?.toInt() ?? 15,
      alarmRef: (json['alarmRef'] ?? 'beforeAdhan').toString(),
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
      holidays: (json['holidays'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
