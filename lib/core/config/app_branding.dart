import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

class AppBranding {
  static const String appName = 'Ibadia';
  static const String appNameEn = 'Ibadia';
  static const String appNameMl = 'ഇബാദിയ';
  static const String appNameAr = 'عبادية';
  static const String appTagline = 'Quran, Prayer & Daily Adhkar';
  static const String appVersion = '5.0.0';

  static const Color primaryEmerald = Color(0xFF047857);
  static const Color darkEmerald = Color(0xFF064E3B);
  static const Color headerEmerald = Color(0xFF065F46);
  static const Color accentGold = Color(0xFFD97706);

  static const int appBuildNumber = int.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: 5,
  );

  static const String logoAsset = 'assets/branding/app_logo.png';
  static const String logoForegroundAsset = 'assets/branding/app_logo_foreground.png';

  static const String webAppUrl = String.fromEnvironment(
    'WEB_APP_URL',
    defaultValue: 'https://ibadia.vercel.app',
  );

  static const String androidApkUrl = String.fromEnvironment(
    'ANDROID_APK_URL',
    defaultValue: 'https://github.com/sanjide003/ibadia/releases/download/latest/Ibadia.apk',
  );

  static const String updateManifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue: 'https://github.com/sanjide003/ibadia/releases/download/latest/version.json',
  );

  static String get resolvedAndroidUpdateManifestUrl {
    final explicit = updateManifestUrl.trim();
    if (explicit.isNotEmpty) return explicit;
    final apk = androidApkUrl.trim();
    if (apk.isEmpty) return '';
    final idx = apk.lastIndexOf('/');
    if (idx <= 0) return '';
    return '${apk.substring(0, idx)}/version.json';
  }

  static bool get isAndroidNative => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String localizedName(String appLang) {
    switch (appLang) {
      case 'ml':
        return appNameMl;
      case 'ar':
        return appNameAr;
      default:
        return appNameEn;
    }
  }
}
