enum UserRole {
  blind,
  volunteer,
}

extension UserRoleX on UserRole {
  String get storageValue => name;

  String get label => switch (this) {
        UserRole.blind => '盲人跑者',
        UserRole.volunteer => '志愿者',
      };

  static UserRole? fromStorage(String? value) {
    return UserRole.values.where((role) => role.storageValue == value).firstOrNull;
  }
}
