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

class CompatibilityItem {
  const CompatibilityItem({
    required this.title,
    required this.ok,
    required this.detail,
  });

  final String title;
  final bool ok;
  final String detail;

  factory CompatibilityItem.fromMap(Map<dynamic, dynamic> map) {
    return CompatibilityItem(
      title: map['title']?.toString() ?? '',
      ok: map['ok'] as bool? ?? false,
      detail: map['detail']?.toString() ?? '',
    );
  }
}

class DownloadTaskEvent {
  const DownloadTaskEvent({
    required this.phase,
    this.progress,
    this.provider,
    this.name,
    this.needConfirmation = false,
    this.done = false,
    this.error,
  });

  final String phase;
  final double? progress;
  final String? provider;
  final String? name;
  final bool needConfirmation;
  final bool done;
  final String? error;

  factory DownloadTaskEvent.fromMap(Map<dynamic, dynamic> map) {
    return DownloadTaskEvent(
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
