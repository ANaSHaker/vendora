import '../../domain/entities/branch_entity.dart';

class BranchModel extends BranchManagementEntity {
  const BranchModel({
    required super.id,
    required super.name,
    super.address,
    required super.isDefault,
    required super.isActive,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        address: json['location'] as String?,
        isDefault: json['is_main'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
      );
}
