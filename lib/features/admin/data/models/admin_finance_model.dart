import '../../domain/entities/admin_finance_entity.dart';

double _n(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

int _i(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

class AdminFinanceCategoryModel extends AdminFinanceCategoryEntity {
  const AdminFinanceCategoryModel({
    required super.id,
    required super.type,
    required super.name,
    required super.slug,
    super.description,
    super.color,
    super.isSystem,
    super.isActive,
    super.sortOrder,
  });

  factory AdminFinanceCategoryModel.fromJson(Map<String, dynamic> j) {
    return AdminFinanceCategoryModel(
      id: j['id']?.toString() ?? '',
      type: j['type'] as String? ?? 'revenue',
      name: j['name'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
      description: j['description'] as String?,
      color: j['color'] as String?,
      isSystem: j['is_system'] as bool? ?? false,
      isActive: j['is_active'] as bool? ?? true,
      sortOrder: _i(j['sort_order']),
    );
  }
}

class AdminFinanceVendorRefModel extends AdminFinanceVendorRefEntity {
  const AdminFinanceVendorRefModel({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory AdminFinanceVendorRefModel.fromJson(Map<String, dynamic> j) {
    return AdminFinanceVendorRefModel(
      id: j['id']?.toString() ?? '',
      name: j['name'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
    );
  }
}

class AdminFinanceEntryModel extends AdminFinanceEntryEntity {
  const AdminFinanceEntryModel({
    required super.id,
    required super.type,
    super.category,
    required super.amount,
    super.currency,
    required super.title,
    super.description,
    required super.entryDate,
    required super.status,
    super.vendor,
    super.billingPaymentId,
    super.reference,
    super.paymentMethod,
    super.recurring,
    super.notes,
    required super.createdAt,
  });

  factory AdminFinanceEntryModel.fromJson(Map<String, dynamic> j) {
    final catRaw = j['category'] as Map<String, dynamic>?;
    final vendorRaw = j['vendor'] as Map<String, dynamic>?;
    return AdminFinanceEntryModel(
      id: j['id']?.toString() ?? '',
      type: j['type'] as String? ?? 'revenue',
      category: catRaw != null
          ? AdminFinanceCategoryModel.fromJson(catRaw)
          : null,
      amount: _n(j['amount']),
      currency: j['currency'] as String? ?? 'USD',
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      entryDate: j['entry_date'] as String? ?? '',
      status: j['status'] as String? ?? 'confirmed',
      vendor: vendorRaw != null
          ? AdminFinanceVendorRefModel.fromJson(vendorRaw)
          : null,
      billingPaymentId: j['billing_payment_id']?.toString(),
      reference: j['reference'] as String?,
      paymentMethod: j['payment_method'] as String?,
      recurring: j['recurring'] as String? ?? 'none',
      notes: j['notes'] as String?,
      createdAt: j['created_at'] as String? ?? '',
    );
  }
}

class AdminFinanceMonthlyStatModel extends AdminFinanceMonthlyStat {
  const AdminFinanceMonthlyStatModel({
    required super.month,
    required super.revenue,
    required super.expense,
    required super.net,
  });

  factory AdminFinanceMonthlyStatModel.fromJson(Map<String, dynamic> j) {
    return AdminFinanceMonthlyStatModel(
      month: j['month'] as String? ?? '',
      revenue: _n(j['revenue']),
      expense: _n(j['expense']),
      net: _n(j['net']),
    );
  }
}

class AdminFinanceSummaryModel extends AdminFinanceSummaryEntity {
  const AdminFinanceSummaryModel({
    super.revenueTotal,
    super.expenseTotal,
    super.netProfit,
    super.pendingRevenue,
    super.pendingExpense,
    super.monthly,
  });

  factory AdminFinanceSummaryModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final monthlyRaw = data['monthly'] as List<dynamic>? ?? [];
    return AdminFinanceSummaryModel(
      revenueTotal: _n(data['revenue_total']),
      expenseTotal: _n(data['expense_total']),
      netProfit: _n(data['net_profit']),
      pendingRevenue: _n(data['pending_revenue']),
      pendingExpense: _n(data['pending_expense']),
      monthly: monthlyRaw
          .map((e) =>
              AdminFinanceMonthlyStatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
