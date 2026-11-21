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

/// No-op stub on Web builds so `dart:io` never enters Flutter Web bundles.
class AndroidUpdaterBridge {
  const AndroidUpdaterBridge._();

  static const AndroidUpdaterBridge instance = AndroidUpdaterBridge._();

  bool get isSupported => false;

  Future<AndroidVersionInfo?> getAppVersionInfo() async => null;

  Future<String?> downloadApk({
    required String url,
    required void Function(double? progress) onProgress,
  }) async =>
      null;

  Future<ApkInstallResult> installApk(String filePath) async =>
      ApkInstallResult.failed;

  Future<bool> openExternalUrl(String url) async => false;
}
