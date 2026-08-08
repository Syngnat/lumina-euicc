import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/l10n.dart';
import 'package:lumina_euicc/pages/settings_page.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

void main() {
  testWidgets('settings exposes localized STK management', (tester) async {
    final bridge = FakeEuiccBridge();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('STK 管理'), findsOneWidget);
    expect(find.textContaining('SIM 卡工具包'), findsOneWidget);

    await tester.tap(find.byKey(const Key('openSimToolkit')));
    await tester.pump();

    expect(bridge.openSimToolkitCalls, 1);
  });

  testWidgets('shows localized guidance when system STK is unavailable',
      (tester) async {
    final bridge = FakeEuiccBridge()..openSimToolkitResult = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: const MaterialApp(
          locale: Locale('zh', 'CN'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSimToolkit')));
    await tester.pump();

    expect(find.textContaining('系统“SIM 卡工具包”不可用'), findsOneWidget);
  });
}
