import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetAdminCurrentUserUseCase {
  final AuthRepository _repository;
  const GetAdminCurrentUserUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call() => _repository.adminGetCurrentUser();
}
