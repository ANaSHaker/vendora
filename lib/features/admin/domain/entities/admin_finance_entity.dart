import 'package:equatable/equatable.dart';

class AdminFinanceCategoryEntity extends Equatable {
  final String id;
  final String type; // 'revenue' | 'expense'
  final String name;
  final String slug;
  final String? description;
  final String? color;
  final bool isSystem;
  final bool isActive;
  final int sortOrder;

  const AdminFinanceCategoryEntity({
    required this.id,
    required this.type,
    required this.name,
    required this.slug,
    this.description,
    this.color,
    this.isSystem = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  @override
  List<Object?> get props =>
      [id, type, name, slug, description, color, isSystem, isActive, sortOrder];
}

class AdminFinanceEntryEntity extends Equatable {
  final String id;
  final String type; // 'revenue' | 'expense'
  final AdminFinanceCategoryEntity? category;
  final double amount;
  final String currency;
  final String title;
  final String? description;
  final String entryDate;
  final String status; // 'confirmed' | 'pending' | 'void'
  final AdminFinanceVendorRefEntity? vendor;
  final String? billingPaymentId;
  final String? reference;
  final String? paymentMethod;
  final String recurring;
  final String? notes;
  final String createdAt;

  const AdminFinanceEntryEntity({
    required this.id,
    required this.type,
    this.category,
    required this.amount,
    this.currency = 'USD',
    required this.title,
    this.description,
    required this.entryDate,
    required this.status,
    this.vendor,
    this.billingPaymentId,
    this.reference,
    this.paymentMethod,
    this.recurring = 'none',
    this.notes,
    required this.createdAt,
  });

  bool get isLocked => billingPaymentId != null && billingPaymentId!.isNotEmpty;

  @override
  List<Object?> get props => [id, type, amount, title, entryDate, status];
}

class AdminFinanceVendorRefEntity extends Equatable {
  final String id;
  final String name;
  final String slug;

  const AdminFinanceVendorRefEntity({
    required this.id,
    required this.name,
    required this.slug,
  });

  @override
  List<Object?> get props => [id, name, slug];
}

class AdminFinanceSummaryEntity extends Equatable {
  final double revenueTotal;
  final double expenseTotal;
  final double netProfit;
  final double pendingRevenue;
  final double pendingExpense;
  final List<AdminFinanceMonthlyStat> monthly;

  const AdminFinanceSummaryEntity({
    this.revenueTotal = 0,
    this.expenseTotal = 0,
    this.netProfit = 0,
    this.pendingRevenue = 0,
    this.pendingExpense = 0,
    this.monthly = const [],
  });

  @override
  List<Object?> get props =>
      [revenueTotal, expenseTotal, netProfit, pendingRevenue, pendingExpense];
}

class AdminFinanceMonthlyStat extends Equatable {
  final String month;
  final double revenue;
  final double expense;
  final double net;

  const AdminFinanceMonthlyStat({
    required this.month,
    required this.revenue,
    required this.expense,
    required this.net,
  });

  @override
  List<Object?> get props => [month, revenue, expense, net];
}
