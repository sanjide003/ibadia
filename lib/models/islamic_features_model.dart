import 'dart:math' as math;

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

class AlAdhanCatalog {
  static const int defaultMethodId = 1; // Karachi (UISK)
  static const int defaultSchool = 0; // Shafi
  static const String defaultCity = 'Kochi';
  static const String defaultCountry = 'India';
  static const double defaultLat = 9.9312;
  static const double defaultLon = 76.2673;

  static const double kaabaLat = 21.422487;
  static const double kaabaLon = 39.826206;

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

  /// Computes exact true-north Qibla bearing in degrees [0..360) via spherical trig.
  static double computeQiblaBearing(double latitude, double longitude) {
    final lat1 = latitude * math.pi / 180.0;
    final lon1 = longitude * math.pi / 180.0;
    const lat2 = kaabaLat * math.pi / 180.0;
    const lon2 = kaabaLon * math.pi / 180.0;
    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360.0) % 360.0;
  }

  /// Computes great-circle Haversine distance to the Kaaba in kilometers.
  static double distanceToKaabaKm(double latitude, double longitude) {
    const earthRadiusKm = 6371.0;
    final dLat = (kaabaLat - latitude) * math.pi / 180.0;
    final dLon = (kaabaLon - longitude) * math.pi / 180.0;
    final lat1 = latitude * math.pi / 180.0;
    const lat2 = kaabaLat * math.pi / 180.0;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1) *
            math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static String compassCardinal(double deg) {
    const dirs = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final idx = ((deg / 22.5).round()) % 16;
    return dirs[idx];
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
        'wd': weekdayEn,
        'hd': hijriDay,
        'hm': hijriMonthNumber,
        'hme': hijriMonthEn,
        'hma': hijriMonthAr,
        'hy': hijriYear,
        if (holidays.isNotEmpty) 'hol': holidays,
      };
}
