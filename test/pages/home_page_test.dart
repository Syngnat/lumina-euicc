import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/pages/home_page.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

void main() {
  testWidgets('profiles are hidden while a refreshed channel is loading',
      (tester) async {
    const channelA = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '1',
      label: 'Channel A',
      type: 'omapi',
    );
    const channelB = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '2',
      label: 'Channel B',
      type: 'usb',
    );
    const profileA = EuiccProfile(
      iccid: 'profile-a',
      name: 'Profile A',
      provider: 'Provider A',
      enabled: false,
      profileClass: 'operational',
      seq: 1,
    );
    const profileB = EuiccProfile(
      iccid: 'profile-b',
      name: 'Profile B',
      provider: 'Provider B',
      enabled: false,
      profileClass: 'operational',
      seq: 1,
    );
    final refreshedProfiles = Completer<List<EuiccProfile>>();
    var blockRefreshedProfiles = false;
    final bridge = FakeEuiccBridge()
      ..channels = const [channelA]
      ..profiles = const [profileA]
      ..listProfilesHandler = ({
        required slotId,
        required portId,
        required seId,
      }) {
        if (blockRefreshedProfiles && slotId == channelB.slotId) {
          return refreshedProfiles.future;
        }
        return Future.value(bridgeProfilesFor(slotId, profileA));
      };
    addTearDown(bridge.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile A'), findsOneWidget);

    bridge.channels = const [channelB];
    blockRefreshedProfiles = true;
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    container.invalidate(channelsProvider);
    container.invalidate(profilesProvider);
    await container.read(channelsProvider.future);
    await tester.pump();

    expect(
      find.text('USB reader · slot 1 · port 0 · SE 2'),
      findsOneWidget,
    );
    expect(find.text('Profile A'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    refreshedProfiles.complete(const [profileB]);
    await tester.pumpAndSettle();
    expect(find.text('Profile B'), findsOneWidget);
  });

  testWidgets('a successful download from the empty state refreshes profiles',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '1',
      label: 'Test eUICC',
      type: 'omapi',
    );
    const downloadedProfile = EuiccProfile(
      iccid: '8901000000000000001',
      name: 'Downloaded profile',
      provider: 'Test provider',
      enabled: false,
      profileClass: 'operational',
      seq: 1,
    );
    final bridge = FakeEuiccBridge()..channels = const [channel];
    addTearDown(bridge.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: const MaterialApp(home: HomePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No profiles yet'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'New eSIM'));
    await tester.pumpAndSettle();
    expect(find.text('Download profile'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      r'LPA:1$smdp.example.com$matching-id',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start download'));
    await tester.pump();
    expect(bridge.downloadCalls, 1);

    bridge.profiles = const [downloadedProfile];
    bridge.taskEventsController.add(
      const DownloadTaskEvent(
        taskId: 'task-1',
        phase: 'done',
        progress: 1,
        done: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Downloaded profile'), findsOneWidget);
  });
}

List<EuiccProfile> bridgeProfilesFor(int slotId, EuiccProfile profileA) =>
    slotId == 0 ? [profileA] : const [];
