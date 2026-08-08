import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _canvas = Color(0xFFF4F8F7);
const _ink = Color(0xFF14211F);
const _muted = Color(0xFF65726F);
const _teal = Color(0xFF0F766E);
const _deepTeal = Color(0xFF173F3A);
const _mint = Color(0xFFDDF4EF);
const _violet = Color(0xFF6D5BD0);
const _violetSurface = Color(0xFFF0EDFF);
const _line = Color(0xFFDCE5E2);
const _danger = Color(0xFFB42318);

final _previewNow = DateTime(2026, 8, 8);
Future<String?>? _previewFont;
const _previewFontPath = r'C:\Windows\Fonts\NotoSansSC-VF.ttf';
const _materialIconsPath =
    r'D:\Work\DevTools\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf';

bool get supportsProfileDashboardGolden =>
    Platform.isWindows &&
    File(_previewFontPath).existsSync() &&
    File(_materialIconsPath).existsSync();

Future<void> pumpProfileDashboardPreview(
  WidgetTester tester, {
  bool highResolution = false,
}) async {
  final previewFontFamily = await tester.runAsync(
    () => _previewFont ??= _loadPreviewFont(),
  );
  if (highResolution) {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(786, 1704);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
  } else {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _teal,
          surface: _canvas,
        ),
        scaffoldBackgroundColor: _canvas,
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: previewFontFamily,
              bodyColor: _ink,
              displayColor: _ink,
            ),
      ),
      home: const MockProfileDashboard(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<String?> _loadPreviewFont() async {
  if (!Platform.isWindows) return null;
  final font = File(_previewFontPath);
  if (!await font.exists()) return null;

  final bytes = Uint8List.fromList(await font.readAsBytes());
  final loader = FontLoader('LuminaPreviewCjk')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();

  final materialIcons = File(_materialIconsPath);
  if (await materialIcons.exists()) {
    final iconBytes = Uint8List.fromList(await materialIcons.readAsBytes());
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconBytes)));
    await iconLoader.load();
  }
  return 'LuminaPreviewCjk';
}

class MockProfileDashboard extends StatelessWidget {
  const MockProfileDashboard({super.key});

  static final _profiles = [
    MockProfile(
      countryCode: 'EE',
      name: '爱沙尼亚 esimplus',
      iccid: '89372040172******938',
      provider: 'eSIM Internet · Top Connect',
      reminderDate: DateTime(2027, 3, 1),
      reminderKind: '保号',
      estimatedSize: '~19 KB',
    ),
    MockProfile(
      countryCode: 'SG',
      name: '新加坡 eSIM（流量）',
      iccid: '896501241118******028',
      provider: 'Eskimo · Singtel',
      reminderDate: DateTime(2027, 11, 27),
      reminderKind: '到期',
      estimatedSize: '~49 KB',
    ),
    MockProfile(
      countryCode: 'US',
      name: '美国 Saily 1',
      iccid: '89852350121******145',
      provider: 'Saily · WEBBING',
      enabled: true,
      reminderDate: DateTime(2027, 5, 2),
      reminderKind: '保号',
      estimatedSize: '39.98 KB',
      sizeMeasured: true,
    ),
    MockProfile(
      countryCode: 'HK',
      name: '香港 1GB（30 天）',
      iccid: '8985202******4431056',
      provider: 'RedteaGO · RTG Android',
      reminderDate: DateTime(2026, 7, 20),
      reminderKind: '已过期',
      estimatedSize: '~7 KB',
    ),
    const MockProfile(
      countryCode: 'GB',
      name: '英国 giffgaff',
      iccid: '89441012345******903',
      provider: 'giffgaff · O2 UK',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('mock-profile-dashboard'),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              children: [
                const _DashboardHeader(),
                const SizedBox(height: 10),
                const _SlotSwitcher(),
                const SizedBox(height: 10),
                const _EuiccIdentityStrip(),
                const SizedBox(height: 11),
                const _ProfileSectionHeader(),
                const SizedBox(height: 7),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: _profiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (_, index) => MockProfileRow(
                      profile: _profiles[index],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _deepTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.sim_card_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lumina eUICC',
                  style: TextStyle(
                    fontSize: 19,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.45,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  '数字 eSIM 护照 · Mock 预览',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const _HeaderAction(icon: Icons.refresh_rounded),
          const SizedBox(width: 2),
          const _HeaderAction(icon: Icons.settings_outlined),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 38,
      child: Icon(icon, color: _ink, size: 24),
    );
  }
}

class _SlotSwitcher extends StatelessWidget {
  const _SlotSwitcher();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6ECEA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x180B2A26),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const _SlotLabel(
                label: 'SIM 1',
                detail: '5 个配置',
                selected: true,
              ),
            ),
          ),
          const Expanded(
            child: _SlotLabel(label: 'SIM 2', detail: '未授权'),
          ),
        ],
      ),
    );
  }
}

