import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../services/web_platform_bridge.dart';

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

Future<void> triggerAndroidApkDownload(
  BuildContext context,
  AppStrings t,
) async {
  const apkUrl = AppBranding.androidApkUrl;
  if (apkUrl.isNotEmpty) {
    final launched = WebPlatformBridge.instance.openExternalUrl(apkUrl);
    if (launched) return;
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
          ],
        ),
      ),
    );
  }
}

/// Compact AppBar action icon shown only on Web when browser install is eligible
/// and the app is not yet running in standalone PWA mode.
class PwaInstallAppBarAction extends StatelessWidget {
  final AppStrings strings;

  const PwaInstallAppBarAction({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final bridge = WebPlatformBridge.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: bridge.isStandaloneNotifier,
      builder: (_, isStandalone, __) {
        if (isStandalone) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: bridge.canInstallNotifier,
          builder: (_, canInstall, __) {
            if (!canInstall && !bridge.isIosWeb) {
              return const SizedBox.shrink();
            }
            return IconButton(
              tooltip: strings.installApp,
              icon: const Icon(
                Icons.install_mobile_rounded,
                color: Colors.white,
              ),
              onPressed: () => triggerPwaInstall(context, strings),
            );
          },
        );
      },
    );
  }
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

/// Web-only Install App (PWA) & Download Android APK cards for CompactSettingsDrawer.
class WebDrawerAppActions extends StatelessWidget {
  final AppStrings strings;

  const WebDrawerAppActions({super.key, required this.strings});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    final bridge = WebPlatformBridge.instance;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: bridge.isStandaloneNotifier,
          builder: (_, isStandalone, __) {
            if (isStandalone) return const SizedBox.shrink();
            return ValueListenableBuilder<bool>(
              valueListenable: bridge.canInstallNotifier,
              builder: (_, canInstall, __) {
                if (!canInstall && !bridge.isIosWeb) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.icon(
                    onPressed: () => triggerPwaInstall(context, strings),
                    icon: const Icon(Icons.install_mobile_rounded, size: 18),
                    label: Text(
                      strings.installApp,
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
            );
          },
        ),
        OutlinedButton.icon(
          onPressed: () => triggerAndroidApkDownload(context, strings),
          icon: Icon(Icons.android_rounded, size: 19, color: cs.primary),
          label: Text(
            strings.downloadAndroidApk,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}
