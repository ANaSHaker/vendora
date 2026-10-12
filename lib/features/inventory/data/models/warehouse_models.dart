import '../../domain/entities/warehouse_entities.dart';

class WarehouseModel extends WarehouseEntity {
  const WarehouseModel({
    required super.id,
    required super.name,
    required super.code,
    required super.type,
    required super.isActive,
    required super.isDefault,
    super.notes,
    super.branchName,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) {
    return WarehouseModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'main',
      isActive: json['is_active'] as bool? ?? true,
      isDefault: json['is_default'] as bool? ?? false,
      notes: json['notes'] as String?,
      branchName: json['branch_name'] as String?,
    );
  }

  Map<String, dynamic> toJson(WarehouseFormData data) => {
        'name': data.name,
        'code': data.code.toUpperCase(),
        'type': data.type,
        'is_active': data.isActive,
        'is_default': data.isDefault,
        if (data.notes != null && data.notes!.isNotEmpty) 'notes': data.notes,
        if (data.branchId != null && data.branchId!.isNotEmpty)
          'branch_id': data.branchId,
      };
}
