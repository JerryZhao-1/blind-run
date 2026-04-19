import 'package:aidrun_demo/core/models/available_time_slot.dart';

class VolunteerProfile {
  const VolunteerProfile({
    required this.id,
    required this.name,
    required this.verificationStatus,
    required this.availableTimeSlots,
    this.rating,
    this.phone,
    this.avatarSeed = 'volunteer-main',
  });

  final String id;
  final String name;
  final String verificationStatus;
  final List<AvailableTimeSlot> availableTimeSlots;
  final double? rating;
  final String? phone;
  final String avatarSeed;

  VolunteerProfile copyWith({
    String? id,
    String? name,
    String? verificationStatus,
    List<AvailableTimeSlot>? availableTimeSlots,
    double? rating,
    String? phone,
    String? avatarSeed,
  }) {
    return VolunteerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      rating: rating ?? this.rating,
      phone: phone ?? this.phone,
      avatarSeed: avatarSeed ?? this.avatarSeed,
    );
  }
}
