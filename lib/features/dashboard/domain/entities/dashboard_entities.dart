import 'package:equatable/equatable.dart';

class DashboardPeriodEntity extends Equatable {
  final DateTime dateFrom;
  final DateTime dateTo;

  const DashboardPeriodEntity({
    required this.dateFrom,
    required this.dateTo,
  });

  @override
  List<Object?> get props => [dateFrom, dateTo];
}

class DashboardSummaryEntity extends Equatable {
  final int totalOrders;
  final double totalSales;
  final double totalRefunds;
  final double netRevenue;
  final double avgOrderValue;

  const DashboardSummaryEntity({
    required this.totalOrders,
    required this.totalSales,
    required this.totalRefunds,
    required this.netRevenue,
    required this.avgOrderValue,
  });

  @override
  List<Object?> get props => [
        totalOrders,
        totalSales,
        totalRefunds,
        netRevenue,
        avgOrderValue,
      ];
}

class TopProductEntity extends Equatable {
  final String productId;
  final String productName;
  final int totalQty;
  final double totalRevenue;

  const TopProductEntity({
    required this.productId,
    required this.productName,
    required this.totalQty,
    required this.totalRevenue,
  });

  @override
  List<Object?> get props => [productId, productName, totalQty, totalRevenue];
}

class TopCustomerEntity extends Equatable {
  final String? customerId;
  final String customerName;
  final int ordersCount;
  final double totalSpent;

  const TopCustomerEntity({
    required this.customerId,
    required this.customerName,
    required this.ordersCount,
    required this.totalSpent,
  });

  @override
  List<Object?> get props => [customerId, customerName, ordersCount, totalSpent];
}

class SalesPerDayEntity extends Equatable {
  final DateTime date;
  final int ordersCount;
  final double totalSales;

  const SalesPerDayEntity({
    required this.date,
    required this.ordersCount,
    required this.totalSales,
  });

  @override
  List<Object?> get props => [date, ordersCount, totalSales];
}

class DashboardDataEntity extends Equatable {
  final DashboardPeriodEntity period;
  final DashboardSummaryEntity summary;
  final List<TopProductEntity> topProducts;
  final List<TopCustomerEntity> topCustomers;
  final List<SalesPerDayEntity> salesPerDay;

  const DashboardDataEntity({
    required this.period,
    required this.summary,
    required this.topProducts,
    required this.topCustomers,
    required this.salesPerDay,
  });

  @override
  List<Object?> get props => [
        period,
        summary,
        topProducts,
        topCustomers,
        salesPerDay,
      ];
}
