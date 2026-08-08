import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'profile_dashboard_preview.dart';

void main() {
  testWidgets('mock dashboard exposes dense card and profile controls', (
    tester,
  ) async {
    await pumpProfileDashboardPreview(tester);

    expect(
        find.byKey(const ValueKey('mock-profile-dashboard')), findsOneWidget);
    expect(find.text('SIM 1'), findsOneWidget);
    expect(find.text('SIM 2'), findsOneWidget);
    expect(find.text('154.53 KB 可用'), findsOneWidget);
    expect(find.byType(MockProfileRow), findsNWidgets(5));
    expect(find.byType(MockProfileSwitch), findsNWidgets(5));
    expect(find.byKey(const ValueKey('profile-flag-EE')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-flag-SG')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-flag-US')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-flag-HK')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-flag-GB')), findsOneWidget);
    expect(find.text('本地提醒'), findsWidgets);
    expect(find.text('大小未知'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders the approved phone-sized visual preview',
      (tester) async {
    await pumpProfileDashboardPreview(tester, highResolution: true);

    await expectLater(
      find.byKey(const ValueKey('mock-profile-dashboard')),
      matchesGoldenFile('goldens/profile_dashboard_mock.png'),
    );
  }, skip: !supportsProfileDashboardGolden);
}
