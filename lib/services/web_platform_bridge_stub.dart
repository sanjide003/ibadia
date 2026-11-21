import 'package:flutter/foundation.dart';

/// No-op platform bridge for native Android/IO builds so Android APK
/// compilation stays completely independent of browser APIs.
class WebPlatformBridge {
  WebPlatformBridge._();

  static final WebPlatformBridge instance = WebPlatformBridge._();

  final ValueNotifier<bool> canInstallNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isStandaloneNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  bool get isIosWeb => false;

  String get currentWebUrl => '';

  Future<bool> promptPwaInstall() async => false;

  bool openExternalUrl(String url) => false;
}
