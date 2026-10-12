import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/transfer_entities.dart';
import '../models/transfer_models.dart';

abstract class TransferRemoteDataSource {
  Future<PaginatedResponse<TransferModel>> getTransfers({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<TransferModel> getTransferById(String id);
  Future<TransferModel> createTransfer(TransferFormData data);
  Future<TransferModel> approveTransfer(String id);
  Future<TransferModel> postTransfer(String id);
  Future<TransferModel> receiveTransfer(String id);
  Future<void> deleteTransfer(String id);
}

class TransferRemoteDataSourceImpl implements TransferRemoteDataSource {
  final ApiClient _client;

  const TransferRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<TransferModel>> getTransfers({
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
      ApiEndpoints.transfers,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, TransferModel.fromJson);
  }

  @override
  Future<TransferModel> getTransferById(String id) async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.transferById(id));
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return TransferModel.fromJson(json);
  }

  @override
  Future<TransferModel> createTransfer(TransferFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.transfers,
      data: TransferModel.buildPayload(data),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return TransferModel.fromJson(json);
  }

  @override
  Future<TransferModel> approveTransfer(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.approveTransfer(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return TransferModel.fromJson(json);
  }

  @override
  Future<TransferModel> postTransfer(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.postTransfer(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return TransferModel.fromJson(json);
  }

  @override
  Future<TransferModel> receiveTransfer(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.receiveTransfer(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return TransferModel.fromJson(json);
  }

  @override
  Future<void> deleteTransfer(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.transferById(id));
  }
}
