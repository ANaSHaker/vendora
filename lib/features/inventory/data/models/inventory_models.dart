import '../../domain/entities/inventory_entities.dart';

class InventoryBranchOptionModel extends InventoryBranchOptionEntity {
  const InventoryBranchOptionModel({required super.id, required super.name});

  factory InventoryBranchOptionModel.fromJson(Map<String, dynamic> json) {
    return InventoryBranchOptionModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class InventoryBalanceModel extends InventoryBalanceEntity {
  const InventoryBalanceModel({
    required super.productId,
    required super.productName,
    super.productSku,
    super.productUnit,
    super.productLowStockThreshold,
    required super.warehouseId,
    required super.warehouseName,
    required super.warehouseCode,
    super.warehouseType,
    super.branchName,
    required super.onHandQty,
    required super.reservedQty,
    required super.availableQty,
    required super.averageCost,
  });

  factory InventoryBalanceModel.fromJson(Map<String, dynamic> json) {
    // Support both nested JSON (from /inventory/warehouses)
    // and flat JSON (from /inventory/stock)
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;

    return InventoryBalanceModel(
      productId: product?['id']?.toString() ??
          json['product_id']?.toString() ??
          '',
      productName: product?['name'] as String? ??
          json['product_name'] as String? ??
          '',
      productSku: product?['sku'] as String? ??
          json['product_sku'] as String?,
      productUnit: product?['unit'] as String? ??
          json['product_unit'] as String?,
      productLowStockThreshold:
          (product?['low_stock_threshold'] as num?)?.toDouble() ??
          (json['product_low_stock_threshold'] as num?)?.toDouble(),
      warehouseId: warehouse?['id']?.toString() ??
          json['warehouse_id']?.toString() ??
          '',
      warehouseName: warehouse?['name'] as String? ??
          json['warehouse_name'] as String? ??
          '',
      warehouseCode: warehouse?['code'] as String? ??
          json['warehouse_code'] as String? ??
          '',
      warehouseType: warehouse?['type'] as String? ??
          json['warehouse_type'] as String? ??
          'main',
      branchName: branch?['name'] as String? ?? json['branch_name'] as String?,
      onHandQty: (json['on_hand_qty'] as num?)?.toDouble() ?? 0.0,
      reservedQty: (json['reserved_qty'] as num?)?.toDouble() ?? 0.0,
      availableQty: (json['available_qty'] as num?)?.toDouble() ?? 0.0,
      averageCost: (json['average_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InventoryMovementModel extends InventoryMovementEntity {
  const InventoryMovementModel({
    required super.id,
    required super.productName,
    super.productSku,
    required super.warehouseName,
    required super.warehouseCode,
    required super.movementType,
    required super.qtyIn,
    required super.qtyOut,
    required super.balanceAfter,
    super.referenceType,
    super.referenceId,
    super.notes,
    required super.createdAt,
  });

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final quantity = (json['quantity'] as num?)?.toDouble() ?? 0.0;
    return InventoryMovementModel(
      id: json['id']?.toString() ?? '',
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      productSku: product?['sku'] as String? ?? json['product_sku'] as String?,
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String? ?? '',
      warehouseCode: warehouse?['code'] as String? ?? json['warehouse_code'] as String? ?? '',
      movementType: json['type'] as String? ?? json['movement_type'] as String? ?? '',
      qtyIn: quantity > 0 ? quantity : (json['qty_in'] as num?)?.toDouble() ?? 0.0,
      qtyOut: quantity < 0 ? quantity.abs() : (json['qty_out'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['quantity_after'] as num?)?.toDouble() ?? (json['balance_after'] as num?)?.toDouble() ?? 0.0,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id']?.toString(),
      notes: json['note'] as String? ?? json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class WarehouseOptionModel extends WarehouseOptionEntity {
  const WarehouseOptionModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory WarehouseOptionModel.fromJson(Map<String, dynamic> json) {
    return WarehouseOptionModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}
