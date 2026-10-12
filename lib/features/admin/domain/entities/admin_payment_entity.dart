import 'package:equatable/equatable.dart';

class AdminPaymentEntity extends Equatable {
  final String id;
  final String vendorName;
  final String? vendorSlug;
  final String? vendorId;
  final double amount;
  final String status; // paid, pending, failed
  final String? method; // card, cash, online, stripe
  final String? paidAt;
  final String? createdAt;
  final String? subscriptionId;
  final String? invoiceId;
  final String? notes;

  const AdminPaymentEntity({
    required this.id,
    required this.vendorName,
    this.vendorSlug,
    this.vendorId,
    required this.amount,
    required this.status,
    this.method,
    this.paidAt,
    this.createdAt,
    this.subscriptionId,
    this.invoiceId,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id, vendorName, vendorSlug, vendorId, amount, status,
        method, paidAt, createdAt, subscriptionId, invoiceId, notes,
      ];
}

class AdminInvoiceEntity extends Equatable {
  final String id;
  final String vendorName;
  final String? vendorSlug;
  final String? vendorId;
  final double amount;
  final String status; // open, paid, void, overdue
  final String? dueDate;
  final String? paidAt;
  final String? createdAt;
  final String? subscriptionId;
  final String? notes;

  const AdminInvoiceEntity({
    required this.id,
    required this.vendorName,
    this.vendorSlug,
    this.vendorId,
    required this.amount,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.createdAt,
    this.subscriptionId,
    this.notes,
  });

  @override
  List<Object?> get props => [
        id, vendorName, vendorSlug, vendorId, amount, status,
        dueDate, paidAt, createdAt, subscriptionId, notes,
      ];
}
