import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/aging_entities.dart';
import '../models/aging_models.dart';

abstract class AgingRemoteDataSource {
  Future<List<AgingRowEntity>> getAging({String? supplierId, String? asOf});
  Future<List<int>> exportAging({String? supplierId, String? asOf});
}

class AgingRemoteDataSourceImpl implements AgingRemoteDataSource {
  final ApiClient _client;
  const AgingRemoteDataSourceImpl(this._client);

  @override
  Future<List<AgingRowEntity>> getAging({
    String? supplierId,
    String? asOf,
  }) async {
    final params = <String, dynamic>{
      if (supplierId != null && supplierId.isNotEmpty) 'supplier_id': supplierId,
      if (asOf != null && asOf.isNotEmpty) 'as_of': asOf,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.suppliersAging,
      queryParameters: params,
    );
    final body = res.data!;
    final rawData = (body['data'] as List<dynamic>?) ?? [];
    return rawData
        .map((e) => AgingRowModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<int>> exportAging({
    String? supplierId,
    String? asOf,
  }) async {
    final params = <String, dynamic>{
      if (supplierId != null && supplierId.isNotEmpty) 'supplier_id': supplierId,
      if (asOf != null && asOf.isNotEmpty) 'as_of': asOf,
    };
    final response = await _client.get<List<int>>(
      ApiEndpoints.exportSuppliersAgingXls,
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
