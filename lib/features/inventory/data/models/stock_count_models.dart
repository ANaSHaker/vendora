import '../../domain/entities/stock_count_entities.dart';

class StockCountModel extends StockCountEntity {
  const StockCountModel({
    required super.id,
    required super.reference,
    required super.status,
    super.branchId,
    super.branchName,
    required super.warehouseName,
    required super.warehouseCode,
    super.notes,
    required super.createdAt,
    super.postedAt,
    super.lastMovementAt,
    required super.itemsCount,
    super.items,
  });

  factory StockCountModel.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;

    final rawItems = json['items'] as List<dynamic>?;
    final items = rawItems
        ?.map((e) => StockCountItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return StockCountModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      branchId: branch?['id']?.toString() ?? json['branch_id']?.toString(),
      branchName: branch?['name'] as String? ?? json['branch_name'] as String?,
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String? ?? '',
      warehouseCode: warehouse?['code'] as String? ?? json['warehouse_code'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      postedAt: json['posted_at'] as String?,
      lastMovementAt: json['last_movement_at'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? items?.length ?? 0,
      items: items,
    );
  }

  static Map<String, dynamic> buildPayload(StockCountFormData data) => {
        if (data.reference != null && data.reference!.isNotEmpty)
          'reference': data.reference,
        if (data.branchId != null) 'branch_id': data.branchId,
        'warehouse_id': data.warehouseId,
        if (data.notes != null && data.notes!.isNotEmpty) 'notes': data.notes,
        if (data.items.isNotEmpty)
          'items': data.items
              .map((i) => {
                    'product_id': i.productId,
                    'counted_qty': i.countedQty,
                  })
              .toList(),
      };
}

class StockCountItemModel extends StockCountItemEntity {
  const StockCountItemModel({
    super.id,
    required super.productId,
    required super.productName,
    super.productSku,
    super.productUnit,
    required super.systemQty,
    required super.countedQty,
    required super.varianceQty,
    super.unitCost,
  });

  factory StockCountItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final systemQty = (json['system_qty'] as num?)?.toDouble() ?? 0.0;
    final countedQty = (json['counted_qty'] as num?)?.toDouble() ?? 0.0;
    final varianceQty = (json['variance_qty'] as num?)?.toDouble() ?? (countedQty - systemQty);

    return StockCountItemModel(
      id: json['id']?.toString(),
      productId: product?['id']?.toString() ?? json['product_id']?.toString() ?? '',
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      productSku: product?['sku'] as String? ?? json['product_sku'] as String?,
      productUnit: product?['unit'] as String? ?? json['product_unit'] as String?,
      systemQty: systemQty,
      countedQty: countedQty,
      varianceQty: varianceQty,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
    );
  }
}
