import '../../domain/entities/order_entity.dart';

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.id,
    required super.productId,
    required super.productName,
    super.sku,
    required super.quantity,
    required super.unitPrice,
    super.discountAmount,
    required super.lineTotal,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qty   = _num(json['quantity']);
    final price = _num(json['unit_price']);
    final disc  = _num(json['discount']);
    final raw   = _num(json['line_total'] ?? json['total'] ?? json['subtotal']);
    return OrderItemModel(
      id:             json['id']?.toString() ?? '',
      productId:      json['product_id']?.toString() ?? '',
      productName:    json['product_name'] as String? ?? '',
      sku:            json['sku'] as String?,
      quantity:       qty.toInt(),
      unitPrice:      price,
      discountAmount: disc,
      lineTotal:      raw > 0 ? raw : qty * price,
    );
  }
}

class OrderPaymentModel extends OrderPaymentEntity {
  const OrderPaymentModel({required super.method, required super.amount});

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory OrderPaymentModel.fromJson(Map<String, dynamic> json) =>
      OrderPaymentModel(
        method: json['method'] as String? ?? 'cash',
        amount: _num(json['amount']),
      );
}

class OrderRefundSummaryModel extends OrderRefundSummaryEntity {
  const OrderRefundSummaryModel({
    required super.id,
    required super.total,
    required super.status,
    required super.reason,
    required super.createdAt,
    super.cashierName,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory OrderRefundSummaryModel.fromJson(Map<String, dynamic> json) {
    final cashierJson = json['cashier'] as Map<String, dynamic>?;
    return OrderRefundSummaryModel(
      id:          json['id']?.toString() ?? '',
      total:       _num(json['total']),
      status:      json['status'] as String? ?? 'pending',
      reason:      json['reason'] as String? ?? '',
      createdAt:   DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      cashierName: json['cashier_name'] as String? ?? cashierJson?['name'] as String?,
    );
  }
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.reference,
    required super.status,
    super.channel,
    super.fulfillmentStatus,
    super.trackingToken,
    required super.paymentMethod,
    super.payments,
    required super.subtotal,
    required super.discountAmount,
    required super.taxAmount,
    required super.total,
    super.customerId,
    super.customerName,
    super.customerPhone,
    required super.branchName,
    super.cashierName,
    super.note,
    super.paidAt,
    super.guestName,
    super.guestPhone,
    super.guestEmail,
    super.shippingAddress,
    required super.items,
    super.refunds,
    required super.createdAt,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '0') ?? 0.0;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsJson    = json['items']   as List<dynamic>? ?? [];
    final paymentsJson = json['payments'] as List<dynamic>? ?? [];
    final refundsJson  = json['refunds']  as List<dynamic>? ?? [];

    final customerJson = json['customer'] as Map<String, dynamic>?;
    final cashierJson  = json['cashier']  as Map<String, dynamic>?;
    final branchJson   = json['branch']   as Map<String, dynamic>?;

    // Derive customer info: prefer nested object, fall back to flat fields
    final customerId   = json['customer_id']?.toString() ?? customerJson?['id']?.toString();
    final customerName = customerJson?['name'] as String? ?? json['customer_name'] as String?;
    final customerPhone = customerJson?['phone'] as String? ?? json['customer_phone'] as String?;

    // Guest checkout fields (present on online orders without a linked customer)
    final guestName  = customerId == null ? (json['customer_name'] as String?) : null;
    final guestPhone = customerId == null ? (json['customer_phone'] as String?) : null;

    return OrderModel(
      id:              json['id']?.toString() ?? '',
      reference:       json['reference'] as String? ?? '',
      status:          json['status'] as String? ?? 'paid',
      channel:         json['channel'] as String? ?? 'pos',
      fulfillmentStatus: json['fulfillment_status'] as String?,
      trackingToken:   json['tracking_token'] as String?,
      paymentMethod:   _primaryPaymentMethod(paymentsJson, json),
      payments:        paymentsJson
          .map((e) => OrderPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal:        _num(json['subtotal']),
      discountAmount:  _num(json['discount_amount'] ?? json['discount']),
      taxAmount:       _num(json['tax_amount'] ?? json['tax']),
      total:           _num(json['total']),
      customerId:      customerId,
      customerName:    customerName,
      customerPhone:   customerPhone,
      branchName:      json['branch_name'] as String? ?? branchJson?['name'] as String? ?? '',
      cashierName:     json['cashier_name'] as String? ?? cashierJson?['name'] as String?,
      note:            json['note'] as String?,
      paidAt:          json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      guestName:       guestName,
      guestPhone:      guestPhone,
      guestEmail:      json['customer_email'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      items:           itemsJson
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      refunds:         refundsJson
          .map((e) => OrderRefundSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt:       DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Returns the first payment method from the payments array, falling back
  /// to the flat payment_method field for backward compatibility.
  static String _primaryPaymentMethod(
      List<dynamic> paymentsJson, Map<String, dynamic> json) {
    if (paymentsJson.isNotEmpty) {
      final first = paymentsJson.first as Map<String, dynamic>;
      return first['method'] as String? ?? 'cash';
    }
    return json['payment_method'] as String? ?? 'cash';
  }
}
