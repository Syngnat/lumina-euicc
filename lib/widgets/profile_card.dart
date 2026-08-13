import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_presentation.dart';
import '../models/profile_reminder.dart';
import 'profile_card_controls.dart';
import 'profile_card_identity.dart';

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
              child: ProfileIdentity(
                profile: profile,
                reminder: reminder,
                estimatedSizeBytes: estimatedSizeBytes,
                onCopyIccid: () => _copyIccid(context),
              ),
            ),
            const SizedBox(width: 5),
            ProfileControls(
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