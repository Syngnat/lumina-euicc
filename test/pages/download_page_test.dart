import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/pages/download_page.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

const _channel = EuiccChannelInfo(
  slotId: 0,
  portId: 0,
  seId: '1',
  label: 'Test eUICC',
  type: 'omapi',
);

void main() {
  testWidgets('a scanned QR code fills the activation code field',
      (tester) async {
    final bridge = FakeEuiccBridge()
      ..scanQrResult = r'LPA:1$scan.example.com$matching-id';
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Scan QR'));
    await tester.pump();

    final activationCode =
        tester.widget<TextField>(find.byType(TextField).first);
    expect(
      activationCode.controller!.text,
      r'LPA:1$scan.example.com$matching-id',
    );
  });

  testWidgets('a QR scanner failure is shown without leaving the page',
      (tester) async {
    final bridge = FakeEuiccBridge()
      ..scanQrError = StateError('camera unavailable');
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Scan QR'));
    await tester.pump();

    expect(find.textContaining('camera unavailable'), findsOneWidget);
    expect(find.text('Download profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only one QR scanner can be active at a time', (tester) async {
    final scan = Completer<String?>();
    final bridge = FakeEuiccBridge()..scanQrFuture = scan.future;
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Scan QR'));
    await tester.pump();

    final scannerButton = tester.widget<IconButton>(
      find.byKey(const Key('scanQrButton')),
    );
    expect(scannerButton.onPressed, isNull);
    expect(bridge.scanQrCalls, 1);

    scan.complete(r'LPA:1$scan.example.com$single');
    await tester.pump();

    final activationCode =
        tester.widget<TextField>(find.byType(TextField).first);
    expect(
      activationCode.controller!.text,
      r'LPA:1$scan.example.com$single',
    );
  });

  testWidgets('leaving an active download cancels the native task',
      (tester) async {
    final bridge = FakeEuiccBridge();
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      r'LPA:1$smdp.example.com$matching-id',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start download'));
    await tester.pump();
    expect(find.text('Downloading…'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(bridge.cancelDownloadCalls, 1);
    expect(bridge.cancelledTaskIds, ['task-1']);
  });

  testWidgets('a late download failure is ignored after leaving the page',
      (tester) async {
    final download = Completer<void>();
    final bridge = FakeEuiccBridge()..downloadResult = download.future;
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      r'LPA:1$smdp.example.com$matching-id',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start download'));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    download.completeError(StateError('late failure'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a stream error does not unlock an overlapping download',
      (tester) async {
    final listenerCancelled = Completer<void>();
    final taskEvents = StreamController<DownloadTaskEvent>.broadcast(
      onCancel: () => listenerCancelled.future,
    );
    final bridge = FakeEuiccBridge()..taskEventsOverride = taskEvents.stream;
    addTearDown(() async {
      if (!listenerCancelled.isCompleted) listenerCancelled.complete();
      await taskEvents.close();
      await bridge.dispose();
    });
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      r'LPA:1$smdp.example.com$matching-id',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start download'));
    await tester.pump();
    expect(bridge.downloadCalls, 1);

    taskEvents.addError(StateError('restart requested'));
    await tester.pump();
    expect(bridge.cancelDownloadCalls, 1);
    expect(find.widgetWithText(FilledButton, 'Start download'), findsNothing);
    expect(bridge.downloadCalls, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    listenerCancelled.complete();
    await tester.pumpAndSettle();

    expect(bridge.downloadCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a task stream error cancels the native task before retry',
      (tester) async {
    final bridge = FakeEuiccBridge();
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      r'LPA:1$smdp.example.com$matching-id',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start download'));
    await tester.pump();

    bridge.taskEventsController.addError(StateError('stream failed'));
    await tester.pump();

    expect(find.textContaining('stream failed'), findsOneWidget);
    expect(bridge.cancelDownloadCalls, 1);
    expect(bridge.cancelledTaskIds, ['task-1']);
    expect(find.text('Downloading…'), findsOneWidget);
    expect(tester.takeException(), isNull);

    bridge.taskEventsController.add(
      const DownloadTaskEvent(
        taskId: 'task-1',
        phase: 'cancelled',
        error: 'cancelled',
      ),
    );
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Start download'), findsOneWidget);
  });

  testWidgets('a terminal event from an older task is ignored', (tester) async {
    final bridge = FakeEuiccBridge()..nextTaskId = 'current-task';
    addTearDown(bridge.dispose);
    await _pumpDownloadLauncher(tester, bridge);

    await tester.tap(find.text('Open download'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      r'LPA:1$smdp.example.com$matching-id',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Start download'));
    await tester.pump();

    bridge.taskEventsController.add(
      const DownloadTaskEvent(
        taskId: 'old-task',
        phase: 'done',
        progress: 1,
        done: true,
      ),
    );
    await tester.pump();
    expect(find.text('Download profile'), findsOneWidget);
    expect(find.text('Downloading…'), findsOneWidget);

    bridge.taskEventsController.add(
      const DownloadTaskEvent(
        taskId: 'current-task',
        phase: 'done',
        progress: 1,
        done: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open download'), findsOneWidget);
  });
}

Future<void> _pumpDownloadLauncher(
  WidgetTester tester,
  FakeEuiccBridge bridge,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const DownloadPage(channel: _channel),
                  ),
                ),
                child: const Text('Open download'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
