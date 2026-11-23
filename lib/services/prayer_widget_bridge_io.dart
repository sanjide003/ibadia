import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Native Android bridge using `home_widget` to push next prayer timing & Hijri
/// date into `PrayerHomeWidgetProvider`.
class PrayerWidgetBridge {
  PrayerWidgetBridge._();

  static final PrayerWidgetBridge instance = PrayerWidgetBridge._();

  static const String _androidProviderName = 'PrayerHomeWidgetProvider';
  static const String _qualifiedAndroidName =
      'com.quranapp.malayalam.quran_malayalam_app.PrayerHomeWidgetProvider';

  bool get isSupported => Platform.isAndroid;

  Future<void> syncWidget({
    required String location,
    required String hijriDate,
    required String nextLabel,
    required String prayerName,
    required String adhanTime,
    required String iqamahTime,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      await Future.wait([
        HomeWidget.saveWidgetData<String>('widget_location', location),
        HomeWidget.saveWidgetData<String>('widget_hijri_date', hijriDate),
        HomeWidget.saveWidgetData<String>('widget_next_label', nextLabel),
        HomeWidget.saveWidgetData<String>('widget_prayer_name', prayerName),
        HomeWidget.saveWidgetData<String>('widget_adhan_time', adhanTime),
        HomeWidget.saveWidgetData<String>('widget_iqamah_time', iqamahTime),
      ]);
      await HomeWidget.updateWidget(
        name: _androidProviderName,
        androidName: _androidProviderName,
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (_) {}
  }
}
