import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../services/providers.dart';

/// Horizontal channel picker shown below the dashboard header.
class ChannelSwitcher extends StatelessWidget {
  const ChannelSwitcher({
    super.key,
    required this.channels,
    required this.selected,
    required this.selectedProfileCount,
    required this.onSelected,
  });

  final List<EuiccChannelInfo> channels;
  final EuiccChannelInfo? selected;
  final int selectedProfileCount;
  final ValueChanged<EuiccChannelInfo> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final channel in channels)
        _ChannelSegment(
          key: ValueKey(
            'channel-segment-${channel.slotId}-${channel.portId}-${channel.seId}',
          ),
          channel: channel,
          selected: channel.key == selected?.key,
          detail: channel.key == selected?.key
              ? context.l10n.profileCount(selectedProfileCount)
              : channel.type.toUpperCase(),
          onTap: () => onSelected(channel),
        ),
    ];

    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(15),
      ),
      child: channels.length <= 2
          ? Row(
              children: [for (final item in items) Expanded(child: item)],
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (_, index) => SizedBox(
                width: 150,
                child: items[index],
              ),
            ),
    );
  }
}

class _ChannelSegment extends StatelessWidget {
  const _ChannelSegment({
    super.key,
    required this.channel,
    required this.selected,
    required this.detail,
    required this.onTap,
  });

  final EuiccChannelInfo channel;
  final bool selected;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUsb = channel.type.toLowerCase() == 'usb';
    final label = isUsb ? 'USB' : 'SIM ${channel.slotId + 1}';
    return Semantics(
      label: context.l10n.euiccChannelLabel(channel),
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        elevation: selected ? 1 : 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUsb ? Icons.usb_rounded : Icons.sim_card_outlined,
                size: 16,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            selected ? scheme.primary : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
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