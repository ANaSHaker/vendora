import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import 'login_usecase.dart';

class AdminLoginUseCase {
  final AuthRepository _repository;
  const AdminLoginUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(LoginParams params) =>
      _repository.adminLogin(email: params.email, password: params.password);
}
