import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../models/order_model.dart';
import '../../domain/entities/order_entity.dart';

abstract class OrdersRemoteDataSource {
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

  Future<OrderEntity> getOrderById(String id);
  Future<OrderEntity> getOrderByToken(String token);
  Future<void> updateStatus(String id, String status, {String? fulfillmentStatus});
  Future<void> updateFulfillmentStatus(String id, String fulfillmentStatus, {String? currentStatus});
  Future<void> refundOrder(
    String id, {
    required String reason,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  });
  Future<List<int>> downloadInvoice(String id);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final ApiClient _client;
  static final _dateFmt = DateFormat('yyyy-MM-dd', 'en_US');

  const OrdersRemoteDataSourceImpl(this._client);

  @override
  Future<double?> getNetRevenue({DateTime? dateFrom, DateTime? dateTo}) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.reportsSummary,
        queryParameters: {
          if (dateFrom != null) 'date_from': _dateFmt.format(dateFrom),
          if (dateTo != null)   'date_to':   _dateFmt.format(dateTo),
        },
      );
      final body = response.data!;
      final data = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      final summary = data['summary'] as Map<String, dynamic>?;
      return (summary?['net_revenue'] as num?)?.toDouble();
    } catch (_) {
      return null;
    }
  }

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
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
      if (fulfillmentStatus != null) 'fulfillment_status': fulfillmentStatus,
      if (channel != null) 'channel': channel,
      if (dateFrom != null) 'date_from': _dateFmt.format(dateFrom),
      if (dateTo != null) 'date_to': _dateFmt.format(dateTo),
    };

    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.orders,
      queryParameters: params,
    );

    return PaginatedResponse.fromJson(
      response.data!,
      OrderModel.fromJson,
    );
  }

  @override
  Future<OrderEntity> getOrderById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.orderById(id),
    );
    final body = response.data!;
    final data = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return OrderModel.fromJson(data);
  }

  @override
  Future<OrderEntity> getOrderByToken(String token) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.orderByToken(token),
    );
    final body = response.data!;
    final data = body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return OrderModel.fromJson(data);
  }

  @override
  Future<void> updateStatus(String id, String status, {String? fulfillmentStatus}) async {
    await _client.patch<dynamic>(
      ApiEndpoints.orderStatus(id),
      data: {
        'payment_status': status,
        if (fulfillmentStatus != null) 'fulfillment_status': fulfillmentStatus,
      },
    );
  }

  @override
  Future<void> updateFulfillmentStatus(String id, String fulfillmentStatus, {String? currentStatus}) async {
    // Backend uses the /status endpoint for both; /fulfillment only supports GET
    await _client.patch<dynamic>(
      ApiEndpoints.orderStatus(id),
      data: {
        if (currentStatus != null) 'payment_status': currentStatus,
        'fulfillment_status': fulfillmentStatus,
      },
    );
  }

  @override
  Future<void> refundOrder(
    String id, {
    required String reason,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.orderRefunds(id),
      data: {
        'reason': reason,
        'payment_method': paymentMethod,
        'items': items,
      },
    );
  }

  @override
  Future<List<int>> downloadInvoice(String id) async {
    final response = await _client.get<List<int>>(
      ApiEndpoints.orderInvoice(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
