import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/providers.dart';
import 'legal_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(selectedChannelProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: Text(context.l10n.legalAndOpenSource),
            subtitle: Text(context.l10n.legalAndOpenSourceDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LegalPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: Text(context.l10n.memoryReset),
            subtitle: Text(
              channel == null
                  ? context.l10n.selectChannelFirst
                  : context.l10n.memoryResetWarning(
                      context.l10n.euiccChannelLabel(channel),
                    ),
            ),
            enabled: channel != null,
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.error),
            onTap: channel == null
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(context.l10n.memoryResetQuestion),
                        content: Text(context.l10n.memoryResetConfirmation),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(context.l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(context.l10n.reset),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await ref.read(euiccBridgeProvider).memoryReset(
                          slotId: channel.slotId,
                          portId: channel.portId,
                          seId: channel.seId,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.memoryResetRequested),
                        ),
                      );
                    }
                    ref.invalidate(profilesProvider);
                  },
          ),
          ListTile(
            title: Text(context.l10n.notifications),
            subtitle: Text(context.l10n.notificationsDescription),
            enabled: channel != null,
            onTap: channel == null
                ? null
                : () async {
                    final list =
                        await ref.read(euiccBridgeProvider).listNotifications(
                              slotId: channel.slotId,
                              portId: channel.portId,
                              seId: channel.seId,
                            );
                    if (!context.mounted) return;
                    await showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (context) {
                        if (list.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(context.l10n.noPendingNotifications),
                          );
                        }
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final n = list[i];
                            return ListTile(
                              title: Text(
                                n['title']?.toString() ??
                                    context.l10n.notification,
                              ),
                              subtitle: Text(n['detail']?.toString() ?? ''),
                            );
                          },
                        );
                      },
                    );
                  },
          ),
        ],
      ),
    );
  }
}
