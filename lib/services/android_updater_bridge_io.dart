import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class AndroidVersionInfo {
  final String versionName;
  final int versionCode;

  const AndroidVersionInfo({
    required this.versionName,
    required this.versionCode,
  });
}

enum ApkInstallResult {
  started,
  permissionRequired,
  failed,
}

/// Native Android self-updater using MethodChannel `com.quranapp.malayalam/app_updater`
/// implemented in `MainActivity.kt` + `FileProvider`.
class AndroidUpdaterBridge {
  const AndroidUpdaterBridge._();

  static const AndroidUpdaterBridge instance = AndroidUpdaterBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.quranapp.malayalam/app_updater');

  bool get isSupported => Platform.isAndroid;

  Future<AndroidVersionInfo?> getAppVersionInfo() async {
    if (!Platform.isAndroid) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'getAppVersionInfo',
      );
      if (raw == null) return null;
      final versionName = (raw['versionName'] ?? '').toString();
      final rawCode = raw['versionCode'];
      final int versionCode = rawCode is int
          ? rawCode
          : int.tryParse(rawCode?.toString() ?? '') ?? 0;
      if (versionCode <= 0) return null;
      return AndroidVersionInfo(
        versionName: versionName,
        versionCode: versionCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> downloadApk({
    required String url,
    required void Function(double? progress) onProgress,
  }) async {
    if (!Platform.isAndroid) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final dirPath = await _channel.invokeMethod<String>('getUpdateCacheDir');
    if (dirPath == null || dirPath.isEmpty) return null;

    final partFile = File('$dirPath/Al-Quran-latest.apk.part');
    final finalFile = File('$dirPath/Al-Quran-latest.apk');
    if (await partFile.exists()) {
      await partFile.delete();
    }

    final client = http.Client();
    IOSink? sink;
    try {
      final request = http.Request('GET', uri);
      request.headers['Cache-Control'] = 'no-cache';
      final response =
          await client.send(request).timeout(const Duration(seconds: 30));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final totalBytes = response.contentLength ?? -1;
      int received = 0;
      sink = partFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          onProgress((received / totalBytes).clamp(0.0, 1.0));
        } else {
          onProgress(null);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await partFile.rename(finalFile.path);
      onProgress(1.0);
      return finalFile.path;
    } catch (_) {
      try {
        await sink?.close();
      } catch (_) {}
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
      return null;
    } finally {
      client.close();
    }
  }

  Future<ApkInstallResult> installApk(String filePath) async {
    if (!Platform.isAndroid) return ApkInstallResult.failed;
    try {
      final status = await _channel.invokeMethod<String>(
        'installApk',
        {'filePath': filePath},
      );
      if (status == 'started') return ApkInstallResult.started;
      if (status == 'permission_required') {
        return ApkInstallResult.permissionRequired;
      }
      return ApkInstallResult.failed;
    } catch (_) {
      return ApkInstallResult.failed;
    }
  }

  Future<bool> openExternalUrl(String url) async {
    if (!Platform.isAndroid || url.trim().isEmpty) return false;
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openExternalUrl',
        {'url': url},
      );
      return opened ?? false;
    } catch (_) {
      return false;
    }
  }
}
