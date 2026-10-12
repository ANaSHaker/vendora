import '../../domain/entities/adjustment_entities.dart';

class AdjustmentModel extends AdjustmentEntity {
  const AdjustmentModel({
    required super.id,
    super.reference,
    required super.adjustmentType,
    required super.status,
    required super.date,
    super.branchId,
    super.branchName,
    super.warehouseName,
    super.warehouseCode,
    super.notes,
    required super.createdAt,
    super.approvedAt,
    super.postedAt,
    super.approvedByName,
    required super.itemsCount,
    super.items,
  });

  factory AdjustmentModel.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    final branch = json['branch'] as Map<String, dynamic>?;
    final approvedBy = json['approved_by'] as Map<String, dynamic>?;

    final rawItems = json['items'] as List<dynamic>?;
    final items = rawItems
        ?.map((e) => AdjustmentItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return AdjustmentModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String?,
      adjustmentType: json['adjustment_type'] as String? ?? 'adjustment_in',
      status: json['status'] as String? ?? 'draft',
      date: json['date'] as String? ?? '',
      branchId: branch?['id']?.toString() ?? json['branch_id']?.toString(),
      branchName: branch?['name'] as String? ?? json['branch_name'] as String?,
      warehouseName: warehouse?['name'] as String? ?? json['warehouse_name'] as String?,
      warehouseCode: warehouse?['code'] as String? ?? json['warehouse_code'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      approvedAt: json['approved_at'] as String?,
      postedAt: json['posted_at'] as String?,
      approvedByName: approvedBy?['name'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? items?.length ?? 0,
      items: items,
    );
  }

  static Map<String, dynamic> buildPayload(AdjustmentFormData data) => {
        'adjustment_type': data.adjustmentType,
        if (data.branchId != null) 'branch_id': data.branchId,
        'warehouse_id': data.warehouseId,
        if (data.reference != null && data.reference!.isNotEmpty)
          'reference': data.reference,
        'date': data.date,
        if (data.notes != null && data.notes!.isNotEmpty) 'notes': data.notes,
        'items': data.items
            .map((i) => {
                  'product_id': i.productId,
                  'qty': i.qty,
                  if (i.note != null && i.note!.isNotEmpty) 'note': i.note,
                })
            .toList(),
      };
}

class AdjustmentItemModel extends AdjustmentItemEntity {
  const AdjustmentItemModel({
    super.id,
    required super.productId,
    required super.productName,
    super.productSku,
    super.productUnit,
    required super.qty,
    super.quantityBefore,
    super.quantityAfter,
    super.note,
  });

  factory AdjustmentItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return AdjustmentItemModel(
      id: json['id']?.toString(),
      productId: product?['id']?.toString() ?? json['product_id']?.toString() ?? '',
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      productSku: product?['sku'] as String? ?? json['product_sku'] as String?,
      productUnit: product?['unit'] as String? ?? json['product_unit'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      quantityBefore: (json['quantity_before'] as num?)?.toDouble(),
      quantityAfter: (json['quantity_after'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }
}
