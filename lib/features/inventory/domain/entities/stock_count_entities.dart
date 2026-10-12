import 'package:equatable/equatable.dart';

class StockCountEntity extends Equatable {
  final String id;
  final String reference;
  final String status;
  final String? branchId;
  final String? branchName;
  final String warehouseName;
  final String warehouseCode;
  final String? notes;
  final String createdAt;
  final String? postedAt;
  final String? lastMovementAt;
  final int itemsCount;
  final List<StockCountItemEntity>? items;

  const StockCountEntity({
    required this.id,
    required this.reference,
    required this.status,
    this.branchId,
    this.branchName,
    required this.warehouseName,
    required this.warehouseCode,
    this.notes,
    required this.createdAt,
    this.postedAt,
    this.lastMovementAt,
    required this.itemsCount,
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        branchId,
        branchName,
        warehouseName,
        warehouseCode,
        notes,
        createdAt,
        postedAt,
        lastMovementAt,
        itemsCount,
        items,
      ];
}

class StockCountItemEntity extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? productUnit;
  final double systemQty;
  final double countedQty;
  final double varianceQty;
  final double? unitCost;

  const StockCountItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productUnit,
    required this.systemQty,
    required this.countedQty,
    required this.varianceQty,
    this.unitCost,
  });

  @override
  List<Object?> get props =>
      [id, productId, productName, productSku, productUnit, systemQty, countedQty, varianceQty, unitCost];
}

class StockCountItemInput extends Equatable {
  final String productId;
  final double countedQty;

  const StockCountItemInput({
    required this.productId,
    required this.countedQty,
  });

  @override
  List<Object?> get props => [productId, countedQty];
}

class StockCountFormData extends Equatable {
  final String? reference;
  final String? branchId;
  final String warehouseId;
  final String? notes;
  final List<StockCountItemInput> items;

  const StockCountFormData({
    this.reference,
    this.branchId,
    required this.warehouseId,
    this.notes,
    this.items = const [],
  });

  @override
  List<Object?> get props => [reference, branchId, warehouseId, notes, items];
}
