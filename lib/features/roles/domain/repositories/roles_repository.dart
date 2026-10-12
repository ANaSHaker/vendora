import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/role_entity.dart';

abstract class RolesRepository {
  Future<Either<Failure, List<RoleEntity>>> getRoles({String? search});
  Future<Either<Failure, RoleEntity>> createRole(RoleFormData data);
  Future<Either<Failure, RoleEntity>> updateRole(String id, RoleFormData data);
  Future<Either<Failure, void>> deleteRole(String id);
  Future<Either<Failure, RoleEntity>> cloneRole(String id);
  Future<Either<Failure, List<PermissionModuleEntity>>> getPermissions();
}
