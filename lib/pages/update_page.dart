import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/app_update_service.dart';
import '../services/providers.dart';
import '../widgets/update_cards.dart';

class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  AppUpdateCheck? _check;
  String? _downloadedPath;
  UpdateFailure? _failure;
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
        _failure = UpdateFailure.check;
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
        _failure = UpdateFailure.download;
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
        _failure = UpdateFailure.install;
      });
    }
  }

  Future<void> _openInstallSettings() async {
    try {
      await _service.openInstallPermissionSettings();
    } catch (error) {
      _logFailure('install_settings', error);
      if (!mounted) return;
      setState(() => _failure = UpdateFailure.install);
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
            const SourceCard(),
            const SizedBox(height: 12),
            if (_checking) const CheckingCard() else _buildResultCard(context),
            if (_downloading || _verifying) ...[
              const SizedBox(height: 12),
              ProgressCard(
                downloading: _downloading,
                progress: _progress,
              ),
            ],
            if (_permissionRequired) ...[
              const SizedBox(height: 12),
              PermissionCard(
                onOpenSettings: _openInstallSettings,
                onRetry: _installDownloadedUpdate,
              ),
            ],
            if (_installerLaunched) ...[
              const SizedBox(height: 12),
              StatusCard(
                icon: Icons.verified_outlined,
                color: Theme.of(context).colorScheme.primary,
                title: context.l10n.updateInstallerLaunched,
              ),
            ],
            if (_failure != null) ...[
              const SizedBox(height: 12),
              FailureCard(
                failure: _failure!,
                onRetry: _failure == UpdateFailure.check
                    ? _checkForUpdate
                    : _failure == UpdateFailure.install &&
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
                  formatBytes(asset.size),
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