import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_presentation.dart';
import '../models/profile_reminder.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.onEnable,
    this.onDisable,
    this.onDelete,
    this.onRename,
    this.onSetReminder,
    this.reminder,
    this.reminderLoading = false,
    this.onCancelReminder,
    this.onMicroDataKeepAlive,
    this.isSwitching = false,
    this.switchLocked = false,
    this.estimatedSizeBytes,
  });

  final EuiccProfile profile;
  final VoidCallback? onEnable;
  final VoidCallback? onDisable;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onSetReminder;
  final ProfileReminder? reminder;
  final bool reminderLoading;
  final VoidCallback? onCancelReminder;
  final VoidCallback? onMicroDataKeepAlive;
  final bool isSwitching;
  final bool switchLocked;
  final int? estimatedSizeBytes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final presentation = ProfilePresentation.infer(
      name: profile.name,
      provider: profile.provider,
      iccid: profile.iccid,
    );
    final regionLabel = switch (presentation.region) {
      ProfileRegion.unitedKingdom when presentation.inferredFromIccid =>
        context.l10n.profileRegionIssuerCountry(
          presentation.countryCode ?? 'GB',
        ),
      ProfileRegion.unitedKingdom => context.l10n.profileRegionUnitedKingdom,
      ProfileRegion.issuerCountry => context.l10n.profileRegionIssuerCountry(
          presentation.countryCode ?? '—',
        ),
      ProfileRegion.global => context.l10n.profileRegionGlobal,
      ProfileRegion.unknown => context.l10n.profileRegionUnknown,
    };

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: profile.enabled
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: profile.enabled
              ? scheme.primary.withValues(alpha: 0.52)
              : scheme.outlineVariant.withValues(alpha: 0.78),
          width: profile.enabled ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RegionBadge(
              symbol: presentation.symbol,
              semanticLabel: regionLabel,
              enabled: profile.enabled,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _ProfileIdentity(
                profile: profile,
                reminder: reminder,
                estimatedSizeBytes: estimatedSizeBytes,
                onCopyIccid: () => _copyIccid(context),
              ),
            ),
            const SizedBox(width: 5),
            _ProfileControls(
              profile: profile,
              isSwitching: isSwitching,
              switchLocked: switchLocked,
              onEnable: onEnable,
              onDisable: onDisable,
              onDelete: onDelete,
              onRename: onRename,
              onSetReminder: onSetReminder,
              reminder: reminder,
              reminderLoading: reminderLoading,
              onCancelReminder: onCancelReminder,
              onMicroDataKeepAlive: onMicroDataKeepAlive,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyIccid(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: profile.iccid));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.iccidCopied)),
    );
  }
}

class _RegionBadge extends StatelessWidget {
  const _RegionBadge({
    required this.symbol,
    required this.semanticLabel,
    required this.enabled,
  });

