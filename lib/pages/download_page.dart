import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../services/euicc_bridge.dart';
import '../services/providers.dart';

class DownloadPage extends ConsumerStatefulWidget {
  const DownloadPage({super.key, required this.channel});

  final EuiccChannelInfo channel;

  @override
  ConsumerState<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends ConsumerState<DownloadPage> {
  final _codeController = TextEditingController();
  final _confirmController = TextEditingController();
  final _imeiController = TextEditingController();
  StreamSubscription<DownloadTaskEvent>? _sub;
  DownloadTaskEvent? _lastEvent;
  bool _busy = false;
  String? _error;
  String? _activeTaskId;
  Object? _pendingTaskError;
  final List<DownloadTaskEvent> _pendingEvents = [];
  late final EuiccBridge _bridge;

  @override
  void initState() {
    super.initState();
    _bridge = ref.read(euiccBridgeProvider);
  }

  @override
  void dispose() {
    final taskId = _activeTaskId;
    if (_busy && taskId != null) {
      unawaited(
        _bridge
            .cancelDownload(taskId: taskId)
            .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Failed to cancel active download: $error');
        }),
      );
    }
    _sub?.cancel();
    _codeController.dispose();
    _confirmController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = context.l10n.activationCodeRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _lastEvent = null;
      _activeTaskId = null;
      _pendingTaskError = null;
      _pendingEvents.clear();
    });
    try {
      await _sub?.cancel();
      if (!mounted) return;
      _sub = _bridge.taskEvents.listen(
        _onTaskEvent,
        onError: (Object error, StackTrace stackTrace) =>
            unawaited(_onTaskError(error)),
      );
      final taskId = await _bridge.downloadProfile(
        slotId: widget.channel.slotId,
        portId: widget.channel.portId,
        seId: widget.channel.seId,
        activationCode: code,
        confirmationCode: _confirmController.text.trim().isEmpty
            ? null
            : _confirmController.text.trim(),
        imei: _imeiController.text.trim().isEmpty
            ? null
            : _imeiController.text.trim(),
      );
      if (!mounted) {
        unawaited(
          _bridge
              .cancelDownload(taskId: taskId)
              .catchError((Object error, StackTrace stackTrace) {
            debugPrint('Failed to cancel detached download: $error');
          }),
        );
        return;
      }
      setState(() => _activeTaskId = taskId);

      final pendingError = _pendingTaskError;
      _pendingTaskError = null;
      if (pendingError != null) {
        await _cancelActiveTaskAfterError(pendingError);
        return;
      }
      final pending = List<DownloadTaskEvent>.of(_pendingEvents);
      _pendingEvents.clear();
      for (final event in pending) {
        if (!mounted || !_busy) break;
        if (event.taskId == taskId) await _handleTaskEvent(event);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _onTaskEvent(DownloadTaskEvent event) {
    if (!mounted || !_busy) return;
    final taskId = _activeTaskId;
    if (taskId == null) {
      _pendingEvents.add(event);
      return;
    }
    if (event.taskId == taskId) {
      unawaited(_handleTaskEvent(event));
    }
  }

  Future<void> _onTaskError(Object error) async {
    if (!mounted || !_busy) return;
    if (_activeTaskId == null) {
      _pendingTaskError = error;
      return;
    }
    await _cancelActiveTaskAfterError(error);
  }

  Future<void> _handleTaskEvent(DownloadTaskEvent event) async {
    if (!mounted) return;
    setState(() => _lastEvent = event);
    try {
      if (event.needConfirmation) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.confirmDownload),
            content: Text(
              context.l10n.confirmDownloadDescription(
                event.provider ?? '-',
                event.name ?? '-',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.continueAction),
              ),
            ],
          ),
        );
        if (!mounted) return;
        await _bridge.confirmDownload(
          taskId: event.taskId,
          continueDownload: ok == true,
        );
      }
    } catch (error) {
      await _cancelActiveTaskAfterError(error);
      return;
    }
    if (!mounted || (!event.done && event.error == null)) return;
    setState(() => _busy = false);
    if (event.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileDownloaded)),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _cancelActiveTaskAfterError(Object error) async {
    final taskId = _activeTaskId;
    if (taskId == null) return;
    try {
      await _bridge.cancelDownload(taskId: taskId);
    } catch (cancelError) {
      debugPrint('Failed to cancel download after task error: $cancelError');
    }
    if (!mounted) return;
    setState(() => _error = error.toString());
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (mounted && code != null && code.isNotEmpty) {
      _codeController.text = code;
    }
  }

  Future<void> _cancelDownload() async {
    final taskId = _activeTaskId;
    if (taskId == null) return;
    try {
      await _bridge.cancelDownload(taskId: taskId);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _lastEvent?.progress;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.downloadProfile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.l10n.channelLabel(
              context.l10n.euiccChannelLabel(widget.channel),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: context.l10n.activationCodeLabel,
              hintText: context.l10n.activationCodeHint,
              suffixIcon: IconButton(
                tooltip: context.l10n.scanQr,
                onPressed: _busy ? null : _scanQr,
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              labelText: context.l10n.confirmationCodeOptional,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imeiController,
            decoration: InputDecoration(
              labelText: context.l10n.imeiOptional,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_lastEvent != null) ...[
            const SizedBox(height: 16),
            Text(
              context.l10n.phaseLabel(
                context.l10n.downloadPhase(_lastEvent!.phase),
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress.clamp(0, 1)),
              const SizedBox(height: 4),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
            if (_lastEvent!.error != null)
              Text(
                _lastEvent!.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _startDownload,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            label: Text(
              _busy ? context.l10n.downloading : context.l10n.startDownload,
            ),
          ),
          if (_busy) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _activeTaskId == null ? null : _cancelDownload,
              child: Text(context.l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }
}

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanQr)),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final raw = barcodes.first.rawValue;
          if (raw == null || raw.isEmpty) return;
          _handled = true;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
