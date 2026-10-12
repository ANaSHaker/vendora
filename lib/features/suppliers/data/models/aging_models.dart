import '../../domain/entities/aging_entities.dart';

class AgingRowModel extends AgingRowEntity {
  const AgingRowModel({
    required super.supplierId,
    required super.supplierName,
    required super.current,
    required super.bucket1to30,
    required super.bucket31to60,
    required super.bucket61to90,
    required super.over90,
    required super.totalBalance,
  });

  factory AgingRowModel.fromJson(Map<String, dynamic> json) {
    return AgingRowModel(
      supplierId:   json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name'] as String? ?? '',
      current:      (json['current'] as num?)?.toDouble() ?? 0.0,
      bucket1to30:  (json['1_30'] as num?)?.toDouble() ?? 0.0,
      bucket31to60: (json['31_60'] as num?)?.toDouble() ?? 0.0,
      bucket61to90: (json['61_90'] as num?)?.toDouble() ?? 0.0,
      over90:       (json['over_90'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
