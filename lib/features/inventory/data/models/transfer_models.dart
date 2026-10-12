import '../../domain/entities/transfer_entities.dart';

class TransferModel extends TransferEntity {
  const TransferModel({
    required super.id,
    super.reference,
    required super.status,
    super.fromBranchId,
    super.fromBranchName,
    required super.fromWarehouseName,
    required super.fromWarehouseCode,
    super.toBranchId,
    super.toBranchName,
    required super.toWarehouseName,
    required super.toWarehouseCode,
    super.notes,
    required super.createdAt,
    super.approvedAt,
    super.postedAt,
    super.receivedAt,
    required super.itemsCount,
    super.items,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    final fromWh = json['from_warehouse'] as Map<String, dynamic>?;
    final toWh = json['to_warehouse'] as Map<String, dynamic>?;
    final fromBranch = json['from_branch'] as Map<String, dynamic>?;
    final toBranch = json['to_branch'] as Map<String, dynamic>?;

    final rawItems = json['items'] as List<dynamic>?;
    final items = rawItems
        ?.map((e) => TransferItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return TransferModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String?,
      status: json['status'] as String? ?? 'draft',
      fromBranchId: fromBranch?['id']?.toString(),
      fromBranchName: fromBranch?['name'] as String?,
      fromWarehouseName: fromWh?['name'] as String? ?? json['from_warehouse_name'] as String? ?? '',
      fromWarehouseCode: fromWh?['code'] as String? ?? json['from_warehouse_code'] as String? ?? '',
      toBranchId: toBranch?['id']?.toString(),
      toBranchName: toBranch?['name'] as String?,
      toWarehouseName: toWh?['name'] as String? ?? json['to_warehouse_name'] as String? ?? '',
      toWarehouseCode: toWh?['code'] as String? ?? json['to_warehouse_code'] as String? ?? '',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      approvedAt: json['approved_at'] as String?,
      postedAt: json['posted_at'] as String?,
      receivedAt: json['received_at'] as String?,
      itemsCount: (json['items_count'] as num?)?.toInt() ?? items?.length ?? 0,
      items: items,
    );
  }

  static Map<String, dynamic> buildPayload(TransferFormData data) => {
        if (data.reference != null && data.reference!.isNotEmpty)
          'reference': data.reference,
        if (data.fromBranchId != null) 'from_branch_id': data.fromBranchId,
        'from_warehouse_id': data.fromWarehouseId,
        if (data.toBranchId != null) 'to_branch_id': data.toBranchId,
        'to_warehouse_id': data.toWarehouseId,
        if (data.notes != null && data.notes!.isNotEmpty) 'notes': data.notes,
        'items': data.items
            .map((i) => {
                  'product_id': i.productId,
                  'qty': i.qty,
                  'unit_cost': i.unitCost,
                })
            .toList(),
      };
}

class TransferItemModel extends TransferItemEntity {
  const TransferItemModel({
    super.id,
    required super.productId,
    required super.productName,
    super.productSku,
    super.productUnit,
    required super.qty,
    required super.unitCost,
  });

  factory TransferItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return TransferItemModel(
      id: json['id']?.toString(),
      productId: product?['id']?.toString() ?? json['product_id']?.toString() ?? '',
      productName: product?['name'] as String? ?? json['product_name'] as String? ?? '',
      productSku: product?['sku'] as String? ?? json['product_sku'] as String?,
      productUnit: product?['unit'] as String? ?? json['product_unit'] as String?,
      qty: (json['qty'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
