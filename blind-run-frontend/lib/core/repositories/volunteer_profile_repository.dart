import 'package:aidrun_demo/core/models/available_time_slot.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/network/api_client.dart';

abstract class VolunteerProfileRepository {
  Future<VolunteerProfile> getProfile();
  Future<VolunteerProfile> updateProfile(VolunteerProfile profile);
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required bool isOnline,
  });
}

class HttpVolunteerProfileRepository implements VolunteerProfileRepository {
  HttpVolunteerProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<VolunteerProfile> getProfile() async {
    final response = await _apiClient.get('/api/volunteer/profile') as Map<String, dynamic>;
    return _parseProfile(response);
  }

  @override
  Future<VolunteerProfile> updateProfile(VolunteerProfile profile) async {
    final response = await _apiClient.put('/api/volunteer/profile', body: {
      'name': profile.name,
      'availableTimeSlots': profile.availableTimeSlots
          .map(
            (slot) => {
              'dayOfWeek': slot.dayOfWeek,
              'startTime': slot.startTime,
              'endTime': slot.endTime,
            },
          )
          .toList(),
    }) as Map<String, dynamic>;
    return _parseProfile((response['data'] as Map?)?.cast<String, dynamic>() ?? response);
  }

  @override
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) async {
    await _apiClient.post('/api/volunteer/location', body: {
      'latitude': latitude,
      'longitude': longitude,
      'isOnline': isOnline,
    });
  }

  VolunteerProfile _parseProfile(Map<String, dynamic> data) {
    final slots = data['availableTimeSlots'];
    return VolunteerProfile(
      id: '',
      name: data['name'] as String? ?? '',
      verificationStatus: data['verificationStatus'] as String? ?? '',
      availableTimeSlots: slots is List
          ? slots
              .whereType<Map>()
              .map(
                (item) => AvailableTimeSlot(
                  dayOfWeek: item['dayOfWeek'] as String? ?? '',
                  startTime: item['startTime'] as String? ?? '',
                  endTime: item['endTime'] as String? ?? '',
                ),
              )
              .toList(growable: false)
          : const [],
    );
  }
}
