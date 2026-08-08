import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/l10n.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/pages/compatibility_page.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

const _diagnostics = <CompatibilityItem>[
  CompatibilityItem(
    code: 'app_identity',
    title: 'native app_identity title',
    ok: true,
    detail: 'native app_identity detail',
    arguments: {
      'packageName': 'top.syngnat.lumina.euicc',
      'signingCertificateSha1s': ['AA:BB'],
    },
  ),
  CompatibilityItem(
    code: 'device_info',
    title: 'native device_info title',
    ok: true,
    detail: 'native device_info detail',
    arguments: {
      'brand': 'OPPO',
      'device': 'OP61C1L1',
      'model': 'PME110',
      'androidRelease': '16',
      'androidSdkInt': 36,
    },
  ),
  CompatibilityItem(
    code: 'lpa_port_failed',
    title: 'native lpa_port_failed title',
    ok: false,
    detail: 'native lpa_port_failed detail',
    arguments: {
      'slotId': 0,
      'portId': 1,
      'failureType': 'SecurityException',
    },
  ),
  CompatibilityItem(
    code: 'lpa_probe_failed',
    title: 'native lpa_probe_failed title',
    ok: false,
    detail: 'native lpa_probe_failed detail',
    arguments: {'failureType': 'IOException'},
  ),
  CompatibilityItem(
    code: 'omapi_present',
    title: 'native omapi_present title',
    ok: true,
    detail: 'native omapi_present detail',
  ),
  CompatibilityItem(
    code: 'omapi_missing',
    title: 'native omapi_missing title',
    ok: false,
    detail: 'native omapi_missing detail',
  ),
  CompatibilityItem(
    code: 'omapi_service_failed',
    title: 'native omapi_service_failed title',
    ok: false,
    detail: 'native omapi_service_failed detail',
    arguments: {'failureType': 'IllegalStateException'},
  ),
  CompatibilityItem(
    code: 'omapi_slot_authorized',
    title: 'native omapi_slot_authorized title',
    ok: true,
    detail: 'native omapi_slot_authorized detail',
    arguments: {'slotId': 0},
  ),
  CompatibilityItem(
    code: 'omapi_slot_access_denied',
    title: 'native omapi_slot_access_denied title',
    ok: false,
    detail: 'native omapi_slot_access_denied detail',
    arguments: {'slotId': 1},
  ),
  CompatibilityItem(
    code: 'omapi_slot_isdr_unavailable',
    title: 'native omapi_slot_isdr_unavailable title',
    ok: false,
    detail: 'native omapi_slot_isdr_unavailable detail',
    arguments: {'slotId': 2},
  ),
  CompatibilityItem(
    code: 'omapi_slot_failed',
    title: 'native omapi_slot_failed title',
    ok: false,
    detail: 'native omapi_slot_failed detail',
    arguments: {'slotId': 3, 'failureType': 'IOException'},
  ),
  CompatibilityItem(
    code: 'omapi_no_uicc_readers',
    title: 'native omapi_no_uicc_readers title',
    ok: false,
    detail: 'native omapi_no_uicc_readers detail',
  ),
  CompatibilityItem(
    code: 'euicc_ports_found',
    title: 'native euicc_ports_found title',
    ok: true,
    detail: 'native euicc_ports_found detail',
    arguments: {
      'ports': [
        {'slotId': 0, 'portId': 0},
        {'slotId': 1, 'portId': 2},
      ],
    },
  ),
  CompatibilityItem(
    code: 'euicc_ports_missing',
    title: 'native euicc_ports_missing title',
    ok: false,
    detail: 'native euicc_ports_missing detail',
  ),
  CompatibilityItem(
    code: 'lpa_channel_valid',
    title: 'native lpa_channel_valid title',
    ok: true,
    detail: 'native lpa_channel_valid detail',
  ),
  CompatibilityItem(
    code: 'lpa_channel_invalid',
    title: 'native lpa_channel_invalid title',
    ok: false,
    detail: 'native lpa_channel_invalid detail',
  ),
  CompatibilityItem(
    code: 'rootless_access_ready',
    title: 'native rootless_access_ready title',
    ok: true,
    detail: 'native rootless_access_ready detail',
  ),
  CompatibilityItem(
    code: 'rootless_ara_m_required',
    title: 'native rootless_ara_m_required title',
    ok: false,
    detail: 'native rootless_ara_m_required detail',
  ),
];

