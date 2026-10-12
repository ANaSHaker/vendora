import 'package:equatable/equatable.dart';

class BranchEntity extends Equatable {
  final String id;
  final String name;

  const BranchEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class WarehouseEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final String? branchId;

  const WarehouseEntity({
    required this.id,
    required this.name,
    this.code,
    this.branchId,
  });

  String get displayName => code != null ? '$name ($code)' : name;

  @override
  List<Object?> get props => [id, name, code, branchId];
}

class PosProductEntity extends Equatable {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final String? categoryId;
  final String? categoryName;
  final bool trackStock;
  final double? availableQty;

  const PosProductEntity({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.trackStock = false,
    this.availableQty,
  });

  bool get isOutOfStock =>
      trackStock && (availableQty == null || availableQty! <= 0);

  @override
  List<Object?> get props =>
      [id, name, sku, barcode, price, categoryId, trackStock, availableQty];
}

class PosCategoryEntity extends Equatable {
  final String id;
  final String name;

  const PosCategoryEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class PosCustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;

  const PosCustomerEntity({
    required this.id,
    required this.name,
    this.phone,
  });

  @override
  List<Object?> get props => [id, name, phone];
}

class PosOrderItemEntity extends Equatable {
  final String productName;
  final double unitPrice;
  final double quantity;
  final double discount;
  final double total;

  const PosOrderItemEntity({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.discount,
    required this.total,
  });

  @override
  List<Object?> get props => [productName, unitPrice, quantity, discount, total];
}

class PosPaymentResultEntity extends Equatable {
  final String method;
  final double amount;

  const PosPaymentResultEntity({required this.method, required this.amount});

  @override
  List<Object?> get props => [method, amount];
}

class PosOrderEntity extends Equatable {
  final String id;
  final String reference;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double change;
  final String? customerName;
  final String? customerPhone;
  final String? cashierName;
  final String? branchName;
  final String? warehouseName;
  final String? storeName;
  final String? note;
  final String? trackingToken;
  final List<PosOrderItemEntity> items;
  final List<PosPaymentResultEntity> payments;
  final DateTime? paidAt;

  const PosOrderEntity({
    required this.id,
    required this.reference,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.change,
    this.customerName,
    this.customerPhone,
    this.cashierName,
    this.branchName,
    this.warehouseName,
    this.storeName,
    this.note,
    this.trackingToken,
    required this.items,
    required this.payments,
    this.paidAt,
  });

  @override
  List<Object?> get props => [id, reference, total, change, note];
}
