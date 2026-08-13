import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Update-failure phase (reused by [FailureCard]).
enum UpdateFailure { check, download, install }

class SourceCard extends StatelessWidget {
  const SourceCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.updateSourceDescription,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(context.l10n.updateSecurityDescription),
            ],
          ),
        ),
      );
}

class CheckingCard extends StatelessWidget {
  const CheckingCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 16),
              Text(context.l10n.checkingForUpdates),
            ],
          ),
        ),
      );
}

class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.downloading,
    required this.progress,
  });

  final bool downloading;
  final double progress;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                downloading
                    ? context.l10n.updateDownloading((progress * 100).round())
                    : context.l10n.verifyingUpdate,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: downloading ? progress : null),
            ],
          ),
        ),
      );
}

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.onOpenSettings,
    required this.onRetry,
  });

  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.installPermissionRequiredTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(context.l10n.installPermissionRequiredDescription),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                key: const Key('openInstallSettings'),
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined),
                label: Text(context.l10n.openInstallSettings),
              ),
              TextButton(
                key: const Key('retryInstallUpdate'),
                onPressed: onRetry,
                child: Text(context.l10n.retryInstall),
              ),
            ],
          ),
        ),
      );
}

class FailureCard extends StatelessWidget {
  const FailureCard({
    super.key,
    required this.failure,
    required this.onRetry,
  });

  final UpdateFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      UpdateFailure.check => context.l10n.updateCheckFailed,
      UpdateFailure.download => context.l10n.updateDownloadFailed,
      UpdateFailure.install => context.l10n.updateInstallFailed,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatusCard(
              icon: Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              title: message,
              embedded: true,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(
                failure == UpdateFailure.check
                    ? context.l10n.checkAgain
                    : context.l10n.retryInstall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.embedded = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Text(title)),
      ],
    );
    if (embedded) return content;
    return Card(
      child: Padding(padding: const EdgeInsets.all(20), child: content),
    );
  }
}

/// Formats a byte count into MB.
String formatBytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';