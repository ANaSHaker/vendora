import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/supplier_entities.dart';
import '../repositories/suppliers_repository.dart';

class GetSuppliersUseCase {
  final SuppliersRepository _repo;
  const GetSuppliersUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<SupplierEntity>>> call({
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getSuppliers(search: search, page: page, perPage: perPage);
}

class GetSupplierByIdUseCase {
  final SuppliersRepository _repo;
  const GetSupplierByIdUseCase(this._repo);

  Future<Either<Failure, SupplierEntity>> call(String id) =>
      _repo.getSupplierById(id);
}

class CreateSupplierUseCase {
  final SuppliersRepository _repo;
  const CreateSupplierUseCase(this._repo);

  Future<Either<Failure, SupplierEntity>> call(SupplierFormData data) =>
      _repo.createSupplier(data);
}

class UpdateSupplierUseCase {
  final SuppliersRepository _repo;
  const UpdateSupplierUseCase(this._repo);

  Future<Either<Failure, SupplierEntity>> call(
          String id, SupplierFormData data) =>
      _repo.updateSupplier(id, data);
}

class DeleteSupplierUseCase {
  final SuppliersRepository _repo;
  const DeleteSupplierUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteSupplier(id);
}
