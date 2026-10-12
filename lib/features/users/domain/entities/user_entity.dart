class UserEntity {
  final String id;
  final String name;
  final String email;
  final bool isActive;
  final DateTime? lastLoginAt;
  final List<RoleSummary> roles;
  final List<String> directPermissions;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.isActive,
    this.lastLoginAt,
    required this.roles,
    required this.directPermissions,
  });
}

class RoleSummary {
  final String id;
  final String name;

  const RoleSummary({required this.id, required this.name});
}

class UserFormData {
  final String name;
  final String email;
  final String? password;
  final List<String> roleIds;
  final bool isActive;
  final List<String> directPermissions;

  const UserFormData({
    required this.name,
    required this.email,
    this.password,
    required this.roleIds,
    required this.isActive,
    this.directPermissions = const [],
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        if (password != null && password!.isNotEmpty) 'password': password,
        'role_ids': roleIds,
        'is_active': isActive,
        'direct_permissions': directPermissions,
      };
}
