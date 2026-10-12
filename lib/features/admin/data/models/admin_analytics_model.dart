import '../../domain/entities/admin_analytics_entity.dart';

class AdminTopVendorModel extends AdminTopVendorEntity {
  const AdminTopVendorModel({
    required super.id,
    required super.name,
    super.email,
    super.slug,
    super.planName,
    required super.totalRevenue,
    required super.ordersCount,
  });

  factory AdminTopVendorModel.fromJson(Map<String, dynamic> json) {
    return AdminTopVendorModel(
      id: json['vendor_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['vendor_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      slug: json['slug'] as String?,
      planName: json['plan_name'] as String?,
      totalRevenue: (json['revenue'] as num?)?.toDouble() ??
          (json['total_revenue'] as num?)?.toDouble() ?? 0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ??
          (json['orders'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDailyPlatformModel extends AdminDailyPlatformEntity {
  const AdminDailyPlatformModel({
    required super.date,
    required super.revenue,
    required super.orders,
    required super.newVendors,
  });

  factory AdminDailyPlatformModel.fromJson(Map<String, dynamic> json) {
    return AdminDailyPlatformModel(
      date: json['date'] as String? ?? '',
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      newVendors: (json['new_vendors'] as num?)?.toInt() ??
          (json['new_vendors_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminAnalyticsModel extends AdminAnalyticsEntity {
  const AdminAnalyticsModel({
    required super.totalVendors,
    required super.activeVendors,
    required super.newVendorsThisMonth,
    required super.totalRevenue,
    required super.mrr,
    required super.arr,
    required super.totalSubscriptions,
    required super.expiringSoon,
    super.totalOrders,
    super.activeStores,
    super.storesOpenedLast30d,
    super.topVendors,
    super.dailyPlatform,
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final activeVendors = (data['active_vendors'] as num?)?.toInt() ?? 0;
    final newVendorsThisMonth =
        (data['new_vendors_this_month'] as num?)?.toInt() ??
            (data['new_this_month'] as num?)?.toInt() ?? 0;

    final topVendorsRaw = data['top_vendors'] as List<dynamic>? ?? [];
    final dailyRaw = data['daily_platform'] as List<dynamic>? ?? [];

    return AdminAnalyticsModel(
      totalVendors: (data['total_vendors'] as num?)?.toInt() ?? 0,
      activeVendors: activeVendors,
      newVendorsThisMonth: newVendorsThisMonth,
      totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0,
      mrr: (data['mrr'] as num?)?.toDouble() ??
          (data['monthly_recurring_revenue'] as num?)?.toDouble() ?? 0,
      arr: (data['arr'] as num?)?.toDouble() ??
          (data['annual_recurring_revenue'] as num?)?.toDouble() ?? 0,
      totalSubscriptions: (data['total_subscriptions'] as num?)?.toInt() ??
          (data['active_subscriptions'] as num?)?.toInt() ?? 0,
      expiringSoon: (data['expiring_soon'] as num?)?.toInt() ?? 0,
      totalOrders: (data['total_orders'] as num?)?.toInt() ?? 0,
      activeStores: (data['active_stores'] as num?)?.toInt() ?? activeVendors,
      storesOpenedLast30d: (data['stores_opened_last_30d'] as num?)?.toInt() ??
          newVendorsThisMonth,
      topVendors: topVendorsRaw
          .map((e) => AdminTopVendorModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dailyPlatform: dailyRaw
          .map((e) =>
              AdminDailyPlatformModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
