/// Web / non-Android stub for Prayer Home Screen Widget updates.
class PrayerWidgetBridge {
  PrayerWidgetBridge._();

  static final PrayerWidgetBridge instance = PrayerWidgetBridge._();

  bool get isSupported => false;

  Future<void> syncWidget({
    required String location,
    required String hijriDate,
    required String nextLabel,
    required String prayerName,
    required String adhanTime,
    required String iqamahTime,
  }) async {
    // Web preview does not host Android home-screen app widgets.
  }
}
