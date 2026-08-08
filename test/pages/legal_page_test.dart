import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/l10n.dart';
import 'package:lumina_euicc/pages/legal_page.dart';
import 'package:lumina_euicc/pages/settings_page.dart';

void main() {
  testWidgets('settings opens localized legal information', (tester) async {
    await _pumpPage(
      tester,
      const Locale('zh', 'CN'),
      const SettingsPage(),
    );

    expect(find.text('法律与开源信息'), findsOneWidget);
    expect(find.text('Legal & open source'), findsNothing);

    await tester.tap(find.text('法律与开源信息'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalPage), findsOneWidget);
    expect(find.text('Lumina 许可证'), findsOneWidget);
    expect(find.text('GPL-3.0-only'), findsOneWidget);
    expect(find.text('无担保声明'), findsOneWidget);
    expect(find.byKey(const Key('sourceRepositoryUrl')), findsOneWidget);
    expect(find.text('OpenEUICC'), findsOneWidget);
    expect(find.text('lpac / lpac-jni'), findsOneWidget);
    expect(find.text('cJSON'), findsOneWidget);
  });

  testWidgets('English legal page exposes source and license locations',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpPage(
      tester,
      const Locale('en', 'US'),
      const LegalPage(),
    );

    expect(find.text('Legal & open source'), findsOneWidget);
    expect(find.text('Lumina license'), findsOneWidget);
    expect(find.text('No warranty'), findsOneWidget);
    expect(
      find.text('https://github.com/Syngnat/lumina-euicc'),
      findsOneWidget,
    );
    expect(find.textContaining('THIRD_PARTY_NOTICES.md'), findsOneWidget);
    expect(find.textContaining('LGPL-2.1-only'), findsOneWidget);
    expect(find.textContaining('MIT License'), findsOneWidget);
    expect(find.text('ZXing Android Embedded / ZXing Core'), findsOneWidget);
    expect(find.textContaining('Apache-2.0'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('openRuntimeLicenses')));
    await tester.tap(find.byKey(const Key('openRuntimeLicenses')));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('Lumina eUICC'), findsOneWidget);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  Locale locale,
  Widget page,
) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
