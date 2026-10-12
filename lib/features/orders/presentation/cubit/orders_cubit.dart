import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final GetOrdersUseCase _getOrders;
  final GetOrderByIdUseCase _getOrderById;
  final UpdateOrderStatusUseCase _updateStatus;
  final UpdateFulfillmentStatusUseCase _updateFulfillmentStatus;
  final RefundOrderUseCase _refundOrder;
  final DownloadInvoiceUseCase _downloadInvoice;
  final GetNetRevenueUseCase _getNetRevenue;

  Timer? _searchDebounce;

  OrdersCubit({
    required GetOrdersUseCase getOrders,
    required GetOrderByIdUseCase getOrderById,
    required UpdateOrderStatusUseCase updateStatus,
    required UpdateFulfillmentStatusUseCase updateFulfillmentStatus,
    required RefundOrderUseCase refundOrder,
    required DownloadInvoiceUseCase downloadInvoice,
    required GetNetRevenueUseCase getNetRevenue,
  })  : _getOrders = getOrders,
        _getOrderById = getOrderById,
        _updateStatus = updateStatus,
        _updateFulfillmentStatus = updateFulfillmentStatus,
        _refundOrder = refundOrder,
        _downloadInvoice = downloadInvoice,
        _getNetRevenue = getNetRevenue,
        super(const OrdersInitial());

  Future<void> load({OrdersFilters? filters}) async {
    final f = filters ?? const OrdersFilters();
    // Preserve existing stats across reloads so the bar doesn't flicker
    final prevStats = state is OrdersLoaded ? (state as OrdersLoaded).stats : null;
    emit(OrdersLoading(filters: f));
    try {
      final result = await _getOrders(
        page: f.page,
        search: f.search.isEmpty ? null : f.search,
        status: f.status,
        fulfillmentStatus: f.fulfillmentStatus,
        channel: f.channel,
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
      );
      emit(OrdersLoaded(
        orders: result.data,
        meta: result.meta,
        filters: f,
        stats: prevStats,
      ));
      _loadStats(dateFrom: f.dateFrom, dateTo: f.dateTo);
    } catch (e) {
      emit(OrdersError(message: e.toString(), filters: f));
    }
  }

  Future<void> _loadStats({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final countResults = await Future.wait([
        _getOrders(page: 1, perPage: 1, dateFrom: dateFrom, dateTo: dateTo),
        _getOrders(page: 1, perPage: 1, status: 'pending', dateFrom: dateFrom, dateTo: dateTo),
        _getOrders(page: 1, perPage: 1, channel: 'online', dateFrom: dateFrom, dateTo: dateTo),
      ]);
      final revenue = await _getNetRevenue(dateFrom: dateFrom, dateTo: dateTo)
          .catchError((_) => null);
      if (state is! OrdersLoaded) return;
      final stats = OrdersStats(
        totalOrders:   countResults[0].meta.total,
        pendingOrders: countResults[1].meta.total,
        onlineOrders:  countResults[2].meta.total,
        netRevenue:    revenue,
      );
      emit((state as OrdersLoaded).copyWith(stats: stats));
    } catch (_) {
      // Stats are non-critical
    }
  }

  void refresh() {
    final f = _currentFilters;
    load(filters: f.copyWith(page: 1));
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      final f = _currentFilters;
      load(filters: f.copyWith(search: query, page: 1));
    });
  }

  void filterByStatus(String? status) {
    final f = _currentFilters;
    load(
      filters: status == null
          ? f.copyWith(page: 1, clearStatus: true)
          : f.copyWith(status: status, page: 1),
    );
  }

  void filterByFulfillmentStatus(String? fulfillmentStatus) {
    final f = _currentFilters;
    load(
      filters: fulfillmentStatus == null
          ? f.copyWith(page: 1, clearFulfillmentStatus: true)
          : f.copyWith(fulfillmentStatus: fulfillmentStatus, page: 1),
    );
  }

  void filterByChannel(String? channel) {
    final f = _currentFilters;
    load(
      filters: channel == null
          ? f.copyWith(page: 1, clearChannel: true)
          : f.copyWith(channel: channel, page: 1),
    );
  }

  void goToPage(int page) {
    load(filters: _currentFilters.copyWith(page: page));
  }

  void applyDatePreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final (from, to) = switch (preset) {
      'today'     => (today, today),
      'thisWeek'  => (today.subtract(Duration(days: now.weekday - 1)), today),
      'thisMonth' => (DateTime(now.year, now.month, 1), today),
      _           => (null as DateTime?, null as DateTime?),
    };
    load(filters: _currentFilters.copyWith(
      dateFrom:   from,
      dateTo:     to,
      datePreset: preset,
      page:       1,
    ));
  }

  void setDateRange(DateTime? from, DateTime? to) {
    load(filters: _currentFilters.copyWith(
      dateFrom:   from,
      dateTo:     to,
      datePreset: (from != null || to != null) ? 'custom' : null,
      page:       1,
    ));
  }

  Future<void> selectOrder(String orderId) async {
    if (state is! OrdersLoaded) return;
    final loaded = state as OrdersLoaded;

    final existing = loaded.orders.where((o) => o.id == orderId).firstOrNull;
    if (existing != null && existing.items.isNotEmpty) {
      emit(loaded.copyWith(selectedOrder: existing));
      return;
    }

    emit(loaded.copyWith(isDetailLoading: true));
    try {
      final order = await _getOrderById(orderId);
      if (state is OrdersLoaded) {
        emit((state as OrdersLoaded).copyWith(
          selectedOrder: order,
          isDetailLoading: false,
        ));
      }
    } catch (_) {
      if (state is OrdersLoaded) {
        emit((state as OrdersLoaded).copyWith(isDetailLoading: false));
      }
    }
  }

  void closeDetail() {
    if (state is OrdersLoaded) {
      emit((state as OrdersLoaded).copyWith(clearSelectedOrder: true));
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> updateOrderStatus(String orderId, String status) async {
    try {
      final currentFulfillment = _selectedOrder?.fulfillmentStatus;
      await _updateStatus(orderId, status, fulfillmentStatus: currentFulfillment);
      refresh();
      return null;
    } catch (e) {
      debugPrint('[OrdersCubit] updateOrderStatus error: $e');
      return _errorMessage(e);
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> updateFulfillmentStatus(String orderId, String fulfillmentStatus) async {
    try {
      final currentStatus = _selectedOrder?.status;
      await _updateFulfillmentStatus(orderId, fulfillmentStatus, currentStatus: currentStatus);
      if (state is OrdersLoaded) {
        final loaded = state as OrdersLoaded;
        if (loaded.selectedOrder?.id == orderId) {
          final updated = await _getOrderById(orderId);
          emit(loaded.copyWith(selectedOrder: updated));
        }
      }
      refresh();
      return null;
    } catch (e) {
      debugPrint('[OrdersCubit] updateFulfillmentStatus error: $e');
      return _errorMessage(e);
    }
  }

  OrderEntity? get _selectedOrder =>
      state is OrdersLoaded ? (state as OrdersLoaded).selectedOrder : null;

  static String _errorMessage(Object e) {
    if (e is DioException) {
      final inner = e.error;
      if (inner is ServerException) return inner.message;
      if (inner is ValidationException) {
        final first = inner.errors?.values.firstOrNull?.firstOrNull;
        return first ?? inner.message;
      }
      if (inner is NetworkException) return inner.message;
      if (inner is ForbiddenException) return 'Permission denied';
      if (inner is UnauthorizedException) return 'Unauthorized';
      if (inner is SubscriptionException) return 'Subscription required';
      final body = e.response?.data;
      if (body is Map) return body['message'] as String? ?? e.message ?? 'Server error';
      return e.message ?? 'Server error';
    }
    if (e is ServerException) return e.message;
    if (e is ValidationException) return e.message;
    if (e is NetworkException) return e.message;
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return e.toString();
  }

  Future<bool> refundOrder(
    String orderId, {
    required String reason,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _refundOrder(
        orderId,
        reason: reason,
        paymentMethod: paymentMethod,
        items: items,
      );
      refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>?> getInvoiceBytes(String orderId) async {
    try {
      return await _downloadInvoice(orderId);
    } catch (e) {
      debugPrint('[OrdersCubit] getInvoiceBytes error: $e');
      return null;
    }
  }

  OrdersFilters get _currentFilters => switch (state) {
        OrdersLoaded(:final filters) => filters,
        OrdersLoading(:final filters) => filters,
        OrdersError(:final filters) => filters,
        _ => const OrdersFilters(),
      };

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
