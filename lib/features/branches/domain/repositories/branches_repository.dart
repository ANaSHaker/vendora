import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/branch_entity.dart';

abstract class BranchesRepository {
  Future<Either<Failure, List<BranchManagementEntity>>> getBranches({String? search});
  Future<Either<Failure, BranchManagementEntity>> createBranch(BranchFormData data);
  Future<Either<Failure, BranchManagementEntity>> updateBranch(String id, BranchFormData data);
  Future<Either<Failure, void>> deleteBranch(String id);
}
