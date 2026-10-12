import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class UsersRepository {
  Future<Either<Failure, List<UserEntity>>> getUsers({
    String? search,
    int page = 1,
  });
  Future<Either<Failure, UserEntity>> getUserById(String id);
  Future<Either<Failure, UserEntity>> createUser(UserFormData data);
  Future<Either<Failure, UserEntity>> updateUser(String id, UserFormData data);
  Future<Either<Failure, void>> deleteUser(String id);
}
