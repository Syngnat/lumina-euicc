import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channel = ref.watch(selectedChannelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('About'),
            subtitle: Text(
              'Lumina eUICC — Flutter UI aligned with EasyEUICC capabilities.\n'
              'Core LPA runs in the Android native bridge.',
            ),
            isThreeLine: true,
          ),
          const Divider(),
          ListTile(
            title: const Text('Memory reset'),
            subtitle: Text(
              channel == null
                  ? 'Select a channel first'
                  : 'Dangerous: wipe profiles on ${channel.label}',
            ),
            enabled: channel != null,
            leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            onTap: channel == null
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Memory reset?'),
                        content: const Text(
                          'This may delete profiles on the eUICC. Continue only if you know what you are doing.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Reset'),
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
                        const SnackBar(content: Text('Memory reset requested')),
                      );
                    }
                    ref.invalidate(profilesProvider);
                  },
          ),
          ListTile(
            title: const Text('Notifications'),
            subtitle: const Text('List / process pending eUICC notifications'),
            enabled: channel != null,
            onTap: channel == null
                ? null
                : () async {
                    final list = await ref.read(euiccBridgeProvider).listNotifications(
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
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No pending notifications'),
                          );
                        }
                        return ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final n = list[i];
                            return ListTile(
                              title: Text(n['title']?.toString() ?? 'Notification'),
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
