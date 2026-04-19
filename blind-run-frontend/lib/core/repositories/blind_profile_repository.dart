import 'package:aidrun_demo/core/models/blind_profile.dart';
import 'package:aidrun_demo/core/network/api_client.dart';

abstract class BlindProfileRepository {
  Future<BlindProfile> getProfile();
  Future<BlindProfile> updateProfile(BlindProfile profile);
}

class HttpBlindProfileRepository implements BlindProfileRepository {
  HttpBlindProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<BlindProfile> getProfile() async {
    final response = await _apiClient.get('/api/blind/profile') as Map<String, dynamic>;
    return _parseProfile(response);
  }

  @override
  Future<BlindProfile> updateProfile(BlindProfile profile) async {
    final response = await _apiClient.put('/api/blind/profile', body: {
      'name': profile.name,
      'runningPace': profile.runningPace,
      'specialNeeds': profile.specialNeeds,
    }) as Map<String, dynamic>;
    return _parseProfile((response['data'] as Map?)?.cast<String, dynamic>() ?? response);
  }

  BlindProfile _parseProfile(Map<String, dynamic> data) {
    return BlindProfile(
      name: data['name'] as String? ?? '',
      runningPace: data['runningPace'] as String? ?? '',
      specialNeeds: data['specialNeeds'] as String? ?? '',
    );
  }
}
