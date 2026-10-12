import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/order_entity.dart';

class OrdersStats extends Equatable {
  final int totalOrders;
  final int pendingOrders;
  final int onlineOrders;
  final double? netRevenue;

  const OrdersStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.onlineOrders,
    this.netRevenue,
  });

  @override
  List<Object?> get props => [totalOrders, pendingOrders, onlineOrders, netRevenue];
}

class OrdersFilters extends Equatable {
  final int page;
  final String search;
  final String? status;
  final String? fulfillmentStatus;
  final String? channel;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  /// 'today' | 'thisWeek' | 'thisMonth' | 'custom' | null
  final String? datePreset;

  const OrdersFilters({
    this.page = 1,
    this.search = '',
    this.status,
    this.fulfillmentStatus,
    this.channel,
    this.dateFrom,
    this.dateTo,
    this.datePreset,
  });

  OrdersFilters copyWith({
    int? page,
    String? search,
    String? status,
    String? fulfillmentStatus,
    String? channel,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? datePreset,
    bool clearStatus = false,
    bool clearFulfillmentStatus = false,
    bool clearChannel = false,
    bool clearDateRange = false,
  }) {
    return OrdersFilters(
      page:              page ?? this.page,
      search:            search ?? this.search,
      status:            clearStatus ? null : (status ?? this.status),
      fulfillmentStatus: clearFulfillmentStatus
          ? null
          : (fulfillmentStatus ?? this.fulfillmentStatus),
      channel:    clearChannel ? null : (channel ?? this.channel),
      dateFrom:   clearDateRange ? null : (dateFrom ?? this.dateFrom),
      dateTo:     clearDateRange ? null : (dateTo ?? this.dateTo),
      datePreset: clearDateRange ? null : (datePreset ?? this.datePreset),
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      fulfillmentStatus != null ||
      dateFrom != null ||
      search.isNotEmpty;

  @override
  List<Object?> get props =>
      [page, search, status, fulfillmentStatus, channel, dateFrom, dateTo, datePreset];
}

sealed class OrdersState extends Equatable {
  const OrdersState();
}

class OrdersInitial extends OrdersState {
  const OrdersInitial();

  @override
  List<Object?> get props => [];
}

class OrdersLoading extends OrdersState {
  final OrdersFilters filters;
  const OrdersLoading({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  final PaginationMeta meta;
  final OrdersFilters filters;
  final OrderEntity? selectedOrder;
  final bool isDetailLoading;
  final OrdersStats? stats;

  const OrdersLoaded({
    required this.orders,
    required this.meta,
    required this.filters,
    this.selectedOrder,
    this.isDetailLoading = false,
    this.stats,
  });

  OrdersLoaded copyWith({
    List<OrderEntity>? orders,
    PaginationMeta? meta,
    OrdersFilters? filters,
    OrderEntity? selectedOrder,
    bool? isDetailLoading,
    OrdersStats? stats,
    bool clearSelectedOrder = false,
  }) {
    return OrdersLoaded(
      orders:          orders ?? this.orders,
      meta:            meta ?? this.meta,
      filters:         filters ?? this.filters,
      selectedOrder:   clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      stats:           stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props =>
      [orders, meta, filters, selectedOrder, isDetailLoading, stats];
}

class OrdersError extends OrdersState {
  final String message;
  final OrdersFilters filters;

  const OrdersError({required this.message, required this.filters});

  @override
  List<Object?> get props => [message, filters];
}
