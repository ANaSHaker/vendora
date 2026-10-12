import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/stock_count_entities.dart';
import '../models/stock_count_models.dart';

abstract class StockCountRemoteDataSource {
  Future<PaginatedResponse<StockCountModel>> getStockCounts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<StockCountModel> getStockCountById(String id);
  Future<StockCountModel> createStockCount(StockCountFormData data);
  Future<StockCountModel> postStockCount(String id);
  Future<void> deleteStockCount(String id);
}

class StockCountRemoteDataSourceImpl implements StockCountRemoteDataSource {
  final ApiClient _client;

  const StockCountRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<StockCountModel>> getStockCounts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.stockCounts,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, StockCountModel.fromJson);
  }

  @override
  Future<StockCountModel> getStockCountById(String id) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.stockCountById(id));
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return StockCountModel.fromJson(json);
  }

  @override
  Future<StockCountModel> createStockCount(StockCountFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.stockCounts,
      data: StockCountModel.buildPayload(data),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return StockCountModel.fromJson(json);
  }

  @override
  Future<StockCountModel> postStockCount(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.postStockCount(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return StockCountModel.fromJson(json);
  }

  @override
  Future<void> deleteStockCount(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.stockCountById(id));
  }
}
