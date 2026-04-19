enum UserRole {
  unset,
  blind,
  volunteer,
}

extension UserRoleX on UserRole {
  String get storageValue => backendValue;

  String get backendValue => switch (this) {
        UserRole.unset => 'UNSET',
        UserRole.blind => 'BLIND',
        UserRole.volunteer => 'VOLUNTEER',
      };

  String get label => switch (this) {
        UserRole.unset => '待选择身份',
        UserRole.blind => '盲人跑者',
        UserRole.volunteer => '志愿者',
      };

  static UserRole? fromStorage(String? value) {
    return fromBackend(value);
  }

  static UserRole? fromBackend(String? value) {
    return switch (value?.toUpperCase()) {
      'UNSET' => UserRole.unset,
      'BLIND' => UserRole.blind,
      'VOLUNTEER' => UserRole.volunteer,
      _ => null,
    };
  }
}
