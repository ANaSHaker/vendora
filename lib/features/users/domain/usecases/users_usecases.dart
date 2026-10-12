import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/users_repository.dart';

class GetUsersUseCase {
  final UsersRepository _repo;
  const GetUsersUseCase(this._repo);

  Future<Either<Failure, List<UserEntity>>> call({
    String? search,
    int page = 1,
  }) =>
      _repo.getUsers(search: search, page: page);
}

class GetUserByIdUseCase {
  final UsersRepository _repo;
  const GetUserByIdUseCase(this._repo);

  Future<Either<Failure, UserEntity>> call(String id) =>
      _repo.getUserById(id);
}

class CreateUserUseCase {
  final UsersRepository _repo;
  const CreateUserUseCase(this._repo);

  Future<Either<Failure, UserEntity>> call(UserFormData data) =>
      _repo.createUser(data);
}

class UpdateUserUseCase {
  final UsersRepository _repo;
  const UpdateUserUseCase(this._repo);

  Future<Either<Failure, UserEntity>> call(String id, UserFormData data) =>
      _repo.updateUser(id, data);
}

class DeleteUserUseCase {
  final UsersRepository _repo;
  const DeleteUserUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteUser(id);
}
