import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_reminder.dart';
import '../services/providers.dart';
import '../widgets/profile_card.dart';
import 'compatibility_page.dart';
import 'download_page.dart';
import 'settings_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? _switchingIccid;

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final profilesAsync = ref.watch(profilesProvider);
    final selected = ref.watch(selectedChannelProvider);
    final euiccInfoAsync = ref.watch(euiccInfoProvider);
    final profileCount = profilesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Column(
                    children: [
                      _DashboardHeader(
                        onCompatibility: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CompatibilityPage(),
                          ),
                        ),
                        onRefresh: _refresh,
                        onSettings: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      channelsAsync.when(
                        data: (channels) => channels.isEmpty
                            ? const SizedBox.shrink()
                            : _ChannelSwitcher(
                                channels: channels,
                                selected: selected,
                                selectedProfileCount: profileCount,
                                onSelected: (channel) {
                                  ref
                                      .read(
                                        selectedChannelKeyProvider.notifier,
                                      )
                                      .state = channel.key;
                                },
                              ),
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 10),
                      _EuiccIdentityStrip(
                        info: euiccInfoAsync.valueOrNull,
                        infoLoading: euiccInfoAsync.isLoading,
                        onNotifications: selected == null
                            ? null
                            : () => _showNotifications(context, ref, selected),
                        onAdd: () =>
                            _openDownloadForCurrentChannel(context, ref),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 11),
                        _ProfilesSectionHeader(count: profileCount),
                        const SizedBox(height: 7),
                      ],
                    ],
                  ),
                ),
              ),
              if (channelsAsync.valueOrNull?.isEmpty == true)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _EmptyCard(
                      icon: '📶',
                      title: context.l10n.noEuiccFound,
                      body: context.l10n.noEuiccFoundDescription,
                      actionLabel: context.l10n.compatibilityCheck,
                      onAction: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CompatibilityPage(),
                        ),
                      ),
                    ),
                  ),
                )
              else
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
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      sliver: SliverList.builder(
                        itemCount: profiles.length,
                        itemBuilder: (context, index) {
                          final p = profiles[index];
                          final reminderAsync =
                              ref.watch(profileReminderProvider(p.iccid));
                          final reminder = reminderAsync.valueOrNull;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == profiles.length - 1 ? 0 : 7,
                            ),
                            child: ProfileCard(
                              profile: p,
                              reminder: reminder,
                              reminderLoading: reminderAsync.isLoading,
                              isSwitching: _switchingIccid == p.iccid,
                              switchLocked: _switchingIccid != null,
                              onEnable: selected == null
                                  ? null
                                  : () => _switch(selected, p, true),
                              onDisable: selected == null
                                  ? null
                                  : () => _switch(selected, p, false),
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
                              onSetReminder: reminderAsync.isLoading
                                  ? null
                                  : () => _setReminder(
                                        context,
                                        ref,
                                        p,
                                        reminder,
                                      ),
                              onCancelReminder: reminder == null
                                  ? null
                                  : () => _cancelReminder(context, ref, p),
                              onMicroDataKeepAlive:
                                  selected?.type.toLowerCase() == 'omapi'
                                      ? () => _runMicroDataKeepAlive(
                                            context,
                                            ref,
                                            selected!,
                                            p,
                                          )
                                      : null,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _EmptyCard(
                        icon: '🔄',
                        title: error is PlatformException &&
                                error.code == 'euicc_channel_unavailable'
                            ? context.l10n.channelReconnectingTitle
                            : context.l10n.profilesUnavailableTitle,
                        body: error is PlatformException &&
                                error.code == 'euicc_channel_unavailable'
                            ? context.l10n.channelReconnectingDescription
                            : context.l10n.profilesUnavailableDescription,
                        actionLabel: context.l10n.retry,
                        onAction: _refresh,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(channelsProvider);
    ref.invalidate(profilesProvider);
    ref.invalidate(euiccInfoProvider);
    try {
      await ref.read(profilesProvider.future);
    } catch (_) {
      // The page renders the actionable provider error state.
    }
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
    EuiccChannelInfo channel,
    EuiccProfile profile,
    bool enable,
  ) async {
    if (_switchingIccid != null) return;
    setState(() => _switchingIccid = profile.iccid);
    final bridge = ref.read(euiccBridgeProvider);
    try {
      await bridge.switchProfile(
        slotId: channel.slotId,
        portId: channel.portId,
        seId: channel.seId,
        iccid: profile.iccid,
        enable: enable,
      );
    } catch (error) {
      debugPrint(
        '[LuminaProfile] switch_failed '
        'errorType=${error.runtimeType} slot=${channel.slotId} '
        'port=${channel.portId}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.l10n.profileSwitchFailed)),
          );
      }
    } finally {
      ref.invalidate(channelsProvider);
      ref.invalidate(profilesProvider);
      ref.invalidate(euiccInfoProvider);
      if (mounted) setState(() => _switchingIccid = null);
    }
  }

  Future<void> _showNotifications(
    BuildContext context,
    WidgetRef ref,
    EuiccChannelInfo channel,
  ) async {
    try {
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
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.l10n.noPendingNotifications),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final notification = list[index];
              return ListTile(
                title: Text(
                  notification['title']?.toString() ??
                      context.l10n.notification,
                ),
                subtitle: Text(notification['detail']?.toString() ?? ''),
              );
            },
          );
        },
      );
    } catch (error) {
      debugPrint(
        '[LuminaNotifications] list_failed errorType=${error.runtimeType}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profilesUnavailableDescription)),
        );
      }
    }
  }

  Future<void> _runMicroDataKeepAlive(
    BuildContext context,
    WidgetRef ref,
    EuiccChannelInfo channel,
    EuiccProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.microDataKeepAliveConfirmTitle),
        content: Text(
          context.l10n.microDataKeepAliveConfirmDescription(profile.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.microDataKeepAliveProceed),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final bridge = ref.read(euiccBridgeProvider);
    try {
      final permissionGranted = await bridge.requestPhoneStatePermission();
      if (!context.mounted) return;
      if (!permissionGranted) {
        await _showMicroDataFailure(
          context,
          context.l10n.microDataPermissionDenied,
        );
        return;
      }

      final outcome = await showDialog<Object?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _MicroDataProgressDialog(
          operation: () => bridge.runMicroDataKeepAlive(
            slotId: channel.slotId,
            portId: channel.portId,
            seId: channel.seId,
            iccid: profile.iccid,
          ),
        ),
      );
      ref.invalidate(channelsProvider);
      ref.invalidate(profilesProvider);
      if (!context.mounted) return;

      if (outcome is Exception) {
        await _showMicroDataFailure(
          context,
          context.l10n.microDataGenericFailure,
        );
        return;
      }
      final result = outcome as MicroDataKeepAliveResult?;
      if (result == null) return;
      if (!result.restored) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(context.l10n.microDataRestoreFailedTitle),
            content: Text(context.l10n.microDataRestoreFailedDescription),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.close),
              ),
            ],
          ),
        );
      } else if (result.connected) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            icon: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(context.l10n.microDataKeepAliveSuccessTitle),
            content: Text(
              context.l10n.microDataKeepAliveSuccessDescription(
                result.httpStatus ?? 0,
                result.responseBodyBytes ?? 0,
                result.maxResponseBodyBytes,
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.close),
              ),
            ],
          ),
        );
      } else {
        await _showMicroDataFailure(
          context,
          _microDataFailureReason(context, result.failureCode),
        );
      }
    } catch (error) {
      debugPrint(
        '[LuminaMicroData] operation_failed errorType=${error.runtimeType}',
      );
      if (context.mounted) {
        await _showMicroDataFailure(
          context,
          context.l10n.microDataGenericFailure,
        );
      }
    }
  }

  String _microDataFailureReason(BuildContext context, String? code) =>
      switch (code) {
        'permissionDenied' => context.l10n.microDataPermissionDenied,
        'unsupportedChannel' => context.l10n.microDataUnsupportedChannel,
        'busy' => context.l10n.microDataBusy,
        'cancelled' => context.l10n.microDataCancelled,
        'profileNotFound' => context.l10n.microDataProfileNotFound,
        'channelUnavailable' => context.l10n.microDataChannelUnavailable,
        'activationFailed' => context.l10n.microDataActivationFailed,
        'subscriptionUnavailable' =>
          context.l10n.microDataSubscriptionUnavailable,
        'cellularNetworkUnavailable' =>
          context.l10n.microDataCellularNetworkUnavailable,
        'connectionFailed' ||
        'invalidHttpResponse' ||
        'responseLimitExceeded' =>
          context.l10n.microDataConnectionFailed,
        _ => context.l10n.microDataGenericFailure,
      };

  Future<void> _showMicroDataFailure(
    BuildContext context,
    String reason,
  ) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          title: Text(context.l10n.microDataKeepAliveFailedTitle),
          content: Text(
            context.l10n.microDataKeepAliveFailedDescription(reason),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
          ],
        ),
      );

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
    try {
      await bridge.cancelProfileReminder(profile.iccid);
    } catch (error) {
      debugPrint(
        '[LuminaReminder] cleanup_after_delete_failed '
        'errorType=${error.runtimeType}',
      );
    }
    ref.invalidate(profileReminderProvider(profile.iccid));
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
    try {
      await bridge.renameProfileReminder(
        iccid: profile.iccid,
        profileName: name,
      );
    } catch (error) {
      debugPrint(
        '[LuminaReminder] rename_sync_failed errorType=${error.runtimeType}',
      );
    }
    ref.invalidate(profilesProvider);
  }

  Future<void> _setReminder(
    BuildContext context,
    WidgetRef ref,
    EuiccProfile profile,
    ProfileReminder? existing,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fallback = DateTime(now.year, now.month, now.day + 1, 9);
    final initial = existing?.at.isAfter(now) == true ? existing!.at : fallback;
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: today,
      lastDate: DateTime(now.year + 20, 12, 31),
      helpText: context.l10n.selectReminderDate,
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: context.l10n.selectReminderTime,
    );
    if (time == null || !context.mounted) return;

    final at =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!at.isAfter(DateTime.now())) {
      _showReminderMessage(context, context.l10n.reminderMustBeFuture);
      return;
    }

    final bridge = ref.read(euiccBridgeProvider);
    try {
      try {
        await bridge.requestReminderNotificationPermission();
      } catch (error) {
        debugPrint(
          '[LuminaReminder] notification_permission_failed '
          'errorType=${error.runtimeType}',
        );
      }
      final scheduled = await bridge.scheduleProfileReminder(
        iccid: profile.iccid,
        profileName: profile.name,
        at: at,
      );
      ref.invalidate(profileReminderProvider(profile.iccid));
      if (!context.mounted) return;
      _showReminderMessage(context, context.l10n.reminderSaved);
      if (!scheduled.notificationPermissionGranted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.reminderNotificationsDeniedTitle),
            content: Text(context.l10n.reminderNotificationsDeniedDescription),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.close),
              ),
            ],
          ),
        );
      } else if (!scheduled.exact) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.l10n.exactAlarmUnavailableTitle),
            content: Text(context.l10n.exactAlarmUnavailableDescription),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.openAlarmSettings),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await bridge.openExactAlarmSettings();
        }
      }
    } catch (error) {
      debugPrint(
        '[LuminaReminder] schedule_failed errorType=${error.runtimeType}',
      );
      if (context.mounted) {
        _showReminderMessage(context, context.l10n.reminderScheduleFailed);
      }
    }
  }

  Future<void> _cancelReminder(
    BuildContext context,
    WidgetRef ref,
    EuiccProfile profile,
  ) async {
    try {
      await ref.read(euiccBridgeProvider).cancelProfileReminder(profile.iccid);
      ref.invalidate(profileReminderProvider(profile.iccid));
      if (context.mounted) {
        _showReminderMessage(context, context.l10n.reminderCancelled);
      }
    } catch (error) {
      debugPrint(
        '[LuminaReminder] cancel_failed errorType=${error.runtimeType}',
      );
      if (context.mounted) {
        _showReminderMessage(context, context.l10n.reminderScheduleFailed);
      }
    }
  }

  void _showReminderMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
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

