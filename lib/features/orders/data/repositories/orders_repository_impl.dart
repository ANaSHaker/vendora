import '../../../../core/api/api_response.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource _ds;
  const OrdersRepositoryImpl(this._ds);

  @override
  Future<double?> getNetRevenue({DateTime? dateFrom, DateTime? dateTo}) =>
      _ds.getNetRevenue(dateFrom: dateFrom, dateTo: dateTo);

  @override
  Future<PaginatedResponse<OrderEntity>> getOrders({
    required int page,
    int perPage = 20,
    String? search,
    String? status,
    String? fulfillmentStatus,
    String? channel,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _ds.getOrders(
        page: page,
        perPage: perPage,
        search: search,
        status: status,
        fulfillmentStatus: fulfillmentStatus,
        channel: channel,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  @override
  Future<OrderEntity> getOrderById(String id) => _ds.getOrderById(id);

  @override
  Future<OrderEntity> getOrderByToken(String token) => _ds.getOrderByToken(token);

  @override
  Future<void> updateStatus(String id, String status, {String? fulfillmentStatus}) =>
      _ds.updateStatus(id, status, fulfillmentStatus: fulfillmentStatus);

  @override
  Future<void> updateFulfillmentStatus(String id, String fulfillmentStatus, {String? currentStatus}) =>
      _ds.updateFulfillmentStatus(id, fulfillmentStatus, currentStatus: currentStatus);

  @override
  Future<void> refundOrder(
    String id, {
    required String reason,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) =>
      _ds.refundOrder(id, reason: reason, paymentMethod: paymentMethod, items: items);

  @override
  Future<List<int>> downloadInvoice(String id) => _ds.downloadInvoice(id);
}
