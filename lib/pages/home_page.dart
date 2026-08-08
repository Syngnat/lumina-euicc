import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
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
        title: Text(context.l10n.appTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.compatibility,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompatibilityPage()),
              );
            },
            icon: const Icon(Icons.verified_user_outlined),
          ),
          IconButton(
            tooltip: context.l10n.settings,
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
        key: const Key('newEsimButton'),
        onPressed: () => _openDownloadForCurrentChannel(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newEsim),
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
                        title: context.l10n.noEuiccFound,
                        body: context.l10n.noEuiccFoundDescription,
                        actionLabel: context.l10n.compatibilityCheck,
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
                          context.l10n.channels,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final c in channels)
                              ChoiceChip(
                                label: Text(context.l10n.euiccChannelLabel(c)),
                                selected: selected?.seId == c.seId &&
                                    selected?.slotId == c.slotId &&
                                    selected?.portId == c.portId,
                                onSelected: (_) {
                                  ref
                                      .read(selectedChannelKeyProvider.notifier)
                                      .state = c.key;
                                },
                                avatar: Icon(
                                  c.type.toLowerCase() == 'usb'
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
                  error: (e, _) => Text(context.l10n.channelError('$e')),
                ),
              ),
            ),
            profilesAsync.when(
              skipLoadingOnRefresh: false,
              skipLoadingOnReload: false,
              data: (profiles) {
                if (profiles.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyCard(
                        icon: '📭',
                        title: context.l10n.noProfilesYet,
                        body: context.l10n.noProfilesDescription,
                        actionLabel: context.l10n.newEsim,
                        onAction: () =>
                            _openDownloadForCurrentChannel(context, ref),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 96, top: 8),
                  sliver: SliverList.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final p = profiles[index];
                      return ProfileCard(
                        profile: p,
                        onEnable: selected == null
                            ? null
                            : () => _switch(ref, selected, p, true),
                        onDisable: selected == null
                            ? null
                            : () => _switch(ref, selected, p, false),
                        onDelete: selected == null
                            ? null
                            : () => _delete(
                                  context,
                                  ref,
                                  selected,
                                  p,
                                ),
                        onRename: selected == null
                            ? null
                            : () => _rename(
                                  context,
                                  ref,
                                  selected,
                                  p,
                                ),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(context.l10n.profilesLoadError('$e')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDownloadForCurrentChannel(
    BuildContext context,
    WidgetRef ref,
  ) async {
    debugPrint('[LuminaAddProfile] tap');
    var channel = ref.read(selectedChannelProvider);

    if (channel == null) {
      debugPrint('[LuminaAddProfile] waiting_for_channel_probe');
      try {
        await ref.read(channelsProvider.future);
      } catch (error) {
        debugPrint(
          '[LuminaAddProfile] channel_probe_failed '
          'errorType=${error.runtimeType}',
        );
        if (context.mounted) {
          _showAddProfileMessage(
            context,
            context.l10n.channelError('$error'),
          );
        }
        return;
      }
      if (!context.mounted) return;
      channel = ref.read(selectedChannelProvider);
    }

    if (channel == null) {
      debugPrint('[LuminaAddProfile] no_channel');
      _showAddProfileMessage(context, context.l10n.noEuiccFoundDescription);
      return;
    }

    debugPrint(
      '[LuminaAddProfile] opening_download '
      'slot=${channel.slotId} port=${channel.portId}',
    );
    try {
      await _openDownload(context, ref, channel);
    } catch (error) {
      debugPrint(
        '[LuminaAddProfile] navigation_failed '
        'errorType=${error.runtimeType}',
      );
      if (context.mounted) {
        _showAddProfileMessage(
          context,
          context.l10n.channelError('$error'),
        );
      }
    }
  }

  void _showAddProfileMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDownload(
    BuildContext context,
    WidgetRef ref,
    EuiccChannelInfo channel,
  ) async {
    final downloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DownloadPage(channel: channel)),
    );
    if (downloaded == true && context.mounted) {
      ref.invalidate(profilesProvider);
    }
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
        title: Text(context.l10n.deleteProfileQuestion),
        content: Text(context.l10n.deleteProfileConfirmation(profile.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.delete)),
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
        title: Text(context.l10n.renameProfile),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: context.l10n.displayName),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.l10n.save),
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
