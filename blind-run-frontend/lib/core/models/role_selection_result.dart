import 'package:aidrun_demo/core/models/user_role.dart';

class RoleSelectionResult {
  const RoleSelectionResult({required this.role, this.token, this.userId});

  final UserRole role;
  final String? token;
  final int? userId;
}
