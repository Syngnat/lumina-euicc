import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/generated/app_localizations.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/models/profile_reminder.dart';
import 'package:lumina_euicc/pages/home_page.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

const _previewFontPath = r'C:\Windows\Fonts\NotoSansSC-VF.ttf';
const _materialIconsPath =
    r'D:\Work\DevTools\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';
const _emojiFontPath = r'C:\Windows\Fonts\seguiemj.ttf';

void main() {
  testWidgets('production dashboard matches the approved dense layout',
      (tester) async {
    if (!Platform.isWindows ||
        !File(_previewFontPath).existsSync() ||
        !File(_materialIconsPath).existsSync() ||
        !File(_emojiFontPath).existsSync()) {
      return;
    }
    final fontFamily = await tester.runAsync(_loadGoldenFonts);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(786, 1704);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    const channel = EuiccChannelInfo(
      slotId: 1,
      portId: 0,
      seId: '0',
      label: 'Phone slot 1',
      type: 'omapi',
    );
    final bridge = FakeEuiccBridge()
      ..channels = const [channel]
      ..profiles = const [
        EuiccProfile(
          iccid: '8944101234567890123',
          name: '英国 giffgaff',
          provider: 'giffgaff · O2 UK',
          enabled: false,
          profileClass: 'operational',
          seq: 1,
        ),
        EuiccProfile(
          iccid: '8985202000000443105',
          name: '香港 1GB（30 天）',
          provider: 'RedteaGO · RTG Android',
          enabled: true,
          profileClass: 'operational',
          seq: 2,
        ),
        EuiccProfile(
          iccid: '8949000000000000123',
          name: '德国 Vodafone',
          provider: 'Vodafone DE',
          enabled: false,
          profileClass: 'operational',
          seq: 3,
        ),
        EuiccProfile(
          iccid: '8937204017200000938',
          name: '爱沙尼亚 esimplus',
          provider: 'eSIM Internet · Top Connect',
          enabled: false,
          profileClass: 'operational',
          seq: 4,
        ),
      ]
      ..reminders['8985202000000443105'] = ProfileReminder(
        at: DateTime(2027, 5, 2, 9),
        exact: true,
        notificationPermissionGranted: true,
        exactAlarmPermissionGranted: true,
      );
    addTearDown(bridge.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F766E),
              surface: const Color(0xFFF4F8F7),
            ),
            scaffoldBackgroundColor: const Color(0xFFF4F8F7),
            textTheme: ThemeData.light().textTheme.apply(
                  fontFamily: fontFamily,
                  bodyColor: const Color(0xFF14211F),
                  displayColor: const Color(0xFF14211F),
                ),
          ),
          home: const RepaintBoundary(
            key: ValueKey('production-dashboard'),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('🇬🇧'), findsOneWidget);
    expect(find.text('🇭🇰'), findsOneWidget);
    expect(find.text('🇩🇪'), findsOneWidget);
    expect(find.text('🇪🇪'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(const ValueKey('production-dashboard')),
      matchesGoldenFile('../design/goldens/home_dashboard_production.png'),
    );
  });
}

Future<String> _loadGoldenFonts() async {
  final fontBytes = Uint8List.fromList(
    await File(_previewFontPath).readAsBytes(),
  );
  final fontLoader = FontLoader('LuminaProductionGolden')
    ..addFont(Future.value(ByteData.sublistView(fontBytes)));
  await fontLoader.load();

  final iconBytes = Uint8List.fromList(
    await File(_materialIconsPath).readAsBytes(),
  );
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(iconBytes)));
  await iconLoader.load();

  final emojiBytes = Uint8List.fromList(
    await File(_emojiFontPath).readAsBytes(),
  );
  final emojiLoader = FontLoader('Noto Color Emoji')
    ..addFont(Future.value(ByteData.sublistView(emojiBytes)));
  await emojiLoader.load();
  return 'LuminaProductionGolden';
}
