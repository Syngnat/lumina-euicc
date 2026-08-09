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
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      clipBehavior: Clip.antiAlias,
      color: profile.enabled
          ? scheme.primaryContainer.withValues(alpha: 0.22)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: profile.enabled
              ? scheme.primary.withValues(alpha: 0.48)
              : scheme.outlineVariant.withValues(alpha: 0.7),
          width: profile.enabled ? 1.2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RegionBadge(
                  symbol: presentation.symbol,
                  semanticLabel: regionLabel,
                  enabled: profile.enabled,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              profile.provider.trim().isEmpty
                                  ? '—'
                                  : profile.provider,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusLabel(enabled: profile.enabled),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              regionLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onMicroDataKeepAlive != null)
                  IconButton(
                    key: ValueKey('micro-data-keep-alive-${profile.seq}'),
                    tooltip: context.l10n.microDataKeepAliveTooltip,
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    onPressed: onMicroDataKeepAlive,
                    icon: const Icon(Icons.network_check_outlined),
                  ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 21,
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
                        child: Text(context.l10n.enable),
                      ),
                    if (profile.enabled)
                      PopupMenuItem(
                        value: 'disable',
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
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ProfileFooter(
              profile: profile,
              reminder: reminder,
              onCopyIccid: () => _copyIccid(context),
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
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? scheme.primaryContainer
              : scheme.secondaryContainer.withValues(alpha: 0.68),
          border: Border.all(
            color: enabled
                ? scheme.primary.withValues(alpha: 0.28)
                : scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Semantics(
          label: semanticLabel,
          image: true,
          child: ExcludeSemantics(
            child: Center(
              child: Text(symbol, style: const TextStyle(fontSize: 19)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      key: const ValueKey('profile-status'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          enabled ? context.l10n.enabled : context.l10n.disabled,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.profile,
    required this.reminder,
    required this.onCopyIccid,
  });

  final EuiccProfile profile;
  final ProfileReminder? reminder;
  final VoidCallback onCopyIccid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Text(
          'ICCID',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            key: const ValueKey('profile-iccid'),
            label: 'ICCID ${profile.iccid}',
            hint: context.l10n.iccidCopyHint,
            button: true,
            onLongPress: onCopyIccid,
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: onCopyIccid,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    profile.iccid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (reminder != null) ...[
          const SizedBox(width: 6),
          Flexible(child: _ReminderLabel(reminder: reminder!)),
        ],
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 82),
          child: Text(
            context.l10n.profileSummary(
              profile.seq,
              context.l10n.profileClass(profile.profileClass),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _ReminderLabel extends StatelessWidget {
  const _ReminderLabel({required this.reminder});

  final ProfileReminder reminder;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final date = material.formatCompactDate(reminder.at);
    final time = material.formatTimeOfDay(TimeOfDay.fromDateTime(reminder.at));
    final label = context.l10n.reminderScheduledAt(date, time);
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Row(
          key: const Key('profile-reminder'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_outlined, size: 14, color: scheme.primary),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                '$date $time',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
