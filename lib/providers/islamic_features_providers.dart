import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/islamic_features_model.dart';
import '../services/islamic_features_service.dart';
import '../services/storage_service.dart';
import 'quran_providers.dart';

final islamicFeaturesServiceProvider = Provider<IslamicFeaturesService>(
  (ref) => IslamicFeaturesService(),
);

class PrayerTimesState {
  final DailyPrayerData? data;
  final bool isLoading;
  final bool isFetchingGps;
  final String? error;
  final String? gpsNotice;
  final bool gpsIsError;

  const PrayerTimesState({
    this.data,
    this.isLoading = false,
    this.isFetchingGps = false,
    this.error,
    this.gpsNotice,
    this.gpsIsError = false,
  });

  PrayerTimesState copyWith({
    DailyPrayerData? data,
    bool? isLoading,
    bool? isFetchingGps,
    String? error,
    bool clearError = false,
    String? gpsNotice,
    bool clearGpsNotice = false,
    bool? gpsIsError,
  }) {
    return PrayerTimesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isFetchingGps: isFetchingGps ?? this.isFetchingGps,
      error: clearError ? null : (error ?? this.error),
      gpsNotice: clearGpsNotice ? null : (gpsNotice ?? this.gpsNotice),
      gpsIsError: gpsIsError ?? this.gpsIsError,
    );
  }
}

class PrayerTimesNotifier extends StateNotifier<PrayerTimesState> {
  final Ref _ref;
  String? _lastLoadedSig;
  String? _lastLoadedDateKey;

  PrayerTimesNotifier(this._ref) : super(const PrayerTimesState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    final settings = await _ref.read(settingsProvider.notifier).ensureLoaded();
    await load(settings: settings);

    _ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (prev == null) return;
      final prevSig = IslamicFeaturesService.buildCacheSignature(prev);
      final nextSig = IslamicFeaturesService.buildCacheSignature(next);
      if (prevSig != nextSig) {
        load(settings: next);
      }
    });
  }

  Future<void> load({AppSettings? settings, bool forceRefresh = false}) async {
    final AppSettings s = settings ?? _ref.read(settingsProvider);
    final dateKey = IslamicFeaturesService.formatDateKey(DateTime.now());
    final sig = IslamicFeaturesService.buildCacheSignature(s);

    if (!forceRefresh &&
        state.data != null &&
        _lastLoadedSig == sig &&
        _lastLoadedDateKey == dateKey) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _ref
          .read(islamicFeaturesServiceProvider)
          .fetchDailyPrayerTimes(
            settings: s,
            storage: _ref.read(storageServiceProvider),
            forceRefresh: forceRefresh,
          );
      if (!mounted) return;
      _lastLoadedSig = sig;
      _lastLoadedDateKey = dateKey;
      state = state.copyWith(
        data: result,
        isLoading: false,
        clearError: true,
      );

      // Sync exact coordinates returned by AlAdhan for custom cities so Qibla updates too
      if (s.prayerLocationMode == 'city' &&
          ((s.prayerLat - result.latitude).abs() > 0.02 ||
              (s.prayerLon - result.longitude).abs() > 0.02)) {
        await _ref.read(settingsProvider.notifier).update(
              s.copyWith(
                prayerLat: result.latitude,
                prayerLon: result.longitude,
              ),
            );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> selectCityPreset(CityPreset preset) async {
    final s = _ref.read(settingsProvider);
    state = state.copyWith(clearGpsNotice: true);
    await _ref.read(settingsProvider.notifier).update(
          s.copyWith(
            prayerLocationMode: 'city',
            prayerCity: preset.city,
            prayerCountry: preset.country,
            prayerLat: preset.latitude,
            prayerLon: preset.longitude,
            clearGpsLocality: true,
          ),
        );
  }

  Future<void> setCustomCity(String city, String country) async {
    final cleanCity = city.trim();
    final cleanCountry = country.trim();
    if (cleanCity.isEmpty || cleanCountry.isEmpty) return;

    final s = _ref.read(settingsProvider);
    state = state.copyWith(clearGpsNotice: true);
    await _ref.read(settingsProvider.notifier).update(
          s.copyWith(
            prayerLocationMode: 'city',
            prayerCity: cleanCity,
            prayerCountry: cleanCountry,
            clearGpsLocality: true,
          ),
        );
  }

  /// Fetches current device/browser GPS location cleanly and refreshes Prayer & Qibla.
  Future<bool> useGpsLocation({
    required String permissionDeniedMsg,
    required String serviceDisabledMsg,
  }) async {
    if (state.isFetchingGps) return false;
    state = state.copyWith(isFetchingGps: true, clearGpsNotice: true);

    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          state = state.copyWith(
            isFetchingGps: false,
            gpsNotice: serviceDisabledMsg,
            gpsIsError: true,
          );
          return false;
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isFetchingGps: false,
          gpsNotice: permissionDeniedMsg,
          gpsIsError: true,
        );
        return false;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final label =
          'GPS (${pos.latitude.toStringAsFixed(2)}°, ${pos.longitude.toStringAsFixed(2)}°)';
      final current = _ref.read(settingsProvider);
      await _ref.read(settingsProvider.notifier).update(
            current.copyWith(
              prayerLocationMode: 'gps',
              prayerLat: pos.latitude,
              prayerLon: pos.longitude,
              gpsLocalityLabel: label,
            ),
          );

      if (!mounted) return true;
      state = state.copyWith(
        isFetchingGps: false,
        clearGpsNotice: true,
        gpsIsError: false,
      );
      return true;
    } catch (_) {
      if (!mounted) return false;
      state = state.copyWith(
        isFetchingGps: false,
        gpsNotice: permissionDeniedMsg,
        gpsIsError: true,
      );
      return false;
    }
  }

  void clearGpsNotice() {
    state = state.copyWith(clearGpsNotice: true);
  }
}

