import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthSessionStore {
  AuthSession? readSession();
  void saveSession(AuthSession session);
  void clearSession();
}

class SharedPrefsAuthSessionStore implements AuthSessionStore {
  SharedPrefsAuthSessionStore(this._preferences);

  static const _tokenKey = 'aidrun_token';
  static const _userIdKey = 'aidrun_user_id';
  static const _roleKey = 'aidrun_role';

  final SharedPreferences _preferences;

  @override
  AuthSession? readSession() {
    final token = _preferences.getString(_tokenKey);
    final userId = _preferences.getInt(_userIdKey);
    final role = UserRoleX.fromBackend(_preferences.getString(_roleKey));
    if (token == null || token.isEmpty || userId == null || role == null) {
      return null;
    }
    return AuthSession(token: token, userId: userId, role: role);
  }

  @override
  void saveSession(AuthSession session) {
    _preferences.setString(_tokenKey, session.token);
    _preferences.setInt(_userIdKey, session.userId);
    _preferences.setString(_roleKey, session.role.backendValue);
  }

  @override
  void clearSession() {
    _preferences.remove(_tokenKey);
    _preferences.remove(_userIdKey);
    _preferences.remove(_roleKey);
  }
}
