import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../models/receipt_model.dart';

abstract class ReceiptRemoteDataSource {
  Future<PaginatedResponse<ReceiptModel>> getReceipts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<ReceiptModel> getReceiptById(String id);
  Future<ReceiptModel> postReceipt(String id);
  Future<ReceiptModel> cancelReceipt(String id);
}

class ReceiptRemoteDataSourceImpl implements ReceiptRemoteDataSource {
  final ApiClient _client;
  const ReceiptRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<ReceiptModel>> getReceipts({
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
      ApiEndpoints.receipts,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, ReceiptModel.fromJson);
  }

  @override
  Future<ReceiptModel> getReceiptById(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.receiptById(id));
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return ReceiptModel.fromJson(json);
  }

  @override
  Future<ReceiptModel> postReceipt(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.postReceipt(id), data: {});
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return ReceiptModel.fromJson(json);
  }

  @override
  Future<ReceiptModel> cancelReceipt(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.cancelReceipt(id), data: {});
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return ReceiptModel.fromJson(json);
  }
}
