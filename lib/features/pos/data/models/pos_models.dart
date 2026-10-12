import '../../domain/entities/pos_entities.dart';

class BranchModel extends BranchEntity {
  const BranchModel({required super.id, required super.name});

  factory BranchModel.fromJson(Map<String, dynamic> json) => BranchModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class WarehouseModel extends WarehouseEntity {
  const WarehouseModel({
    required super.id,
    required super.name,
    super.code,
    super.branchId,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => WarehouseModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        branchId: json['branch_id']?.toString(),
      );
}

class PosProductModel extends PosProductEntity {
  const PosProductModel({
    required super.id,
    required super.name,
    super.sku,
    super.barcode,
    required super.price,
    super.categoryId,
    super.categoryName,
    super.trackStock,
    super.availableQty,
  });

  factory PosProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;
    final rawQty = json['available_qty'];
    final availableQty = rawQty == null
        ? null
        : (rawQty is num ? rawQty.toDouble() : double.tryParse(rawQty.toString()));

    return PosProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: price,
      categoryId: category?['id']?.toString(),
      categoryName: category?['name'] as String?,
      trackStock: json['track_stock'] as bool? ?? false,
      availableQty: availableQty,
    );
  }
}

class PosCategoryModel extends PosCategoryEntity {
  const PosCategoryModel({required super.id, required super.name});

  factory PosCategoryModel.fromJson(Map<String, dynamic> json) =>
      PosCategoryModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
      );
}

class PosCustomerModel extends PosCustomerEntity {
  const PosCustomerModel({
    required super.id,
    required super.name,
    super.phone,
  });

  factory PosCustomerModel.fromJson(Map<String, dynamic> json) =>
      PosCustomerModel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String?,
      );
}

class PosOrderModel extends PosOrderEntity {
  const PosOrderModel({
    required super.id,
    required super.reference,
    required super.subtotal,
    required super.discount,
    required super.tax,
    required super.total,
    required super.change,
    super.customerName,
    super.customerPhone,
    super.cashierName,
    super.branchName,
    super.warehouseName,
    super.storeName,
    super.note,
    super.trackingToken,
    required super.items,
    required super.payments,
    super.paidAt,
  });

  factory PosOrderModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final cashierJson = json['cashier'] as Map<String, dynamic>?;
    final branchJson = json['branch'] as Map<String, dynamic>?;
    final warehouseJson = json['warehouse'] as Map<String, dynamic>?;
    final vendorJson = json['vendor'] as Map<String, dynamic>?;
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final paymentsList = json['payments'] as List<dynamic>? ?? [];

    return PosOrderModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ?? '',
      subtotal: _num(json['subtotal']),
      discount: _num(json['discount']),
      tax: _num(json['tax']),
      total: _num(json['total']),
      change: _num(json['change']),
      customerName: customerJson?['name'] as String? ?? json['customer_name'] as String?,
      customerPhone: customerJson?['phone'] as String? ?? json['customer_phone'] as String?,
      cashierName: cashierJson?['name'] as String?,
      branchName: branchJson?['name'] as String? ?? json['branch_name'] as String?,
      warehouseName: warehouseJson?['name'] as String? ?? json['warehouse_name'] as String?,
      storeName: vendorJson?['name'] as String? ?? vendorJson?['store_name'] as String?,
      note: json['note'] as String?,
      trackingToken: json['tracking_token'] as String?,
      items: itemsList
          .map((e) => _orderItemFromJson(e as Map<String, dynamic>))
          .toList(),
      payments: paymentsList
          .map((e) => _paymentFromJson(e as Map<String, dynamic>))
          .toList(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
    );
  }

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  static PosOrderItemEntity _orderItemFromJson(Map<String, dynamic> json) =>
      PosOrderItemEntity(
        productName: json['product_name'] as String? ?? '',
        unitPrice: _num(json['unit_price']),
        quantity: _num(json['quantity']),
        discount: _num(json['discount']),
        total: _num(json['total']),
      );

  static PosPaymentResultEntity _paymentFromJson(Map<String, dynamic> json) =>
      PosPaymentResultEntity(
        method: json['method'] as String? ?? 'cash',
        amount: _num(json['amount']),
      );
}
