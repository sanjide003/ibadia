import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../services/web_platform_bridge.dart';

const String _hasDownloadedApkKey = 'has_downloaded_apk_v1';

Future<void> triggerPwaInstall(BuildContext context, AppStrings t) async {
  final bridge = WebPlatformBridge.instance;
  if (bridge.canInstallNotifier.value) {
    await bridge.promptPwaInstall();
    return;
  }
  if (bridge.isIosWeb && context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: t.textDirection,
        child: AlertDialog(
          title: Text(t.installOnIosTitle),
          content: Text(t.installOnIosSteps),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.closeLabel),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> triggerShareApp(BuildContext context, AppStrings t) async {
  final bridge = WebPlatformBridge.instance;
  final String runtimeOrigin = kIsWeb ? bridge.currentWebUrl : '';
  final String webUrl = runtimeOrigin.isNotEmpty
      ? runtimeOrigin
      : AppBranding.webAppUrl;
  const String apkUrl = AppBranding.androidApkUrl;

  final buffer = StringBuffer()
    ..writeln('${AppBranding.appName} — ${AppBranding.appTagline}');
  if (webUrl.isNotEmpty) {
    buffer.writeln('Web App: $webUrl');
  }
  if (apkUrl.isNotEmpty) {
    buffer.writeln('Android APK: $apkUrl');
  }
  final shareText = buffer.toString().trim();

  try {
    await Share.share(shareText, subject: AppBranding.appName);
    return;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: shareText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.shareAppCopied),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

Future<bool> triggerAndroidApkDownload(
  BuildContext context,
  AppStrings t,
) async {
  const apkUrl = AppBranding.androidApkUrl;
  if (apkUrl.isNotEmpty) {
    final launched = WebPlatformBridge.instance.openExternalUrl(apkUrl);
    if (launched) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasDownloadedApkKey, true);
      return true;
    }
  }
  if (context.mounted) {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: t.textDirection,
        child: AlertDialog(
          title: Text(t.apkSetupTitle),
          content: Text(t.apkSetupDesc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.closeLabel),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                triggerShareApp(context, t);
              },
              icon: const Icon(Icons.share_rounded, size: 17),
              label: Text(t.shareApp),
            ),
          ],
        ),
      ),
    );
  }
  return false;
}

/// Non-intrusive offline mode banner displayed on Web when navigator.onLine is false.
class OfflineStatusBanner extends StatelessWidget {
  final AppStrings strings;

  const OfflineStatusBanner({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: WebPlatformBridge.instance.isOnlineNotifier,
      builder: (_, isOnline, __) {
        if (isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: const Color(0xFFD97706),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  strings.offlineBanner,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom-anchored actions inside CompactSettingsDrawer:
/// - Install App (only on Web when eligible & not yet installed as PWA)
/// - Download Android APK (only on Web before APK download / PWA install)
/// - Share App (automatically shown inside Android APK, installed PWA, or after APK download)
class DrawerBottomAppActions extends StatefulWidget {
  final AppStrings strings;

  const DrawerBottomAppActions({super.key, required this.strings});

  @override
  State<DrawerBottomAppActions> createState() => _DrawerBottomAppActionsState();
}

class _DrawerBottomAppActionsState extends State<DrawerBottomAppActions> {
  bool _hasDownloadedApk = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadFlag();
  }

  Future<void> _loadDownloadFlag() async {
    if (!kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getBool(_hasDownloadedApkKey) ?? false;
    if (downloaded && mounted) {
      setState(() => _hasDownloadedApk = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final bridge = WebPlatformBridge.instance;
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<bool>(
      valueListenable: bridge.isStandaloneNotifier,
      builder: (_, isStandalone, __) {
        final bool showShareInstead =
            !kIsWeb || isStandalone || _hasDownloadedApk;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kIsWeb && !isStandalone)
              ValueListenableBuilder<bool>(
                valueListenable: bridge.canInstallNotifier,
                builder: (_, canInstall, __) {
                  if (!canInstall && !bridge.isIosWeb) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.icon(
                      onPressed: () => triggerPwaInstall(context, t),
                      icon: const Icon(Icons.install_mobile_rounded, size: 18),
                      label: Text(
                        t.installApp,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (showShareInstead)
              OutlinedButton.icon(
                onPressed: () => triggerShareApp(context, t),
                icon: Icon(Icons.share_rounded, size: 18, color: cs.primary),
                label: Text(
                  t.shareApp,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  final started = await triggerAndroidApkDownload(context, t);
                  if (started && mounted) {
                    setState(() => _hasDownloadedApk = true);
                  }
                },
                icon: Icon(Icons.android_rounded, size: 19, color: cs.primary),
                label: Text(
                  t.downloadAndroidApk,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
