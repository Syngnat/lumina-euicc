import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/app_update_service.dart';
import '../services/providers.dart';

enum _UpdateFailure { check, download, install }

class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  AppUpdateCheck? _check;
  String? _downloadedPath;
  _UpdateFailure? _failure;
  bool _checking = true;
  bool _downloading = false;
  bool _verifying = false;
  bool _permissionRequired = false;
  bool _installerLaunched = false;
  double _progress = 0;

  AppUpdateService get _service => ref.read(appUpdateServiceProvider);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_checkForUpdate);
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checking = true;
      _failure = null;
      _permissionRequired = false;
      _installerLaunched = false;
    });
    try {
      final check = await _service.checkForUpdate();
      if (!mounted) return;
      setState(() {
        _check = check;
        _checking = false;
        _downloadedPath = null;
      });
    } catch (error) {
      _logFailure('check', error);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _failure = _UpdateFailure.check;
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    final check = _check;
    if (check == null || !check.updateAvailable || _downloading) return;
    setState(() {
      _downloading = true;
      _verifying = false;
      _failure = null;
      _permissionRequired = false;
      _installerLaunched = false;
      _progress = 0;
    });
    try {
      final path = await _service.downloadUpdate(
        check,
        onProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _progress = (received / total).clamp(0, 1));
        },
      );
      if (!mounted) return;
      setState(() {
        _downloadedPath = path;
        _downloading = false;
        _verifying = true;
      });
      await _installDownloadedUpdate();
    } catch (error) {
      _logFailure('download', error);
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _verifying = false;
        _failure = _UpdateFailure.download;
      });
    }
  }

  Future<void> _installDownloadedUpdate() async {
    final check = _check;
    final path = _downloadedPath;
    if (check == null || path == null) return;
    setState(() {
      _verifying = true;
      _failure = null;
      _permissionRequired = false;
    });
    try {
      final status = await _service.installDownloadedUpdate(check, path);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _permissionRequired = status == InstallUpdateStatus.permissionRequired;
        _installerLaunched = status == InstallUpdateStatus.launched;
      });
    } catch (error) {
      _logFailure('install', error);
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _failure = _UpdateFailure.install;
      });
    }
  }

  Future<void> _openInstallSettings() async {
    try {
      await _service.openInstallPermissionSettings();
    } catch (error) {
      _logFailure('install_settings', error);
      if (!mounted) return;
      setState(() => _failure = _UpdateFailure.install);
    }
  }

  void _logFailure(String action, Object error) {
    final code = error is AppUpdateException ? error.code : error.runtimeType;
    debugPrint('Lumina update $action failed: $code');
  }

  @override
  Widget build(BuildContext context) {
    final busy = _downloading || _verifying;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.softwareUpdate),
          actions: [
            IconButton(
              key: const Key('checkForUpdate'),
              tooltip: context.l10n.checkAgain,
              onPressed: busy || _checking ? null : _checkForUpdate,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _SourceCard(),
            const SizedBox(height: 12),
            if (_checking) _CheckingCard() else _buildResultCard(context),
            if (_downloading || _verifying) ...[
              const SizedBox(height: 12),
              _ProgressCard(
                downloading: _downloading,
                progress: _progress,
              ),
            ],
            if (_permissionRequired) ...[
              const SizedBox(height: 12),
              _PermissionCard(
                onOpenSettings: _openInstallSettings,
                onRetry: _installDownloadedUpdate,
              ),
            ],
            if (_installerLaunched) ...[
              const SizedBox(height: 12),
              _StatusCard(
                icon: Icons.verified_outlined,
                color: Theme.of(context).colorScheme.primary,
                title: context.l10n.updateInstallerLaunched,
              ),
            ],
            if (_failure != null) ...[
              const SizedBox(height: 12),
              _FailureCard(
                failure: _failure!,
                onRetry: _failure == _UpdateFailure.check
                    ? _checkForUpdate
                    : _failure == _UpdateFailure.install &&
                            _downloadedPath != null
                        ? _installDownloadedUpdate
                        : _downloadAndInstall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context) {
    final check = _check;
    if (check == null) return const SizedBox.shrink();
    final asset = check.asset;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  check.updateAvailable
                      ? Icons.system_update_alt
                      : Icons.check_circle_outline,
                  size: 32,
                  color: check.updateAvailable
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green.shade700,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        check.updateAvailable
                            ? context.l10n.updateAvailableTitle
                            : context.l10n.upToDateTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.currentVersionLabel(
                          check.runtime.versionName,
                        ),
                      ),
                      Text(
                        context.l10n.latestVersionLabel(
                          check.release.version.toString(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (asset != null) ...[
              const SizedBox(height: 16),
              Text(
                context.l10n.updateAssetDetail(
                  asset.variant.assetSuffix,
                  _formatBytes(asset.size),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('downloadAndInstallUpdate'),
                onPressed:
                    _downloading || _verifying ? null : _downloadAndInstall,
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text(context.l10n.downloadAndInstall),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Text(context.l10n.upToDateDescription),
            ],
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
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

class _CheckingCard extends StatelessWidget {
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.downloading, required this.progress});

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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
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

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.failure, required this.onRetry});

  final _UpdateFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (failure) {
      _UpdateFailure.check => context.l10n.updateCheckFailed,
      _UpdateFailure.download => context.l10n.updateDownloadFailed,
      _UpdateFailure.install => context.l10n.updateInstallFailed,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StatusCard(
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
                failure == _UpdateFailure.check
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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

String _formatBytes(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
