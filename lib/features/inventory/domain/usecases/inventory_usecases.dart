import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/inventory_entities.dart';
import '../repositories/inventory_repository.dart';

class GetInventoryStockUseCase {
  final InventoryRepository _repo;
  const GetInventoryStockUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<InventoryBalanceEntity>>> call({
    String? search,
    String? branchId,
    String? warehouseId,
    bool? lowStockOnly,
    int page = 1,
    int perPage = 50,
  }) =>
      _repo.getStock(
        search: search,
        branchId: branchId,
        warehouseId: warehouseId,
        lowStockOnly: lowStockOnly,
        page: page,
        perPage: perPage,
      );
}

class GetInventoryMovementsUseCase {
  final InventoryRepository _repo;
  const GetInventoryMovementsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<InventoryMovementEntity>>> call({
    String? search,
    String? warehouseId,
    String? productId,
    String? movementType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getMovements(
        search: search,
        warehouseId: warehouseId,
        productId: productId,
        movementType: movementType,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        perPage: perPage,
      );
}

class GetInventoryWarehouseOptionsUseCase {
  final InventoryRepository _repo;
  const GetInventoryWarehouseOptionsUseCase(this._repo);

  Future<Either<Failure, List<WarehouseOptionEntity>>> call() =>
      _repo.getWarehouses();
}

class GetInventoryBranchOptionsUseCase {
  final InventoryRepository _repo;
  const GetInventoryBranchOptionsUseCase(this._repo);

  Future<Either<Failure, List<InventoryBranchOptionEntity>>> call() =>
      _repo.getBranches();
}
