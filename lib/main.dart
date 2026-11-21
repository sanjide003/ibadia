import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_branding.dart';
import 'providers/quran_providers.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: QuranMalayalamApp()));
}

class QuranMalayalamApp extends ConsumerWidget {
  const QuranMalayalamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    TextTheme applyFont(TextTheme base) {
      if (settings.appLanguage == 'ml') {
        return GoogleFonts.notoSansMalayalamTextTheme(base);
      }
      if (settings.appLanguage == 'ar') {
        return GoogleFonts.notoSansArabicTextTheme(base);
      }
      return GoogleFonts.plusJakartaSansTextTheme(base);
    }

    ThemeData buildTheme(String mode) {
      if (mode == 'dark') {
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: AppBranding.primaryEmerald,
          scaffoldBackgroundColor: const Color(0xFF0A0D0C),
          textTheme: applyFont(ThemeData.dark().textTheme),
        );
      }
      if (mode == 'sepia') {
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: AppBranding.darkEmerald,
          scaffoldBackgroundColor: const Color(0xFFFBF6E9),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF5ECD7),
            foregroundColor: Color(0xFF1F2421),
          ),
          textTheme: applyFont(ThemeData.light().textTheme),
        );
      }
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: AppBranding.primaryEmerald,
        scaffoldBackgroundColor: Colors.white,
        textTheme: applyFont(ThemeData.light().textTheme),
      );
    }

    return MaterialApp(
      title: AppBranding.appName,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(settings.themeMode),
      home: const HomeScreen(),
    );
  }
}
