import 'package:equatable/equatable.dart';

class AdjustmentEntity extends Equatable {
  final String id;
  final String? reference;
  final String adjustmentType;
  final String status;
  final String date;
  final String? branchId;
  final String? branchName;
  final String? warehouseName;
  final String? warehouseCode;
  final String? notes;
  final String createdAt;
  final String? approvedAt;
  final String? postedAt;
  final String? approvedByName;
  final int itemsCount;
  final List<AdjustmentItemEntity>? items;

  const AdjustmentEntity({
    required this.id,
    this.reference,
    required this.adjustmentType,
    required this.status,
    required this.date,
    this.branchId,
    this.branchName,
    this.warehouseName,
    this.warehouseCode,
    this.notes,
    required this.createdAt,
    this.approvedAt,
    this.postedAt,
    this.approvedByName,
    required this.itemsCount,
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        adjustmentType,
        status,
        date,
        branchId,
        branchName,
        warehouseName,
        warehouseCode,
        notes,
        createdAt,
        approvedAt,
        postedAt,
        approvedByName,
        itemsCount,
        items,
      ];
}

class AdjustmentItemEntity extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? productUnit;
  final double qty;
  final double? quantityBefore;
  final double? quantityAfter;
  final String? note;

  const AdjustmentItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productUnit,
    required this.qty,
    this.quantityBefore,
    this.quantityAfter,
    this.note,
  });

  @override
  List<Object?> get props =>
      [id, productId, productName, productSku, productUnit, qty, quantityBefore, quantityAfter, note];
}

class AdjustmentItemInput extends Equatable {
  final String productId;
  final String productName;
  final double qty;
  final String? note;

  const AdjustmentItemInput({
    required this.productId,
    required this.productName,
    required this.qty,
    this.note,
  });

  @override
  List<Object?> get props => [productId, productName, qty, note];
}

class AdjustmentFormData extends Equatable {
  final String adjustmentType;
  final String? branchId;
  final String warehouseId;
  final String? reference;
  final String date;
  final String? notes;
  final List<AdjustmentItemInput> items;

  const AdjustmentFormData({
    required this.adjustmentType,
    this.branchId,
    required this.warehouseId,
    this.reference,
    required this.date,
    this.notes,
    required this.items,
  });

  @override
  List<Object?> get props =>
      [adjustmentType, branchId, warehouseId, reference, date, notes, items];
}
