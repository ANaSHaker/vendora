import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../models/inventory_models.dart';

abstract class InventoryRemoteDataSource {
  Future<PaginatedResponse<InventoryBalanceModel>> getStock({
    String? search,
    String? branchId,
    String? warehouseId,
    bool? lowStockOnly,
    int page = 1,
    int perPage = 50,
  });

  Future<PaginatedResponse<InventoryMovementModel>> getMovements({
    String? search,
    String? warehouseId,
    String? productId,
    String? movementType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  });

  Future<List<WarehouseOptionModel>> getWarehouses();

  Future<List<InventoryBranchOptionModel>> getBranches();
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final ApiClient _client;

  const InventoryRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<InventoryBalanceModel>> getStock({
    String? search,
    String? branchId,
    String? warehouseId,
    bool? lowStockOnly,
    int page = 1,
    int perPage = 50,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (branchId != null) 'branch_id': branchId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (lowStockOnly == true) 'low_stock': true,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.inventoryWarehouses,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, InventoryBalanceModel.fromJson);
  }

  @override
  Future<PaginatedResponse<InventoryMovementModel>> getMovements({
    String? search,
    String? warehouseId,
    String? productId,
    String? movementType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (productId != null) 'product_id': productId,
      if (movementType != null) 'type': movementType,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.inventoryMovements,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(
        res.data!, InventoryMovementModel.fromJson);
  }

  @override
  Future<List<WarehouseOptionModel>> getWarehouses() async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.warehouses,
      queryParameters: {'per_page': 200},
    );
    final body = res.data!;
    final rawData = body['data'] as List<dynamic>? ?? [];
    return rawData
        .map((e) => WarehouseOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<InventoryBranchOptionModel>> getBranches() async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.branches,
      queryParameters: {'per_page': 200},
    );
    final body = res.data!;
    final rawData = body['data'] as List<dynamic>? ?? [];
    return rawData
        .map((e) =>
            InventoryBranchOptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
