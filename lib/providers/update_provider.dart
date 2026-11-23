import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_branding.dart';
import '../services/android_updater_bridge.dart';
import '../services/web_platform_bridge.dart';

class AppUpdateState {
  final String currentVersion;
  final int currentBuildNumber;
  final bool isChecking;
  final bool isDownloading;
  final bool isInstalling;
  final double? downloadProgress;
  final bool updateAvailable;
  final String? latestVersion;
  final int? latestBuildNumber;
  final String? downloadUrl;
  final String? downloadedApkPath;
  final bool needsInstallPermission;
  final String? errorMessage;
  final UpdateCheckOutcome? lastManualOutcome;

  const AppUpdateState({
    this.currentVersion = AppBranding.appVersion,
    this.currentBuildNumber = AppBranding.appBuildNumber,
    this.isChecking = false,
    this.isDownloading = false,
    this.isInstalling = false,
    this.downloadProgress,
    this.updateAvailable = false,
    this.latestVersion,
    this.latestBuildNumber,
    this.downloadUrl,
    this.downloadedApkPath,
    this.needsInstallPermission = false,
    this.errorMessage,
    this.lastManualOutcome,
  });

  bool get isBusy => isChecking || isDownloading || isInstalling;

  AppUpdateState copyWith({
    String? currentVersion,
    int? currentBuildNumber,
    bool? isChecking,
    bool? isDownloading,
    bool? isInstalling,
    double? downloadProgress,
    bool clearDownloadProgress = false,
    bool? updateAvailable,
    String? latestVersion,
    int? latestBuildNumber,
    String? downloadUrl,
    String? downloadedApkPath,
    bool clearDownloadedApkPath = false,
    bool? needsInstallPermission,
    String? errorMessage,
    bool clearError = false,
    UpdateCheckOutcome? lastManualOutcome,
    bool clearLastManualOutcome = false,
  }) {
    return AppUpdateState(
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuildNumber: currentBuildNumber ?? this.currentBuildNumber,
      isChecking: isChecking ?? this.isChecking,
      isDownloading: isDownloading ?? this.isDownloading,
      isInstalling: isInstalling ?? this.isInstalling,
      downloadProgress: clearDownloadProgress
          ? null
          : (downloadProgress ?? this.downloadProgress),
      updateAvailable: updateAvailable ?? this.updateAvailable,
      latestVersion: latestVersion ?? this.latestVersion,
      latestBuildNumber: latestBuildNumber ?? this.latestBuildNumber,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      downloadedApkPath: clearDownloadedApkPath
          ? null
          : (downloadedApkPath ?? this.downloadedApkPath),
      needsInstallPermission:
          needsInstallPermission ?? this.needsInstallPermission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastManualOutcome: clearLastManualOutcome
          ? null
          : (lastManualOutcome ?? this.lastManualOutcome),
    );
  }
}

enum UpdateCheckOutcome {
  updateAvailable,
  upToDate,
  unavailable,
}

class AppUpdateNotifier extends StateNotifier<AppUpdateState> {
  AppUpdateNotifier() : super(const AppUpdateState()) {
    _hydrateLocalVersion();
  }

  Future<void> _hydrateLocalVersion() async {
    if (!kIsWeb && AndroidUpdaterBridge.instance.isSupported) {
      final info = await AndroidUpdaterBridge.instance.getAppVersionInfo();
      if (info != null) {
        final effectiveBuild = info.versionCode > state.currentBuildNumber
            ? info.versionCode
            : state.currentBuildNumber;
        state = state.copyWith(
          currentVersion:
              info.versionName.isNotEmpty ? info.versionName : null,
          currentBuildNumber: effectiveBuild,
        );
      }
    }
  }

