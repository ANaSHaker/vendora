import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/warehouse_entities.dart';

abstract class WarehouseRepository {
  Future<Either<Failure, PaginatedResponse<WarehouseEntity>>> getWarehouses({
    String? search,
    String? branchId,
    int page = 1,
    int perPage = 25,
  });

  Future<Either<Failure, WarehouseEntity>> createWarehouse(
      WarehouseFormData data);

  Future<Either<Failure, WarehouseEntity>> updateWarehouse(
      String id, WarehouseFormData data);

  Future<Either<Failure, void>> deleteWarehouse(String id);

  Future<Either<Failure, void>> setDefaultWarehouse(String id);
}
