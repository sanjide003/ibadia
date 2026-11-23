import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/islamic_features_model.dart';
import 'storage_service.dart';

class IslamicFeaturesService {
  static String formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatAlAdhanDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d-$m-$y';
  }

  static String buildCacheSignature(AppSettings settings) {
    if (settings.prayerLocationMode == 'gps') {
      return 'gps|${settings.prayerLat.toStringAsFixed(3)}|${settings.prayerLon.toStringAsFixed(3)}|m${settings.prayerMethod}|s${settings.prayerSchool}|a${settings.hijriAdjustment}';
    }
    return 'city|${settings.prayerCity.trim().toLowerCase()}|${settings.prayerCountry.trim().toLowerCase()}|m${settings.prayerMethod}|s${settings.prayerSchool}|a${settings.hijriAdjustment}';
  }

  static String _cleanTime(dynamic raw) {
    final str = (raw ?? '00:00').toString();
    final m = RegExp(r'(\d{1,2}:\d{2})').firstMatch(str);
    return m?.group(1) ?? '00:00';
  }

  Future<DailyPrayerData> fetchDailyPrayerTimes({
    required AppSettings settings,
    required StorageService storage,
    DateTime? targetDate,
    bool forceRefresh = false,
  }) async {
    final dt = targetDate ?? DateTime.now();
    final dateKey = formatDateKey(dt);
    final apiDate = formatAlAdhanDate(dt);
    final cacheSig = buildCacheSignature(settings);

    if (!forceRefresh) {
      final cachedRaw = await storage.loadDailyPrayerCache();
      if (cachedRaw != null) {
        final cached = DailyPrayerData.fromJson(cachedRaw);
        if (cached.dateKey == dateKey && cached.cacheSig == cacheSig) {
          return cached.copyWith(loadedFromCache: true);
        }
      }
    }

    final queryParams = <String, String>{
      'method': settings.prayerMethod.toString(),
      'school': settings.prayerSchool.toString(),
      'adjustment': settings.hijriAdjustment.toString(),
      'calendarMethod': 'MATHEMATICAL',
    };

    late final Uri uri;
    if (settings.prayerLocationMode == 'gps') {
      queryParams['latitude'] = settings.prayerLat.toStringAsFixed(5);
      queryParams['longitude'] = settings.prayerLon.toStringAsFixed(5);
      uri = Uri.parse('${ApiConfig.alAdhanBaseUrl}/timings/$apiDate')
          .replace(queryParameters: queryParams);
    } else {
      queryParams['city'] =
          settings.prayerCity.trim().isEmpty ? 'Kochi' : settings.prayerCity.trim();
      queryParams['country'] = settings.prayerCountry.trim().isEmpty
          ? 'India'
          : settings.prayerCountry.trim();
      uri = Uri.parse('${ApiConfig.alAdhanBaseUrl}/timingsByCity/$apiDate')
          .replace(queryParameters: queryParams);
    }

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('AlAdhan HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! Map) {
        throw Exception('Invalid AlAdhan response');
      }

      final timings =
          Map<String, dynamic>.from((data['timings'] as Map?) ?? {});
      final date = Map<String, dynamic>.from((data['date'] as Map?) ?? {});
      final meta = Map<String, dynamic>.from((data['meta'] as Map?) ?? {});
      final hijri = Map<String, dynamic>.from((date['hijri'] as Map?) ?? {});
      final greg = Map<String, dynamic>.from((date['gregorian'] as Map?) ?? {});
      final hMonth = Map<String, dynamic>.from((hijri['month'] as Map?) ?? {});
      final hWeekday =
          Map<String, dynamic>.from((hijri['weekday'] as Map?) ?? {});
      final gWeekday =
          Map<String, dynamic>.from((greg['weekday'] as Map?) ?? {});

      final parsed = DailyPrayerData(
        dateKey: dateKey,
        locationLabel: settings.displayLocationLabel,
        latitude: (meta['latitude'] as num?)?.toDouble() ?? settings.prayerLat,
        longitude:
            (meta['longitude'] as num?)?.toDouble() ?? settings.prayerLon,
        timezone: (meta['timezone'] ?? 'Asia/Kolkata').toString(),
        methodId: settings.prayerMethod,
        school: settings.prayerSchool,
        hijriAdjustment: settings.hijriAdjustment,
        gregorianReadable: (date['readable'] ?? dateKey).toString(),
        hijriDay: (hijri['day'] ?? '1').toString(),
        hijriMonthNumber: (hMonth['number'] as num?)?.toInt() ?? 1,
        hijriMonthEn: (hMonth['en'] ?? '').toString(),
        hijriMonthAr: (hMonth['ar'] ?? '').toString(),
        hijriYear: (hijri['year'] ?? '1448').toString(),
        weekdayEn: (gWeekday['en'] ?? hWeekday['en'] ?? '').toString(),
        weekdayAr: (hWeekday['ar'] ?? '').toString(),
        baseTimings: {
          'fajr': _cleanTime(timings['Fajr']),
          'sunrise': _cleanTime(timings['Sunrise']),
          'dhuhr': _cleanTime(timings['Dhuhr']),
          'asr': _cleanTime(timings['Asr']),
          'maghrib': _cleanTime(timings['Maghrib']),
          'isha': _cleanTime(timings['Isha']),
        },
        loadedFromCache: false,
        cacheSig: cacheSig,
      );

      await storage.saveDailyPrayerCache(parsed.toJson());
      return parsed;
    } catch (err) {
      final cachedRaw = await storage.loadDailyPrayerCache();
      if (cachedRaw != null) {
        final cached = DailyPrayerData.fromJson(cachedRaw);
        if (cached.cacheSig == cacheSig) {
          return cached.copyWith(loadedFromCache: true);
        }
      }
      rethrow;
    }
  }

  Future<({int year, int month, int day})> resolveTodayHijriDate({
    required int adjustment,
  }) async {
    final normAdj = adjustment.clamp(-1, 1);
    final apiDate = formatAlAdhanDate(DateTime.now());
    final uri = Uri.parse('${ApiConfig.alAdhanBaseUrl}/gToH/$apiDate').replace(
      queryParameters: {
        'calendarMethod': 'MATHEMATICAL',
        'adjustment': '$normAdj',
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AlAdhan HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = (body['data'] as Map?) ?? {};
    final hijri = (data['hijri'] as Map?) ?? {};
    final hMonth = (hijri['month'] as Map?) ?? {};

    final year = int.tryParse((hijri['year'] ?? '').toString()) ??
        (hijri['year'] as num?)?.toInt() ??
        1448;
    final month = ((int.tryParse((hMonth['number'] ?? '').toString()) ??
                (hMonth['number'] as num?)?.toInt() ??
                1)
            .clamp(1, 12));
    final day = int.tryParse((hijri['day'] ?? '').toString()) ??
        (hijri['day'] as num?)?.toInt() ??
        1;

    return (year: year, month: month, day: day);
  }

  Future<List<CalendarDayEntry>> fetchHijriMonthCalendar({
    required int hijriYear,
    required int hijriMonth,
    required int adjustment,
    required StorageService storage,
    bool forceRefresh = false,
  }) async {
    final normAdj = adjustment.clamp(-1, 1);
    final normMonth = hijriMonth.clamp(1, 12);

    if (!forceRefresh) {
      final cachedRaw = await storage.loadHijriCalendarCache(
        hijriYear,
        normMonth,
        normAdj,
      );
      if (cachedRaw != null && cachedRaw.isNotEmpty) {
        return cachedRaw
            .whereType<Map>()
            .map((e) => CalendarDayEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    final uri = Uri.parse(
      '${ApiConfig.alAdhanBaseUrl}/hToGCalendar/$normMonth/$hijriYear',
    ).replace(
      queryParameters: {
        'calendarMethod': 'MATHEMATICAL',
        'adjustment': '$normAdj',
      },
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AlAdhan HTTP ${res.statusCode}');
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawList = (body['data'] as List<dynamic>? ?? const []);
    final entries = rawList.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final greg = Map<String, dynamic>.from((item['gregorian'] as Map?) ?? {});
      final hijri = Map<String, dynamic>.from((item['hijri'] as Map?) ?? {});
      final gMonth = Map<String, dynamic>.from((greg['month'] as Map?) ?? {});
      final gWeekday =
          Map<String, dynamic>.from((greg['weekday'] as Map?) ?? {});
      final hMonth = Map<String, dynamic>.from((hijri['month'] as Map?) ?? {});
      final rawHolidays = hijri['holidays'];
      final holidays = rawHolidays is List
          ? rawHolidays.map((e) => e.toString()).toList()
          : const <String>[];

      int parseInt(dynamic v, int fallback) =>
          (v is num) ? v.toInt() : (int.tryParse((v ?? '').toString()) ?? fallback);

      return CalendarDayEntry(
        gregorianDay: parseInt(greg['day'], 1),
        gregorianMonth: parseInt(gMonth['number'], 1),
        gregorianYear: parseInt(greg['year'], 2026),
        gregorianMonthEn: (gMonth['en'] ?? '').toString(),
        weekdayEn: (gWeekday['en'] ?? '').toString(),
        hijriDay: parseInt(hijri['day'], 1),
        hijriMonthNumber: parseInt(hMonth['number'], normMonth),
        hijriMonthEn: (hMonth['en'] ?? '').toString(),
        hijriMonthAr: (hMonth['ar'] ?? '').toString(),
        hijriYear: parseInt(hijri['year'], hijriYear),
        holidays: holidays,
      );
    }).toList();

    await storage.saveHijriCalendarCache(
      hijriYear,
      normMonth,
      normAdj,
      entries.map((e) => e.toJson()).toList(),
    );
    return entries;
  }
}
