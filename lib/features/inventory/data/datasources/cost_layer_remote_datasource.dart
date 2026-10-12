import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../models/cost_layer_models.dart';

abstract class CostLayerRemoteDataSource {
  Future<PaginatedResponse<CostLayerModel>> getCostLayers({
    String? search,
    String? warehouseId,
    String? branchId,
    String? productId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  });

  Future<List<CostLayerConsumptionModel>> getConsumptions(String layerId);
}

class CostLayerRemoteDataSourceImpl implements CostLayerRemoteDataSource {
  final ApiClient _client;

  const CostLayerRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<CostLayerModel>> getCostLayers({
    String? search,
    String? warehouseId,
    String? branchId,
    String? productId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (warehouseId != null && warehouseId.isNotEmpty)
        'warehouse_id': warehouseId,
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
      if (productId != null && productId.isNotEmpty) 'product_id': productId,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.inventoryCostLayers,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, CostLayerModel.fromJson);
  }

  @override
  Future<List<CostLayerConsumptionModel>> getConsumptions(
      String layerId) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.costLayerConsumptions(layerId),
    );
    final body = res.data!;
    final list =
        (body['data'] ?? body) as List<dynamic>;
    return list
        .map((e) =>
            CostLayerConsumptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
