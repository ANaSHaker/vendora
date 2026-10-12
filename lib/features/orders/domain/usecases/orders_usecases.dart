import '../../../../core/api/api_response.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUseCase {
  final OrdersRepository _repo;
  const GetOrdersUseCase(this._repo);

  Future<PaginatedResponse<OrderEntity>> call({
    required int page,
    int perPage = 20,
    String? search,
    String? status,
    String? fulfillmentStatus,
    String? channel,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _repo.getOrders(
        page: page,
        perPage: perPage,
        search: search,
        status: status,
        fulfillmentStatus: fulfillmentStatus,
        channel: channel,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
}

class GetOrderByIdUseCase {
  final OrdersRepository _repo;
  const GetOrderByIdUseCase(this._repo);

  Future<OrderEntity> call(String id) => _repo.getOrderById(id);
}

class GetOrderByTokenUseCase {
  final OrdersRepository _repo;
  const GetOrderByTokenUseCase(this._repo);

  Future<OrderEntity> call(String token) => _repo.getOrderByToken(token);
}

class UpdateOrderStatusUseCase {
  final OrdersRepository _repo;
  const UpdateOrderStatusUseCase(this._repo);

  Future<void> call(String id, String status, {String? fulfillmentStatus}) =>
      _repo.updateStatus(id, status, fulfillmentStatus: fulfillmentStatus);
}

class UpdateFulfillmentStatusUseCase {
  final OrdersRepository _repo;
  const UpdateFulfillmentStatusUseCase(this._repo);

  Future<void> call(String id, String fulfillmentStatus, {String? currentStatus}) =>
      _repo.updateFulfillmentStatus(id, fulfillmentStatus, currentStatus: currentStatus);
}

class RefundOrderUseCase {
  final OrdersRepository _repo;
  const RefundOrderUseCase(this._repo);

  Future<void> call(
    String id, {
    required String reason,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) =>
      _repo.refundOrder(id, reason: reason, paymentMethod: paymentMethod, items: items);
}

class DownloadInvoiceUseCase {
  final OrdersRepository _repo;
  const DownloadInvoiceUseCase(this._repo);

  Future<List<int>> call(String id) => _repo.downloadInvoice(id);
}

class GetNetRevenueUseCase {
  final OrdersRepository _repo;
  const GetNetRevenueUseCase(this._repo);

  Future<double?> call({DateTime? dateFrom, DateTime? dateTo}) =>
      _repo.getNetRevenue(dateFrom: dateFrom, dateTo: dateTo);
}
