import '../../domain/entities/receipt_entity.dart';

class ReceiptModel extends ReceiptEntity {
  const ReceiptModel({
    required super.id,
    super.reference,
    required super.status,
    super.supplierName,
    super.warehouseName,
    super.branchName,
    super.notes,
    required super.createdAt,
    super.postedAt,
    required super.totalValue,
    required super.itemsCount,
    super.items,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] as Map<String, dynamic>?;
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;

    final rawItems = json['items'] as List<dynamic>?;
    final items = rawItems
        ?.map((e) =>
            ReceiptItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ReceiptModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'draft',
      supplierName: supplier?['name'] as String? ??
          json['supplier_name'] as String?,
      warehouseName: warehouse?['name'] as String? ??
          json['warehouse_name'] as String?,
      branchName:
          branch?['name'] as String? ?? json['branch_name'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      postedAt: json['posted_at'] as String?,
      totalValue: (json['total_value'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          0.0,
      itemsCount: (json['items_count'] as num?)?.toInt() ??
          (json['items'] as List?)?.length ??
          0,
      items: items,
    );
  }
}

class ReceiptItemModel extends ReceiptItemEntity {
  const ReceiptItemModel({
    super.id,
    required super.productId,
    required super.productName,
    super.productSku,
    super.productUnit,
    required super.qty,
    required super.unitCost,
  });

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ReceiptItemModel(
      id: json['id']?.toString(),
      productId: (product?['id'] ?? json['product_id'])?.toString() ?? '',
      productName: product?['name'] as String? ??
          json['product_name'] as String? ??
          '',
      productSku: product?['sku'] as String?,
      productUnit: product?['unit'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ??
          (json['quantity'] as num?)?.toDouble() ??
          0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ??
          (json['cost'] as num?)?.toDouble() ??
          0.0,
    );
  }
}
