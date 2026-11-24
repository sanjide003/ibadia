import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/config/app_branding.dart';
import 'providers/quran_providers.dart';
import 'screens/home_screen.dart';
import 'services/hive_db.dart';
import 'widgets/tv_mode_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDb.instance.ensureInitialized();
  runApp(const ProviderScope(child: IbadiaApp()));
}

class IbadiaApp extends ConsumerWidget {
  const IbadiaApp({super.key});

  ThemeData _buildLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppBranding.primaryEmerald,
      brightness: Brightness.light,
      primary: AppBranding.primaryEmerald,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF3F6F4),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppBranding.headerEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  ThemeData _buildSepiaTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppBranding.headerEmerald,
      brightness: Brightness.light,
      primary: AppBranding.headerEmerald,
      surface: const Color(0xFFFBF6E9),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4ECDA),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppBranding.headerEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF10B981),
      brightness: Brightness.dark,
      primary: const Color(0xFF10B981),
      surface: const Color(0xFF141A17),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0A0D0C),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppBranding.darkEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (themeModeKey, appLang, tvModeEnabled, tvFontScale) = ref.watch(
      settingsProvider.select(
        (s) => (s.themeMode, s.appLanguage, s.tvModeEnabled, s.tvFontScale),
      ),
    );
    ref.listen<bool>(
      settingsProvider.select((s) => s.tvModeEnabled),
      (prev, next) {
        if (prev != next) {
          applyTvModePlatformState(next);
        }
      },
    );
    if (tvModeEnabled) {
      // Ensure persisted TV mode applies on initial startup too
      WidgetsBinding.instance.addPostFrameCallback((_) {
        applyTvModePlatformState(true);
      });
    }

    final ThemeData activeLightTheme =
        themeModeKey == 'sepia' ? _buildSepiaTheme() : _buildLightTheme();
    final ThemeMode materialThemeMode =
        themeModeKey == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final Locale activeLocale;
    switch (appLang) {
      case 'ml':
        activeLocale = const Locale('ml');
        break;
      case 'ar':
        activeLocale = const Locale('ar');
        break;
      default:
        activeLocale = const Locale('en');
        break;
    }

    return MaterialApp(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: activeLightTheme,
      darkTheme: _buildDarkTheme(),
      themeMode: materialThemeMode,
      locale: activeLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('ml'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (ctx, child) {
        final mq = MediaQuery.of(ctx);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(tvFontScale.clamp(0.85, 2.2)),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomeScreen(),
    );
  }
}
