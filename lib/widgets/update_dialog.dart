import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_strings.dart';
import '../providers/quran_providers.dart';
import '../providers/update_provider.dart';

Future<void> showAppUpdateDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _AppUpdateDialog(),
  );
}

class _AppUpdateDialog extends ConsumerWidget {
  const _AppUpdateDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);
    final AppStrings t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    final targetVersion = update.latestVersion ?? update.currentVersion;
    final targetBuild = update.latestBuildNumber ?? update.currentBuildNumber;

    return Directionality(
      textDirection: t.textDirection,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                update.needsInstallPermission
                    ? Icons.admin_panel_settings_rounded
                    : Icons.system_update_rounded,
                color: cs.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                update.needsInstallPermission
                    ? t.allowInstallPermissionTitle
                    : t.updateAvailableTitle,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              update.needsInstallPermission
                  ? t.allowInstallPermissionDesc
                  : t.updateAvailableDesc(targetVersion, targetBuild),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'v${update.currentVersion} (#${update.currentBuildNumber})',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: cs.primary),
                  Text(
                    'v$targetVersion (#$targetBuild)',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (update.isDownloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: update.downloadProgress,
                borderRadius: BorderRadius.circular(6),
                minHeight: 7,
              ),
              const SizedBox(height: 8),
              Text(
                update.downloadProgress != null
                    ? '${t.downloadingUpdate} (${(update.downloadProgress! * 100).round()}%)'
                    : t.downloadingUpdate,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ] else if (update.isInstalling) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(6),
                minHeight: 7,
              ),
              const SizedBox(height: 8),
              Text(
                t.installingUpdate,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ],
            if (update.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                t.updateCheckUnavailable,
                style: TextStyle(
                  fontSize: 12.5,
                  color: cs.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!update.isDownloading && !update.isInstalling)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.updateLater),
            ),
          if (!kIsWeb &&
              (update.errorMessage != null || update.needsInstallPermission))
            TextButton.icon(
              onPressed: () => notifier.openApkInBrowserFallback(),
              icon: const Icon(Icons.open_in_browser_rounded, size: 17),
              label: Text(t.downloadInBrowser),
            ),
          FilledButton.icon(
            onPressed: update.isBusy
                ? null
                : () async {
                    await notifier.performOneClickUpdate();
                  },
            icon: Icon(
              update.needsInstallPermission
                  ? Icons.install_mobile_rounded
                  : Icons.system_update_rounded,
              size: 18,
            ),
            label: Text(
              update.needsInstallPermission
                  ? t.installDownloadedApk
                  : t.updateNow,
            ),
          ),
        ],
      ),
    );
  }
}