void main() {
  testWidgets('stable compatibility codes render in Simplified Chinese',
      (tester) async {
    await _pumpCompatibility(tester, const Locale('zh', 'CN'), _diagnostics);

    for (final item in _diagnostics) {
      expect(find.text(item.title), findsNothing);
      expect(find.text(item.detail), findsNothing);
    }
    expect(find.text('用于 ARA-M 的应用身份'), findsOneWidget);
    expect(find.text('兼容性概览'), findsOneWidget);
    expect(find.text('OPPO PME110 · OP61C1L1'), findsOneWidget);
    expect(find.text('Android 16 · API 36'), findsOneWidget);
    expect(find.text('OMAPI 枚举的 SIM 卡槽'), findsOneWidget);
    expect(find.text('SIM 0、SIM 1、SIM 2、SIM 3'), findsOneWidget);
    expect(find.text('已到达 ISD-R 访问检查'), findsOneWidget);
    expect(find.text('SIM 0、SIM 1'), findsOneWidget);
    expect(find.text('已授权打开 ISD-R'), findsOneWidget);
    expect(find.text('SIM 0'), findsOneWidget);
    expect(find.text('ARA-M / 访问控制拒绝'), findsOneWidget);
    expect(find.text('SIM 1'), findsOneWidget);
    expect(
      find.text(
        '手机卡槽 1 可访问，但 OMAPI 访问控制（UICC 通常为 ARA-M / ARF）未授权当前应用身份。',
      ),
      findsOneWidget,
    );
    expect(
      find.text('卡槽 0 / 端口 0、卡槽 1 / 端口 2'),
      findsOneWidget,
    );
    expect(find.text('免 Root 访问 / ARA-M'), findsNWidgets(2));
  });

  testWidgets('stable compatibility codes render in English', (tester) async {
    await _pumpCompatibility(tester, const Locale('en', 'US'), _diagnostics);

    for (final item in _diagnostics) {
      expect(find.text(item.title), findsNothing);
      expect(find.text(item.detail), findsNothing);
    }
    expect(find.text('App identity for ARA-M'), findsOneWidget);
    expect(find.text('Compatibility overview'), findsOneWidget);
    expect(find.text('OPPO PME110 · OP61C1L1'), findsOneWidget);
    expect(find.text('Android 16 · API 36'), findsOneWidget);
    expect(find.text('OMAPI-enumerated SIM slots'), findsOneWidget);
    expect(find.text('SIM 0, SIM 1, SIM 2, SIM 3'), findsOneWidget);
    expect(find.text('ISD-R access check reached'), findsOneWidget);
    expect(find.text('SIM 0, SIM 1'), findsOneWidget);
    expect(find.text('Authorized ISD-R access'), findsOneWidget);
    expect(find.text('SIM 0'), findsOneWidget);
    expect(find.text('ARA-M / access control denied'), findsOneWidget);
    expect(find.text('SIM 1'), findsOneWidget);
    expect(
      find.text(
        'Phone slot 1 is reachable, but OMAPI access control (normally ARA-M / ARF for UICC) did not authorize the current app identity.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('slot 0 / port 0, slot 1 / port 2'),
      findsOneWidget,
    );
    expect(find.text('Rootless access / ARA-M'), findsNWidgets(2));
  });

  testWidgets('unknown compatibility code keeps native fallback',
      (tester) async {
    const item = CompatibilityItem(
      code: 'future_diagnostic',
      title: 'Future native title',
      ok: false,
      detail: 'Future native detail',
    );
    await _pumpCompatibility(tester, const Locale('zh', 'CN'), [item]);

    expect(find.text(item.title), findsOneWidget);
    expect(find.text(item.detail), findsOneWidget);
  });
}

Future<void> _pumpCompatibility(
  WidgetTester tester,
  Locale locale,
  List<CompatibilityItem> items,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1080, 10000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  final bridge = FakeEuiccBridge()..compatibilityItems = items;
  addTearDown(bridge.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CompatibilityPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
