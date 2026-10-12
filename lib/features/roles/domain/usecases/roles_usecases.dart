import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/role_entity.dart';
import '../repositories/roles_repository.dart';

class GetRolesUseCase {
  final RolesRepository _repo;
  const GetRolesUseCase(this._repo);

  Future<Either<Failure, List<RoleEntity>>> call({String? search}) =>
      _repo.getRoles(search: search);
}

class CreateRoleUseCase {
  final RolesRepository _repo;
  const CreateRoleUseCase(this._repo);

  Future<Either<Failure, RoleEntity>> call(RoleFormData data) =>
      _repo.createRole(data);
}

class UpdateRoleUseCase {
  final RolesRepository _repo;
  const UpdateRoleUseCase(this._repo);

  Future<Either<Failure, RoleEntity>> call(String id, RoleFormData data) =>
      _repo.updateRole(id, data);
}

class DeleteRoleUseCase {
  final RolesRepository _repo;
  const DeleteRoleUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteRole(id);
}

class CloneRoleUseCase {
  final RolesRepository _repo;
  const CloneRoleUseCase(this._repo);

  Future<Either<Failure, RoleEntity>> call(String id) =>
      _repo.cloneRole(id);
}

class GetPermissionsUseCase {
  final RolesRepository _repo;
  const GetPermissionsUseCase(this._repo);

  Future<Either<Failure, List<PermissionModuleEntity>>> call() =>
      _repo.getPermissions();
}
