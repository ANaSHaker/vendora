import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/warehouse_entities.dart';
import '../models/warehouse_models.dart';

abstract class WarehouseRemoteDataSource {
  Future<PaginatedResponse<WarehouseModel>> getWarehouses({
    String? search,
    String? branchId,
    int page = 1,
    int perPage = 25,
  });

  Future<WarehouseModel> createWarehouse(WarehouseFormData data);
  Future<WarehouseModel> updateWarehouse(String id, WarehouseFormData data);
  Future<void> deleteWarehouse(String id);
  Future<void> setDefault(String id);
}

class WarehouseRemoteDataSourceImpl implements WarehouseRemoteDataSource {
  final ApiClient _client;

  const WarehouseRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<WarehouseModel>> getWarehouses({
    String? search,
    String? branchId,
    int page = 1,
    int perPage = 25,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.warehouses,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, WarehouseModel.fromJson);
  }

  @override
  Future<WarehouseModel> createWarehouse(WarehouseFormData data) async {
    final payload = WarehouseModel(
      id: '',
      name: data.name,
      code: data.code,
      type: data.type,
      isActive: data.isActive,
      isDefault: data.isDefault,
    ).toJson(data);
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.warehouses,
      data: payload,
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return WarehouseModel.fromJson(json);
  }

  @override
  Future<WarehouseModel> updateWarehouse(
      String id, WarehouseFormData data) async {
    final payload = WarehouseModel(
      id: id,
      name: data.name,
      code: data.code,
      type: data.type,
      isActive: data.isActive,
      isDefault: data.isDefault,
    ).toJson(data);
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.warehouseById(id),
      data: payload,
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return WarehouseModel.fromJson(json);
  }

  @override
  Future<void> deleteWarehouse(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.warehouseById(id));
  }

  @override
  Future<void> setDefault(String id) async {
    await _client.post<dynamic>(ApiEndpoints.setDefaultWarehouse(id));
  }
}
