import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/generated/app_localizations.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/widgets/channel_switcher.dart';
import 'package:lumina_euicc/widgets/dashboard_header.dart';
import 'package:lumina_euicc/widgets/empty_card.dart';
import 'package:lumina_euicc/widgets/euicc_identity_strip.dart';
import 'package:lumina_euicc/widgets/profiles_section_header.dart';

void main() {
  group('DashboardHeader', () {
    testWidgets('renders actions and invokes callbacks', (tester) async {
      var compat = 0, refresh = 0, settings = 0;
      await _pump(
        tester,
        DashboardHeader(
          onCompatibility: () => compat++,
          onRefresh: () async {
            refresh++;
          },
          onSettings: () => settings++,
        ),
      );

      expect(find.byIcon(Icons.sim_card_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.verified_user_outlined));
      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(compat, 1);
      expect(refresh, 1);
      expect(settings, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('ChannelSwitcher', () {
    final channels = [
      const EuiccChannelInfo(
        slotId: 0,
        portId: 0,
        seId: 'se0',
        label: 'eUICC 0',
        type: 'omapi',
      ),
      const EuiccChannelInfo(
        slotId: 1,
        portId: 0,
        seId: 'se1',
        label: 'eUICC 1',
        type: 'usb',
      ),
    ];

    testWidgets('renders SIM / USB labels and selects a channel',
        (tester) async {
      EuiccChannelInfo? selected;
      await _pump(
        tester,
        ChannelSwitcher(
          channels: channels,
          selected: channels.first,
          selectedProfileCount: 3,
          onSelected: (c) => selected = c,
        ),
      );

      expect(find.text('SIM 1'), findsOneWidget);
      expect(find.text('USB'), findsOneWidget);

      await tester.tap(find.text('USB'));
      await tester.pumpAndSettle();
      expect(selected?.slotId, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('EuiccIdentityStrip', () {
    testWidgets('renders masked EID and invokes quick actions', (tester) async {
      var reminders = 0, add = 0;
      await _pump(
        tester,
        EuiccIdentityStrip(
          info: const EuiccInfo(
            eid: '89049032000000000001',
            freeNonVolatileMemory: 4096,
            freeVolatileMemory: 1024,
          ),
          infoLoading: false,
          onReminders: () => reminders++,
          onAdd: () => add++,
        ),
      );

      expect(find.textContaining('8904'), findsOneWidget);
      await tester.tap(find.byKey(const Key('keepAliveRemindersButton')));
      await tester.tap(find.byKey(const Key('newEsimButton')));
      await tester.pumpAndSettle();
      expect(reminders, 1);
      expect(add, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('ProfilesSectionHeader', () {
    testWidgets('shows the profile count', (tester) async {
      await _pump(tester, const ProfilesSectionHeader(count: 5));
      expect(find.text('5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('EmptyCard', () {
    testWidgets('renders content and triggers action', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        EmptyCard(
          icon: '📶',
          title: 'No eUICC',
          body: 'Connect a removable SIM.',
          actionLabel: 'Check compatibility',
          onAction: () => taps++,
        ),
      );

      expect(find.text('📶'), findsOneWidget);
      expect(find.text('No eUICC'), findsOneWidget);
      await tester.tap(find.text('Check compatibility'));
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}