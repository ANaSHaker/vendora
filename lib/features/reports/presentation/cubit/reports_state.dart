import 'package:equatable/equatable.dart';
import '../../domain/entities/report_entities.dart';
import '../../../../core/api/api_response.dart' show PaginationMeta;
import '../../../../design_system/widgets/inputs/app_date_range_picker.dart';

class ReportFilters extends Equatable {
  final DateTime dateFrom;
  final DateTime dateTo;
  final DateRangePreset preset;
  final String? branchId;
  final String? warehouseId;
  final String? productId;
  final String? paymentMethod;
  final String? movementType;

  const ReportFilters({
    required this.dateFrom,
    required this.dateTo,
    this.preset = DateRangePreset.thisMonth,
    this.branchId,
    this.warehouseId,
    this.productId,
    this.paymentMethod,
    this.movementType,
  });

  static ReportFilters thisMonth() {
    final now = DateTime.now();
    return ReportFilters(
      dateFrom: DateTime(now.year, now.month, 1),
      dateTo: now,
      preset: DateRangePreset.thisMonth,
    );
  }

  ReportFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    DateRangePreset? preset,
    String? branchId,
    String? warehouseId,
    String? productId,
    String? paymentMethod,
    String? movementType,
    bool clearBranch = false,
    bool clearWarehouse = false,
    bool clearProduct = false,
    bool clearPaymentMethod = false,
    bool clearMovementType = false,
  }) {
    return ReportFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      preset: preset ?? this.preset,
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      warehouseId: clearWarehouse ? null : (warehouseId ?? this.warehouseId),
      productId: clearProduct ? null : (productId ?? this.productId),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      movementType: clearMovementType ? null : (movementType ?? this.movementType),
    );
  }

  @override
  List<Object?> get props =>
      [dateFrom, dateTo, preset, branchId, warehouseId, productId, paymentMethod, movementType];
}

// ─── Sales Report ─────────────────────────────────────────────────────────────

sealed class SalesReportState extends Equatable {
  const SalesReportState();
}

class SalesReportInitial extends SalesReportState {
  final ReportFilters filters;
  const SalesReportInitial(this.filters);

  @override
  List<Object?> get props => [filters];
}

class SalesReportLoading extends SalesReportState {
  final ReportFilters filters;
  const SalesReportLoading(this.filters);

  @override
  List<Object?> get props => [filters];
}

class SalesReportLoaded extends SalesReportState {
  final SalesReportEntity data;
  final ReportFilters filters;
  final List<SalesOrderRowEntity> orders;
  final PaginationMeta? ordersMeta;
  final bool ordersLoading;

  const SalesReportLoaded({
    required this.data,
    required this.filters,
    this.orders = const [],
    this.ordersMeta,
    this.ordersLoading = false,
  });

  SalesReportLoaded copyWith({
    SalesReportEntity? data,
    ReportFilters? filters,
    List<SalesOrderRowEntity>? orders,
    PaginationMeta? ordersMeta,
    bool? ordersLoading,
  }) {
    return SalesReportLoaded(
      data: data ?? this.data,
      filters: filters ?? this.filters,
      orders: orders ?? this.orders,
      ordersMeta: ordersMeta ?? this.ordersMeta,
      ordersLoading: ordersLoading ?? this.ordersLoading,
    );
  }

  @override
  List<Object?> get props => [data, filters, orders, ordersMeta, ordersLoading];
}

class SalesReportError extends SalesReportState {
  final String message;
  final ReportFilters filters;

  const SalesReportError({required this.message, required this.filters});

  @override
  List<Object?> get props => [message, filters];
}

// ─── Inventory Report ─────────────────────────────────────────────────────────

enum InventoryReportTab { stock, movements, transfers, stockCounts }

sealed class InventoryReportState extends Equatable {
  const InventoryReportState();
}

class InventoryReportInitial extends InventoryReportState {
  final ReportFilters filters;
  const InventoryReportInitial(this.filters);

  @override
  List<Object?> get props => [filters];
}

class InventoryReportLoading extends InventoryReportState {
  final ReportFilters filters;
  final InventoryReportTab activeTab;
  const InventoryReportLoading(this.filters, {this.activeTab = InventoryReportTab.stock});

  @override
  List<Object?> get props => [filters, activeTab];
}

class InventoryReportLoaded extends InventoryReportState {
  final InventoryTabReport data;
  final ReportFilters filters;
  final InventoryReportTab activeTab;

  const InventoryReportLoaded({
    required this.data,
    required this.filters,
    this.activeTab = InventoryReportTab.stock,
  });

  InventoryReportLoaded copyWith({
    InventoryTabReport? data,
    ReportFilters? filters,
    InventoryReportTab? activeTab,
  }) {
    return InventoryReportLoaded(
      data: data ?? this.data,
      filters: filters ?? this.filters,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  List<Object?> get props => [data, filters, activeTab];
}

class InventoryReportError extends InventoryReportState {
  final String message;
  final ReportFilters filters;

  const InventoryReportError({required this.message, required this.filters});

  @override
  List<Object?> get props => [message, filters];
}

// ─── Financial Report ─────────────────────────────────────────────────────────

enum FinancialReportTab { pnl, sales, inventory, fifo }

sealed class FinancialReportState extends Equatable {
  const FinancialReportState();
}

class FinancialReportInitial extends FinancialReportState {
  final ReportFilters filters;
  const FinancialReportInitial(this.filters);

  @override
  List<Object?> get props => [filters];
}

class FinancialReportLoading extends FinancialReportState {
  final ReportFilters filters;
  const FinancialReportLoading(this.filters);

  @override
  List<Object?> get props => [filters];
}

class FinancialReportLoaded extends FinancialReportState {
  final FinancialReportEntity data;
  final ReportFilters filters;
  final FinancialReportTab activeTab;

  const FinancialReportLoaded({
    required this.data,
    required this.filters,
    this.activeTab = FinancialReportTab.pnl,
  });

  FinancialReportLoaded copyWith({
    FinancialReportEntity? data,
    ReportFilters? filters,
    FinancialReportTab? activeTab,
  }) {
    return FinancialReportLoaded(
      data: data ?? this.data,
      filters: filters ?? this.filters,
      activeTab: activeTab ?? this.activeTab,
    );
  }

  @override
  List<Object?> get props => [data, filters, activeTab];
}

class FinancialReportError extends FinancialReportState {
  final String message;
  final ReportFilters filters;

  const FinancialReportError({required this.message, required this.filters});

  @override
  List<Object?> get props => [message, filters];
}