  final String symbol;
  final String semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      key: const ValueKey('profile-region-badge'),
      width: 42,
      height: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              enabled ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: enabled
                ? scheme.primary.withValues(alpha: 0.25)
                : scheme.outlineVariant,
          ),
        ),
        child: Semantics(
          label: semanticLabel,
          image: true,
          child: ExcludeSemantics(
            child: Center(
              child: Text(
                symbol,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Noto Color Emoji',
                  fontFamilyFallback: ['Segoe UI Emoji'],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
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
                _maskIdentifier(profile.iccid),
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
            Flexible(child: _ReminderChip(reminder: reminder)),
            if (estimatedSizeBytes case final bytes?) ...[
              const SizedBox(width: 5),
              _MetadataChip(
                icon: Icons.storage_rounded,
                label: context.l10n.profileSizeEstimate(
                  _formatEstimatedProfileSize(bytes),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String _formatEstimatedProfileSize(int bytes) {
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KiB';
  return '$bytes B';
}

class _ProfileControls extends StatelessWidget {
  const _ProfileControls({
    required this.profile,
    required this.isSwitching,
    required this.switchLocked,
    required this.onEnable,
    required this.onDisable,
    required this.onDelete,
    required this.onRename,
    required this.onSetReminder,
    required this.reminder,
    required this.reminderLoading,
    required this.onCancelReminder,
    required this.onMicroDataKeepAlive,
  });

  final EuiccProfile profile;
  final bool isSwitching;
  final bool switchLocked;
  final VoidCallback? onEnable;
  final VoidCallback? onDisable;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;
  final VoidCallback? onSetReminder;
  final ProfileReminder? reminder;
  final bool reminderLoading;
  final VoidCallback? onCancelReminder;
  final VoidCallback? onMicroDataKeepAlive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactToggle(
            key: ValueKey('profile-toggle-${profile.seq}'),
            value: profile.enabled,
            busy: isSwitching,
            onChanged: switchLocked ||
                    (profile.enabled ? onDisable == null : onEnable == null)
                ? null
                : (value) => value ? onEnable?.call() : onDisable?.call(),
          ),
          const SizedBox(height: 2),
          Text(
            profile.enabled ? context.l10n.enabled : context.l10n.disabled,
            key: const ValueKey('profile-status'),
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: profile.enabled
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onMicroDataKeepAlive != null)
                _TinyAction(
                  key: ValueKey('micro-data-keep-alive-${profile.seq}'),
                  tooltip: context.l10n.microDataKeepAliveTooltip,
                  icon: Icons.network_check_outlined,
                  onPressed: onMicroDataKeepAlive,
                ),
              PopupMenuButton<String>(
                tooltip: context.l10n.profileActions,
                padding: EdgeInsets.zero,
                position: PopupMenuPosition.under,
                onSelected: (value) {
                  switch (value) {
                    case 'enable':
                      onEnable?.call();
                    case 'disable':
                      onDisable?.call();
                    case 'rename':
                      onRename?.call();
                    case 'reminder':
                      onSetReminder?.call();
                    case 'cancelReminder':
                      onCancelReminder?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (!profile.enabled)
                    PopupMenuItem(
                      value: 'enable',
                      enabled:
                          !switchLocked && !isSwitching && onEnable != null,
                      child: Text(context.l10n.enable),
                    ),
                  if (profile.enabled)
                    PopupMenuItem(
                      value: 'disable',
                      enabled:
                          !switchLocked && !isSwitching && onDisable != null,
                      child: Text(context.l10n.disable),
                    ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(context.l10n.rename),
                  ),
                  PopupMenuItem(
                    value: 'reminder',
                    enabled: !reminderLoading && onSetReminder != null,
                    child: Text(
                      reminder == null
                          ? context.l10n.keepAliveReminder
                          : context.l10n.editKeepAliveReminder,
                    ),
                  ),
                  if (reminder != null)
                    PopupMenuItem(
                      value: 'cancelReminder',
                      child: Text(context.l10n.cancelReminder),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.l10n.delete),
                  ),
                ],
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(Icons.more_vert_rounded, size: 19),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    super.key,
    required this.value,
    required this.busy,
    required this.onChanged,
  });

  final bool value;
  final bool busy;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      toggled: value,
      enabled: !busy && onChanged != null,
      button: true,
      label: value ? context.l10n.disable : context.l10n.enable,
      onTap: busy || onChanged == null ? null : () => onChanged!(!value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy || onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 25,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: value
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.9),
            ),
          ),
          child: busy
              ? Center(
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: value ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                )
              : AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment:
                      value ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      color: value ? scheme.onPrimary : scheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x24000000),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(icon, size: 17),
            ),
          ),
        ),
      );
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.reminder});

  final ProfileReminder? reminder;

  @override
  Widget build(BuildContext context) {
    final value = reminder;
    if (value == null) {
      return _MetadataChip(
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
    return _MetadataChip(
      key: const Key('profile-reminder'),
      icon: Icons.event_outlined,
      label: '$date · $suffix',
      emphasized: true,
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
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

String _maskIdentifier(String value) {
  final normalized = value.trim();
  if (normalized.length <= 10) return normalized;
  return '${normalized.substring(0, 7)}••••••${normalized.substring(normalized.length - 4)}';
}
