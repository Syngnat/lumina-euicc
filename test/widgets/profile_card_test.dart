import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/generated/app_localizations.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/models/profile_presentation.dart';
import 'package:lumina_euicc/models/profile_reminder.dart';
import 'package:lumina_euicc/widgets/profile_card.dart';

void main() {
  group('ProfilePresentation', () {
    test('maps an explicit giffgaff identity to the United Kingdom', () {
      expect(
        ProfilePresentation.infer(name: 'My profile', provider: 'giffgaff'),
        const ProfilePresentation(
          region: ProfileRegion.unitedKingdom,
          symbol: '🇬🇧',
          countryCode: 'GB',
        ),
      );
    });

    test(
        'keeps explicit travel identities global and unknown identities unknown',
        () {
      expect(
        ProfilePresentation.infer(name: 'Saily Travel', provider: 'Saily')
            .region,
        ProfileRegion.global,
      );
      expect(
        ProfilePresentation.infer(name: 'Personal', provider: 'Carrier X')
            .region,
        ProfileRegion.unknown,
      );
    });

    test('falls back to the E.118 ICCID issuer country code', () {
      expect(
        ProfilePresentation.infer(
          name: 'Personal line',
          provider: 'Carrier X',
          iccid: '8944100000000000001',
        ),
        const ProfilePresentation(
          region: ProfileRegion.unitedKingdom,
          symbol: '🇬🇧',
          countryCode: 'GB',
          inferredFromIccid: true,
        ),
      );
    });

    test('maps an explicit CTExcel identity to the United Kingdom', () {
      expect(
        ProfilePresentation.infer(
          name: 'CTExcel UK',
          provider: 'China Telecom Global',
        ),
        const ProfilePresentation(
          region: ProfileRegion.unitedKingdom,
          symbol: '🇬🇧',
          countryCode: 'GB',
        ),
      );
    });

    test('keeps malformed and shared-code ICCIDs unknown', () {
      expect(
        ProfilePresentation.infer(
          name: 'Personal line',
          provider: 'Carrier X',
          iccid: 'not-an-iccid',
        ).region,
        ProfileRegion.unknown,
      );
      expect(
        ProfilePresentation.infer(
          name: 'Personal line',
          provider: 'Carrier X',
          iccid: '8911234567890123456',
        ).region,
        ProfileRegion.unknown,
      );
    });
  });

  testWidgets('renders a localized digital-passport hierarchy', (tester) async {
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8944101234567890123',
        name: 'giffgaff UK',
        provider: 'giffgaff',
        enabled: true,
        profileClass: 'operational',
        seq: 3,
      ),
      locale: const Locale('zh'),
    );

    final badge = tester.widget<SizedBox>(
      find.byKey(const ValueKey('profile-region-badge')),
    );
    expect(badge.width, 34);
    expect(badge.height, 34);
    expect(find.text('🇬🇧'), findsOneWidget);
    expect(find.text('英国'), findsOneWidget);
    expect(find.text('giffgaff UK'), findsOneWidget);
    expect(find.text('giffgaff'), findsOneWidget);
    expect(find.text('已启用'), findsOneWidget);
    expect(find.text('8944101234567890123'), findsOneWidget);
    expect(find.text('#3 · 正式'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the unknown fallback without guessing a region',
      (tester) async {
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8901000000000000001',
        name: 'Personal line',
        provider: 'Unknown carrier',
        enabled: false,
        profileClass: 'operational',
        seq: 1,
      ),
    );

    expect(find.text('🌐'), findsOneWidget);
    expect(find.text('Region unknown'), findsOneWidget);
    expect(find.text('Global'), findsNothing);
    expect(find.text('Disabled'), findsOneWidget);
  });

  testWidgets('shows an ICCID issuer-country fallback when metadata is vague',
      (tester) async {
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8986100000000000001',
        name: 'Personal line',
        provider: 'Carrier X',
        enabled: false,
        profileClass: 'operational',
        seq: 2,
      ),
      locale: const Locale('zh'),
    );

    expect(find.text('🇨🇳'), findsOneWidget);
    expect(find.text('发卡地区 CN'), findsOneWidget);
    expect(find.text('地区未知'), findsNothing);
  });

  testWidgets('stays overflow-free at a 1.3 text scale', (tester) async {
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8901000000000000001',
        name: 'A long travel profile name for a compact phone',
        provider: 'A long global network provider name',
        enabled: true,
        profileClass: 'operational',
        seq: 12,
      ),
      surfaceSize: const Size(390, 844),
      textScaler: const TextScaler.linear(1.3),
      reminder: ProfileReminder(
        at: DateTime(2027, 3, 1, 9),
        exact: true,
        notificationPermissionGranted: true,
        exactAlarmPermissionGranted: true,
      ),
    );

    expect(find.byType(ProfileCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps a standard profile card compact enough for dense lists',
      (tester) async {
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8944101234567890123',
        name: 'Compact profile',
        provider: 'Carrier',
        enabled: true,
        profileClass: 'operational',
        seq: 4,
      ),
    );

    expect(
      tester.getSize(find.byType(ProfileCard)).height,
      lessThanOrEqualTo(96),
    );
  });

  testWidgets('preserves actions and long-press ICCID copy', (tester) async {
    var enableCalls = 0;
    var renameCalls = 0;
    var deleteCalls = 0;
    const iccid = '8901000000000000001';

    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: iccid,
        name: 'Work line',
        provider: 'Carrier',
        enabled: false,
        profileClass: 'operational',
        seq: 2,
      ),
      onEnable: () => enableCalls += 1,
      onRename: () => renameCalls += 1,
      onDelete: () => deleteCalls += 1,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();
    expect(enableCalls, 1);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    expect(renameCalls, 1);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleteCalls, 1);

    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.longPress(find.text(iccid));
    await tester.pumpAndSettle();
    final iccidSemantics = tester.getSemantics(
      find.byKey(const ValueKey('profile-iccid')),
    );
    expect(iccidSemantics.label, contains('ICCID $iccid'));
    expect(iccidSemantics.hint, contains('Long-press to copy ICCID'));
    expect(
      iccidSemantics.getSemanticsData().hasAction(SemanticsAction.longPress),
      isTrue,
    );
    expect(
      clipboardCalls.where((call) => call.method == 'Clipboard.setData'),
      hasLength(1),
    );
    expect(find.text('ICCID copied'), findsOneWidget);
  });

  testWidgets('exposes a keep-alive reminder action', (tester) async {
    var reminderCalls = 0;

    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8901000000000000001',
        name: 'Keep-alive line',
        provider: 'Carrier',
        enabled: false,
        profileClass: 'operational',
        seq: 5,
      ),
      onSetReminder: () => reminderCalls += 1,
    );

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep-alive reminder'));
    await tester.pumpAndSettle();

    expect(reminderCalls, 1);
  });

  testWidgets('shows and cancels an existing reminder', (tester) async {
    var cancelCalls = 0;
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8901000000000000001',
        name: 'Keep-alive line',
        provider: 'Carrier',
        enabled: false,
        profileClass: 'operational',
        seq: 5,
      ),
      reminder: ProfileReminder(
        at: DateTime(2027, 3, 1, 9),
        exact: true,
        notificationPermissionGranted: true,
        exactAlarmPermissionGranted: true,
      ),
      onCancelReminder: () => cancelCalls += 1,
    );

    expect(find.byKey(const Key('profile-reminder')), findsOneWidget);
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel reminder'));
    await tester.pumpAndSettle();

    expect(cancelCalls, 1);
  });

  testWidgets('exposes one direct micro-data action without duplicating flags',
      (tester) async {
    var calls = 0;
    await _pumpCard(
      tester,
      profile: const EuiccProfile(
        iccid: '8944100000000000001',
        name: 'Keep-alive line',
        provider: 'giffgaff',
        enabled: false,
        profileClass: 'operational',
        seq: 7,
      ),
      onMicroDataKeepAlive: () => calls += 1,
    );

    expect(find.text('🇬🇧'), findsOneWidget);
    expect(
        find.byTooltip('Run one tiny cellular-network check'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('micro-data-keep-alive-7')));
    expect(calls, 1);
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required EuiccProfile profile,
  Locale locale = const Locale('en'),
  VoidCallback? onEnable,
  VoidCallback? onDisable,
  VoidCallback? onRename,
  VoidCallback? onDelete,
  VoidCallback? onSetReminder,
  ProfileReminder? reminder,
  VoidCallback? onCancelReminder,
  VoidCallback? onMicroDataKeepAlive,
  Size surfaceSize = const Size(360, 800),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ProfileCard(
            profile: profile,
            onEnable: onEnable,
            onDisable: onDisable,
            onRename: onRename,
            onDelete: onDelete,
            onSetReminder: onSetReminder,
            reminder: reminder,
            onCancelReminder: onCancelReminder,
            onMicroDataKeepAlive: onMicroDataKeepAlive,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
