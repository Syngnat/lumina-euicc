class ProfileReminder {
  const ProfileReminder({
    required this.at,
    required this.exact,
    required this.notificationPermissionGranted,
    required this.exactAlarmPermissionGranted,
  });

  factory ProfileReminder.fromMap(Map<dynamic, dynamic> map) {
    final triggerAtMillis = map['triggerAtMillis'];
    if (triggerAtMillis is! num || triggerAtMillis <= 0) {
      throw const FormatException('Invalid profile reminder timestamp');
    }
    return ProfileReminder(
      at: DateTime.fromMillisecondsSinceEpoch(triggerAtMillis.toInt()),
      exact: map['exact'] == true,
      notificationPermissionGranted:
          map['notificationPermissionGranted'] == true,
      exactAlarmPermissionGranted: map['exactAlarmPermissionGranted'] == true,
    );
  }

  final DateTime at;
  final bool exact;
  final bool notificationPermissionGranted;
  final bool exactAlarmPermissionGranted;
}
