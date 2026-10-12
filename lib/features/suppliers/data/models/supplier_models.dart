import '../../domain/entities/supplier_entities.dart';

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.taxNo,
    super.openingBalance,
    super.isActive,
    super.notes,
    super.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      taxNo: json['tax_no'] as String?,
      openingBalance:
          (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson(SupplierFormData data) => {
        'name': data.name,
        'phone': data.phone,
        'email': data.email,
        'address': data.address,
        'tax_no': data.taxNo,
        'opening_balance': data.openingBalance,
        'is_active': data.isActive,
        'notes': data.notes,
      };
}
