import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cross-platform Hive CE offline storage manager (Android local disk + Web IndexedDB).
/// Automatically migrates legacy SharedPreferences keys on first initialization so
/// bookmarks, settings, resume state, and cached Quran chapters remain intact.
class HiveDb {
  HiveDb._();

  static final HiveDb instance = HiveDb._();

  static const String appPrefsBoxName = 'app_prefs_box_v1';
  static const String quranCacheBoxName = 'quran_cache_box_v1';
  static const String islamicCacheBoxName = 'islamic_cache_box_v1';
  static const String adhkarProgressBoxName = 'adhkar_progress_box_v1';
  static const String tasbihBoxName = 'tasbih_box_v1';

  static const String _migratedFlagKey = '__sp_migrated_v1';

  Future<void>? _initFuture;

  late final Box<dynamic> appPrefsBox;
  late final Box<dynamic> quranCacheBox;
  late final Box<dynamic> islamicCacheBox;
  late final Box<dynamic> adhkarProgressBox;
  late final Box<dynamic> tasbihBox;

  Future<void> ensureInitialized() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    await Hive.initFlutter();

    final boxes = await Future.wait([
      Hive.openBox<dynamic>(appPrefsBoxName),
      Hive.openBox<dynamic>(quranCacheBoxName),
      Hive.openBox<dynamic>(islamicCacheBoxName),
      Hive.openBox<dynamic>(adhkarProgressBoxName),
      Hive.openBox<dynamic>(tasbihBoxName),
    ]);

    appPrefsBox = boxes[0];
    quranCacheBox = boxes[1];
    islamicCacheBox = boxes[2];
    adhkarProgressBox = boxes[3];
    tasbihBox = boxes[4];

    if (appPrefsBox.get(_migratedFlagKey) != true) {
      await _migrateLegacySharedPreferences();
      await appPrefsBox.put(_migratedFlagKey, true);
    }
  }

  Future<void> _migrateLegacySharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        final value = prefs.get(key);
        if (value == null) continue;

        if (key.startsWith('cache_')) {
          if (!quranCacheBox.containsKey(key)) {
            await quranCacheBox.put(key, value);
          }
        } else if (key == 'prayer_daily_cache_v1' ||
            key == 'prayer_alarm_dismissed_v1' ||
            key.startsWith('hijri_month_cal_v2_')) {
          if (!islamicCacheBox.containsKey(key)) {
            await islamicCacheBox.put(key, value);
          }
        } else {
          if (!appPrefsBox.containsKey(key)) {
            await appPrefsBox.put(key, value);
          }
        }
      }
    } catch (_) {
      // Migration best-effort: app starts cleanly even if prefs are empty/unavailable.
    }
  }
}
