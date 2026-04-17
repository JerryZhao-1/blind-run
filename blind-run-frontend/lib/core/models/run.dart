import 'package:aidrun_demo/core/models/run_rating.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';

class Run {
  const Run({
    required this.id,
    required this.blindRunnerId,
    required this.location,
    required this.timeLabel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.address = '',
    this.volunteer,
    this.blindRating,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.durationMinutes,
  });

  final String id;
  final String blindRunnerId;
  final String location;
  final String timeLabel;
  final String notes;
  final String address;
  final RunStatus status;
  final VolunteerProfile? volunteer;
  final RunRating? blindRating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final int? durationMinutes;

  Run copyWith({
    String? id,
    String? blindRunnerId,
    String? location,
    String? timeLabel,
    String? notes,
    String? address,
    RunStatus? status,
    VolunteerProfile? volunteer,
    bool clearVolunteer = false,
    RunRating? blindRating,
    bool clearBlindRating = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? durationMinutes,
  }) {
    return Run(
      id: id ?? this.id,
      blindRunnerId: blindRunnerId ?? this.blindRunnerId,
      location: location ?? this.location,
      timeLabel: timeLabel ?? this.timeLabel,
      notes: notes ?? this.notes,
      address: address ?? this.address,
      status: status ?? this.status,
      volunteer: clearVolunteer ? null : (volunteer ?? this.volunteer),
      blindRating: clearBlindRating ? null : (blindRating ?? this.blindRating),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
