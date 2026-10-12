import '../../../../core/api/api_response.dart';
import '../entities/order_entity.dart';

abstract class OrdersRepository {
  Future<double?> getNetRevenue({DateTime? dateFrom, DateTime? dateTo});

  Future<PaginatedResponse<OrderEntity>> getOrders({
    required int page,
    int perPage,
    String? search,
    String? status,
    String? fulfillmentStatus,
    String? channel,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<void> updateFulfillmentStatus(String id, String fulfillmentStatus, {String? currentStatus});

  Future<OrderEntity> getOrderById(String id);
  Future<OrderEntity> getOrderByToken(String token);

  Future<void> updateStatus(String id, String status, {String? fulfillmentStatus});

  Future<void> refundOrder(
    String id, {
    required String reason,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  });

  Future<List<int>> downloadInvoice(String id);
}
