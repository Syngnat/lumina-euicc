import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/euicc_models.dart';
import '../services/providers.dart';
import '../widgets/profile_card.dart';
import 'compatibility_page.dart';
import 'download_page.dart';
import 'settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(channelsProvider);
    final profilesAsync = ref.watch(profilesProvider);
    final selected = ref.watch(selectedChannelProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lumina eUICC'),
        actions: [
          IconButton(
            tooltip: 'Compatibility',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompatibilityPage()),
              );
            },
            icon: const Icon(Icons.verified_user_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selected == null
            ? null
            : () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DownloadPage(channel: selected),
                  ),
                );
                ref.invalidate(profilesProvider);
              },
        icon: const Icon(Icons.add),
        label: const Text('New eSIM'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(channelsProvider);
          ref.invalidate(profilesProvider);
          await ref.read(profilesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: channelsAsync.when(
                  data: (channels) {
                    if (channels.isEmpty) {
                      return _EmptyCard(
                        icon: '📶',
                        title: 'No eUICC found',
                        body:
                            'Insert a compatible removable eUICC, or connect a USB CCID reader.',
                        actionLabel: 'Compatibility check',
                        onAction: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CompatibilityPage(),
                            ),
                          );
                        },
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Channels',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in channels)
                              ChoiceChip(
                                label: Text(c.label),
                                selected: selected?.seId == c.seId &&
                                    selected?.slotId == c.slotId &&
                                    selected?.portId == c.portId,
                                onSelected: (_) {
                                  ref.read(selectedChannelProvider.notifier).state = c;
                                  ref.invalidate(profilesProvider);
                                },
                                avatar: Icon(
                                  c.type == 'usb'
                                      ? Icons.usb
                                      : Icons.sim_card_outlined,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Channel error: $e'),
                ),
              ),
            ),
            profilesAsync.when(
              data: (profiles) {
                if (profiles.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyCard(
                        icon: '📭',
                        title: 'No profiles yet',
                        body: 'Download a profile with a QR / activation code.',
                        actionLabel: 'New eSIM',
                        onAction: selected == null
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DownloadPage(channel: selected),
                                  ),
                                );
                              },
                      ),
                    ),
                  );
                }
                return Consumer(
                  builder: (context, ref, _) {
                    final channel = ref.watch(selectedChannelProvider);
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 96, top: 8),
                      sliver: SliverList.builder(
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final p = profiles[index];
                          return ProfileCard(
                            profile: p,
                            onEnable: channel == null
                                ? null
                                : () => _switch(ref, channel, p, true),
                            onDisable: channel == null
                                ? null
                                : () => _switch(ref, channel, p, false),
                            onDelete: channel == null
                                ? null
                                : () => _delete(context, ref, channel, p),
                            onRename: channel == null
                                ? null
                                : () => _rename(context, ref, channel, p),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Failed to load profiles: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switch(
    WidgetRef ref,
    EuiccChannelInfo channel,
    EuiccProfile profile,
    bool enable,
  ) async {
    final bridge = ref.read(euiccBridgeProvider);
    await bridge.switchProfile(
      slotId: channel.slotId,
      portId: channel.portId,
      seId: channel.seId,
      iccid: profile.iccid,
      enable: enable,
    );
    ref.invalidate(profilesProvider);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    EuiccChannelInfo channel,
    EuiccProfile profile,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete profile?'),
        content: Text('Delete “${profile.name}”? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    final bridge = ref.read(euiccBridgeProvider);
    await bridge.deleteProfile(
      slotId: channel.slotId,
      portId: channel.portId,
      seId: channel.seId,
      iccid: profile.iccid,
    );
    ref.invalidate(profilesProvider);
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    EuiccChannelInfo channel,
    EuiccProfile profile,
  ) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final bridge = ref.read(euiccBridgeProvider);
    await bridge.renameProfile(
      slotId: channel.slotId,
      portId: channel.portId,
      seId: channel.seId,
      iccid: profile.iccid,
      name: name,
    );
    ref.invalidate(profilesProvider);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    this.onAction,
  });

  final String icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
