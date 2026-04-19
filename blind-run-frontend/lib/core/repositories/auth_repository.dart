import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/current_user.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/network/api_client.dart';

abstract class AuthRepository {
  Future<void> sendCode(String phone);
  Future<AuthSession> verifyCode(String phone, String code);
  Future<CurrentUser> getCurrentUser();
  Future<UserRole> setRole(UserRole role);
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> sendCode(String phone) async {
    await _apiClient.post('/api/auth/send-code', body: {
      'phone': phone,
    });
  }

  @override
  Future<AuthSession> verifyCode(String phone, String code) async {
    final response = await _apiClient.post('/api/auth/verify-code', body: {
      'phone': phone,
      'code': code,
    }) as Map<String, dynamic>;
    return AuthSession(
      token: response['token'] as String? ?? '',
      userId: _readInt(response['userId']) ?? 0,
      role: UserRoleX.fromBackend(response['role'] as String?) ?? UserRole.unset,
    );
  }

  @override
  Future<CurrentUser> getCurrentUser() async {
    final response = await _apiClient.get('/api/auth/me') as Map<String, dynamic>;
    return CurrentUser(
      userId: _readInt(response['userId']) ?? 0,
      phoneMasked: response['phone'] as String? ?? '',
      role: UserRoleX.fromBackend(response['role'] as String?) ?? UserRole.unset,
      createdAt: _parseDateTime(response['createdAt']),
    );
  }

  @override
  Future<UserRole> setRole(UserRole role) async {
    await _apiClient.post('/api/user/role', body: {
      'role': role.backendValue,
    });
    return role;
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

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
