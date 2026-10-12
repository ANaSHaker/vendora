class BranchManagementEntity {
  final String id;
  final String name;
  final String? address;
  final bool isDefault;
  final bool isActive;

  const BranchManagementEntity({
    required this.id,
    required this.name,
    this.address,
    required this.isDefault,
    required this.isActive,
  });
}

class BranchFormData {
  final String name;
  final String? address;
  final bool isActive;
  final bool isDefault;

  const BranchFormData({
    required this.name,
    this.address,
    required this.isActive,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (address != null && address!.isNotEmpty) 'location': address,
        'is_active': isActive,
        'is_main': isDefault,
      };
}
