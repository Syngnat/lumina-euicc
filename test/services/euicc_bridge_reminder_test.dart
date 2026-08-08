import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumina_euicc/services/euicc_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/profile-reminder');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('an empty native reminder response maps to null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getProfileReminder');
      expect((call.arguments as Map)['iccid'], 'profile-id');
      return <String, Object?>{};
    });
    final bridge = EuiccBridge(methodChannel: channel);

    expect(await bridge.getProfileReminder('profile-id'), isNull);
  });

  test('schedule sends epoch time and parses native permission state',
      () async {
    final at = DateTime(2027, 3, 1, 9, 30);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'scheduleProfileReminder');
      final arguments = call.arguments as Map;
      expect(arguments['iccid'], 'profile-id');
      expect(arguments['profileName'], 'Travel line');
      expect(arguments['triggerAtMillis'], at.millisecondsSinceEpoch);
      return <String, Object?>{
        'triggerAtMillis': at.millisecondsSinceEpoch,
        'exact': false,
        'notificationPermissionGranted': true,
        'exactAlarmPermissionGranted': false,
      };
    });
    final bridge = EuiccBridge(methodChannel: channel);

    final reminder = await bridge.scheduleProfileReminder(
      iccid: 'profile-id',
      profileName: 'Travel line',
      at: at,
    );

    expect(reminder.at, at);
    expect(reminder.exact, isFalse);
    expect(reminder.notificationPermissionGranted, isTrue);
    expect(reminder.exactAlarmPermissionGranted, isFalse);
  });
}
