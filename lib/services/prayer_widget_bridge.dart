import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class PrayerWidgetBridge {
  const PrayerWidgetBridge._();

  static const PrayerWidgetBridge instance = PrayerWidgetBridge._();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> syncWidget({
    required String location,
    required String hijriDate,
    required String nextLabel,
    required String prayerName,
    required String adhanTime,
    required String iqamahTime,
  }) async {
    if (!isSupported) return;
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
        name: 'PrayerHomeWidgetProvider',
        androidName: 'PrayerHomeWidgetProvider',
        qualifiedAndroidName: 'com.ibadia.ibadia.PrayerHomeWidgetProvider',
      );
    } catch (_) {
      // Widget update is best-effort and must not crash prayer slot sync.
    }
  }
}
