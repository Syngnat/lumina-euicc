import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_reminder.dart';

/// Right-hand control column of a profile card: compact toggle, keep-alive
/// action and the "more" popup menu.
class ProfileControls extends StatelessWidget {
  const ProfileControls({
    super.key,
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
          CompactToggle(
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
                TinyAction(
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

class CompactToggle extends StatelessWidget {
  const CompactToggle({
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

class TinyAction extends StatelessWidget {
  const TinyAction({
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