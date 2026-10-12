import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/pos_models.dart';

abstract class PosRemoteDataSource {
  Future<List<BranchModel>> getBranches();
  Future<List<WarehouseModel>> getWarehouses({String? branchId});
  Future<List<PosProductModel>> getProducts({
    String? categoryId,
    String? search,
    String? warehouseId,
    int perPage = 200,
  });
  Future<List<PosCategoryModel>> getCategories();
  Future<List<PosCustomerModel>> searchCustomers({required String query});
  Future<PosCustomerModel> createCustomer({required String name, String? phone});
  Future<PosOrderModel> createOrder(Map<String, dynamic> payload);
}

class PosRemoteDataSourceImpl implements PosRemoteDataSource {
  final ApiClient _client;

  const PosRemoteDataSourceImpl(this._client);

  @override
  Future<List<BranchModel>> getBranches() async {
    final res = await _client.get<Map<String, dynamic>>(ApiEndpoints.branches);
    return _parseList(res.data!, (e) => BranchModel.fromJson(e));
  }

  @override
  Future<List<WarehouseModel>> getWarehouses({String? branchId}) async {
    final params = <String, dynamic>{
      if (branchId != null) 'branch_id': branchId,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.warehouses,
      queryParameters: params,
    );
    return _parseList(res.data!, (e) => WarehouseModel.fromJson(e));
  }

  @override
  Future<List<PosProductModel>> getProducts({
    String? categoryId,
    String? search,
    String? warehouseId,
    int perPage = 200,
  }) async {
    final params = <String, dynamic>{
      'active_only': 1,
      'per_page': perPage,
      if (warehouseId != null && warehouseId.isNotEmpty)
        'warehouse_id': warehouseId,
      if (categoryId != null) 'category_id': categoryId,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.products,
      queryParameters: params,
    );
    final body = res.data!;
    final rawData = body['data'] as List<dynamic>?
        ?? (body is List ? body as List<dynamic> : <dynamic>[]);
    return rawData
        .map((e) => PosProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PosCategoryModel>> getCategories() async {
    final res = await _client.get<Map<String, dynamic>>(ApiEndpoints.categories);
    return _parseList(res.data!, (e) => PosCategoryModel.fromJson(e));
  }

  @override
  Future<List<PosCustomerModel>> searchCustomers({
    required String query,
  }) async {
    final params = <String, dynamic>{
      'search': query,
      'is_active': 1,
      'per_page': 8,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.customers,
      queryParameters: params,
    );
    return _parseList(res.data!, (e) => PosCustomerModel.fromJson(e));
  }

  @override
  Future<PosCustomerModel> createCustomer({
    required String name,
    String? phone,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.customers,
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
    final body = res.data!;
    final data = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return PosCustomerModel.fromJson(data);
  }

  @override
  Future<PosOrderModel> createOrder(Map<String, dynamic> payload) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.orders,
      data: payload,
    );
    final body = res.data!;
    final orderJson = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return PosOrderModel.fromJson(orderJson);
  }

  List<T> _parseList<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = body['data'] as List<dynamic>?
        ?? (body.values.firstWhere(
              (v) => v is List,
              orElse: () => <dynamic>[],
            ) as List<dynamic>);
    return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }
}
