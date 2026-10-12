import '../../domain/entities/admin_payment_entity.dart';

class AdminPaymentModel extends AdminPaymentEntity {
  const AdminPaymentModel({
    required super.id,
    required super.vendorName,
    super.vendorSlug,
    super.vendorId,
    required super.amount,
    required super.status,
    super.method,
    super.paidAt,
    super.createdAt,
    super.subscriptionId,
    super.invoiceId,
    super.notes,
  });

  factory AdminPaymentModel.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return AdminPaymentModel(
      id: json['id'].toString(),
      vendorName: vendor?['name'] as String? ?? json['vendor_name'] as String? ?? '',
      vendorSlug: vendor?['slug'] as String? ?? json['vendor_slug'] as String?,
      vendorId: vendor?['id']?.toString() ?? json['vendor_id']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'pending',
      method: json['method'] as String? ?? json['payment_method'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
      subscriptionId: json['subscription_id']?.toString(),
      invoiceId: json['invoice_id']?.toString(),
      notes: json['notes'] as String?,
    );
  }
}

class AdminInvoiceModel extends AdminInvoiceEntity {
  const AdminInvoiceModel({
    required super.id,
    required super.vendorName,
    super.vendorSlug,
    super.vendorId,
    required super.amount,
    required super.status,
    super.dueDate,
    super.paidAt,
    super.createdAt,
    super.subscriptionId,
    super.notes,
  });

  factory AdminInvoiceModel.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    return AdminInvoiceModel(
      id: json['id'].toString(),
      vendorName: vendor?['name'] as String? ?? json['vendor_name'] as String? ?? '',
      vendorSlug: vendor?['slug'] as String? ?? json['vendor_slug'] as String?,
      vendorId: vendor?['id']?.toString() ?? json['vendor_id']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'open',
      dueDate: json['due_date'] as String?,
      paidAt: json['paid_at'] as String?,
      createdAt: json['created_at'] as String?,
      subscriptionId: json['subscription_id']?.toString(),
      notes: json['notes'] as String?,
    );
  }
}
