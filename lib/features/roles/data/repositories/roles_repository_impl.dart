import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/repositories/roles_repository.dart';
import '../datasources/roles_remote_datasource.dart';

class RolesRepositoryImpl implements RolesRepository {
  final RolesRemoteDataSource _ds;
  const RolesRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<RoleEntity>>> getRoles({String? search}) async {
    try {
      return Right(await _ds.getRoles(search: search));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> createRole(RoleFormData data) async {
    try {
      return Right(await _ds.createRole(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> updateRole(
    String id,
    RoleFormData data,
  ) async {
    try {
      return Right(await _ds.updateRole(id, data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRole(String id) async {
    try {
      await _ds.deleteRole(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoleEntity>> cloneRole(String id) async {
    try {
      return Right(await _ds.cloneRole(id));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PermissionModuleEntity>>>
      getPermissions() async {
    try {
      return Right(await _ds.getPermissions());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
