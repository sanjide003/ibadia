import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

@JS('__ibadiaPwa')
external _IbadiaPwaJs? get _ibadiaPwa;

@JS()
@staticInterop
class _IbadiaPwaJs {}

extension _IbadiaPwaJsExt on _IbadiaPwaJs {
  external bool isIOS();
  external bool isStandalone();
  external bool canInstall();
  external bool isOnline();
  external String currentUrl();
  external JSPromise<JSString> promptInstall();
  external bool openExternal(String url);
  external JSPromise<JSBoolean> applyWebUpdate();
}

class WebPlatformBridge {
  WebPlatformBridge._() {
    _syncState();
    web.window.addEventListener(
      'ibadia-pwa-changed',
      ((web.Event _) => _syncState()).toJS,
    );
    web.window.addEventListener(
      'online',
      ((web.Event _) => _syncState()).toJS,
    );
    web.window.addEventListener(
      'offline',
      ((web.Event _) => _syncState()).toJS,
    );
  }

  static final WebPlatformBridge instance = WebPlatformBridge._();

  final ValueNotifier<bool> canInstallNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isStandaloneNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  void _syncState() {
    final pwa = _ibadiaPwa;
    if (pwa == null) {
      isOnlineNotifier.value = web.window.navigator.onLine;
      return;
    }
    try {
      canInstallNotifier.value = pwa.canInstall();
      isStandaloneNotifier.value = pwa.isStandalone();
      isOnlineNotifier.value = pwa.isOnline();
    } catch (_) {}
  }

  bool get isIosWeb {
    try {
      return _ibadiaPwa?.isIOS() ?? false;
    } catch (_) {
      return false;
    }
  }

  String get currentWebUrl {
    try {
      final raw = _ibadiaPwa?.currentUrl() ?? web.window.location.origin;
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
        return uri.origin;
      }
      return web.window.location.origin;
    } catch (_) {
      return '';
    }
  }

  Future<void> promptPwaInstall() async {
    final pwa = _ibadiaPwa;
    if (pwa == null) return;
    try {
      await pwa.promptInstall().toDart;
    } catch (_) {}
    _syncState();
  }

  bool openExternalUrl(String url) {
    final pwa = _ibadiaPwa;
    if (pwa != null) {
      try {
        return pwa.openExternal(url);
      } catch (_) {}
    }
    try {
      web.window.open(url, '_blank');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> applyWebUpdate() async {
    final pwa = _ibadiaPwa;
    if (pwa != null) {
      try {
        await pwa.applyWebUpdate().toDart;
        return;
      } catch (_) {}
    }
    web.window.location.reload();
  }
}
