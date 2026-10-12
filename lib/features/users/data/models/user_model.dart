import '../../domain/entities/user_entity.dart';

class RoleSummaryModel extends RoleSummary {
  const RoleSummaryModel({required super.id, required super.name});

  factory RoleSummaryModel.fromJson(Map<String, dynamic> json) =>
      RoleSummaryModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.isActive,
    super.lastLoginAt,
    required super.roles,
    required super.directPermissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'] as List<dynamic>? ?? [];
    final roles = rawRoles
        .whereType<Map<String, dynamic>>()
        .map(RoleSummaryModel.fromJson)
        .toList();

    final rawPerms = json['direct_permissions'] as List<dynamic>? ?? [];
    final directPermissions = rawPerms.cast<String>();

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      roles: roles,
      directPermissions: directPermissions,
    );
  }
}
