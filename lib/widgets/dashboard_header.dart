import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Top app bar for the homepage dashboard.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.onCompatibility,
    required this.onRefresh,
    required this.onSettings,
  });

  final VoidCallback onCompatibility;
  final Future<void> Function() onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF173F3A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sim_card_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.45,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.dashboardSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          _HeaderAction(
            tooltip: context.l10n.compatibility,
            icon: Icons.verified_user_outlined,
            onPressed: onCompatibility,
          ),
          _HeaderAction(
            tooltip: context.l10n.refresh,
            icon: Icons.refresh_rounded,
            onPressed: onRefresh,
          ),
          _HeaderAction(
            tooltip: context.l10n.settings,
            icon: Icons.settings_outlined,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 38, height: 38),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
      );
}