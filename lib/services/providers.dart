import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/euicc_models.dart';
import 'euicc_bridge.dart';

final euiccBridgeProvider = Provider<EuiccBridge>((ref) => EuiccBridge());

final channelsProvider = FutureProvider<List<EuiccChannelInfo>>((ref) async {
  final bridge = ref.watch(euiccBridgeProvider);
  return bridge.listChannels();
});

final selectedChannelProvider = StateProvider<EuiccChannelInfo?>((ref) => null);

final profilesProvider = FutureProvider.autoDispose<List<EuiccProfile>>((ref) async {
  final bridge = ref.watch(euiccBridgeProvider);
  final channel = ref.watch(selectedChannelProvider);
  final channels = await ref.watch(channelsProvider.future);
  final active = channel ?? (channels.isEmpty ? null : channels.first);
  if (active == null) return const [];
  if (channel == null) {
    // seed selection once
    Future.microtask(() => ref.read(selectedChannelProvider.notifier).state = active);
  }
  return bridge.listProfiles(
    slotId: active.slotId,
    portId: active.portId,
    seId: active.seId,
  );
});
