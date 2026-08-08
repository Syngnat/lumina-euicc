import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/l10n/l10n.dart';
import 'package:lumina_euicc/main.dart';
import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/services/providers.dart';

import '../support/fake_euicc_bridge.dart';

const _channel = EuiccChannelInfo(
  slotId: 0,
  portId: 0,
  seId: '1',
  label: 'Removable eUICC',
  type: 'omapi',
);

void main() {
  test('all native download phases have Simplified Chinese labels', () {
    final l10n = lookupAppLocalizations(const Locale('zh', 'CN'));
    const expected = {
      'resolving': '正在解析',
      'metadata': '正在读取信息',
      'preparing': '正在准备',
      'connecting': '正在连接',
      'authenticating': '正在认证',
      'confirming': '等待确认',
      'downloading': '正在下载',
      'finalizing': '正在完成',
      'cancelling': '正在取消',
      'cancelled': '已取消',
      'done': '已完成',
      'error': '失败',
    };

    for (final entry in expected.entries) {
      expect(l10n.downloadPhase(entry.key), entry.value);
    }
  });

  testWidgets('home follows a Simplified Chinese system locale',
      (tester) async {
    await _pumpHome(tester, const Locale('zh', 'CN'));

    expect(find.text('通道'), findsOneWidget);
    expect(find.text('新增 eSIM'), findsWidgets);
    expect(find.text('手机卡槽 0 · 端口 0 · 安全元件 1'), findsOneWidget);
    expect(find.text('Removable eUICC'), findsNothing);
    expect(find.text('Channels'), findsNothing);
  });

  testWidgets('home remains English for an English system locale',
      (tester) async {
    await _pumpHome(tester, const Locale('en', 'US'));

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('New eSIM'), findsWidgets);
    expect(find.text('Phone slot 0 · port 0 · SE 1'), findsOneWidget);
    expect(find.text('Removable eUICC'), findsNothing);
    expect(find.text('通道'), findsNothing);
  });

  testWidgets('home falls back to English for an unsupported system locale',
      (tester) async {
    await _pumpHome(tester, const Locale('fr', 'FR'));

    expect(find.text('Channels'), findsOneWidget);
    expect(find.text('New eSIM'), findsWidgets);
    expect(find.text('通道'), findsNothing);
  });
}

Future<void> _pumpHome(WidgetTester tester, Locale locale) async {
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
  final bridge = FakeEuiccBridge()..channels = const [_channel];
  addTearDown(bridge.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [euiccBridgeProvider.overrideWithValue(bridge)],
      child: const LuminaEuiccApp(),
    ),
  );
  await tester.pumpAndSettle();
}
