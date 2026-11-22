import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../core/l10n/app_strings.dart';
import '../models/islamic_features_model.dart';
import '../services/islamic_features_service.dart';
import '../services/prayer_alarm_bridge.dart';
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

      // Sync exact coordinates returned by AlAdhan for custom cities
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

  /// Fetches current device/browser GPS location cleanly and refreshes Prayer Times.
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

// ---------------------------------------------------------------------------
// PRAYER ALARM COORDINATOR (Slots, Sound Preview, Lock-Screen Dismiss Sync)
// ---------------------------------------------------------------------------

class RingingAlarmInfo {
  final String prayerKey;
  final String title;
  final String timeLabel;
  final String dateKey;

  const RingingAlarmInfo({
    required this.prayerKey,
    required this.title,
    required this.timeLabel,
    required this.dateKey,
  });
}

class PrayerAlarmState {
  final List<ComputedPrayerSlot> slots;
  final Set<String> dismissedTodayKeys;
  final RingingAlarmInfo? activeRinging;
  final bool isPreviewingSound;
  final String currentDateKey;

  const PrayerAlarmState({
    this.slots = const [],
    this.dismissedTodayKeys = const {},
    this.activeRinging,
    this.isPreviewingSound = false,
    this.currentDateKey = '',
  });

  PrayerAlarmState copyWith({
    List<ComputedPrayerSlot>? slots,
    Set<String>? dismissedTodayKeys,
    RingingAlarmInfo? activeRinging,
    bool clearActiveRinging = false,
    bool? isPreviewingSound,
    String? currentDateKey,
  }) {
    return PrayerAlarmState(
      slots: slots ?? this.slots,
      dismissedTodayKeys: dismissedTodayKeys ?? this.dismissedTodayKeys,
      activeRinging:
          clearActiveRinging ? null : (activeRinging ?? this.activeRinging),
      isPreviewingSound: isPreviewingSound ?? this.isPreviewingSound,
      currentDateKey: currentDateKey ?? this.currentDateKey,
    );
  }
}

class PrayerAlarmNotifier extends StateNotifier<PrayerAlarmState> {
  final Ref _ref;
  final PrayerAlarmBridge _bridge = PrayerAlarmBridge.instance;
  Timer? _ticker;
  String? _lastScheduledSignature;
  String? _lastTriggeredSlotKey;

