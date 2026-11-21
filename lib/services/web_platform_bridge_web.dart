import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

/// Web browser bridge backed by `window.__alQuranPwa` (defined in web/index.html)
/// for PWA install prompts, standalone detection, iOS Safari detection,
/// live online/offline status, and safe external APK download triggers.
class WebPlatformBridge {
  WebPlatformBridge._() {
    _syncState();
    _attachListeners();
  }

  static final WebPlatformBridge instance = WebPlatformBridge._();

  final ValueNotifier<bool> canInstallNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isStandaloneNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  JSObject? get _helper {
    final obj = globalContext['__alQuranPwa'];
    if (obj == null || obj.isUndefinedOrNull) return null;
    return obj as JSObject;
  }

  bool get isIosWeb {
    final helper = _helper;
    if (helper == null) return false;
    try {
      return helper.callMethod<JSBoolean>('isIOS'.toJS).toDart;
    } catch (_) {
      return false;
    }
  }

  void _attachListeners() {
    try {
      final refreshHandler = ((JSAny _) => _syncState()).toJS;
      globalContext.callMethod(
        'addEventListener'.toJS,
        'alquran-pwa-changed'.toJS,
        refreshHandler,
      );
      globalContext.callMethod(
        'addEventListener'.toJS,
        'online'.toJS,
        refreshHandler,
      );
      globalContext.callMethod(
        'addEventListener'.toJS,
        'offline'.toJS,
        refreshHandler,
      );
    } catch (_) {}
  }

  void _syncState() {
    final helper = _helper;
    if (helper == null) return;
    try {
      canInstallNotifier.value =
          helper.callMethod<JSBoolean>('canInstall'.toJS).toDart;
      isStandaloneNotifier.value =
          helper.callMethod<JSBoolean>('isStandalone'.toJS).toDart;
      isOnlineNotifier.value =
          helper.callMethod<JSBoolean>('isOnline'.toJS).toDart;
    } catch (_) {}
  }

  Future<bool> promptPwaInstall() async {
    final helper = _helper;
    if (helper == null) return false;
    try {
      final result =
          await helper.callMethod<JSPromise<JSString>>('promptInstall'.toJS).toDart;
      _syncState();
      return result.toDart == 'accepted';
    } catch (_) {
      _syncState();
      return false;
    }
  }

  bool openExternalUrl(String url) {
    final helper = _helper;
    if (helper == null || url.trim().isEmpty) return false;
    try {
      return helper.callMethod<JSBoolean>('openExternal'.toJS, url.toJS).toDart;
    } catch (_) {
      return false;
    }
  }
}
