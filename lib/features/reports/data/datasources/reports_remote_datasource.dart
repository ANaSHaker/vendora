import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../models/report_models.dart';
import '../../domain/entities/report_entities.dart';

abstract class ReportsRemoteDataSource {
  Future<SalesReportEntity> getSalesReport({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
  });

  Future<PaginatedResponse<SalesOrderRowEntity>> getSalesOrders({
    required int page,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
    int perPage,
  });

  Future<InventoryTabReport> getInventoryTabReport({
    String? branchId,
    String? warehouseId,
    String? productId,
    String? movementType,
    DateTime? dateFrom,
    DateTime? dateTo,
  });

  Future<FinancialReportEntity> getFinancialReport({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? warehouseId,
    String? productId,
  });

  Future<List<int>> exportBytes(String endpoint, Map<String, dynamic> params);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final ApiClient _client;
  static final _dateFmt = DateFormat('yyyy-MM-dd', 'en_US');

  const ReportsRemoteDataSourceImpl(this._client);

  Map<String, dynamic> _dateParams(
    DateTime from,
    DateTime to, {
    String? branchId,
    String? paymentMethod,
    String? warehouseId,
    String? productId,
  }) =>
      {
        'date_from': _dateFmt.format(from),
        'date_to': _dateFmt.format(to),
        if (branchId != null) 'branch_id': branchId,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (warehouseId != null) 'warehouse_id': warehouseId,
        if (productId != null) 'product_id': productId,
      };

  dynamic _unwrap(Map<String, dynamic> body) {
    if (body.containsKey('data')) return body['data'];
    return body;
  }

