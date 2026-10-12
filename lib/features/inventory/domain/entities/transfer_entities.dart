import 'package:equatable/equatable.dart';

class TransferEntity extends Equatable {
  final String id;
  final String? reference;
  final String status;
  final String? fromBranchId;
  final String? fromBranchName;
  final String fromWarehouseName;
  final String fromWarehouseCode;
  final String? toBranchId;
  final String? toBranchName;
  final String toWarehouseName;
  final String toWarehouseCode;
  final String? notes;
  final String createdAt;
  final String? approvedAt;
  final String? postedAt;
  final String? receivedAt;
  final int itemsCount;
  final List<TransferItemEntity>? items;

  const TransferEntity({
    required this.id,
    this.reference,
    required this.status,
    this.fromBranchId,
    this.fromBranchName,
    required this.fromWarehouseName,
    required this.fromWarehouseCode,
    this.toBranchId,
    this.toBranchName,
    required this.toWarehouseName,
    required this.toWarehouseCode,
    this.notes,
    required this.createdAt,
    this.approvedAt,
    this.postedAt,
    this.receivedAt,
    required this.itemsCount,
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        fromBranchId,
        fromBranchName,
        fromWarehouseName,
        fromWarehouseCode,
        toBranchId,
        toBranchName,
        toWarehouseName,
        toWarehouseCode,
        notes,
        createdAt,
        approvedAt,
        postedAt,
        receivedAt,
        itemsCount,
        items,
      ];
}

class TransferItemEntity extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? productUnit;
  final double qty;
  final double unitCost;

  const TransferItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productUnit,
    required this.qty,
    required this.unitCost,
  });

  @override
  List<Object?> get props =>
      [id, productId, productName, productSku, productUnit, qty, unitCost];
}

class TransferItemInput extends Equatable {
  final String productId;
  final String productName;
  final double qty;
  final double unitCost;

  const TransferItemInput({
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitCost,
  });

  @override
  List<Object?> get props => [productId, productName, qty, unitCost];
}

class TransferFormData extends Equatable {
  final String? reference;
  final String? fromBranchId;
  final String fromWarehouseId;
  final String? toBranchId;
  final String toWarehouseId;
  final String? notes;
  final List<TransferItemInput> items;

  const TransferFormData({
    this.reference,
    this.fromBranchId,
    required this.fromWarehouseId,
    this.toBranchId,
    required this.toWarehouseId,
    this.notes,
    required this.items,
  });

  @override
  List<Object?> get props =>
      [reference, fromBranchId, fromWarehouseId, toBranchId, toWarehouseId, notes, items];
}
