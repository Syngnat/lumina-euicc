import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/euicc_models.dart';
import 'euicc_bridge.dart';

final euiccBridgeProvider = Provider<EuiccBridge>((ref) => EuiccBridge());

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

final profilesProvider =
    FutureProvider.autoDispose<List<EuiccProfile>>((ref) async {
  final bridge = ref.watch(euiccBridgeProvider);
  final selectedKey = ref.watch(selectedChannelKeyProvider);
  final channels = await ref.watch(channelsProvider.future);
  final active = _currentChannel(channels, selectedKey);
  if (active == null) return const [];
  return bridge.listProfiles(
    slotId: active.slotId,
    portId: active.portId,
    seId: active.seId,
  );
});

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
