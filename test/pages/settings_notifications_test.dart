import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/pages/settings_page.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

void main() {
  testWidgets('settings labels card-side reports as technical eUICC events',
      (tester) async {
    final bridge = FakeEuiccBridge()
      ..channels = const [
        EuiccChannelInfo(
          slotId: 0,
          portId: 0,
          seId: '0',
          label: 'Phone slot',
          type: 'omapi',
        ),
      ];
    addTearDown(bridge.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('eUICC pending reports'), findsOneWidget);
    expect(find.textContaining('not keep-alive reminders'), findsOneWidget);
  });
}
