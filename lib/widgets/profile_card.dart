import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_presentation.dart';

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
    final presentation = ProfilePresentation.infer(
      name: profile.name,
      provider: profile.provider,
    );
    final regionLabel = switch (presentation.region) {
      ProfileRegion.unitedKingdom => context.l10n.profileRegionUnitedKingdom,
      ProfileRegion.global => context.l10n.profileRegionGlobal,
      ProfileRegion.unknown => context.l10n.profileRegionUnknown,
    };

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: profile.enabled
          ? scheme.primaryContainer.withValues(alpha: 0.22)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: profile.enabled
              ? scheme.primary.withValues(alpha: 0.48)
              : scheme.outlineVariant.withValues(alpha: 0.7),
          width: profile.enabled ? 1.2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 12, 14),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
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
                        const SizedBox(height: 3),
                        Text(
                          profile.provider.trim().isEmpty
                              ? '—'
                              : profile.provider,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
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
                      value: 'delete',
                      child: Text(context.l10n.delete),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                _StatusPill(enabled: profile.enabled),
                _RegionPill(
                  label: regionLabel,
                ),
              ],
            ),
            const SizedBox(height: 13),
            _ProfileDetails(
              profile: profile,
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
      width: 44,
      height: 44,
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
              child: Text(symbol, style: const TextStyle(fontSize: 23)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('profile-status'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            enabled ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            enabled ? context.l10n.enabled : context.l10n.disabled,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: enabled
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _RegionPill extends StatelessWidget {
  const _RegionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
        color: scheme.surface.withValues(alpha: 0.72),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({
    required this.profile,
    required this.onCopyIccid,
  });

  final EuiccProfile profile;
  final VoidCallback onCopyIccid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ICCID',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(height: 3),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    profile.iccid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Divider(
              height: 1, color: scheme.outlineVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            context.l10n.profileSummary(
              profile.seq,
              context.l10n.profileClass(profile.profileClass),
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
