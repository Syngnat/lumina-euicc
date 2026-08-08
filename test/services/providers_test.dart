import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

void main() {
  test('profiles use a current channel when the selected channel disappears',
      () async {
    const stale = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '1',
      label: 'Removed channel',
      type: 'omapi',
    );
    const current = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '2',
      label: 'Current channel',
      type: 'usb',
    );
    final bridge = FakeEuiccBridge()..channels = const [current];
    final container = ProviderContainer(
      overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(() async {
      container.dispose();
      await bridge.dispose();
    });
    container.read(selectedChannelKeyProvider.notifier).state = stale.key;

    await container.read(profilesProvider.future);

    expect(
      bridge.profileRequests,
      const [(slotId: 1, portId: 0, seId: '2')],
    );
    expect(container.read(selectedChannelProvider), same(current));
  });

  test('an empty channel list clears the active channel and skips profiles',
      () async {
    const stale = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '1',
      label: 'Removed channel',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge();
    final container = ProviderContainer(
      overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(() async {
      container.dispose();
      await bridge.dispose();
    });
    container.read(selectedChannelKeyProvider.notifier).state = stale.key;

    expect(await container.read(profilesProvider.future), isEmpty);
    expect(container.read(selectedChannelProvider), isNull);
    expect(bridge.profileRequests, isEmpty);
  });

  test('a transient missing channel after a card switch is retried once',
      () async {
    const channel = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '0',
      label: 'Phone slot',
      type: 'omapi',
    );
    const replacementProfile = EuiccProfile(
      iccid: '8986000000000000001',
      name: 'Replacement profile',
      provider: 'Replacement provider',
      enabled: true,
      profileClass: 'operational',
      seq: 1,
    );
    final bridge = _TransientChannelBridge(
      channel: channel,
      replacementProfile: replacementProfile,
    );
    final container = ProviderContainer(
      overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(() async {
      container.dispose();
      await bridge.dispose();
    });
    final subscription = container.listen(
      profilesProvider,
      (_, __) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final profiles = await container.read(profilesProvider.future);

    expect(profiles, const [replacementProfile]);
    expect(bridge.channelRequests, 1);
    expect(
      bridge.profileRequests,
      const [
        (slotId: 0, portId: 0, seId: '0'),
        (slotId: 0, portId: 0, seId: '0'),
      ],
    );
  });
}

class _TransientChannelBridge extends FakeEuiccBridge {
  _TransientChannelBridge({
    required this.channel,
    required this.replacementProfile,
  });

  final EuiccChannelInfo channel;
  final EuiccProfile replacementProfile;
  int channelRequests = 0;
  var _profileRequests = 0;

  @override
  Future<List<EuiccChannelInfo>> listChannels() async {
    channelRequests += 1;
    return [channel];
  }

  @override
  Future<List<EuiccProfile>> listProfiles({
    required int slotId,
    required int portId,
    required String seId,
  }) async {
    profileRequests.add((slotId: slotId, portId: portId, seId: seId));
    _profileRequests += 1;
    if (_profileRequests == 1) {
      throw PlatformException(code: 'euicc_channel_unavailable');
    }
    return [replacementProfile];
  }
}
