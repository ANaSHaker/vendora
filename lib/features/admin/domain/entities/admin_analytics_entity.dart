import 'package:equatable/equatable.dart';

class AdminAnalyticsEntity extends Equatable {
  final int totalVendors;
  final int activeVendors;
  final int newVendorsThisMonth;
  final double totalRevenue;
  final double mrr;
  final double arr;
  final int totalSubscriptions;
  final int expiringSoon;
  final int totalOrders;
  final int activeStores;
  final int storesOpenedLast30d;
  final List<AdminTopVendorEntity> topVendors;
  final List<AdminDailyPlatformEntity> dailyPlatform;

  const AdminAnalyticsEntity({
    required this.totalVendors,
    required this.activeVendors,
    required this.newVendorsThisMonth,
    required this.totalRevenue,
    required this.mrr,
    required this.arr,
    required this.totalSubscriptions,
    required this.expiringSoon,
    this.totalOrders = 0,
    this.activeStores = 0,
    this.storesOpenedLast30d = 0,
    this.topVendors = const [],
    this.dailyPlatform = const [],
  });

  @override
  List<Object?> get props => [
        totalVendors, activeVendors, newVendorsThisMonth,
        totalRevenue, mrr, arr, totalSubscriptions, expiringSoon,
        totalOrders, activeStores, storesOpenedLast30d,
        topVendors, dailyPlatform,
      ];
}

class AdminTopVendorEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? slug;
  final String? planName;
  final double totalRevenue;
  final int ordersCount;

  const AdminTopVendorEntity({
    required this.id,
    required this.name,
    this.email,
    this.slug,
    this.planName,
    required this.totalRevenue,
    required this.ordersCount,
  });

  @override
  List<Object?> get props => [id, name, email, slug, planName, totalRevenue, ordersCount];
}

class AdminDailyPlatformEntity extends Equatable {
  final String date;
  final double revenue;
  final int orders;
  final int newVendors;

  const AdminDailyPlatformEntity({
    required this.date,
    required this.revenue,
    required this.orders,
    required this.newVendors,
  });

  @override
  List<Object?> get props => [date, revenue, orders, newVendors];
}
