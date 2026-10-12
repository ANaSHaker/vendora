import '../../domain/entities/role_entity.dart';

class PermissionModel extends PermissionEntity {
  const PermissionModel({
    required super.name,
    required super.label,
    required super.description,
  });

  factory PermissionModel.fromJson(Map<String, dynamic> json) =>
      PermissionModel(
        name: json['name'] as String? ?? '',
        label: json['label'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );
}

class PermissionModuleModel extends PermissionModuleEntity {
  const PermissionModuleModel({
    required super.key,
    required super.label,
    required super.description,
    required super.icon,
    required super.order,
    required super.permissions,
  });

  factory PermissionModuleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List<dynamic>? ?? [];
    final permissions = rawPerms
        .whereType<Map<String, dynamic>>()
        .map(PermissionModel.fromJson)
        .toList();

    return PermissionModuleModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      permissions: permissions,
    );
  }
}

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    super.description,
    required super.isSystem,
    required super.isProtected,
    required super.isOwner,
    required super.usersCount,
    required super.permissions,
    super.createdAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List<dynamic>? ?? [];
    final permissions = rawPerms.cast<String>();

    return RoleModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      isProtected: json['is_protected'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
      usersCount: json['users_count'] as int? ?? 0,
      permissions: permissions,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
