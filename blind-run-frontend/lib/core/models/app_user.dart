import 'package:aidrun_demo/core/models/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String displayName;
  final UserRole role;
}
