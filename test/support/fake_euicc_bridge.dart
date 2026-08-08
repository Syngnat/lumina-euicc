import 'dart:async';

import 'package:lumina_euicc/models/euicc_models.dart';
import 'package:lumina_euicc/services/euicc_bridge.dart';

class FakeEuiccBridge extends EuiccBridge {
  List<EuiccChannelInfo> channels = const [];
  List<EuiccProfile> profiles = const [];
  List<CompatibilityItem> compatibilityItems = const [];
  int downloadCalls = 0;
  int cancelDownloadCalls = 0;
  int confirmDownloadCalls = 0;
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
