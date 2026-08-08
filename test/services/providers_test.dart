import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}
