class AppSettings {
  const AppSettings({
    this.emergencyContact = '',
    this.notificationsEnabled = true,
    this.volunteerAvailable = true,
  });

  final String emergencyContact;
  final bool notificationsEnabled;
  final bool volunteerAvailable;

  AppSettings copyWith({
    String? emergencyContact,
    bool? notificationsEnabled,
    bool? volunteerAvailable,
  }) {
    return AppSettings(
      emergencyContact: emergencyContact ?? this.emergencyContact,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      volunteerAvailable: volunteerAvailable ?? this.volunteerAvailable,
    );
  }
}
