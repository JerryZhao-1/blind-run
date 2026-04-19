class BlindProfile {
  const BlindProfile({
    this.name = '',
    this.runningPace = '',
    this.specialNeeds = '',
  });

  final String name;
  final String runningPace;
  final String specialNeeds;

  BlindProfile copyWith({
    String? name,
    String? runningPace,
    String? specialNeeds,
  }) {
    return BlindProfile(
      name: name ?? this.name,
      runningPace: runningPace ?? this.runningPace,
      specialNeeds: specialNeeds ?? this.specialNeeds,
    );
  }
}
