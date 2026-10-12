import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../datasources/inventory_remote_datasource.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource _remote;

  const InventoryRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<InventoryBalanceEntity>>> getStock({
    String? search,
    String? branchId,
    String? warehouseId,
    bool? lowStockOnly,
    int page = 1,
    int perPage = 50,
  }) =>
      _wrap(() => _remote.getStock(
            search: search,
            branchId: branchId,
            warehouseId: warehouseId,
            lowStockOnly: lowStockOnly,
            page: page,
            perPage: perPage,
          ));

  @override
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
  }) =>
          _wrap(() => _remote.getMovements(
                search: search,
                warehouseId: warehouseId,
                productId: productId,
                movementType: movementType,
                dateFrom: dateFrom,
                dateTo: dateTo,
                page: page,
                perPage: perPage,
              ));

  @override
  Future<Either<Failure, List<WarehouseOptionEntity>>> getWarehouses() =>
      _wrap(() => _remote.getWarehouses());

  @override
  Future<Either<Failure, List<InventoryBranchOptionEntity>>> getBranches() =>
      _wrap(() => _remote.getBranches());

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) {
        return const Left(UnauthorizedFailure());
      }
      if (error is ForbiddenException) return const Left(ForbiddenFailure());
      if (error is NetworkException) return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(
            ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
