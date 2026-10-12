import '../../domain/entities/cost_layer_entities.dart';

class CostLayerModel extends CostLayerEntity {
  const CostLayerModel({
    required super.id,
    required super.productName,
    super.productSku,
    required super.warehouseName,
    required super.warehouseCode,
    required super.originalQty,
    required super.remainingQty,
    required super.unitCost,
    required super.totalValue,
    required super.status,
    super.referenceType,
    super.referenceId,
    required super.createdAt,
    required super.ageDays,
  });

  factory CostLayerModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    return CostLayerModel(
      id: json['id']?.toString() ?? '',
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      productSku: product?['sku'] as String? ?? json['product_sku'] as String?,
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String? ?? '',
      warehouseCode: warehouse?['code'] as String? ?? json['warehouse_code'] as String? ?? '',
      originalQty: (json['original_qty'] as num?)?.toDouble() ?? 0.0,
      remainingQty: (json['remaining_qty'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
      totalValue: (json['total_value'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'full',
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
      ageDays: (json['age_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class CostLayerConsumptionModel extends CostLayerConsumptionEntity {
  const CostLayerConsumptionModel({
    required super.id,
    required super.consumedQty,
    required super.unitCost,
    required super.totalCost,
    super.referenceType,
    super.referenceId,
    required super.createdAt,
  });

  factory CostLayerConsumptionModel.fromJson(Map<String, dynamic> json) {
    return CostLayerConsumptionModel(
      id: json['id']?.toString() ?? '',
      consumedQty: (json['consumed_qty'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0.0,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
