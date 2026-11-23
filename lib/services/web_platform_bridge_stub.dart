import 'package:flutter/foundation.dart';

class WebPlatformBridge {
  WebPlatformBridge._();

  static final WebPlatformBridge instance = WebPlatformBridge._();

  final ValueNotifier<bool> canInstallNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isStandaloneNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  bool get isIosWeb => false;

  String get currentWebUrl => '';

  Future<void> promptPwaInstall() async {}

  bool openExternalUrl(String url) => false;

  Future<void> applyWebUpdate() async {}
}