  PrayerAlarmNotifier(this._ref)
      : super(
          PrayerAlarmState(
            currentDateKey: IslamicFeaturesService.formatDateKey(DateTime.now()),
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    _bridge.setOnAlarmRingingHandler((nativeInfo) {
      if (!mounted) return;
      state = state.copyWith(
        activeRinging: RingingAlarmInfo(
          prayerKey: nativeInfo.prayerKey,
          title: nativeInfo.title,
          timeLabel: nativeInfo.timeLabel,
          dateKey: nativeInfo.dateKey,
        ),
      );
    });

    await _ref.read(settingsProvider.notifier).ensureLoaded();
    await _reloadDismissedForDate(
      IslamicFeaturesService.formatDateKey(DateTime.now()),
    );
    await syncWithNative();
    _recomputeAndSync(syncNative: true);

    _ref.listen<PrayerTimesState>(prayerTimesProvider, (prev, next) {
      if (next.data != prev?.data) {
        _recomputeAndSync(syncNative: true);
      }
    });

    _ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (prev == null) return;
      _recomputeAndSync(syncNative: true);
    });

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onSecondTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bridge.setOnAlarmRingingHandler(null);
    super.dispose();
  }

  Future<void> _reloadDismissedForDate(String dateKey) async {
    final storage = _ref.read(storageServiceProvider);
    final stored = await storage.loadDismissedAlarmsForDate(dateKey);
    final nativeList = await _bridge.getNativeDismissedKeys(dateKey);
    final merged = {...stored, ...nativeList};
    if (merged.length != stored.length) {
      await storage.saveDismissedAlarmsForDate(dateKey, merged);
    }
    if (!mounted) return;
    state = state.copyWith(
      currentDateKey: dateKey,
      dismissedTodayKeys: merged,
    );
  }

  Future<void> syncWithNative() async {
    final todayKey = IslamicFeaturesService.formatDateKey(DateTime.now());
    await _reloadDismissedForDate(todayKey);

    final nativeRinging = await _bridge.getActiveRingingAlarm();
    if (!mounted) return;
    if (nativeRinging != null) {
      state = state.copyWith(
        activeRinging: RingingAlarmInfo(
          prayerKey: nativeRinging.prayerKey,
          title: nativeRinging.title,
          timeLabel: nativeRinging.timeLabel,
          dateKey: nativeRinging.dateKey,
        ),
      );
    } else if (_bridge.isNativeAndroid && state.activeRinging != null) {
      state = state.copyWith(clearActiveRinging: true);
    }
    _recomputeAndSync(syncNative: false);
  }

  String _prayerName(String key, AppStrings t) {
    switch (key) {
      case 'fajr':
        return t.fajrName;
      case 'dhuhr':
        return t.dhuhrName;
      case 'asr':
        return t.asrName;
      case 'maghrib':
        return t.maghribName;
      case 'isha':
        return t.ishaName;
      default:
        return key;
    }
  }

  void _recomputeAndSync({required bool syncNative}) {
    final prayerData = _ref.read(prayerTimesProvider).data;
    if (prayerData == null) return;

    final now = DateTime.now();
    final settings = _ref.read(settingsProvider);
    final strings = _ref.read(stringsProvider);

    final slots = prayerData.computeDailySlots(
      referenceDay: now,
      tuneFor: settings.tuneFor,
      configs: settings.prayerConfigs,
      masterAlarmEnabled: settings.prayerAlarmMasterEnabled,
      dismissedTodayKeys: state.dismissedTodayKeys,
    );

    if (mounted) {
      state = state.copyWith(slots: slots);
    }

    if (syncNative && _bridge.isNativeAndroid) {
      final sig =
          '${state.currentDateKey}|${settings.prayerAlarmMasterEnabled}|${settings.alarmSoundType}|${settings.alarmVolume}|${settings.alarmVibrate}|${settings.appLanguage}|${slots.map((s) => '${s.prayerKey}:${s.alarmTime?.millisecondsSinceEpoch}:${s.isAlarmActive}:${s.dismissedToday}').join(',')}';
      if (sig != _lastScheduledSignature) {
        _lastScheduledSignature = sig;
        unawaited(
          _bridge.syncNativeSchedule(
            slots: slots,
            settings: settings,
            strings: strings,
            referenceDay: now,
          ),
        );
      }
    }
  }

  Future<void> _onSecondTick() async {
    if (!mounted) return;
    final now = DateTime.now();
    final dateKey = IslamicFeaturesService.formatDateKey(now);

    // Rollover to a fresh calendar day at midnight so today-only dismissals clear cleanly
    if (dateKey != state.currentDateKey) {
      _lastTriggeredSlotKey = null;
      _lastScheduledSignature = null;
      await _reloadDismissedForDate(dateKey);
      await _ref.read(prayerTimesProvider.notifier).load(forceRefresh: false);
      _recomputeAndSync(syncNative: true);
      return;
    }

    // Check active alarm match while app is open
    final settings = _ref.read(settingsProvider);
    if (!settings.prayerAlarmMasterEnabled || state.slots.isEmpty) return;

    if (_bridge.isNativeAndroid) {
      // Poll native ringing state gently near an active alarm minute so foreground UI updates immediately
      for (final slot in state.slots) {
        final alarmDt = slot.alarmTime;
        if (!slot.isAlarmActive || slot.dismissedToday || alarmDt == null) {
          continue;
        }
        final diffSec = now.difference(alarmDt).inSeconds;
        if (diffSec >= 0 && diffSec <= 5 && state.activeRinging == null) {
          await syncWithNative();
          break;
        }
      }
      return;
    }

    // Web / Desktop foreground alarm check
    if (state.activeRinging != null) return;
    final t = _ref.read(stringsProvider);
    for (final slot in state.slots) {
      final alarmDt = slot.alarmTime;
      if (!slot.isAlarmActive || slot.dismissedToday || alarmDt == null) {
        continue;
      }
      if (now.year == alarmDt.year &&
          now.month == alarmDt.month &&
          now.day == alarmDt.day &&
          now.hour == alarmDt.hour &&
          now.minute == alarmDt.minute) {
        final occKey = '$dateKey|${slot.prayerKey}';
        if (_lastTriggeredSlotKey == occKey) continue;
        _lastTriggeredSlotKey = occKey;
        final label = _prayerName(slot.prayerKey, t);
        state = state.copyWith(
          isPreviewingSound: false,
          activeRinging: RingingAlarmInfo(
            prayerKey: slot.prayerKey,
            title: '$label • ${t.prayerReminderRinging}',
            timeLabel: DailyPrayerData.format12Hour(alarmDt),
            dateKey: dateKey,
          ),
        );
        unawaited(_bridge.startRingingLoopSound(settings));
        break;
      }
    }
  }

  Future<void> setMasterAlarmEnabled(bool enabled) async {
    final notifier = _ref.read(settingsProvider.notifier);
    final current = _ref.read(settingsProvider);
    if (enabled) {
      await _bridge.requestAlarmPermissions();
    }
    await notifier.update(
      current.copyWith(prayerAlarmMasterEnabled: enabled),
    );
  }

  Future<void> dismissTodayAlarm([String? prayerKey]) async {
    final active = state.activeRinging;
    final key = prayerKey ?? active?.prayerKey;
    final dateKey = active?.dateKey ??
        IslamicFeaturesService.formatDateKey(DateTime.now());

    await _bridge.dismissNativeAlarm(dateKey: dateKey, prayerKey: key);

    final nextDismissed = Set<String>.from(state.dismissedTodayKeys);
    if (key != null && key.isNotEmpty) {
      nextDismissed.add('$dateKey|$key');
    }

    await _ref
        .read(storageServiceProvider)
        .saveDismissedAlarmsForDate(dateKey, nextDismissed);

    if (!mounted) return;
    state = state.copyWith(
      clearActiveRinging: true,
      dismissedTodayKeys: nextDismissed,
    );
    _recomputeAndSync(syncNative: true);
  }

  Future<void> togglePreviewSound() async {
    if (state.isPreviewingSound) {
      await stopPreviewSound();
      return;
    }
    final settings = _ref.read(settingsProvider);
    state = state.copyWith(isPreviewingSound: true);
    await _bridge.previewSound(
      settings,
      onFinished: () {
        if (mounted) {
          state = state.copyWith(isPreviewingSound: false);
        }
      },
    );
  }

  Future<void> stopPreviewSound() async {
    await _bridge.stopSound();
    if (mounted) {
      state = state.copyWith(isPreviewingSound: false);
    }
  }
}

