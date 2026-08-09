class EuiccChannelInfo {
  const EuiccChannelInfo({
    required this.slotId,
    required this.portId,
    required this.seId,
    required this.label,
    required this.type,
  });

  final int slotId;
  final int portId;
  final String seId;
  final String label;
  final String type; // omapi | usb

  factory EuiccChannelInfo.fromMap(Map<dynamic, dynamic> map) {
    return EuiccChannelInfo(
      slotId: map['slotId'] as int? ?? 0,
      portId: map['portId'] as int? ?? 0,
      seId: map['seId']?.toString() ?? 'default',
      label: map['label']?.toString() ?? 'eUICC',
      type: map['type']?.toString() ?? 'omapi',
    );
  }
}

class EuiccProfile {
  const EuiccProfile({
    required this.iccid,
    required this.name,
    required this.provider,
    required this.enabled,
    required this.profileClass,
    required this.seq,
  });

  final String iccid;
  final String name;
  final String provider;
  final bool enabled;
  final String profileClass;
  final int seq;

  factory EuiccProfile.fromMap(Map<dynamic, dynamic> map) {
    return EuiccProfile(
      iccid: map['iccid']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Profile',
      provider: map['provider']?.toString() ?? '',
      enabled: map['enabled'] as bool? ?? false,
      profileClass: map['profileClass']?.toString() ?? 'operational',
      seq: map['seq'] as int? ?? 0,
    );
  }

  EuiccProfile copyWith({
    String? name,
    bool? enabled,
  }) {
    return EuiccProfile(
      iccid: iccid,
      name: name ?? this.name,
      provider: provider,
      enabled: enabled ?? this.enabled,
      profileClass: profileClass,
      seq: seq,
    );
  }
}

class MicroDataKeepAliveResult {
  const MicroDataKeepAliveResult({
    required this.status,
    required this.restored,
    required this.maxResponseBodyBytes,
    this.failureCode,
    this.targetActivationAttempted = false,
    this.httpStatus,
    this.responseBodyBytes,
  });

  final String status;
  final String? failureCode;
  final bool restored;
  final bool targetActivationAttempted;
  final int? httpStatus;
  final int? responseBodyBytes;
  final int maxResponseBodyBytes;

  bool get connected => status == 'connected';

  factory MicroDataKeepAliveResult.fromMap(Map<dynamic, dynamic> map) {
    return MicroDataKeepAliveResult(
      status: map['status']?.toString() ?? 'failed',
      failureCode: map['failureCode']?.toString(),
      restored: map['restored'] as bool? ?? false,
      targetActivationAttempted:
          map['targetActivationAttempted'] as bool? ?? false,
      httpStatus: (map['httpStatus'] as num?)?.toInt(),
      responseBodyBytes: (map['responseBodyBytes'] as num?)?.toInt(),
      maxResponseBodyBytes:
          (map['maxResponseBodyBytes'] as num?)?.toInt() ?? 1024,
    );
  }
}

class CompatibilityItem {
  const CompatibilityItem({
    required this.code,
    required this.title,
    required this.ok,
    required this.detail,
    this.arguments = const {},
  });

  final String code;
  final String title;
  final bool ok;
  final String detail;
  final Map<String, dynamic> arguments;

  factory CompatibilityItem.fromMap(Map<dynamic, dynamic> map) {
    return CompatibilityItem(
      code: map['code']?.toString() ?? 'unknown',
      title: map['title']?.toString() ?? '',
      ok: map['ok'] as bool? ?? false,
      detail: map['detail']?.toString() ?? '',
      arguments: Map<String, dynamic>.from(
        (map['arguments'] as Map?) ?? const {},
      ),
    );
  }
}

class DownloadTaskEvent {
  const DownloadTaskEvent({
    required this.taskId,
    required this.phase,
    this.progress,
    this.provider,
    this.name,
    this.needConfirmation = false,
    this.done = false,
    this.error,
  });

  final String taskId;
  final String phase;
  final double? progress;
  final String? provider;
  final String? name;
  final bool needConfirmation;
  final bool done;
  final String? error;

  factory DownloadTaskEvent.fromMap(Map<dynamic, dynamic> map) {
    final taskId = map['taskId']?.toString();
    if (taskId == null || taskId.isEmpty) {
      throw const FormatException('Download task event is missing taskId');
    }
    return DownloadTaskEvent(
      taskId: taskId,
      phase: map['phase']?.toString() ?? 'unknown',
      progress: (map['progress'] as num?)?.toDouble(),
      provider: map['provider']?.toString(),
      name: map['name']?.toString(),
      needConfirmation: map['needConfirmation'] as bool? ?? false,
      done: map['done'] as bool? ?? false,
      error: map['error']?.toString(),
    );
  }
}
