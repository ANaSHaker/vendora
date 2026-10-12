import 'package:equatable/equatable.dart';

class InventoryBranchOptionEntity {
  final String id;
  final String name;
  const InventoryBranchOptionEntity({required this.id, required this.name});
}

class InventoryBalanceEntity extends Equatable {
  final String productId;
  final String productName;
  final String? productSku;
  final String? productUnit;
  final double? productLowStockThreshold;
  final String warehouseId;
  final String warehouseName;
  final String warehouseCode;
  final String warehouseType;
  final String? branchName;
  final double onHandQty;
  final double reservedQty;
  final double availableQty;
  final double averageCost;

  const InventoryBalanceEntity({
    required this.productId,
    required this.productName,
    this.productSku,
    this.productUnit,
    this.productLowStockThreshold,
    required this.warehouseId,
    required this.warehouseName,
    required this.warehouseCode,
    this.warehouseType = 'main',
    this.branchName,
    required this.onHandQty,
    required this.reservedQty,
    required this.availableQty,
    required this.averageCost,
  });

  bool get isLowStock {
    final threshold = productLowStockThreshold;
    if (threshold == null) return false;
    return availableQty <= threshold;
  }

  bool get isOutOfStock => onHandQty <= 0;

  String get stockStatus {
    if (isOutOfStock) return 'out';
    final threshold = productLowStockThreshold;
    if (threshold != null && onHandQty <= threshold) return 'low';
    return 'ok';
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        productSku,
        productUnit,
        productLowStockThreshold,
        warehouseId,
        warehouseName,
        warehouseCode,
        warehouseType,
        branchName,
        onHandQty,
        reservedQty,
        availableQty,
        averageCost,
      ];
}

class InventoryMovementEntity extends Equatable {
  final String id;
  final String productName;
  final String? productSku;
  final String warehouseName;
  final String warehouseCode;
  final String movementType;
  final double qtyIn;
  final double qtyOut;
  final double balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String createdAt;

  const InventoryMovementEntity({
    required this.id,
    required this.productName,
    this.productSku,
    required this.warehouseName,
    required this.warehouseCode,
    required this.movementType,
    required this.qtyIn,
    required this.qtyOut,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        productName,
        productSku,
        warehouseName,
        warehouseCode,
        movementType,
        qtyIn,
        qtyOut,
        balanceAfter,
        referenceType,
        referenceId,
        notes,
        createdAt,
      ];
}

class WarehouseOptionEntity extends Equatable {
  final String id;
  final String name;
  final String code;

  const WarehouseOptionEntity({
    required this.id,
    required this.name,
    required this.code,
  });

  @override
  List<Object?> get props => [id, name, code];
}