final prayerTimesProvider =
    StateNotifierProvider<PrayerTimesNotifier, PrayerTimesState>(
  (ref) => PrayerTimesNotifier(ref),
);

class HijriCalendarState {
  final int year;
  final int month;
  final List<CalendarDayEntry> days;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;

  const HijriCalendarState({
    required this.year,
    required this.month,
    this.days = const [],
    this.isLoading = false,
    this.error,
    required this.selectedDate,
  });

  HijriCalendarState copyWith({
    int? year,
    int? month,
    List<CalendarDayEntry>? days,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? selectedDate,
  }) {
    return HijriCalendarState(
      year: year ?? this.year,
      month: month ?? this.month,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class HijriCalendarNotifier extends StateNotifier<HijriCalendarState> {
  final Ref _ref;

  HijriCalendarNotifier(this._ref)
      : super(
          HijriCalendarState(
            year: DateTime.now().year,
            month: DateTime.now().month,
            selectedDate: DateTime.now(),
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    final settings = await _ref.read(settingsProvider.notifier).ensureLoaded();
    await loadMonth(
      state.year,
      state.month,
      adjustment: settings.hijriAdjustment,
    );

    _ref.listen<int>(
      settingsProvider.select((s) => s.hijriAdjustment),
      (prev, next) {
        if (prev != next) {
          loadMonth(state.year, state.month, adjustment: next);
        }
      },
    );
  }

  Future<void> loadMonth(
    int year,
    int month, {
    int? adjustment,
    bool forceRefresh = false,
  }) async {
    final adj = adjustment ?? _ref.read(settingsProvider).hijriAdjustment;
    state = state.copyWith(
      year: year,
      month: month,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _ref
          .read(islamicFeaturesServiceProvider)
          .fetchMonthlyHijriCalendar(
            year: year,
            month: month,
            adjustment: adj,
            storage: _ref.read(storageServiceProvider),
            forceRefresh: forceRefresh,
          );
      if (!mounted) return;
      state = state.copyWith(
        days: list,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> previousMonth() async {
    var y = state.year;
    var m = state.month - 1;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    await loadMonth(y, m);
  }

  Future<void> nextMonth() async {
    var y = state.year;
    var m = state.month + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    await loadMonth(y, m);
  }

  Future<void> goToToday() async {
    final now = DateTime.now();
    state = state.copyWith(selectedDate: now);
    await loadMonth(now.year, now.month);
  }

  void selectDay(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}

final hijriCalendarProvider =
    StateNotifierProvider<HijriCalendarNotifier, HijriCalendarState>(
  (ref) => HijriCalendarNotifier(ref),
);
