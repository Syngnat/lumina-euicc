import 'dart:async';

import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/models/profile_reminder.dart';
import 'package:lumina_euicc/services/euicc_bridge.dart';

class FakeEuiccBridge extends EuiccBridge {
  List<EuiccChannelInfo> channels = const [];
  List<EuiccProfile> profiles = const [];
  List<CompatibilityItem> compatibilityItems = const [];
  int downloadCalls = 0;
  int cancelDownloadCalls = 0;
  int confirmDownloadCalls = 0;
  int scanQrCalls = 0;
  int openSimToolkitCalls = 0;
  int scheduleReminderCalls = 0;
  int cancelReminderCalls = 0;
  int requestPhoneStatePermissionCalls = 0;
  int microDataKeepAliveCalls = 0;
  bool reminderNotificationPermissionGranted = true;
  bool reminderExact = true;
  bool phoneStatePermissionGranted = true;
  MicroDataKeepAliveResult microDataKeepAliveResult =
      const MicroDataKeepAliveResult(
    status: 'connected',
    restored: true,
    maxResponseBodyBytes: 1024,
    httpStatus: 200,
    responseBodyBytes: 0,
  );
  Future<MicroDataKeepAliveResult>? microDataKeepAliveFuture;
  ({int slotId, int portId, String seId})? lastMicroDataChannel;
  final Map<String, ProfileReminder> reminders = {};
  bool openSimToolkitResult = true;
  Object? openSimToolkitError;
  String? scanQrResult;
  Object? scanQrError;
  Future<String?>? scanQrFuture;
  String nextTaskId = 'task-1';
  Future<void>? downloadResult;
  Stream<DownloadTaskEvent>? taskEventsOverride;
  Future<List<EuiccProfile>> Function({
    required int slotId,
    required int portId,
    required String seId,
  })? listProfilesHandler;

  final List<({int slotId, int portId, String seId})> profileRequests = [];
  final List<String> cancelledTaskIds = [];
  final List<({String taskId, bool continueDownload})> confirmationRequests =
      [];
  final StreamController<DownloadTaskEvent> taskEventsController =
      StreamController<DownloadTaskEvent>.broadcast();

  @override
  Stream<DownloadTaskEvent> get taskEvents =>
      taskEventsOverride ?? taskEventsController.stream;

  @override
  Future<String?> scanQr() async {
    scanQrCalls++;
    final error = scanQrError;
    if (error != null) throw error;
    final future = scanQrFuture;
    if (future != null) return future;
    return scanQrResult;
  }

  @override
  Future<bool> openSimToolkit() async {
    openSimToolkitCalls++;
    final error = openSimToolkitError;
    if (error != null) throw error;
    return openSimToolkitResult;
  }

  @override
  Future<ProfileReminder?> getProfileReminder(String iccid) async =>
      reminders[iccid];

  @override
  Future<ProfileReminder> scheduleProfileReminder({
    required String iccid,
    required String profileName,
    required DateTime at,
  }) async {
    scheduleReminderCalls++;
    final reminder = ProfileReminder(
      at: at,
      exact: reminderExact,
      notificationPermissionGranted: reminderNotificationPermissionGranted,
      exactAlarmPermissionGranted: reminderExact,
    );
    reminders[iccid] = reminder;
    return reminder;
  }

  @override
  Future<void> cancelProfileReminder(String iccid) async {
    cancelReminderCalls++;
    reminders.remove(iccid);
  }

  @override
  Future<void> renameProfileReminder({
    required String iccid,
    required String profileName,
  }) async {}

  @override
  Future<bool> requestReminderNotificationPermission() async =>
      reminderNotificationPermissionGranted;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<bool> requestPhoneStatePermission() async {
    requestPhoneStatePermissionCalls++;
    return phoneStatePermissionGranted;
  }

  @override
  Future<MicroDataKeepAliveResult> runMicroDataKeepAlive({
    required int slotId,
    required int portId,
    required String seId,
    required String iccid,
  }) async {
    microDataKeepAliveCalls++;
    lastMicroDataChannel = (slotId: slotId, portId: portId, seId: seId);
    final future = microDataKeepAliveFuture;
    if (future != null) return future;
    return microDataKeepAliveResult;
  }

  @override
  Future<List<EuiccChannelInfo>> listChannels() async => channels;

  @override
  Future<List<CompatibilityItem>> runCompatibilityCheck() async =>
      compatibilityItems;

  @override
  Future<List<EuiccProfile>> listProfiles({
    required int slotId,
    required int portId,
    required String seId,
  }) async {
    profileRequests.add((slotId: slotId, portId: portId, seId: seId));
    final handler = listProfilesHandler;
    if (handler != null) {
      return handler(slotId: slotId, portId: portId, seId: seId);
    }
    return profiles;
  }

  @override
  Future<String> downloadProfile({
    required int slotId,
    required int portId,
    required String seId,
    required String activationCode,
    String? confirmationCode,
    String? imei,
  }) async {
    downloadCalls++;
    await downloadResult;
    return nextTaskId;
  }

  @override
  Future<void> cancelDownload({required String taskId}) async {
    cancelDownloadCalls++;
    cancelledTaskIds.add(taskId);
  }

  @override
  Future<void> confirmDownload({
    required String taskId,
    required bool continueDownload,
  }) async {
    confirmDownloadCalls++;
    confirmationRequests.add(
      (taskId: taskId, continueDownload: continueDownload),
    );
  }

  Future<void> dispose() => taskEventsController.close();
}
