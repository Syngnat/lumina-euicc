import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_reminder.dart';

/// Left/center identity column of a profile card: name, masked ICCID, provider,
/// reminder and profile-size chips.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    required this.profile,
    required this.reminder,
    required this.estimatedSizeBytes,
    required this.onCopyIccid,
  });

  final EuiccProfile profile;
  final ProfileReminder? reminder;
  final int? estimatedSizeBytes;
  final VoidCallback onCopyIccid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                height: 1.1,
              ),
        ),
        const SizedBox(height: 2),
        Semantics(
          key: const ValueKey('profile-iccid'),
          label: 'ICCID ${profile.iccid}',
          hint: context.l10n.iccidCopyHint,
          button: true,
          onLongPress: onCopyIccid,
          child: ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onCopyIccid,
              child: Text(
                maskIdentifier(profile.iccid),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          profile.provider.trim().isEmpty ? '—' : profile.provider,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Flexible(child: ReminderChip(reminder: reminder)),
            if (estimatedSizeBytes case final bytes?) ...[
              const SizedBox(width: 5),
              MetadataChip(
                icon: Icons.storage_rounded,
                label: context.l10n.profileSizeEstimate(
                  formatEstimatedProfileSize(bytes),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Masks a long identifier, keeping the head and tail: "1234567••••••9012".
String maskIdentifier(String value) {
  final normalized = value.trim();
  if (normalized.length <= 10) return normalized;
  return '${normalized.substring(0, 7)}••••••${normalized.substring(normalized.length - 4)}';
}

/// Formats a byte count into a human readable size (KiB if >= 1024).
String formatEstimatedProfileSize(int bytes) {
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '$bytes B';
}

class ReminderChip extends StatelessWidget {
  const ReminderChip({super.key, required this.reminder});

  final ProfileReminder? reminder;

  @override
  Widget build(BuildContext context) {
    final value = reminder;
    if (value == null) {
      return MetadataChip(
        key: const Key('profile-reminder'),
        icon: Icons.event_outlined,
        label: context.l10n.reminderUnset,
      );
    }

    final now = DateTime.now();
    final remaining = value.at.difference(now).inDays;
    final date = MaterialLocalizations.of(context).formatCompactDate(value.at);
    final suffix = value.at.isBefore(now)
        ? context.l10n.reminderExpired
        : context.l10n.reminderDaysRemaining(remaining < 0 ? 0 : remaining);
    return MetadataChip(
      key: const Key('profile-reminder'),
      icon: Icons.event_outlined,
      label: '$date · $suffix',
      emphasized: true,
    );
  }
}

class MetadataChip extends StatelessWidget {
  const MetadataChip({
    super.key,
    required this.icon,
    required this.label,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        emphasized ? const Color(0xFF6D5BD0) : scheme.onSurfaceVariant;
    return Container(
      height: 21,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? const Color(0xFFF0EDFF)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}