import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/warehouse_entities.dart';
import '../repositories/warehouse_repository.dart';

class GetManagedWarehousesUseCase {
  final WarehouseRepository _repo;
  const GetManagedWarehousesUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<WarehouseEntity>>> call({
    String? search,
    String? branchId,
    int page = 1,
    int perPage = 25,
  }) =>
      _repo.getWarehouses(
          search: search, branchId: branchId, page: page, perPage: perPage);
}

class CreateWarehouseUseCase {
  final WarehouseRepository _repo;
  const CreateWarehouseUseCase(this._repo);

  Future<Either<Failure, WarehouseEntity>> call(WarehouseFormData data) =>
      _repo.createWarehouse(data);
}

class UpdateWarehouseUseCase {
  final WarehouseRepository _repo;
  const UpdateWarehouseUseCase(this._repo);

  Future<Either<Failure, WarehouseEntity>> call(
          String id, WarehouseFormData data) =>
      _repo.updateWarehouse(id, data);
}

class DeleteWarehouseUseCase {
  final WarehouseRepository _repo;
  const DeleteWarehouseUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteWarehouse(id);
}

class SetDefaultWarehouseUseCase {
  final WarehouseRepository _repo;
  const SetDefaultWarehouseUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) =>
      _repo.setDefaultWarehouse(id);
}
