import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';

/// Non-dismissible progress dialog shown while a micro-data keep-alive runs.
/// Pops with the operation result (or the thrown Exception) on completion.
class MicroDataProgressDialog extends StatefulWidget {
  const MicroDataProgressDialog({super.key, required this.operation});

  final Future<MicroDataKeepAliveResult> Function() operation;

  @override
  State<MicroDataProgressDialog> createState() =>
      _MicroDataProgressDialogState();
}

class _MicroDataProgressDialogState extends State<MicroDataProgressDialog> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    Object? outcome;
    try {
      outcome = await widget.operation();
    } on Exception catch (error) {
      outcome = error;
    }
    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(context.l10n.microDataKeepAliveRunningTitle),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  context.l10n.microDataKeepAliveRunningDescription,
                ),
              ),
            ],
          ),
        ),
      );
}