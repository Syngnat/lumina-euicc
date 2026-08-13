import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';

/// Identity + memory strip and quick actions (reminders / add profile).
class EuiccIdentityStrip extends StatelessWidget {
  const EuiccIdentityStrip({
    super.key,
    required this.info,
    required this.infoLoading,
    required this.onReminders,
    required this.onAdd,
  });

  final EuiccInfo? info;
  final bool infoLoading;
  final VoidCallback? onReminders;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final eid = info?.eid.trim() ?? '';
    final freeMemory = info?.freeNonVolatileMemory ?? 0;
    final eidLabel = eid.isEmpty ? context.l10n.eidUnavailable : maskEid(eid);
    final memoryLabel = freeMemory > 0
        ? context.l10n.freeMemory(formatStorage(freeMemory))
        : context.l10n.freeMemoryUnknown;

    return SizedBox(
      height: 73,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 9, 12, 9),
              decoration: BoxDecoration(
                color: const Color(0xFF173F3A),
                borderRadius: BorderRadius.circular(17),
              ),
              child: infoLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8FD8CC),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.fingerprint_rounded,
                              color: Color(0xFF8FD8CC),
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                eidLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.storage_rounded,
                              color: Color(0xFF8FD8CC),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                memoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: const Color(0xFFD7ECE8),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 8),
          DashboardSquareAction(
            key: const Key('keepAliveRemindersButton'),
            tooltip: context.l10n.localReminders,
            icon: Icons.notifications_none_rounded,
            onPressed: onReminders,
          ),
          const SizedBox(width: 8),
          DashboardSquareAction(
            key: const Key('newEsimButton'),
            tooltip: context.l10n.newEsim,
            icon: Icons.add_rounded,
            emphasized: true,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class DashboardSquareAction extends StatelessWidget {
  const DashboardSquareAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: emphasized ? scheme.primary : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(17),
      elevation: emphasized ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 54,
            height: 73,
            child: Icon(
              icon,
              color: emphasized ? scheme.onPrimary : scheme.onSurface,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

/// Masks a long EID, keeping the head and tail: "12345678••••••901234".
String maskEid(String eid) {
  if (eid.length <= 12) return eid;
  return '${eid.substring(0, 8)}••••••${eid.substring(eid.length - 6)}';
}

/// Formats a byte count into a human readable size (KiB if >= 1024).
String formatStorage(int bytes) {
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KiB';
  return '$bytes B';
}