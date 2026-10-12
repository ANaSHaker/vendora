import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/supplier_entities.dart';
import '../models/supplier_models.dart';

abstract class SuppliersRemoteDataSource {
  Future<PaginatedResponse<SupplierModel>> getSuppliers({
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<SupplierModel> getSupplierById(String id);
  Future<SupplierModel> createSupplier(SupplierFormData data);
  Future<SupplierModel> updateSupplier(String id, SupplierFormData data);
  Future<void> deleteSupplier(String id);
}

class SuppliersRemoteDataSourceImpl implements SuppliersRemoteDataSource {
  final ApiClient _client;

  const SuppliersRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<SupplierModel>> getSuppliers({
    String? search,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.suppliers,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, SupplierModel.fromJson);
  }

  @override
  Future<SupplierModel> getSupplierById(String id) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.supplierById(id));
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return SupplierModel.fromJson(json);
  }

  @override
  Future<SupplierModel> createSupplier(SupplierFormData data) async {
    final payload = SupplierModel(
      id: '',
      name: data.name,
    ).toJson(data);
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.suppliers,
      data: payload,
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return SupplierModel.fromJson(json);
  }

  @override
  Future<SupplierModel> updateSupplier(String id, SupplierFormData data) async {
    final payload = SupplierModel(
      id: id,
      name: data.name,
    ).toJson(data);
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.supplierById(id),
      data: payload,
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return SupplierModel.fromJson(json);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.supplierById(id));
  }
}
