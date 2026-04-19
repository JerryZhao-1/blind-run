import 'package:aidrun_demo/core/models/user_role.dart';

class CurrentUser {
  const CurrentUser({
    required this.userId,
    required this.phoneMasked,
    required this.role,
    this.createdAt,
  });

  final int userId;
  final String phoneMasked;
  final UserRole role;
  final DateTime? createdAt;

  String get displayName => switch (role) {
        UserRole.blind => '盲人跑者',
        UserRole.volunteer => '爱心志愿者',
        UserRole.unset => '新用户',
      };
}
