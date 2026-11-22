import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/islamic_features_model.dart';
import 'storage_service.dart';

class IslamicFeaturesService {
  final http.Client _client;
  final Map<String, Future<DailyPrayerData>> _inFlightPrayer = {};
  final Map<String, Future<List<CalendarDayEntry>>> _inFlightCalendar = {};

  IslamicFeaturesService({http.Client? client})
      : _client = client ?? http.Client();

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

  Future<DailyPrayerData> fetchDailyPrayerTimes({
    required AppSettings settings,
    required StorageService storage,
    DateTime? targetDate,
    bool forceRefresh = false,
  }) async {
    final now = targetDate ?? DateTime.now();
    final dateKey = formatDateKey(now);
    final apiDate = formatAlAdhanDate(now);
    final cacheSig = buildCacheSignature(settings);

    if (!forceRefresh) {
      final cached = await storage.loadDailyPrayerCache();
      if (cached != null &&
          cached['dateKey'] == dateKey &&
          cached['cacheSig'] == cacheSig) {
        return DailyPrayerData.fromCacheJson(cached);
      }
    }

    final reqKey = '$dateKey|$cacheSig|$forceRefresh';
    if (_inFlightPrayer.containsKey(reqKey)) {
      return _inFlightPrayer[reqKey]!;
    }

    final future = _fetchDailyPrayerNetwork(
      settings: settings,
      storage: storage,
      dateKey: dateKey,
      apiDate: apiDate,
      cacheSig: cacheSig,
    );
    _inFlightPrayer[reqKey] = future;
    try {
      return await future;
    } finally {
      _inFlightPrayer.remove(reqKey);
    }
  }

  Future<DailyPrayerData> _fetchDailyPrayerNetwork({
    required AppSettings settings,
    required StorageService storage,
    required String dateKey,
    required String apiDate,
    required String cacheSig,
  }) async {
    final Uri uri;
    if (settings.prayerLocationMode == 'gps') {
      uri = Uri.https('api.aladhan.com', '/v1/timings/$apiDate', {
        'latitude': settings.prayerLat.toStringAsFixed(5),
        'longitude': settings.prayerLon.toStringAsFixed(5),
        'method': '${settings.prayerMethod}',
        'school': '${settings.prayerSchool}',
        'adjustment': '${settings.hijriAdjustment}',
        'calendarMethod': 'MATHEMATICAL',
      });
    } else {
      uri = Uri.https('api.aladhan.com', '/v1/timingsByCity/$apiDate', {
        'city': settings.prayerCity.trim().isEmpty
            ? AlAdhanCatalog.defaultCity
            : settings.prayerCity.trim(),
        'country': settings.prayerCountry.trim().isEmpty
            ? AlAdhanCatalog.defaultCountry
            : settings.prayerCountry.trim(),
        'method': '${settings.prayerMethod}',
        'school': '${settings.prayerSchool}',
        'adjustment': '${settings.hijriAdjustment}',
        'calendarMethod': 'MATHEMATICAL',
      });
    }

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        throw Exception('AlAdhan HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid AlAdhan response format');
      }

      final parsed = DailyPrayerData.fromAlAdhanJson(
        data,
        dateKey: dateKey,
        locationLabel: settings.displayLocationLabel,
        methodId: settings.prayerMethod,
        school: settings.prayerSchool,
        hijriAdjustment: settings.hijriAdjustment,
      );

      final cachePayload = parsed.toCacheJson()..['cacheSig'] = cacheSig;
      await storage.saveDailyPrayerCache(cachePayload);
      return parsed;
    } catch (e) {
      // Fallback to cached data if available for same settings signature
      final cached = await storage.loadDailyPrayerCache();
      if (cached != null && cached['cacheSig'] == cacheSig) {
        return DailyPrayerData.fromCacheJson(cached);
      }
      rethrow;
    }
  }

  Future<List<CalendarDayEntry>> fetchMonthlyHijriCalendar({
    required int year,
    required int month,
    required int adjustment,
    required StorageService storage,
    bool forceRefresh = false,
  }) async {
    final normAdj = adjustment.clamp(-1, 1);

    if (!forceRefresh) {
      final cached =
          await storage.loadHijriCalendarCache(year, month, normAdj);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .whereType<Map<String, dynamic>>()
            .map(CalendarDayEntry.fromCacheJson)
            .toList();
      }
    }

    final reqKey = '${year}_${month}_adj$normAdj';
    if (_inFlightCalendar.containsKey(reqKey)) {
      return _inFlightCalendar[reqKey]!;
    }

    final future = _fetchMonthlyHijriNetwork(
      year: year,
      month: month,
      adjustment: normAdj,
      storage: storage,
    );
    _inFlightCalendar[reqKey] = future;
    try {
      return await future;
    } finally {
      _inFlightCalendar.remove(reqKey);
    }
  }

  Future<List<CalendarDayEntry>> _fetchMonthlyHijriNetwork({
    required int year,
    required int month,
    required int adjustment,
    required StorageService storage,
  }) async {
    final uri = Uri.https('api.aladhan.com', '/v1/gToHCalendar/$month/$year', {
      'calendarMethod': 'MATHEMATICAL',
      'adjustment': '$adjustment',
    });

    final res = await _client.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('AlAdhan calendar HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final rawList = body['data'];
    if (rawList is! List) {
      throw Exception('Invalid AlAdhan calendar response');
    }

    final entries = rawList
        .whereType<Map<String, dynamic>>()
        .map(CalendarDayEntry.fromAlAdhanJson)
        .toList();

    await storage.saveHijriCalendarCache(
      year,
      month,
      adjustment,
      entries.map((e) => e.toCacheJson()).toList(),
    );
    return entries;
  }
}