class _SlotLabel extends StatelessWidget {
  const _SlotLabel({
    required this.label,
    required this.detail,
    this.selected = false,
  });

  final String label;
  final String detail;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sim_card_outlined,
          size: 16,
          color: selected ? _teal : _muted,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? _teal : _muted,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          detail,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: selected ? _muted : _muted.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

class _EuiccIdentityStrip extends StatelessWidget {
  const _EuiccIdentityStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 73,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 9, 12, 9),
              decoration: BoxDecoration(
                color: _deepTeal,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        color: Color(0xFF8FD8CC),
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '89086029********0036938',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Text(
                        '154.53 KB 可用',
                        style: TextStyle(
                          color: Color(0xFFD9F7F1),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const LinearProgressIndicator(
                            value: 0.62,
                            minHeight: 4,
                            backgroundColor: Color(0xFF315A55),
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xFF8FD8CC),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 7),
          const _SquareAction(
            icon: Icons.notifications_none_rounded,
            badge: '2',
          ),
          const SizedBox(width: 7),
          const _SquareAction(icon: Icons.add_rounded, emphasized: true),
        ],
      ),
    );
  }
}

class _SquareAction extends StatelessWidget {
  const _SquareAction({
    required this.icon,
    this.badge,
    this.emphasized = false,
  });

