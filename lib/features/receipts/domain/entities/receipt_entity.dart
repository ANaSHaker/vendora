import 'package:equatable/equatable.dart';

class ReceiptEntity extends Equatable {
  final String id;
  final String? reference;
  final String status;
  final String? supplierName;
  final String? warehouseName;
  final String? branchName;
  final String? notes;
  final String createdAt;
  final String? postedAt;
  final double totalValue;
  final int itemsCount;
  final List<ReceiptItemEntity>? items;

  const ReceiptEntity({
    required this.id,
    this.reference,
    required this.status,
    this.supplierName,
    this.warehouseName,
    this.branchName,
    this.notes,
    required this.createdAt,
    this.postedAt,
    required this.totalValue,
    required this.itemsCount,
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        supplierName,
        warehouseName,
        branchName,
        notes,
        createdAt,
        postedAt,
        totalValue,
        itemsCount,
        items,
      ];
}

class ReceiptItemEntity extends Equatable {
  final String? id;
  final String productId;
  final String productName;
  final String? productSku;
  final String? productUnit;
  final double qty;
  final double unitCost;

  const ReceiptItemEntity({
    this.id,
    required this.productId,
    required this.productName,
    this.productSku,
    this.productUnit,
    required this.qty,
    required this.unitCost,
  });

  double get total => qty * unitCost;

  @override
  List<Object?> get props =>
      [id, productId, productName, productSku, productUnit, qty, unitCost];
}
