import '../../domain/entities/dashboard_entities.dart';

class DashboardPeriodModel extends DashboardPeriodEntity {
  const DashboardPeriodModel({
    required super.dateFrom,
    required super.dateTo,
  });

  factory DashboardPeriodModel.fromJson(Map<String, dynamic> json) {
    return DashboardPeriodModel(
      dateFrom: DateTime.tryParse(json['date_from'] as String? ?? '') ??
          DateTime.now(),
      dateTo: DateTime.tryParse(json['date_to'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    required super.totalOrders,
    required super.totalSales,
    required super.totalRefunds,
    required super.netRevenue,
    required super.avgOrderValue,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      totalRefunds: (json['total_refunds'] as num?)?.toDouble() ?? 0.0,
      netRevenue: (json['net_revenue'] as num?)?.toDouble() ?? 0.0,
      avgOrderValue: (json['avg_order_value'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopProductModel extends TopProductEntity {
  const TopProductModel({
    required super.productId,
    required super.productName,
    required super.totalQty,
    required super.totalRevenue,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      totalQty: (json['total_qty'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopCustomerModel extends TopCustomerEntity {
  const TopCustomerModel({
    required super.customerId,
    required super.customerName,
    required super.ordersCount,
    required super.totalSpent,
  });

  factory TopCustomerModel.fromJson(Map<String, dynamic> json) {
    return TopCustomerModel(
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String? ?? 'Guest',
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesPerDayModel extends SalesPerDayEntity {
  const SalesPerDayModel({
    required super.date,
    required super.ordersCount,
    required super.totalSales,
  });

  factory SalesPerDayModel.fromJson(Map<String, dynamic> json) {
    return SalesPerDayModel(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DashboardDataModel extends DashboardDataEntity {
  const DashboardDataModel({
    required super.period,
    required super.summary,
    required super.topProducts,
    required super.topCustomers,
    required super.salesPerDay,
  });

  factory DashboardDataModel.fromJson(Map<String, dynamic> json) {
    final periodJson = json['period'] as Map<String, dynamic>? ?? {};
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final productsJson = json['top_products'] as List<dynamic>? ?? [];
    final customersJson = json['top_customers'] as List<dynamic>? ?? [];
    final salesJson = json['sales_per_day'] as List<dynamic>? ?? [];

    return DashboardDataModel(
      period: DashboardPeriodModel.fromJson(periodJson),
      summary: DashboardSummaryModel.fromJson(summaryJson),
      topProducts: productsJson
          .map((e) => TopProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCustomers: customersJson
          .map((e) => TopCustomerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      salesPerDay: salesJson
          .map((e) => SalesPerDayModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
