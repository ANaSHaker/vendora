import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/branch_entity.dart';
import '../repositories/branches_repository.dart';

class GetManagedBranchesUseCase {
  final BranchesRepository _repo;
  const GetManagedBranchesUseCase(this._repo);
  Future<Either<Failure, List<BranchManagementEntity>>> call({String? search}) =>
      _repo.getBranches(search: search);
}

class CreateBranchUseCase {
  final BranchesRepository _repo;
  const CreateBranchUseCase(this._repo);
  Future<Either<Failure, BranchManagementEntity>> call(BranchFormData data) =>
      _repo.createBranch(data);
}

class UpdateBranchUseCase {
  final BranchesRepository _repo;
  const UpdateBranchUseCase(this._repo);
  Future<Either<Failure, BranchManagementEntity>> call(String id, BranchFormData data) =>
      _repo.updateBranch(id, data);
}

class DeleteBranchUseCase {
  final BranchesRepository _repo;
  const DeleteBranchUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.deleteBranch(id);
}
