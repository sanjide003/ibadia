import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../core/config/app_branding.dart';
import '../core/l10n/app_strings.dart';
import '../providers/update_provider.dart';
import '../services/web_platform_bridge.dart';
import 'update_dialog.dart';

OverlayEntry? _activeTopNoticeEntry;
Timer? _activeTopNoticeTimer;

/// Displays a sleek foreground banner at the very top of the root overlay,
/// painting cleanly ABOVE any open drawer or modal scrim.
void showTopForegroundNotice(
  BuildContext context, {
  required String message,
  required TextDirection textDirection,
  bool isError = false,
  IconData? icon,
}) {
  _activeTopNoticeTimer?.cancel();
  _activeTopNoticeEntry?.remove();
  _activeTopNoticeEntry = null;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      final topInset = MediaQuery.paddingOf(ctx).top;
      final cs = Theme.of(ctx).colorScheme;
      final Color bg = isError ? cs.errorContainer : AppBranding.darkEmerald;
      final Color fg = isError ? cs.onErrorContainer : Colors.white;

      return Positioned(
        top: topInset + 12,
        left: 16,
        right: 16,
        child: Directionality(
          textDirection: textDirection,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Material(
                color: bg,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    _activeTopNoticeTimer?.cancel();
                    if (_activeTopNoticeEntry == entry) {
                      entry.remove();
                      _activeTopNoticeEntry = null;
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon ??
                              (isError
                                  ? Icons.info_outline_rounded
                                  : Icons.check_circle_rounded),
                          color: fg,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: TextStyle(
                              color: fg,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.close_rounded,
                          color: fg.withValues(alpha: 0.78),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  _activeTopNoticeEntry = entry;
  overlay.insert(entry);
  _activeTopNoticeTimer = Timer(const Duration(seconds: 4), () {
    if (_activeTopNoticeEntry == entry) {
      entry.remove();
      _activeTopNoticeEntry = null;
    }
  });
}

Future<void> triggerPwaInstall(BuildContext context, AppStrings t) async {
  final bridge = WebPlatformBridge.instance;
  if (bridge.canInstallNotifier.value) {
    await bridge.promptPwaInstall();
    return;
  }
  if (!context.mounted) return;
  final bool isIos = bridge.isIosWeb;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: t.textDirection,
      child: AlertDialog(
        title: Text(isIos ? t.installOnIosTitle : t.browserInstallTitle),
        content: Text(isIos ? t.installOnIosSteps : t.browserInstallSteps),
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

Future<void> triggerShareApp(BuildContext context, AppStrings t) async {
  final bridge = WebPlatformBridge.instance;
  final String runtimeOrigin = kIsWeb ? bridge.currentWebUrl : '';
  final bool isLocalPreview = runtimeOrigin.contains('localhost') ||
      runtimeOrigin.contains('127.0.0.1') ||
      runtimeOrigin.contains('run.app');
  final String webUrl = (!isLocalPreview && runtimeOrigin.isNotEmpty)
      ? runtimeOrigin
      : AppBranding.webAppUrl;

  final shareText = '${t.appTitle} — ${t.appTagline}\n$webUrl';

  try {
    await Share.share(shareText, subject: t.appTitle);
    return;
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: shareText));
    if (context.mounted) {
      showTopForegroundNotice(
        context,
        message: t.shareAppCopied,
        textDirection: t.textDirection,
        icon: Icons.copy_rounded,
      );
    }
  }
}

Future<bool> triggerAndroidApkDownload(
  BuildContext context,
  AppStrings t,
) async {
  final apkUrl = AppBranding.resolvedAndroidApkUrl;
  if (apkUrl.isNotEmpty) {
    final launched = WebPlatformBridge.instance.openExternalUrl(apkUrl);
    if (launched) {
      if (context.mounted) {
        showTopForegroundNotice(
          context,
          message: t.apkDownloadStarted,
          textDirection: t.textDirection,
          icon: Icons.download_rounded,
        );
      }
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
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: apkUrl));
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  showTopForegroundNotice(
                    context,
                    message: t.apkLinkCopied,
                    textDirection: t.textDirection,
                    icon: Icons.copy_rounded,
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: Text(t.copyApkLink),
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

/// Dedicated Home bottom card for:
/// - Check for App Updates / Update Now
/// - Install Ibadia App (on Web when not yet running as a standalone PWA)
/// - Download Android APK (direct Ibadia.apk download from GitHub Releases)
/// - Share App
class HomeAppUpdatesCard extends ConsumerStatefulWidget {
  final AppStrings strings;
  final Color cardBg;
  final Color cardBorder;

  const HomeAppUpdatesCard({
    super.key,
    required this.strings,
    required this.cardBg,
    required this.cardBorder,
  });

  @override
  ConsumerState<HomeAppUpdatesCard> createState() => _HomeAppUpdatesCardState();
}

class _HomeAppUpdatesCardState extends ConsumerState<HomeAppUpdatesCard> {
  Future<void> _handleUpdateButtonTap(AppStrings t) async {
    final update = ref.read(updateProvider);
    final notifier = ref.read(updateProvider.notifier);

    if (update.updateAvailable) {
      await showAppUpdateDialog(context);
      return;
    }

    final outcome = await notifier.checkForUpdates(silent: false);
    if (!mounted) return;

    switch (outcome) {
      case UpdateCheckOutcome.updateAvailable:
        await showAppUpdateDialog(context);
      case UpdateCheckOutcome.upToDate:
        showTopForegroundNotice(
          context,
          message: t.upToDateMessage,
          textDirection: t.textDirection,
          icon: Icons.verified_rounded,
        );
      case UpdateCheckOutcome.unavailable:
        showTopForegroundNotice(
          context,
          message: t.updateCheckUnavailable,
          textDirection: t.textDirection,
          isError: true,
          icon: Icons.cloud_off_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    final bridge = WebPlatformBridge.instance;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final update = ref.watch(updateProvider);
    final manualOutcome = update.lastManualOutcome;
    final accentColor = isDark ? AppBranding.accentGold : cs.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: bridge.isStandaloneNotifier,
        builder: (_, isStandalone, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card Header with Brand Icon + Version
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      AppBranding.logoAsset,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.appAndUpdatesTitle,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${t.appTitle} • ${update.currentVersion} (#${update.currentBuildNumber})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Check for App Updates / Update Now
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: update.updateAvailable
                    ? FilledButton.icon(
                        onPressed: update.isBusy
                            ? null
                            : () => _handleUpdateButtonTap(t),
                        icon: const Icon(Icons.system_update_rounded, size: 18),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                t.updateNow,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppBranding.accentGold,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.updateAvailableBadge,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppBranding.primaryEmerald,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: update.isChecking
                            ? null
                            : () => _handleUpdateButtonTap(t),
                        icon: update.isChecking
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor,
                                ),
                              )
                            : Icon(
                                Icons.system_update_alt_rounded,
                                size: 18,
                                color: accentColor,
                              ),
                        label: Text(
                          update.isChecking
                              ? t.checkingUpdates
                              : t.checkForUpdates,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),

              // Inline update check status card
              if (!update.isChecking &&
                  (manualOutcome == UpdateCheckOutcome.upToDate ||
                      manualOutcome == UpdateCheckOutcome.unavailable))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: manualOutcome == UpdateCheckOutcome.upToDate
                          ? cs.primaryContainer.withValues(alpha: 0.45)
                          : cs.errorContainer.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: manualOutcome == UpdateCheckOutcome.upToDate
                            ? cs.primary.withValues(alpha: 0.3)
                            : cs.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          manualOutcome == UpdateCheckOutcome.upToDate
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 17,
                          color: manualOutcome == UpdateCheckOutcome.upToDate
                              ? cs.primary
                              : cs.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            manualOutcome == UpdateCheckOutcome.upToDate
                                ? t.upToDateMessage
                                : t.updateCheckUnavailable,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color:
                                  manualOutcome == UpdateCheckOutcome.upToDate
                                      ? cs.onPrimaryContainer
                                      : cs.onErrorContainer,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => ref
                              .read(updateProvider.notifier)
                              .clearManualOutcome(),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Install Ibadia App (Web non-standalone)
              if (kIsWeb && !isStandalone)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton.icon(
                    onPressed: () => triggerPwaInstall(context, t),
                    icon: const Icon(Icons.install_mobile_rounded, size: 18),
                    label: Text(
                      t.installApp,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppBranding.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              // 3. Download Android APK (Web)
              if (kIsWeb)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => triggerAndroidApkDownload(context, t),
                    icon: Icon(
                      Icons.android_rounded,
                      size: 19,
                      color: accentColor,
                    ),
                    label: Text(
                      t.downloadAndroidApk,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              // 4. Share App
              OutlinedButton.icon(
                onPressed: () => triggerShareApp(context, t),
                icon: Icon(Icons.share_rounded, size: 18, color: accentColor),
                label: Text(
                  t.shareApp,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
