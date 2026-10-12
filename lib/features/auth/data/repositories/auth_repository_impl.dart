import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  const AuthRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) =>
      _withMapping(() => _remote.login(email: email, password: password));

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Logout always succeeds locally even if the API call fails
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() =>
      _withMapping(() => _remote.getCurrentUser());

  @override
  Future<Either<Failure, UserEntity>> adminLogin({
    required String email,
    required String password,
  }) =>
      _withMapping(
        () => _remote.adminLogin(email: email, password: password),
      );

  @override
  Future<Either<Failure, void>> adminLogout() async {
    try {
      await _remote.adminLogout();
    } catch (_) {
      // Logout always succeeds locally even if the API call fails
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity>> adminGetCurrentUser() =>
      _withMapping(() => _remote.adminGetCurrentUser());

  Future<Either<Failure, T>> _withMapping<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is UseAdminLoginException) {
        return const Left(UseAdminLoginFailure());
      }
      if (error is UnauthorizedException) {
        return const Left(UnauthorizedFailure('Invalid email or password'));
      }
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is ForbiddenException) {
        return const Left(ForbiddenFailure());
      }
      if (error is NetworkException) {
        return Left(NetworkFailure(error.message));
      }
      if (error is ServerException) {
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
