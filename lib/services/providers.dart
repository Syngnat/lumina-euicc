import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/euicc_models.dart';
import '../models/profile_reminder.dart';
import 'app_update_service.dart';
import 'euicc_bridge.dart';
import 'profile_size_estimator.dart';

final euiccBridgeProvider = Provider<EuiccBridge>((ref) => EuiccBridge());

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return GitHubAppUpdateService(bridge: ref.watch(euiccBridgeProvider));
});

final profileSizeEstimatorProvider = FutureProvider<ProfileSizeEstimator>(
  (ref) => ProfileSizeEstimator.load(),
);

final channelsProvider = FutureProvider<List<EuiccChannelInfo>>((ref) async {
  final bridge = ref.watch(euiccBridgeProvider);
  return bridge.listChannels();
});

typedef EuiccChannelKey = ({int slotId, int portId, String seId});

extension EuiccChannelIdentity on EuiccChannelInfo {
  EuiccChannelKey get key => (slotId: slotId, portId: portId, seId: seId);
}

final selectedChannelKeyProvider =
    StateProvider<EuiccChannelKey?>((ref) => null);

final selectedChannelProvider = Provider<EuiccChannelInfo?>((ref) {
  final channels = ref.watch(channelsProvider).valueOrNull;
  final selectedKey = ref.watch(selectedChannelKeyProvider);
  return _currentChannel(channels ?? const [], selectedKey);
});

final euiccInfoProvider = FutureProvider.autoDispose<EuiccInfo?>((ref) async {
  final channel = ref.watch(selectedChannelProvider);
  if (channel == null) return null;
  final raw = await ref.watch(euiccBridgeProvider).getEuiccInfo(
        slotId: channel.slotId,
        portId: channel.portId,
        seId: channel.seId,
      );
  return EuiccInfo.fromMap(raw);
});

final profileReminderProvider =
    FutureProvider.autoDispose.family<ProfileReminder?, String>((ref, iccid) {
  return ref.watch(euiccBridgeProvider).getProfileReminder(iccid);
});

final profilesProvider =
    FutureProvider.autoDispose<List<EuiccProfile>>((ref) async {
  final bridge = ref.watch(euiccBridgeProvider);
  final selectedKey = ref.watch(selectedChannelKeyProvider);
  final channels = await ref.watch(channelsProvider.future);
  final active = _currentChannel(channels, selectedKey);
  if (active == null) return const [];
  try {
    return await _listProfiles(bridge, active);
  } on PlatformException catch (error) {
    if (error.code != 'euicc_channel_unavailable') rethrow;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _listProfiles(bridge, active);
  }
});

Future<List<EuiccProfile>> _listProfiles(
  EuiccBridge bridge,
  EuiccChannelInfo channel,
) =>
    bridge.listProfiles(
      slotId: channel.slotId,
      portId: channel.portId,
      seId: channel.seId,
    );

EuiccChannelInfo? _currentChannel(
  List<EuiccChannelInfo> channels,
  EuiccChannelKey? selectedKey,
) {
  if (channels.isEmpty) return null;
  if (selectedKey != null) {
    for (final channel in channels) {
      if (channel.key == selectedKey) return channel;
    }
  }
  return channels.first;
}
