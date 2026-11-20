import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final String appLanguage; // 'en' (default) | 'ml' | 'ar'
  final String readingMode; // 'mushaf' | 'verse'
  final String themeMode; // 'light' | 'sepia' | 'dark'
  final double arabicFontSize;
  final double translationFontSize;
  final bool showTranslation;
  final List<String> selectedTranslations; // any subset of ['en', 'ml', 'ar']
  final double autoScrollSpeed; // 0.5x to 4.0x
  /// Normalized relative position (0.0 .. 1.0) inside safe viewport
  final double? fabRelX;
  final double? fabRelY;

  const AppSettings({
    this.appLanguage = 'en',
    this.readingMode = 'mushaf',
    this.themeMode = 'sepia',
    this.arabicFontSize = 27.0,
    this.translationFontSize = 15.0,
    this.showTranslation = false,
    this.selectedTranslations = const ['en'],
    this.autoScrollSpeed = 1.0,
    this.fabRelX,
    this.fabRelY,
  });

  AppSettings copyWith({
    String? appLanguage,
    String? readingMode,
    String? themeMode,
    double? arabicFontSize,
    double? translationFontSize,
    bool? showTranslation,
    List<String>? selectedTranslations,
    double? autoScrollSpeed,
    double? fabRelX,
    double? fabRelY,
    bool clearFabPos = false,
  }) {
    return AppSettings(
      appLanguage: appLanguage ?? this.appLanguage,
      readingMode: readingMode ?? this.readingMode,
      themeMode: themeMode ?? this.themeMode,
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      translationFontSize: translationFontSize ?? this.translationFontSize,
      showTranslation: showTranslation ?? this.showTranslation,
      selectedTranslations: selectedTranslations ?? this.selectedTranslations,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      fabRelX: clearFabPos ? null : (fabRelX ?? this.fabRelX),
      fabRelY: clearFabPos ? null : (fabRelY ?? this.fabRelY),
    );
  }
}

class LastReadPosition {
  final int surahNumber;
  final String surahName;
  final String surahArabicName;
  final int ayahNumber;

  const LastReadPosition({
    required this.surahNumber,
    required this.surahName,
    this.surahArabicName = '',
    required this.ayahNumber,
  });

  factory LastReadPosition.fromJson(Map<String, dynamic> json) =>
      LastReadPosition(
        surahNumber: json['surahNumber'] as int,
        surahName: (json['surahName'] ?? '') as String,
        surahArabicName: (json['surahArabicName'] ?? '') as String,
        ayahNumber: json['ayahNumber'] as int,
      );

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'surahName': surahName,
        'surahArabicName': surahArabicName,
        'ayahNumber': ayahNumber,
      };
}

class StorageService {
  static const _bookmarksKey = 'user_bookmarks_v3';
  static const _lastReadKey = 'user_last_read_v3';
  static const _appLangKey = 'pref_app_lang_v3';
  static const _readModeKey = 'pref_read_mode_v3';
  static const _themeKey = 'pref_theme_mode_v3';
  static const _arSizeKey = 'pref_arabic_size_v3';
  static const _trSizeKey = 'pref_trans_size_v3';
  static const _showTransKey = 'pref_show_trans_v3';
  static const _selTransKey = 'pref_selected_trans_v3';
  static const _scrollSpeedKey = 'pref_scroll_speed_v3';
  static const _fabRelXKey = 'pref_fab_rel_x_v4';
  static const _fabRelYKey = 'pref_fab_rel_y_v4';

  Future<List<String>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_bookmarksKey) ?? <String>[];
  }

  Future<void> saveBookmarks(List<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_bookmarksKey, keys);
  }

  Future<LastReadPosition?> loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastReadKey);
    if (raw == null) return null;
    return LastReadPosition.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveLastRead(LastReadPosition pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReadKey, jsonEncode(pos.toJson()));
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTrans = prefs.getStringList(_selTransKey);
    return AppSettings(
      appLanguage: prefs.getString(_appLangKey) ?? 'en',
      readingMode: prefs.getString(_readModeKey) ?? 'mushaf',
      themeMode: prefs.getString(_themeKey) ?? 'sepia',
      arabicFontSize: prefs.getDouble(_arSizeKey) ?? 27.0,
      translationFontSize: prefs.getDouble(_trSizeKey) ?? 15.0,
      showTranslation: prefs.getBool(_showTransKey) ?? false,
      selectedTranslations:
          (savedTrans != null && savedTrans.isNotEmpty) ? savedTrans : ['en'],
      autoScrollSpeed: prefs.getDouble(_scrollSpeedKey) ?? 1.0,
      fabRelX: prefs.getDouble(_fabRelXKey),
      fabRelY: prefs.getDouble(_fabRelYKey),
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appLangKey, settings.appLanguage);
    await prefs.setString(_readModeKey, settings.readingMode);
    await prefs.setString(_themeKey, settings.themeMode);
    await prefs.setDouble(_arSizeKey, settings.arabicFontSize);
    await prefs.setDouble(_trSizeKey, settings.translationFontSize);
    await prefs.setBool(_showTransKey, settings.showTranslation);
    await prefs.setStringList(_selTransKey, settings.selectedTranslations);
    await prefs.setDouble(_scrollSpeedKey, settings.autoScrollSpeed);
    if (settings.fabRelX != null && settings.fabRelY != null) {
      await prefs.setDouble(_fabRelXKey, settings.fabRelX!);
      await prefs.setDouble(_fabRelYKey, settings.fabRelY!);
    } else {
      await prefs.remove(_fabRelXKey);
      await prefs.remove(_fabRelYKey);
    }
  }
}
