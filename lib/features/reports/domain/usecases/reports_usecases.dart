import '../../../../core/api/api_response.dart';
import '../entities/report_entities.dart';
import '../repositories/reports_repository.dart';

class GetSalesReportUseCase {
  final ReportsRepository _repo;
  const GetSalesReportUseCase(this._repo);

  Future<SalesReportEntity> call({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
  }) =>
      _repo.getSalesReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
        paymentMethod: paymentMethod,
      );
}

class GetSalesOrdersUseCase {
  final ReportsRepository _repo;
  const GetSalesOrdersUseCase(this._repo);

  Future<PaginatedResponse<SalesOrderRowEntity>> call({
    required int page,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? paymentMethod,
    int perPage = 15,
  }) =>
      _repo.getSalesOrders(
        page: page,
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
        paymentMethod: paymentMethod,
        perPage: perPage,
      );
}

class GetInventoryTabReportUseCase {
  final ReportsRepository _repo;
  const GetInventoryTabReportUseCase(this._repo);

  Future<InventoryTabReport> call({
    String? branchId,
    String? warehouseId,
    String? productId,
    String? movementType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) =>
      _repo.getInventoryTabReport(
        branchId: branchId,
        warehouseId: warehouseId,
        productId: productId,
        movementType: movementType,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
}

class GetFinancialReportUseCase {
  final ReportsRepository _repo;
  const GetFinancialReportUseCase(this._repo);

  Future<FinancialReportEntity> call({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
    String? warehouseId,
    String? productId,
  }) =>
      _repo.getFinancialReport(
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
        warehouseId: warehouseId,
        productId: productId,
      );
}

class ExportReportUseCase {
  final ReportsRepository _repo;
  const ExportReportUseCase(this._repo);

  Future<List<int>> call(String endpoint, Map<String, dynamic> params) =>
      _repo.exportBytes(endpoint, params);
}
