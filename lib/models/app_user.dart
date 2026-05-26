enum UserRole { visitor, tenant, owner, admin, agent, client }

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.role,
    this.email,
    this.avatarPath,
    this.isBlocked = false,
  });

  final String id;
  final String fullName;
  final String phone;
  final UserRole role;
  final String? email;
  final String? avatarPath;
  final bool isBlocked;

  bool get canManageAgency => role == UserRole.agent || role == UserRole.admin;

  AppUser copyWith({
    String? id,
    String? fullName,
    String? phone,
    UserRole? role,
    String? email,
    String? avatarPath,
    bool? isBlocked,
  }) {
    return AppUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      email: email ?? this.email,
      avatarPath: avatarPath ?? this.avatarPath,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
