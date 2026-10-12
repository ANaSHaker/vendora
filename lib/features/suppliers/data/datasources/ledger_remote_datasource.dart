import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/ledger_entities.dart';
import '../models/ledger_models.dart';

class LedgerPageResult {
  final List<LedgerEntryModel> entries;
  final PaginationMeta meta;
  final LedgerSummary summary;

  const LedgerPageResult({
    required this.entries,
    required this.meta,
    required this.summary,
  });
}

abstract class LedgerRemoteDataSource {
  Future<LedgerPageResult> getLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 50,
  });

  Future<void> recordPayment(String supplierId, Map<String, dynamic> data);

  Future<List<int>> exportLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
  });
}

class LedgerRemoteDataSourceImpl implements LedgerRemoteDataSource {
  final ApiClient _client;

  const LedgerRemoteDataSourceImpl(this._client);

  @override
  Future<void> recordPayment(
    String supplierId,
    Map<String, dynamic> data,
  ) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.supplierPayments(supplierId),
      data: data,
    );
  }

  @override
  Future<LedgerPageResult> getLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 50,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (type != null && type.isNotEmpty) 'type': type,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    // Use supplier-specific endpoint when a supplier is selected
    final endpoint = (supplierId != null && supplierId.isNotEmpty)
        ? ApiEndpoints.supplierLedger(supplierId)
        : ApiEndpoints.suppliersLedger;
    final res = await _client.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: params,
    );
    final body = res.data!;
    final rawData = body['data'] as List<dynamic>? ?? [];
    final rawMeta = body['meta'] as Map<String, dynamic>? ?? {};
    final rawSummary =
        (body['summary'] as Map<String, dynamic>?) ??
        (rawMeta['summary'] as Map<String, dynamic>?) ??
        {};

    final entries = rawData
        .map((e) => LedgerEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = PaginationMeta.fromJson(rawMeta);
    final summary = LedgerSummaryModel.fromJson(rawSummary);

    return LedgerPageResult(entries: entries, meta: meta, summary: summary);
  }

  @override
  Future<List<int>> exportLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
  }) async {
    final params = <String, dynamic>{
      if (supplierId != null && supplierId.isNotEmpty) 'supplier_id': supplierId,
      if (type != null && type.isNotEmpty) 'type': type,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };
    final response = await _client.get<List<int>>(
      ApiEndpoints.exportSuppliersLedgerXls,
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
