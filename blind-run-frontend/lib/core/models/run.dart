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
    this.plannedStart,
    this.plannedEnd,
    this.volunteerPhone,
    this.blindUserPhone,
    this.volunteerOwnershipConfirmed = false,
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
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final String? volunteerPhone;
  final String? blindUserPhone;
  final bool volunteerOwnershipConfirmed;

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
    DateTime? plannedStart,
    DateTime? plannedEnd,
    String? volunteerPhone,
    String? blindUserPhone,
    bool? volunteerOwnershipConfirmed,
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
      plannedStart: plannedStart ?? this.plannedStart,
      plannedEnd: plannedEnd ?? this.plannedEnd,
      volunteerPhone: volunteerPhone ?? this.volunteerPhone,
      blindUserPhone: blindUserPhone ?? this.blindUserPhone,
      volunteerOwnershipConfirmed:
          volunteerOwnershipConfirmed ?? this.volunteerOwnershipConfirmed,
    );
  }

  Run mergedWith(Run fallback) {
    return copyWith(
      location: location.isNotEmpty ? location : fallback.location,
      timeLabel: timeLabel.isNotEmpty ? timeLabel : fallback.timeLabel,
      notes: notes.isNotEmpty ? notes : fallback.notes,
      address: address.isNotEmpty ? address : fallback.address,
      volunteer: volunteer ?? fallback.volunteer,
      blindRating: blindRating ?? fallback.blindRating,
      createdAt: createdAt,
      updatedAt: updatedAt,
      latitude: latitude ?? fallback.latitude,
      longitude: longitude ?? fallback.longitude,
      distanceKm: distanceKm ?? fallback.distanceKm,
      durationMinutes: durationMinutes ?? fallback.durationMinutes,
      plannedStart: plannedStart ?? fallback.plannedStart,
      plannedEnd: plannedEnd ?? fallback.plannedEnd,
      volunteerPhone: _preferNonEmpty(volunteerPhone, fallback.volunteerPhone),
      blindUserPhone: _preferNonEmpty(blindUserPhone, fallback.blindUserPhone),
      volunteerOwnershipConfirmed:
          volunteerOwnershipConfirmed || fallback.volunteerOwnershipConfirmed,
    );
  }

  bool get hasPickupCoordinates => latitude != null && longitude != null;

  String? _preferNonEmpty(String? primary, String? secondary) {
    if (primary != null && primary.trim().isNotEmpty) {
      return primary;
    }
    return secondary;
  }

  static String formatTimeLabel(DateTime? start, DateTime? end) {
    if (start == null) {
      return '';
    }
    final now = DateTime.now();
    final sameDay = start.year == now.year &&
        start.month == now.month &&
        start.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = start.year == tomorrow.year &&
        start.month == tomorrow.month &&
        start.day == tomorrow.day;
    final startText = _hhmm(start);
    final endText = end == null ? null : _hhmm(end);
    final prefix = sameDay
        ? '今天'
        : isTomorrow
            ? '明天'
            : '${start.month}月${start.day}日';
    return endText == null ? '$prefix $startText' : '$prefix $startText-$endText';
  }

  static String _hhmm(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
