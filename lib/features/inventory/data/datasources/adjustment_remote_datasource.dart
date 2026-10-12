import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/adjustment_entities.dart';
import '../models/adjustment_models.dart';

abstract class AdjustmentRemoteDataSource {
  Future<PaginatedResponse<AdjustmentModel>> getAdjustments({
    String? status,
    String? adjustmentType,
    int page = 1,
    int perPage = 20,
  });

  Future<AdjustmentModel> getAdjustmentById(String id);
  Future<AdjustmentModel> createAdjustment(AdjustmentFormData data);
  Future<AdjustmentModel> updateAdjustment(String id, AdjustmentFormData data);
  Future<AdjustmentModel> approveAdjustment(String id);
  Future<AdjustmentModel> postAdjustment(String id);
  Future<AdjustmentModel> cancelAdjustment(String id);
  Future<void> deleteAdjustment(String id);
}

class AdjustmentRemoteDataSourceImpl implements AdjustmentRemoteDataSource {
  final ApiClient _client;

  const AdjustmentRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<AdjustmentModel>> getAdjustments({
    String? status,
    String? adjustmentType,
    int page = 1,
    int perPage = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (status != null && status.isNotEmpty) 'status': status,
      if (adjustmentType != null && adjustmentType.isNotEmpty)
        'adjustment_type': adjustmentType,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adjustments,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(res.data!, AdjustmentModel.fromJson);
  }

  @override
  Future<AdjustmentModel> getAdjustmentById(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.adjustmentById(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return AdjustmentModel.fromJson(json);
  }

  @override
  Future<AdjustmentModel> createAdjustment(AdjustmentFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.adjustments,
      data: AdjustmentModel.buildPayload(data),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return AdjustmentModel.fromJson(json);
  }

  @override
  Future<AdjustmentModel> updateAdjustment(
      String id, AdjustmentFormData data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.adjustmentById(id),
      data: AdjustmentModel.buildPayload(data),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return AdjustmentModel.fromJson(json);
  }

  @override
  Future<AdjustmentModel> approveAdjustment(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.approveAdjustment(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return AdjustmentModel.fromJson(json);
  }

  @override
  Future<AdjustmentModel> postAdjustment(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.postAdjustment(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return AdjustmentModel.fromJson(json);
  }

  @override
  Future<AdjustmentModel> cancelAdjustment(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.cancelAdjustment(id),
    );
    final body = res.data!;
    final json =
        body.containsKey('data') ? body['data'] as Map<String, dynamic> : body;
    return AdjustmentModel.fromJson(json);
  }

  @override
  Future<void> deleteAdjustment(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.adjustmentById(id));
  }
}
