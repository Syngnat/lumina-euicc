import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/euicc_models.dart';
import '../models/profile_reminder.dart';
import '../services/providers.dart';
import '../widgets/channel_switcher.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_card.dart';
import '../widgets/euicc_identity_strip.dart';
import '../widgets/micro_data_dialog.dart';
import '../widgets/profile_card.dart';
import '../widgets/profiles_section_header.dart';
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
    final sizeEstimator = ref.watch(profileSizeEstimatorProvider).valueOrNull;
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
                      DashboardHeader(
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
                            : ChannelSwitcher(
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
                      EuiccIdentityStrip(
                        info: euiccInfoAsync.valueOrNull,
                        infoLoading: euiccInfoAsync.isLoading,
                        onReminders: selected == null
                            ? null
                            : () => _showReminders(
                                  context,
                                  ref,
                                  profilesAsync.valueOrNull ?? const [],
                                ),
                        onAdd: () =>
                            _openDownloadForCurrentChannel(context, ref),
                      ),
                      if (selected != null) ...[
                        const SizedBox(height: 11),
                        ProfilesSectionHeader(count: profileCount),
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
                    child: EmptyCard(
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
                          child: EmptyCard(
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
                              estimatedSizeBytes: sizeEstimator?.estimateBytes(
                                provider: p.provider,
                                profileName: p.name,
                                eid: euiccInfoAsync.valueOrNull?.eid ?? '',
                              ),
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
                      child: EmptyCard(
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
    refreshEuiccData(ref);
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
      refreshEuiccData(ref);
      if (mounted) setState(() => _switchingIccid = null);
    }
  }

  Future<void> _showReminders(
    BuildContext context,
    WidgetRef ref,
    List<EuiccProfile> profiles,
  ) async {
    try {
      final reminders = <({EuiccProfile profile, ProfileReminder reminder})>[];
      for (final profile in profiles) {
        final reminder = await ref.read(
          profileReminderProvider(profile.iccid).future,
        );
        if (reminder != null) {
          reminders.add((profile: profile, reminder: reminder));
        }
      }
      reminders.sort((a, b) => a.reminder.at.compareTo(b.reminder.at));
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.keepAliveReminderCenterTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (reminders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(context.l10n.noKeepAliveReminders),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: reminders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = reminders[index];
                          final date = MaterialLocalizations.of(context)
                              .formatMediumDate(item.reminder.at);
                          final time =
                              MaterialLocalizations.of(context).formatTimeOfDay(
                            TimeOfDay.fromDateTime(item.reminder.at),
                          );
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.alarm_rounded),
                            title: Text(item.profile.name),
                            subtitle: Text(
                              context.l10n.reminderScheduledAt(date, time),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      debugPrint(
        '[LuminaReminders] list_failed errorType=${error.runtimeType}',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reminderScheduleFailed)),
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
        builder: (_) => MicroDataProgressDialog(
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