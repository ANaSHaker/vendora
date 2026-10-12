import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/repositories/branches_repository.dart';
import '../datasources/branches_remote_datasource.dart';

class BranchesRepositoryImpl implements BranchesRepository {
  final BranchesRemoteDataSource _ds;
  const BranchesRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<BranchManagementEntity>>> getBranches({
    String? search,
  }) async {
    try {
      return Right(await _ds.getBranches(search: search));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BranchManagementEntity>> createBranch(
    BranchFormData data,
  ) async {
    try {
      return Right(await _ds.createBranch(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BranchManagementEntity>> updateBranch(
    String id,
    BranchFormData data,
  ) async {
    try {
      return Right(await _ds.updateBranch(id, data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBranch(String id) async {
    try {
      await _ds.deleteBranch(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