  /// Checks whether a newer build exists on GitHub Releases (Android) or Vercel (`/app_version.json`).
  /// Because both endpoints always point to the newest rolling release, jumping across
  /// multiple skipped updates lands directly on the latest build in 1 click.
  Future<UpdateCheckOutcome> checkForUpdates({bool silent = true}) async {
    if (state.isChecking || state.isDownloading) {
      return state.updateAvailable
          ? UpdateCheckOutcome.updateAvailable
          : UpdateCheckOutcome.upToDate;
    }

    state = state.copyWith(
      isChecking: true,
      clearError: true,
      clearLastManualOutcome: !silent,
    );

    try {
      await _hydrateLocalVersion();

      final String? manifestUrl = _resolveManifestUrl();
      if (manifestUrl == null || manifestUrl.isEmpty) {
        state = state.copyWith(
          isChecking: false,
          lastManualOutcome: silent ? null : UpdateCheckOutcome.unavailable,
        );
        return UpdateCheckOutcome.unavailable;
      }

      final baseUri = Uri.parse(manifestUrl);
      final bustedUri = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          't': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await http
          .get(bustedUri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        state = state.copyWith(
          isChecking: false,
          errorMessage: silent ? null : 'HTTP ${response.statusCode}',
          lastManualOutcome: silent ? null : UpdateCheckOutcome.unavailable,
        );
        return UpdateCheckOutcome.unavailable;
      }

      final trimmedBody = response.body.trimLeft();
      if (!trimmedBody.startsWith('{')) {
        // Local dev / SPA fallback returning HTML instead of JSON.
        state = state.copyWith(
          isChecking: false,
          lastManualOutcome: silent ? null : UpdateCheckOutcome.unavailable,
        );
        return UpdateCheckOutcome.unavailable;
      }

      final decoded = jsonDecode(trimmedBody);
      if (decoded is! Map<String, dynamic>) {
        state = state.copyWith(
          isChecking: false,
          lastManualOutcome: silent ? null : UpdateCheckOutcome.unavailable,
        );
        return UpdateCheckOutcome.unavailable;
      }

      final remoteVersion =
          (decoded['version'] ?? AppBranding.appVersion).toString();
      final rawBuild = decoded['buildNumber'];
      final int remoteBuild = rawBuild is int
          ? rawBuild
          : int.tryParse(rawBuild?.toString() ?? '') ?? 0;

      final String? remoteApkUrl = decoded['apkUrl']?.toString().trim();
      final resolvedDownloadUrl = (remoteApkUrl != null && remoteApkUrl.isNotEmpty)
          ? remoteApkUrl
          : AppBranding.androidApkUrl;

      if (remoteBuild > state.currentBuildNumber) {
        state = state.copyWith(
          isChecking: false,
          updateAvailable: true,
          latestVersion: remoteVersion,
          latestBuildNumber: remoteBuild,
          downloadUrl: resolvedDownloadUrl,
          lastManualOutcome:
              silent ? null : UpdateCheckOutcome.updateAvailable,
        );
        return UpdateCheckOutcome.updateAvailable;
      }

      state = state.copyWith(
        isChecking: false,
        updateAvailable: false,
        latestVersion: remoteVersion,
        latestBuildNumber: remoteBuild,
        lastManualOutcome: silent ? null : UpdateCheckOutcome.upToDate,
      );
      return UpdateCheckOutcome.upToDate;
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        errorMessage: silent ? null : e.toString(),
        lastManualOutcome: silent ? null : UpdateCheckOutcome.unavailable,
      );
      return UpdateCheckOutcome.unavailable;
    }
  }

  void clearManualOutcome() {
    state = state.copyWith(clearLastManualOutcome: true);
  }

  String? _resolveManifestUrl() {
    if (kIsWeb) {
      final origin = WebPlatformBridge.instance.currentWebUrl;
      if (origin.isEmpty) return null;
      return '$origin/app_version.json';
    }
    final androidManifest = AppBranding.resolvedAndroidUpdateManifestUrl;
    return androidManifest.isNotEmpty ? androidManifest : null;
  }

  /// Executes 1-click update:
  /// - Web/PWA: clears service worker caches and reloads the newest deploy.
  /// - Android APK: downloads `latest/Ibadia.apk` with live progress, then
  ///   launches Android's PackageInstaller (handling unknown-app permission cleanly).
  Future<void> performOneClickUpdate() async {
    if (kIsWeb) {
      state = state.copyWith(isInstalling: true, clearError: true);
      await WebPlatformBridge.instance.applyWebUpdate();
      state = state.copyWith(isInstalling: false);
      return;
    }

    // If APK was already downloaded and user just granted install permission, install right away.
    final cachedPath = state.downloadedApkPath;
    if (cachedPath != null && state.needsInstallPermission) {
      await _installApkFile(cachedPath);
      return;
    }

    final apkUrl = (state.downloadUrl != null && state.downloadUrl!.isNotEmpty)
        ? state.downloadUrl!
        : AppBranding.androidApkUrl;
    if (apkUrl.isEmpty) {
      state = state.copyWith(errorMessage: 'missing_apk_url');
      return;
    }

    state = state.copyWith(
      isDownloading: true,
      downloadProgress: 0.0,
      needsInstallPermission: false,
      clearError: true,
    );

    final filePath = await AndroidUpdaterBridge.instance.downloadApk(
      url: apkUrl,
      onProgress: (p) {
        if (mounted) {
          state = state.copyWith(downloadProgress: p);
        }
      },
    );

    if (filePath == null) {
      state = state.copyWith(
        isDownloading: false,
        clearDownloadProgress: true,
        errorMessage: 'download_failed',
      );
      return;
    }

    state = state.copyWith(
      isDownloading: false,
      downloadedApkPath: filePath,
    );

    await _installApkFile(filePath);
  }

  Future<void> _installApkFile(String filePath) async {
    state = state.copyWith(isInstalling: true, clearError: true);
    final res = await AndroidUpdaterBridge.instance.installApk(filePath);
    if (!mounted) return;

    switch (res) {
      case ApkInstallResult.started:
        state = state.copyWith(
          isInstalling: false,
          needsInstallPermission: false,
        );
      case ApkInstallResult.permissionRequired:
        state = state.copyWith(
          isInstalling: false,
          needsInstallPermission: true,
        );
      case ApkInstallResult.failed:
        state = state.copyWith(
          isInstalling: false,
          errorMessage: 'install_failed',
        );
    }
  }

  Future<void> openApkInBrowserFallback() async {
    final apkUrl = (state.downloadUrl != null && state.downloadUrl!.isNotEmpty)
        ? state.downloadUrl!
        : AppBranding.androidApkUrl;
    if (apkUrl.isEmpty) return;

    if (kIsWeb) {
      WebPlatformBridge.instance.openExternalUrl(apkUrl);
    } else {
      await AndroidUpdaterBridge.instance.openExternalUrl(apkUrl);
    }
  }
}

final updateProvider =
    StateNotifierProvider<AppUpdateNotifier, AppUpdateState>((ref) {
  return AppUpdateNotifier();
});
