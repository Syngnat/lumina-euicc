import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/euicc_models.dart';
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

  @override
  void dispose() {
    _sub?.cancel();
    _codeController.dispose();
    _confirmController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  Future<void> _startDownload() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Activation code is required');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _lastEvent = null;
    });
    final bridge = ref.read(euiccBridgeProvider);
    await _sub?.cancel();
    _sub = bridge.taskEvents.listen((event) async {
      setState(() => _lastEvent = event);
      if (event.needConfirmation && mounted) {
        final ok = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm download'),
            content: Text(
              'Provider: ${event.provider ?? "-"}\n'
              'Name: ${event.name ?? "-"}\n\nContinue?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
            ],
          ),
        );
        await bridge.confirmDownload(continueDownload: ok == true);
      }
      if (event.done || event.error != null) {
        setState(() => _busy = false);
        if (event.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile downloaded')),
          );
          Navigator.of(context).pop(true);
        }
      }
    });

    try {
      await bridge.downloadProfile(
        slotId: widget.channel.slotId,
        portId: widget.channel.portId,
        seId: widget.channel.seId,
        activationCode: code,
        confirmationCode: _confirmController.text.trim().isEmpty
            ? null
            : _confirmController.text.trim(),
        imei: _imeiController.text.trim().isEmpty ? null : _imeiController.text.trim(),
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanPage()),
    );
    if (code != null && code.isNotEmpty) {
      _codeController.text = code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _lastEvent?.progress;
    return Scaffold(
      appBar: AppBar(title: const Text('Download profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Channel: ${widget.channel.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Activation code / LPA string',
              hintText: 'LPA:1\$smdp.example.com\$...',
              suffixIcon: IconButton(
                tooltip: 'Scan QR',
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
            decoration: const InputDecoration(
              labelText: 'Confirmation code (optional)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _imeiController,
            decoration: const InputDecoration(
              labelText: 'IMEI (optional)',
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_lastEvent != null) ...[
            const SizedBox(height: 16),
            Text('Phase: ${_lastEvent!.phase}'),
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
            label: Text(_busy ? 'Downloading…' : 'Start download'),
          ),
          if (_busy) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(euiccBridgeProvider).cancelDownload(),
              child: const Text('Cancel'),
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
      appBar: AppBar(title: const Text('Scan QR')),
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
