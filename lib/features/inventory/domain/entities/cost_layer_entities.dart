import 'package:equatable/equatable.dart';

class CostLayerEntity extends Equatable {
  final String id;
  final String productName;
  final String? productSku;
  final String warehouseName;
  final String warehouseCode;
  final double originalQty;
  final double remainingQty;
  final double unitCost;
  final double totalValue;
  final String status; // full | partial | exhausted
  final String? referenceType;
  final String? referenceId;
  final String createdAt;
  final int ageDays;

  const CostLayerEntity({
    required this.id,
    required this.productName,
    this.productSku,
    required this.warehouseName,
    required this.warehouseCode,
    required this.originalQty,
    required this.remainingQty,
    required this.unitCost,
    required this.totalValue,
    required this.status,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
    required this.ageDays,
  });

  @override
  List<Object?> get props => [
        id, productName, productSku, warehouseName, warehouseCode,
        originalQty, remainingQty, unitCost, totalValue, status,
        referenceType, referenceId, createdAt, ageDays,
      ];
}

class CostLayerConsumptionEntity extends Equatable {
  final String id;
  final double consumedQty;
  final double unitCost;
  final double totalCost;
  final String? referenceType;
  final String? referenceId;
  final String createdAt;

  const CostLayerConsumptionEntity({
    required this.id,
    required this.consumedQty,
    required this.unitCost,
    required this.totalCost,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, consumedQty, unitCost, totalCost, referenceType, referenceId, createdAt];
}

class CostLayerFilters extends Equatable {
  final String? search;
  final String? warehouseId;
  final String? branchId;
  final String? productId;
  final String? dateFrom;
  final String? dateTo;

  const CostLayerFilters({
    this.search,
    this.warehouseId,
    this.branchId,
    this.productId,
    this.dateFrom,
    this.dateTo,
  });

  @override
  List<Object?> get props =>
      [search, warehouseId, branchId, productId, dateFrom, dateTo];
}
