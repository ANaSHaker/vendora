import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/inventory_entities.dart';

abstract class InventoryRepository {
  Future<Either<Failure, PaginatedResponse<InventoryBalanceEntity>>> getStock({
    String? search,
    String? branchId,
    String? warehouseId,
    bool? lowStockOnly,
    int page = 1,
    int perPage = 50,
  });

  Future<Either<Failure, PaginatedResponse<InventoryMovementEntity>>>
      getMovements({
    String? search,
    String? warehouseId,
    String? productId,
    String? movementType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, List<WarehouseOptionEntity>>> getWarehouses();

  Future<Either<Failure, List<InventoryBranchOptionEntity>>> getBranches();
}
