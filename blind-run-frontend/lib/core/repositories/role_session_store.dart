import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class RoleSessionStore {
  UserRole? readRole();
  void saveRole(UserRole role);
  void clearRole();
}

class SharedPrefsRoleSessionStore implements RoleSessionStore {
  SharedPrefsRoleSessionStore(this._preferences);

  static const _key = 'aidrun_role';
  final SharedPreferences _preferences;

  @override
  UserRole? readRole() => UserRoleX.fromStorage(_preferences.getString(_key));

  @override
  void saveRole(UserRole role) {
    _preferences.setString(_key, role.storageValue);
  }

  @override
  void clearRole() {
    _preferences.remove(_key);
  }
}
