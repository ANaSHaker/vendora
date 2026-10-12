import '../../../../core/api/api_response.dart';
import '../../domain/entities/report_entities.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource _ds;
  const ReportsRepositoryImpl(this._ds);

  @override
  Future<SalesReportEntity> getSalesReport({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
  }) =>
      _ds.getSalesReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
        paymentMethod: paymentMethod,
      );

  @override
  Future<PaginatedResponse<SalesOrderRowEntity>> getSalesOrders({
    required int page,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
    int perPage = 15,
  }) =>
      _ds.getSalesOrders(
        page: page,
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
        paymentMethod: paymentMethod,
        perPage: perPage,
      );

  @override
  Future<InventoryTabReport> getInventoryTabReport({
    String? branchId,
    String? warehouseId,
    String? productId,
    String? movementType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _ds.getInventoryTabReport(
        branchId: branchId,
        warehouseId: warehouseId,
        productId: productId,
        movementType: movementType,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );

  @override
  Future<FinancialReportEntity> getFinancialReport({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? warehouseId,
    String? productId,
  }) =>
      _ds.getFinancialReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
        warehouseId: warehouseId,
        productId: productId,
      );

  @override
  Future<List<int>> exportBytes(String endpoint, Map<String, dynamic> params) =>
      _ds.exportBytes(endpoint, params);
}
