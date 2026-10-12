import 'package:equatable/equatable.dart';

class OrderPaymentEntity extends Equatable {
  final String method;
  final double amount;

  const OrderPaymentEntity({required this.method, required this.amount});

  @override
  List<Object?> get props => [method, amount];
}

class OrderRefundSummaryEntity extends Equatable {
  final String id;
  final double total;
  final String status;
  final String reason;
  final DateTime createdAt;
  final String? cashierName;

  const OrderRefundSummaryEntity({
    required this.id,
    required this.total,
    required this.status,
    required this.reason,
    required this.createdAt,
    this.cashierName,
  });

  @override
  List<Object?> get props => [id, total, status, reason, createdAt, cashierName];
}

class OrderItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? sku;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final double lineTotal;

  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    required this.unitPrice,
    this.discountAmount = 0,
    required this.lineTotal,
  });

  @override
  List<Object?> get props =>
      [id, productId, productName, sku, quantity, unitPrice, discountAmount, lineTotal];
}

class OrderEntity extends Equatable {
  final String id;
  final String reference;
  final String status;
  final String channel;
  final String? fulfillmentStatus;
  final String? trackingToken;
  final String paymentMethod;
  final List<OrderPaymentEntity> payments;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double total;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String branchName;
  final String? cashierName;
  final String? note;
  final DateTime? paidAt;
  // Guest checkout fields (online orders without a registered customer)
  final String? guestName;
  final String? guestPhone;
  final String? guestEmail;
  final String? shippingAddress;
  final List<OrderItemEntity> items;
  final List<OrderRefundSummaryEntity> refunds;
  final DateTime createdAt;

  const OrderEntity({
    required this.id,
    required this.reference,
    required this.status,
    this.channel = 'pos',
    this.fulfillmentStatus,
    this.trackingToken,
    required this.paymentMethod,
    this.payments = const [],
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.total,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.branchName,
    this.cashierName,
    this.note,
    this.paidAt,
    this.guestName,
    this.guestPhone,
    this.guestEmail,
    this.shippingAddress,
    required this.items,
    this.refunds = const [],
    required this.createdAt,
  });

  /// Resolved display name: registered customer name, or guest name, or null.
  String? get displayCustomerName => customerName ?? guestName;

  /// True if this was a guest checkout (no linked customer account).
  bool get isGuestCheckout =>
      customerId == null && (guestName != null || guestPhone != null);

  /// True if the payment status is terminal (cannot be changed via dashboard).
  bool get isTerminalStatus =>
      status == 'refunded' ||
      status == 'partially_refunded' ||
      status == 'void';

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        channel,
        fulfillmentStatus,
        trackingToken,
        paymentMethod,
        payments,
        subtotal,
        discountAmount,
        taxAmount,
        total,
        customerId,
        customerName,
        customerPhone,
        branchName,
        cashierName,
        note,
        paidAt,
        guestName,
        guestPhone,
        guestEmail,
        shippingAddress,
        items,
        refunds,
        createdAt,
      ];
}
