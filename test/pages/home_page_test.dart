import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/pages/download_page.dart';
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

  testWidgets('a reconnect failure is actionable and never exposes internals',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '0',
      label: 'Phone slot',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [channel]
      ..profiles = const [_profile];
    var channelReady = false;
    bridge.listProfilesHandler = ({
      required slotId,
      required portId,
      required seId,
    }) async {
      if (!channelReady) {
        throw PlatformException(
          code: 'euicc_channel_unavailable',
          message: 'EuiccChannelNotFoundException',
        );
      }
      return bridge.profiles;
    };
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    expect(find.text('eUICC channel is reconnecting'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('PlatformException'), findsNothing);
    expect(find.textContaining('EuiccChannelNotFoundException'), findsNothing);

    channelReady = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('giffgaff'), findsWidgets);
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

  testWidgets('the add-profile FAB opens download with the current channel',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '0',
      label: 'Phone slot 1',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [channel]
      ..profiles = const [_profile];
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    expect(find.text('giffgaff'), findsWidgets);

    final fab = tester.widget<FloatingActionButton>(
      find.byKey(const Key('newEsimButton')),
    );
    expect(fab.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('newEsimButton')));
    await tester.pumpAndSettle();

    final page = tester.widget<DownloadPage>(find.byType(DownloadPage));
    expect(page.channel.key, channel.key);
  });

  testWidgets('a profile keep-alive reminder reaches the native scheduler',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '0',
      label: 'Phone slot 1',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [channel]
      ..profiles = const [_profile];
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep-alive reminder'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(bridge.scheduleReminderCalls, 1);
    expect(
        bridge.reminders[_profile.iccid]?.at.isAfter(DateTime.now()), isTrue);
    expect(find.text('Keep-alive reminder saved'), findsOneWidget);
  });

  testWidgets(
      'micro-data action confirms, binds the selected channel and reports success',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 1,
      portId: 2,
      seId: '3',
      label: 'Phone slot 1',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [channel]
      ..profiles = const [_profile];
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('micro-data-keep-alive-1')));
    await tester.pumpAndSettle();

    expect(find.text('Use cellular data once?'), findsOneWidget);
    expect(find.textContaining('cannot guarantee keep-alive status'),
        findsOneWidget);
    await tester.tap(find.text('Connect once'));
    await tester.pumpAndSettle();

    expect(bridge.requestPhoneStatePermissionCalls, 1);
    expect(bridge.microDataKeepAliveCalls, 1);
    expect(
      bridge.lastMicroDataChannel,
      (slotId: 1, portId: 2, seId: '3'),
    );
    expect(find.text('Micro-data connection succeeded'), findsOneWidget);
    expect(find.textContaining('0/1024 bytes'), findsOneWidget);
    expect(
        find.textContaining('released its dedicated cellular-network request'),
        findsOneWidget);
  });

  testWidgets('micro-data action stops when phone permission is denied',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: '0',
      label: 'Phone slot',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [channel]
      ..profiles = const [_profile]
      ..phoneStatePermissionGranted = false;
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('micro-data-keep-alive-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect once'));
    await tester.pumpAndSettle();

    expect(bridge.microDataKeepAliveCalls, 0);
    expect(find.text('Micro-data connection failed'), findsOneWidget);
    expect(find.textContaining('Phone permission is needed'), findsOneWidget);
  });

  testWidgets('the add-profile FAB waits for the initial channel probe',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '0',
      label: 'Phone slot 1',
      type: 'omapi',
    );
    final channels = Completer<List<EuiccChannelInfo>>();
    final bridge = _DeferredChannelsBridge(channels.future)
      ..profiles = const [_profile];
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pump();
    await tester.tap(find.byKey(const Key('newEsimButton')));
    await tester.pump();

    channels.complete(const [channel]);
    await tester.pumpAndSettle();

    final page = tester.widget<DownloadPage>(find.byType(DownloadPage));
    expect(page.channel.key, channel.key);
  });

  testWidgets('the add-profile FAB explains an empty channel list',
      (tester) async {
    final bridge = FakeEuiccBridge();
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newEsimButton')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(
          'Insert a compatible removable eUICC, or connect a USB CCID reader.',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the add-profile FAB reports a failed channel probe',
      (tester) async {
    final bridge = _FailingChannelsBridge();
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newEsimButton')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(
          'Channel error: Bad state: channel probe failed',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the add-profile FAB uses the second selected channel',
      (tester) async {
    const first = EuiccChannelInfo(
      slotId: 0,
      portId: 0,
      seId: 'first',
      label: 'First slot',
      type: 'omapi',
    );
    const second = EuiccChannelInfo(
      slotId: 1,
      portId: 2,
      seId: 'second',
      label: 'Second slot',
      type: 'usb',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [first, second]
      ..profiles = const [_profile];
    addTearDown(bridge.dispose);

    await _pumpHome(tester, bridge);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ChoiceChip).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newEsimButton')));
    await tester.pumpAndSettle();

    final page = tester.widget<DownloadPage>(find.byType(DownloadPage));
    expect(page.channel.key, second.key);
  });

  testWidgets('the add-profile FAB reports a navigation failure',
      (tester) async {
    const channel = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '0',
      label: 'Phone slot 1',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()..channels = const [channel];
    addTearDown(bridge.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Localizations(
            locale: const Locale('en'),
            delegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Theme(
                data: ThemeData(),
                child: ScaffoldMessenger(
                  child: Overlay(
                    initialEntries: [
                      OverlayEntry(builder: (_) => const HomePage()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newEsimButton')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.textContaining(
          'Channel error: Navigator operation requested',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

List<EuiccProfile> bridgeProfilesFor(int slotId, EuiccProfile profileA) =>
    slotId == 0 ? [profileA] : const [];

const _profile = EuiccProfile(
  iccid: '8944100000000000001',
  name: 'giffgaff',
  provider: 'giffgaff',
  enabled: false,
  profileClass: 'operational',
  seq: 1,
);

Future<void> _pumpHome(WidgetTester tester, FakeEuiccBridge bridge) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: const MaterialApp(home: HomePage()),
      ),
    );

class _DeferredChannelsBridge extends FakeEuiccBridge {
  _DeferredChannelsBridge(this.result);

  final Future<List<EuiccChannelInfo>> result;

  @override
  Future<List<EuiccChannelInfo>> listChannels() => result;
}

class _FailingChannelsBridge extends FakeEuiccBridge {
  @override
  Future<List<EuiccChannelInfo>> listChannels() async {
    throw StateError('channel probe failed');
  }
}