final prayerAlarmProvider =
    StateNotifierProvider<PrayerAlarmNotifier, PrayerAlarmState>(
  (ref) => PrayerAlarmNotifier(ref),
);

// ---------------------------------------------------------------------------
// HIJRI-MONTH-FIRST CALENDAR NOTIFIER (`hToGCalendar`)
// ---------------------------------------------------------------------------

class HijriCalendarState {
  final int hijriYear;
  final int hijriMonth;
  final List<CalendarDayEntry> days;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;

  const HijriCalendarState({
    required this.hijriYear,
    required this.hijriMonth,
    this.days = const [],
    this.isLoading = false,
    this.error,
    required this.selectedDate,
  });

  HijriCalendarState copyWith({
    int? hijriYear,
    int? hijriMonth,
    List<CalendarDayEntry>? days,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DateTime? selectedDate,
  }) {
    return HijriCalendarState(
      hijriYear: hijriYear ?? this.hijriYear,
      hijriMonth: hijriMonth ?? this.hijriMonth,
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class HijriCalendarNotifier extends StateNotifier<HijriCalendarState> {
  final Ref _ref;
  int? _todayHijriYear;
  int? _todayHijriMonth;

  HijriCalendarNotifier(this._ref)
      : super(
          HijriCalendarState(
            hijriYear: 1448,
            hijriMonth: 1,
            isLoading: true,
            selectedDate: DateTime.now(),
          ),
        ) {
    _init();
  }

  Future<void> _init() async {
    final settings = await _ref.read(settingsProvider.notifier).ensureLoaded();
    await _jumpToCurrentHijriMonth(adjustment: settings.hijriAdjustment);

    _ref.listen<int>(
      settingsProvider.select((s) => s.hijriAdjustment),
      (prev, next) {
        if (prev != null && prev != next) {
          _todayHijriYear = null;
          _todayHijriMonth = null;
          loadHijriMonth(
            state.hijriYear,
            state.hijriMonth,
            adjustment: next,
          );
        }
      },
    );
  }

  Future<({int year, int month})> _resolveTodayHijriYearMonth(
    int adjustment,
  ) async {
    final prayerData = _ref.read(prayerTimesProvider).data;
    if (prayerData != null && prayerData.hijriAdjustment == adjustment) {
      final y = int.tryParse(prayerData.hijriYear);
      if (y != null && y > 1300) {
        return (year: y, month: prayerData.hijriMonthNumber.clamp(1, 12));
      }
    }
    try {
      final resolved = await _ref
          .read(islamicFeaturesServiceProvider)
          .resolveTodayHijriDate(adjustment: adjustment);
      return (year: resolved.year, month: resolved.month);
    } catch (_) {
      // Fallback safely to prayerData if network resolution fails while offline
      if (prayerData != null) {
        final y = int.tryParse(prayerData.hijriYear);
        if (y != null && y > 1300) {
          return (year: y, month: prayerData.hijriMonthNumber.clamp(1, 12));
        }
      }
      return (year: 1448, month: 1);
    }
  }

  Future<void> _jumpToCurrentHijriMonth({required int adjustment}) async {
    final todayHm = await _resolveTodayHijriYearMonth(adjustment);
    if (!mounted) return;
    _todayHijriYear = todayHm.year;
    _todayHijriMonth = todayHm.month;
    await loadHijriMonth(
      todayHm.year,
      todayHm.month,
      adjustment: adjustment,
    );
  }

  Future<void> loadHijriMonth(
    int hijriYear,
    int hijriMonth, {
    int? adjustment,
    bool forceRefresh = false,
  }) async {
    final adj = adjustment ?? _ref.read(settingsProvider).hijriAdjustment;
    state = state.copyWith(
      hijriYear: hijriYear,
      hijriMonth: hijriMonth,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _ref
          .read(islamicFeaturesServiceProvider)
          .fetchHijriMonthCalendar(
            hijriYear: hijriYear,
            hijriMonth: hijriMonth,
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
    var y = state.hijriYear;
    var m = state.hijriMonth - 1;
    if (m < 1) {
      m = 12;
      y -= 1;
    }
    await loadHijriMonth(y, m);
  }

  Future<void> nextMonth() async {
    var y = state.hijriYear;
    var m = state.hijriMonth + 1;
    if (m > 12) {
      m = 1;
      y += 1;
    }
    await loadHijriMonth(y, m);
  }

  Future<void> goToToday() async {
    final now = DateTime.now();
    state = state.copyWith(selectedDate: now);
    final adj = _ref.read(settingsProvider).hijriAdjustment;
    if (_todayHijriYear != null && _todayHijriMonth != null) {
      await loadHijriMonth(_todayHijriYear!, _todayHijriMonth!, adjustment: adj);
    } else {
      await _jumpToCurrentHijriMonth(adjustment: adj);
    }
  }

  void selectDay(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }
}

final hijriCalendarProvider =
    StateNotifierProvider<HijriCalendarNotifier, HijriCalendarState>(
  (ref) => HijriCalendarNotifier(ref),
);
