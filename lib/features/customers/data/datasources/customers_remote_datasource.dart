import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/customer_entities.dart';
import '../models/customer_models.dart';

abstract class CustomersRemoteDataSource {
  Future<PaginatedResponse<CustomerModel>> getCustomers({
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<CustomerModel> getCustomerById(String id);
  Future<CustomerModel> createCustomer(CustomerFormData data);
  Future<CustomerModel> updateCustomer(String id, CustomerFormData data);
  Future<void> deleteCustomer(String id);
}

class CustomersRemoteDataSourceImpl implements CustomersRemoteDataSource {
  final ApiClient _client;

  const CustomersRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<CustomerModel>> getCustomers({
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
      ApiEndpoints.customers,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, CustomerModel.fromJson);
  }

  @override
  Future<CustomerModel> getCustomerById(String id) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.customerById(id));
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return CustomerModel.fromJson(json);
  }

  @override
  Future<CustomerModel> createCustomer(CustomerFormData data) async {
    final payload = CustomerModel(
      id: '',
      name: data.name,
    ).toJson(data);
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.customers,
      data: payload,
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return CustomerModel.fromJson(json);
  }

  @override
  Future<CustomerModel> updateCustomer(
      String id, CustomerFormData data) async {
    final payload = CustomerModel(
      id: id,
      name: data.name,
    ).toJson(data);
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.customerById(id),
      data: payload,
    );
    final body = res.data!;
    final json = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return CustomerModel.fromJson(json);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.customerById(id));
  }
}
