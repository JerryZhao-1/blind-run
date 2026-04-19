enum VolunteerIntakeReadiness {
  offline,
  connecting,
  onlineReady,
  locationUnavailable,
  reportFailed,
}

extension VolunteerIntakeReadinessX on VolunteerIntakeReadiness {
  bool get isReady => this == VolunteerIntakeReadiness.onlineReady;
}
