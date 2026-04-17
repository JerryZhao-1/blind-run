class VolunteerProfile {
  const VolunteerProfile({
    required this.id,
    required this.name,
    required this.rating,
    required this.phone,
    required this.avatarSeed,
  });

  final String id;
  final String name;
  final double rating;
  final String phone;
  final String avatarSeed;
}
