import '../models/app_user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String token;
  final String userId;
  final String fullName;
  final String email;
  final UserRole role;
}
