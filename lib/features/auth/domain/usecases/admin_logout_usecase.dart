import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class AdminLogoutUseCase {
  final AuthRepository _repository;
  const AdminLogoutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.adminLogout();
}
