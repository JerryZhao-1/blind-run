class AppSettings {
  const AppSettings({
    this.notificationsEnabled = true,
    this.volunteerAvailable = true,
  });

  final bool notificationsEnabled;
  final bool volunteerAvailable;

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? volunteerAvailable,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      volunteerAvailable: volunteerAvailable ?? this.volunteerAvailable,
    );
  }
}
