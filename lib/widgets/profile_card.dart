import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.profile,
    this.onEnable,
    this.onDisable,
    this.onDelete,
    this.onRename,
  });

  final EuiccProfile profile;
  final VoidCallback? onEnable;
  final VoidCallback? onDisable;
  final VoidCallback? onDelete;
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = profile.enabled;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: enabled ? scheme.primary : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'enable':
                                  onEnable?.call();
                                case 'disable':
                                  onDisable?.call();
                                case 'rename':
                                  onRename?.call();
                                case 'delete':
                                  onDelete?.call();
                              }
                            },
                            itemBuilder: (context) => [
                              if (!enabled)
                                PopupMenuItem(
                                  value: 'enable',
                                  child: Text(context.l10n.enable),
                                ),
                              if (enabled)
                                PopupMenuItem(
                                  value: 'disable',
                                  child: Text(context.l10n.disable),
                                ),
                              PopupMenuItem(
                                value: 'rename',
                                child: Text(context.l10n.rename),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(context.l10n.delete),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: enabled
                              ? const Color(0xFFD1FAE5)
                              : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          enabled
                              ? context.l10n.enabled
                              : context.l10n.disabled,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: enabled
                                ? const Color(0xFF065F46)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetaRow(
                        label: context.l10n.provider,
                        value: profile.provider,
                      ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        label: 'ICCID',
                        value: profile.iccid,
                        mono: true,
                        onLongPress: () async {
                          await Clipboard.setData(
                              ClipboardData(text: profile.iccid));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(context.l10n.iccidCopied),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.profileSummary(
                          profile.seq,
                          context.l10n.profileClass(profile.profileClass),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.onLongPress,
  });

  final String label;
  final String value;
  final bool mono;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null,
                    fontSize: mono ? 12.5 : null,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
