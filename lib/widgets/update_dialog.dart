import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_branding.dart';
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
    final t = ref.watch(stringsProvider);
    final cs = Theme.of(context).colorScheme;

    final version = update.latestVersion ?? AppBranding.appVersion;
    final buildNum = update.latestBuildNumber ?? update.currentBuildNumber;

    return Directionality(
      textDirection: t.textDirection,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: cs.onPrimaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                update.needsInstallPermission
                    ? t.allowInstallPermissionTitle
                    : t.updateAvailableTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
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
                  : t.updateAvailableDesc(version, buildNum),
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (update.isDownloading) ...[
              const SizedBox(height: 16),
              Text(
                t.downloadingUpdate,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: update.downloadProgress,
                borderRadius: BorderRadius.circular(6),
              ),
            ] else if (update.isInstalling) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.installingUpdate,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (update.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  t.updateCheckUnavailable,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!update.isBusy)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.updateLater),
            ),
          if (!kIsWeb && update.errorMessage != null)
            OutlinedButton.icon(
              onPressed: () => notifier.openApkInBrowserFallback(),
              icon: const Icon(Icons.open_in_browser_rounded, size: 17),
              label: Text(t.downloadInBrowser),
            ),
          FilledButton.icon(
            onPressed: update.isBusy
                ? null
                : () async {
                    await notifier.performOneClickUpdate();
                    if (!kIsWeb &&
                        context.mounted &&
                        ref.read(updateProvider).errorMessage == null &&
                        !ref.read(updateProvider).needsInstallPermission) {
                      Navigator.of(context).pop();
                    }
                  },
            icon: Icon(
              update.needsInstallPermission
                  ? Icons.install_mobile_rounded
                  : Icons.download_rounded,
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