class _ChannelSwitcher extends StatelessWidget {
  const _ChannelSwitcher({
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

class _EuiccIdentityStrip extends StatelessWidget {
  const _EuiccIdentityStrip({
    required this.info,
    required this.infoLoading,
    required this.onNotifications,
    required this.onAdd,
  });

  final EuiccInfo? info;
  final bool infoLoading;
  final VoidCallback? onNotifications;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final eid = info?.eid.trim() ?? '';
    final freeMemory = info?.freeNonVolatileMemory ?? 0;
    final eidLabel = eid.isEmpty ? context.l10n.eidUnavailable : _maskEid(eid);
    final memoryLabel = freeMemory > 0
        ? context.l10n.freeMemory(_formatStorage(freeMemory))
        : context.l10n.freeMemoryUnknown;

    return SizedBox(
      height: 73,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 9, 12, 9),
              decoration: BoxDecoration(
                color: const Color(0xFF173F3A),
                borderRadius: BorderRadius.circular(17),
              ),
              child: infoLoading
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8FD8CC),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.fingerprint_rounded,
                              color: Color(0xFF8FD8CC),
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                eidLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.storage_rounded,
                              color: Color(0xFF8FD8CC),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                memoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: const Color(0xFFD7ECE8),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 8),
          _DashboardSquareAction(
            tooltip: context.l10n.notifications,
            icon: Icons.notifications_none_rounded,
            onPressed: onNotifications,
          ),
          const SizedBox(width: 8),
          _DashboardSquareAction(
            key: const Key('newEsimButton'),
            tooltip: context.l10n.newEsim,
            icon: Icons.add_rounded,
            emphasized: true,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}

class _DashboardSquareAction extends StatelessWidget {
  const _DashboardSquareAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.emphasized = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: emphasized ? scheme.primary : scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(17),
      elevation: emphasized ? 1 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 54,
            height: 73,
            child: Icon(
              icon,
              color: emphasized ? scheme.onPrimary : scheme.onSurface,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilesSectionHeader extends StatelessWidget {
  const _ProfilesSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          context.l10n.profilesSectionTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
        const Spacer(),
        Icon(Icons.alarm_outlined, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          context.l10n.localReminders,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

String _maskEid(String eid) {
  if (eid.length <= 12) return eid;
  return '${eid.substring(0, 8)}••••••${eid.substring(eid.length - 6)}';
}

String _formatStorage(int bytes) {
  if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KiB';
  return '$bytes B';
}

class _MicroDataProgressDialog extends StatefulWidget {
  const _MicroDataProgressDialog({required this.operation});

  final Future<MicroDataKeepAliveResult> Function() operation;

  @override
  State<_MicroDataProgressDialog> createState() =>
      _MicroDataProgressDialogState();
}

class _MicroDataProgressDialogState extends State<_MicroDataProgressDialog> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    Object? outcome;
    try {
      outcome = await widget.operation();
    } on Exception catch (error) {
      outcome = error;
    }
    if (mounted) Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(context.l10n.microDataKeepAliveRunningTitle),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  context.l10n.microDataKeepAliveRunningDescription,
                ),
              ),
            ],
          ),
        ),
      );
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