  final IconData icon;
  final String? badge;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 73,
      decoration: BoxDecoration(
        color: emphasized ? _teal : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: emphasized ? null : Border.all(color: _line),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            icon,
            color: emphasized ? Colors.white : _ink,
            size: emphasized ? 28 : 24,
          ),
          if (badge != null)
            Positioned(
              right: 9,
              top: 13,
              child: Container(
                width: 15,
                height: 15,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _danger,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  const _ProfileSectionHeader();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: Row(
        children: [
          Text(
            '配置',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          SizedBox(width: 7),
          _CountPill(label: '5'),
          Spacer(),
          Icon(Icons.event_outlined, size: 14, color: _violet),
          SizedBox(width: 4),
          Text(
            '本地提醒',
            style: TextStyle(
              color: _violet,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _mint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _teal,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class MockProfileRow extends StatelessWidget {
  const MockProfileRow({super.key, required this.profile});

  final MockProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: profile.enabled ? const Color(0xFFE8F7F3) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profile.enabled ? const Color(0xFF79BFB4) : _line,
          width: profile.enabled ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C14211F),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: Duration.zero,
            width: 4,
            color: profile.enabled ? _teal : Colors.transparent,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 8, 8),
            child: _FlagBadge(countryCode: profile.countryCode),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.2,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    profile.iccid,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.7,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.provider,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _ReminderChip(profile: profile),
                      const SizedBox(width: 5),
                      _SizeChip(profile: profile),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MockProfileSwitch(value: profile.enabled),
                const SizedBox(height: 6),
                Text(
                  profile.enabled ? '使用中' : '未启用',
                  style: TextStyle(
                    color: profile.enabled ? _teal : _muted,
                    fontSize: 9.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderChip extends StatelessWidget {
  const _ReminderChip({required this.profile});

  final MockProfile profile;

  @override
  Widget build(BuildContext context) {
    final date = profile.reminderDate;
    final expired = date != null && date.isBefore(_previewNow);
    final label = date == null
        ? '未设置提醒'
        : '${_formatDate(date)} · ${expired ? '已过期' : '${date.difference(_previewNow).inDays}天'}';

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: expired ? const Color(0xFFFFECEA) : _violetSurface,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_outlined,
              size: 11,
              color: expired ? _danger : _violet,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: expired ? _danger : _violet,
                  fontSize: 9.2,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.profile});

  final MockProfile profile;

  @override
  Widget build(BuildContext context) {
    final label = profile.estimatedSize ?? '大小未知';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: profile.sizeMeasured
            ? const Color(0xFFDAF0EA)
            : const Color(0xFFF0F3F2),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.storage_outlined,
            size: 11,
            color: profile.sizeMeasured ? _teal : _muted,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: profile.sizeMeasured ? _teal : _muted,
              fontSize: 9.2,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MockProfileSwitch extends StatelessWidget {
  const MockProfileSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? _teal : const Color(0xFFD6DEDC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: AnimatedAlign(
        duration: Duration.zero,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(width: 20, height: 20),
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.countryCode});

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('profile-flag-$countryCode'),
      width: 42,
      height: 28,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0x26000000), width: 0.7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: CustomPaint(painter: _FlagPainter(countryCode)),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.countryCode);

  final String countryCode;

  @override
  void paint(Canvas canvas, Size size) {
    switch (countryCode) {
      case 'EE':
        _horizontal(canvas, size, const [
          Color(0xFF4891D9),
          Color(0xFF151A1C),
          Colors.white,
        ]);
      case 'SG':
        _horizontal(canvas, size, const [Color(0xFFE31B23), Colors.white]);
        canvas.drawCircle(
          Offset(size.width * .26, size.height * .27),
          size.height * .18,
          Paint()..color = Colors.white,
        );
        canvas.drawCircle(
          Offset(size.width * .30, size.height * .24),
          size.height * .14,
          Paint()..color = const Color(0xFFE31B23),
        );
      case 'US':
        final stripe = size.height / 7;
        for (var index = 0; index < 7; index += 1) {
          canvas.drawRect(
            Rect.fromLTWH(0, index * stripe, size.width, stripe),
            Paint()
              ..color = index.isEven ? const Color(0xFFB22234) : Colors.white,
          );
        }
        canvas.drawRect(
          Rect.fromLTWH(0, 0, size.width * .43, size.height * .58),
          Paint()..color = const Color(0xFF3C3B6E),
        );
      case 'HK':
        canvas.drawColor(const Color(0xFFDE2910), BlendMode.src);
        for (var index = 0; index < 5; index += 1) {
          final angle = -math.pi / 2 + index * math.pi * 2 / 5;
          canvas.drawCircle(
            Offset(
              size.width / 2 + math.cos(angle) * size.height * .19,
              size.height / 2 + math.sin(angle) * size.height * .19,
            ),
            size.height * .075,
            Paint()..color = Colors.white,
          );
        }
      case 'GB':
        canvas.drawColor(const Color(0xFF153B73), BlendMode.src);
        final white = Paint()..color = Colors.white;
        final red = Paint()..color = const Color(0xFFC8102E);
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * .34, size.width, size.height * .32),
          white,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width * .38, 0, size.width * .24, size.height),
          white,
        );
        canvas.drawRect(
          Rect.fromLTWH(0, size.height * .42, size.width, size.height * .16),
          red,
        );
        canvas.drawRect(
          Rect.fromLTWH(size.width * .44, 0, size.width * .12, size.height),
          red,
        );
      default:
        canvas.drawColor(_line, BlendMode.src);
    }
  }

  void _horizontal(Canvas canvas, Size size, List<Color> colors) {
    final stripe = size.height / colors.length;
    for (var index = 0; index < colors.length; index += 1) {
      canvas.drawRect(
        Rect.fromLTWH(0, index * stripe, size.width, stripe),
        Paint()..color = colors[index],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.countryCode != countryCode;
}

class MockProfile {
  const MockProfile({
    required this.countryCode,
    required this.name,
    required this.iccid,
    required this.provider,
    this.enabled = false,
    this.reminderDate,
    this.reminderKind,
    this.estimatedSize,
    this.sizeMeasured = false,
  });

  final String countryCode;
  final String name;
  final String iccid;
  final String provider;
  final bool enabled;
  final DateTime? reminderDate;
  final String? reminderKind;
  final String? estimatedSize;
  final bool sizeMeasured;
}
