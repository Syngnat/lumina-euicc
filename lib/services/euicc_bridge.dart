import 'dart:async';

import 'package:flutter/services.dart';

import '../models/euicc_models.dart';

/// MethodChannel contract aligned with EasyEUICC LPA operations.
class EuiccBridge {
  EuiccBridge({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methods = methodChannel ??
            const MethodChannel('top.syngnat.lumina.euicc/bridge'),
        _events = eventChannel ??
            const EventChannel('top.syngnat.lumina.euicc/task_events');

  final MethodChannel _methods;
  final EventChannel _events;

  Stream<DownloadTaskEvent> get taskEvents =>
      _events.receiveBroadcastStream().map((raw) {
        final map = Map<dynamic, dynamic>.from(raw as Map);
        return DownloadTaskEvent.fromMap(map);
      });

  Future<List<EuiccChannelInfo>> listChannels() async {
    final raw = await _methods.invokeMethod<Map>('listChannels');
    final list = (raw?['channels'] as List?) ?? const [];
    return list
        .map((e) =>
            EuiccChannelInfo.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<EuiccProfile>> listProfiles({
    required int slotId,
    required int portId,
    required String seId,
  }) async {
    final raw = await _methods.invokeMethod<Map>('listProfiles', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
    });
    final list = (raw?['profiles'] as List?) ?? const [];
    return list
        .map((e) => EuiccProfile.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> switchProfile({
    required int slotId,
    required int portId,
    required String seId,
    required String iccid,
    required bool enable,
  }) async {
    await _methods.invokeMethod('switchProfile', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
      'iccid': iccid,
      'enable': enable,
    });
  }

  Future<void> deleteProfile({
    required int slotId,
    required int portId,
    required String seId,
    required String iccid,
  }) async {
    await _methods.invokeMethod('deleteProfile', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
      'iccid': iccid,
    });
  }

  Future<void> renameProfile({
    required int slotId,
    required int portId,
    required String seId,
    required String iccid,
    required String name,
  }) async {
    await _methods.invokeMethod('renameProfile', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
      'iccid': iccid,
      'name': name,
    });
  }

  Future<String> downloadProfile({
    required int slotId,
    required int portId,
    required String seId,
    required String activationCode,
    String? confirmationCode,
    String? imei,
  }) async {
    final raw = await _methods.invokeMethod<Map>('downloadProfile', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
      'activationCode': activationCode,
      if (confirmationCode != null) 'confirmationCode': confirmationCode,
      if (imei != null) 'imei': imei,
    });
    final taskId = raw?['taskId']?.toString();
    if (taskId == null || taskId.isEmpty) {
      throw StateError('Native download did not return a taskId');
    }
    return taskId;
  }

  Future<void> confirmDownload({
    required String taskId,
    required bool continueDownload,
  }) async {
    await _methods.invokeMethod('confirmDownload', {
      'taskId': taskId,
      'continue': continueDownload,
    });
  }

  Future<void> cancelDownload({required String taskId}) async {
    await _methods.invokeMethod('cancelDownload', {'taskId': taskId});
  }

  Future<List<CompatibilityItem>> runCompatibilityCheck() async {
    final raw = await _methods.invokeMethod<Map>('runCompatibilityCheck');
    final list = (raw?['items'] as List?) ?? const [];
    return list
        .map((e) =>
            CompatibilityItem.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getEuiccInfo({
    required int slotId,
    required int portId,
    required String seId,
  }) async {
    final raw = await _methods.invokeMethod<Map>('getEuiccInfo', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
    });
    return Map<String, dynamic>.from(raw ?? const {});
  }

  Future<void> memoryReset({
    required int slotId,
    required int portId,
    required String seId,
  }) async {
    await _methods.invokeMethod('memoryReset', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
    });
  }

  Future<List<Map<String, dynamic>>> listNotifications({
    required int slotId,
    required int portId,
    required String seId,
  }) async {
    final raw = await _methods.invokeMethod<Map>('listNotifications', {
      'slotId': slotId,
      'portId': portId,
      'seId': seId,
    });
    final list = (raw?['notifications'] as List?) ?? const [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
