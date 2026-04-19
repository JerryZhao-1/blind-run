import 'package:aidrun_demo/core/models/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsRepository {
  AppSettings load();
  void save(AppSettings settings);
}

class SharedPrefsSettingsRepository implements SettingsRepository {
  SharedPrefsSettingsRepository(this._preferences);

  static const _notificationsKey = 'aidrun_notifications_enabled';
  static const _availableKey = 'aidrun_volunteer_available';

  final SharedPreferences _preferences;

  @override
  AppSettings load() {
    return AppSettings(
      notificationsEnabled: _preferences.getBool(_notificationsKey) ?? true,
      volunteerAvailable: _preferences.getBool(_availableKey) ?? true,
    );
  }

  @override
  void save(AppSettings settings) {
    _preferences.setBool(_notificationsKey, settings.notificationsEnabled);
    _preferences.setBool(_availableKey, settings.volunteerAvailable);
  }
}