  List<dynamic> _unwrapList(dynamic body, List<String> listKeys) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      for (final key in listKeys) {
        if (body[key] is List) return body[key] as List;
      }
    }
    return [];
  }

  @override
  Future<SalesReportEntity> getSalesReport({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
  }) async {
    final params = _dateParams(dateFrom, dateTo, branchId: branchId, paymentMethod: paymentMethod);

    final summaryFuture = _client.get<Map<String, dynamic>>(
      ApiEndpoints.reportsSummary,
      queryParameters: params,
    );
    final productsFuture = _client.get<Map<String, dynamic>>(
      ApiEndpoints.reportsProducts,
      queryParameters: params,
    );

    final results = await Future.wait([summaryFuture, productsFuture]);

    final summaryRaw = _unwrap(results[0].data!);
    debugPrint('[SalesReport/summary] keys: ${summaryRaw is Map ? summaryRaw.keys.toList() : summaryRaw.runtimeType}');
    // The summary may be nested inside a "summary" key or at the top level
    final summaryMap = summaryRaw is Map<String, dynamic>
        ? (summaryRaw['summary'] as Map<String, dynamic>? ??
           summaryRaw['data']  as Map<String, dynamic>? ??
           summaryRaw)
        : <String, dynamic>{};
    final summary = SalesReportSummaryModel.fromJson(summaryMap);

    final salesByDayRaw = _unwrapList(
      summaryRaw,
      ['sales_per_day', 'sales_by_day', 'daily_sales'],
    );
    final salesByDay = salesByDayRaw
        .map((e) => SalesByDayModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final productsRaw = _unwrapList(results[1].data!, ['data', 'products', 'items']);
    final topProducts = productsRaw
        .map((e) => TopSellingProductModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return SalesReportModel(
      summary: summary,
      salesByDay: salesByDay,
      topProducts: topProducts,
    );
  }

  @override
  Future<PaginatedResponse<SalesOrderRowEntity>> getSalesOrders({
    required int page,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
    int perPage = 15,
  }) async {
    final params = {
      ..._dateParams(dateFrom, dateTo, branchId: branchId, paymentMethod: paymentMethod),
      'page': page,
      'per_page': perPage,
    };
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.reportsSales,
      queryParameters: params,
    );
    return PaginatedResponse.fromJson(
      response.data!,
      (json) => SalesOrderRowModel.fromJson(json),
    );
  }

  @override
  Future<InventoryTabReport> getInventoryTabReport({
    String? branchId,
    String? warehouseId,
    String? productId,
    String? movementType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final baseParams = <String, dynamic>{
      if (branchId != null) 'branch_id': branchId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (productId != null) 'product_id': productId,
      if (dateFrom != null) 'date_from': _dateFmt.format(dateFrom),
      if (dateTo != null) 'date_to': _dateFmt.format(dateTo),
    };

    final movParams = <String, dynamic>{
      ...baseParams,
      if (movementType != null) 'type': movementType,
    };

    final results = await Future.wait([
      _client.get<Map<String, dynamic>>(ApiEndpoints.reportsFinancialInventory, queryParameters: baseParams),
      _client.get<Map<String, dynamic>>(ApiEndpoints.inventoryMovements, queryParameters: movParams),
      _client.get<Map<String, dynamic>>(ApiEndpoints.transfers, queryParameters: baseParams),
      _client.get<Map<String, dynamic>>(ApiEndpoints.stockCounts, queryParameters: baseParams),
    ]);

    final stockRaw = _unwrapList(results[0].data!, ['data', 'items', 'stock']);
    final stock = stockRaw
        .map((e) => StockByWarehouseModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalStockValue = stock.fold<double>(0.0, (s, i) => s + i.totalValue);

    final movRaw = _unwrapList(results[1].data!, ['data', 'movements', 'items']);
    final movements = movRaw
        .map((e) => MovementModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final transfersRaw = _unwrapList(results[2].data!, ['data', 'transfers', 'items']);
    final transfers = transfersRaw
        .map((e) => TransferRowModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final countsRaw = _unwrapList(results[3].data!, ['data', 'counts', 'items']);
    final stockCounts = countsRaw
        .map((e) => StockCountRowModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return InventoryTabReport(
      stock: stock,
      totalStockValue: totalStockValue,
      movements: movements,
      transfers: transfers,
      stockCounts: stockCounts,
    );
  }

  @override
  Future<FinancialReportEntity> getFinancialReport({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? warehouseId,
    String? productId,
  }) async {
    final params = _dateParams(
      dateFrom,
      dateTo,
      branchId: branchId,
      warehouseId: warehouseId,
      productId: productId,
    );

    final results = await Future.wait([
      _client.get<Map<String, dynamic>>(ApiEndpoints.reportsFinancialSummary, queryParameters: params),
      _client.get<Map<String, dynamic>>(ApiEndpoints.reportsFinancialPnl, queryParameters: params),
      _client.get<Map<String, dynamic>>(ApiEndpoints.reportsFinancialFifo, queryParameters: params),
      _client.get<Map<String, dynamic>>(ApiEndpoints.reportsFinancialSales, queryParameters: params),
      _client.get<Map<String, dynamic>>(ApiEndpoints.reportsFinancialInventory, queryParameters: params),
    ]);

    final summaryRaw = _unwrap(results[0].data!);
    final summary = FinancialSummaryModel.fromJson(
      summaryRaw is Map<String, dynamic> ? summaryRaw : <String, dynamic>{},
    );

    // The P&L endpoint may return a flat object {revenue, cost_of_goods_sold, ...}
    // instead of an array — detect and convert either way.
    final pnlBody = results[1].data!;
    final pnlListRaw = _unwrapList(pnlBody, ['rows', 'items', 'data']);
    final List<PnlRowEntity> pnlRows;
    if (pnlListRaw.isNotEmpty) {
      pnlRows = pnlListRaw
          .map((e) => PnlRowModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final flatObj = pnlBody.containsKey('data') &&
              pnlBody['data'] is Map<String, dynamic>
          ? pnlBody['data'] as Map<String, dynamic>
          : pnlBody;
      pnlRows = PnlRowModel.fromPnlObject(flatObj);
    }

    final fifoRaw = _unwrapList(results[2].data!, ['products', 'items', 'data']);
    final fifoRows = fifoRaw
        .map((e) => FifoProfitRowModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final salesRaw = _unwrapList(results[3].data!, ['data', 'items', 'rows']);
    final salesRows = salesRaw
        .map((e) => FinancialSalesRowModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final invRaw = _unwrapList(results[4].data!, ['data', 'items', 'stock']);
    final inventoryRows = invRaw
        .map((e) => FinancialInventoryRowModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return FinancialReportModel(
      summary: summary,
      pnlRows: pnlRows,
      fifoRows: fifoRows,
      salesRows: salesRows,
      inventoryRows: inventoryRows,
    );
  }

  @override
  Future<List<int>> exportBytes(String endpoint, Map<String, dynamic> params) async {
    final response = await _client.get<List<int>>(
      endpoint,
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? [];
  }
}
