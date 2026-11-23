import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_branding.dart';
import 'core/l10n/app_strings.dart';
import 'providers/islamic_features_providers.dart';
import 'providers/quran_providers.dart';
import 'screens/home_screen.dart';
import 'services/hive_db.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveDb.instance.ensureInitialized();
  runApp(const ProviderScope(child: QuranMalayalamApp()));
}

class QuranMalayalamApp extends ConsumerWidget {
  const QuranMalayalamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final t = ref.watch(stringsProvider);
    final activeAlarm = ref.watch(
      prayerAlarmProvider.select((s) => s.activeRinging),
    );

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
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (activeAlarm != null)
              _RingingAlarmOverlay(
                alarm: activeAlarm,
                strings: t,
                onDismissToday: () => ref
                    .read(prayerAlarmProvider.notifier)
                    .dismissTodayAlarm(activeAlarm.prayerKey),
              ),
          ],
        );
      },
    );
  }
}

/// Full-screen Dismiss-Only overlay (No Snooze!) displayed when a prayer alarm triggers
/// both on Android lock-screen wakeups and across any open screen.
class _RingingAlarmOverlay extends StatefulWidget {
  final RingingAlarmInfo alarm;
  final AppStrings strings;
  final VoidCallback onDismissToday;

  const _RingingAlarmOverlay({
    required this.alarm,
    required this.strings,
    required this.onDismissToday,
  });

  @override
  State<_RingingAlarmOverlay> createState() => _RingingAlarmOverlayState();
}

class _RingingAlarmOverlayState extends State<_RingingAlarmOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return Directionality(
      textDirection: t.textDirection,
      child: Material(
        color: AppBranding.darkEmerald.withValues(alpha: 0.96),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final scale = 0.94 + (_pulseCtrl.value * 0.12);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          color: AppBranding.accentGold.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppBranding.accentGold,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          size: 52,
                          color: AppBranding.accentGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      widget.alarm.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.alarm.timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        widget.alarm.timeLabel,
                        style: const TextStyle(
                          color: AppBranding.accentGold,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      t.dismissOnlyNote,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppBranding.accentGold,
                          foregroundColor: const Color(0xFF141A17),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: widget.onDismissToday,
                        icon: const Icon(Icons.alarm_off_rounded, size: 22),
                        label: Text(
                          t.dismissTodayAlarm,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
