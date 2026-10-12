class RoleEntity {
  final String id;
  final String name;
  final String? description;
  final bool isSystem;
  final bool isProtected;
  final bool isOwner;
  final int usersCount;
  final List<String> permissions;
  final DateTime? createdAt;

  const RoleEntity({
    required this.id,
    required this.name,
    this.description,
    required this.isSystem,
    required this.isProtected,
    required this.isOwner,
    required this.usersCount,
    required this.permissions,
    this.createdAt,
  });
}

class PermissionModuleEntity {
  final String key;
  final String label;
  final String description;
  final String icon;
  final int order;
  final List<PermissionEntity> permissions;

  const PermissionModuleEntity({
    required this.key,
    required this.label,
    required this.description,
    required this.icon,
    required this.order,
    required this.permissions,
  });
}

class PermissionEntity {
  final String name;
  final String label;
  final String description;

  const PermissionEntity({
    required this.name,
    required this.label,
    required this.description,
  });
}

class RoleFormData {
  final String name;
  final String? description;
  final List<String> permissions;

  const RoleFormData({
    required this.name,
    this.description,
    required this.permissions,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'permissions': permissions,
      };
}
