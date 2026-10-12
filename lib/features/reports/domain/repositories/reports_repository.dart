import '../../../../core/api/api_response.dart';
import '../entities/report_entities.dart';

abstract class ReportsRepository {
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
