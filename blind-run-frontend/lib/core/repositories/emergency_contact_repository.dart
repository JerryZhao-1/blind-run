import 'package:aidrun_demo/core/models/emergency_contact.dart';
import 'package:aidrun_demo/core/network/api_client.dart';

abstract class EmergencyContactRepository {
  Future<List<EmergencyContact>> listContacts(int userId);
  Future<EmergencyContact> createContact(
    int userId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  });
  Future<EmergencyContact> updateContact(
    int userId,
    int contactId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  });
  Future<void> deleteContact(int userId, int contactId);
  Future<void> setPrimary(int userId, int contactId);
}

class HttpEmergencyContactRepository implements EmergencyContactRepository {
  HttpEmergencyContactRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<EmergencyContact>> listContacts(int userId) async {
    final response = await _apiClient.get('/api/users/$userId/emergency-contacts');
    if (response is! List) {
      return const [];
    }
    return response
        .whereType<Map>()
        .map((item) => _parse(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<EmergencyContact> createContact(
    int userId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final response = await _apiClient.post(
      '/api/users/$userId/emergency-contacts',
      body: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'isPrimary': isPrimary,
      },
    ) as Map<String, dynamic>;
    return _parse(response);
  }

  @override
  Future<EmergencyContact> updateContact(
    int userId,
    int contactId, {
    required String name,
    required String phone,
    required String relationship,
    required bool isPrimary,
  }) async {
    final response = await _apiClient.put(
      '/api/users/$userId/emergency-contacts/$contactId',
      body: {
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'isPrimary': isPrimary,
      },
    ) as Map<String, dynamic>;
    return _parse(response);
  }

  @override
  Future<void> deleteContact(int userId, int contactId) async {
    await _apiClient.delete('/api/users/$userId/emergency-contacts/$contactId');
  }

  @override
  Future<void> setPrimary(int userId, int contactId) async {
    await _apiClient.put('/api/users/$userId/emergency-contacts/$contactId/set-primary');
  }

  EmergencyContact _parse(Map<String, dynamic> data) {
    return EmergencyContact(
      id: _readInt(data['id']) ?? 0,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      relationship: data['relationship'] as String? ?? '',
      isPrimary: data['isPrimary'] as bool? ?? false,
    );
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
