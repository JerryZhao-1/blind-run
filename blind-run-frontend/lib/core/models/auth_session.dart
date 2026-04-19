import 'package:aidrun_demo/core/models/user_role.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.role,
  });

  final String token;
  final int userId;
  final UserRole role;

  AuthSession copyWith({
    String? token,
    int? userId,
    UserRole? role,
  }) {
    return AuthSession(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      role: role ?? this.role,
    );
  }
}
