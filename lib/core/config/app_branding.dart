import 'package:flutter/material.dart';

/// Central branding tokens for Al-Quran.
///
/// Edit the values below to customize the app's in-app name, version label,
/// master logo asset, and primary emerald/gold brand palette in one place.
/// See `BRANDING_GUIDE.md` (Malayalam) for full step-by-step instructions.
class AppBranding {
  const AppBranding._();

  /// Primary app name used in MaterialApp title and English UI labels.
  static const String appName = 'Al-Quran';

  /// Short tagline displayed inside the compact drawer brand card.
  static const String appTagline = 'Read, Listen & Export';

  /// Display version string (keep in sync with pubspec.yaml version).
  static const String appVersion = '4.0.0';

  /// Master 1024x1024 logo asset registered in pubspec.yaml.
  static const String logoAsset = 'assets/branding/app_logo.png';

  /// Optional Android APK download URL shown in the Web app.
  /// Set via Vercel Environment Variable `ANDROID_APK_URL`
  /// (e.g. https://github.com/<user>/<repo>/releases/latest/download/Al-Quran.apk)
  /// or paste your direct link as defaultValue below.
  static const String androidApkUrl = String.fromEnvironment(
    'ANDROID_APK_URL',
    defaultValue: '',
  );

  /// Primary brand emerald palette.
  static const Color primaryEmerald = Color(0xFF047857);
  static const Color darkEmerald = Color(0xFF064E3B);
  static const Color headerEmerald = Color(0xFF065F46);
  static const Color accentGold = Color(0xFFD97706);
}
