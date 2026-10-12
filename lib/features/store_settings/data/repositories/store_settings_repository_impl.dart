import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/store_settings_entity.dart';
import '../../domain/repositories/store_settings_repository.dart';
import '../datasources/store_settings_remote_datasource.dart';

class StoreSettingsRepositoryImpl implements StoreSettingsRepository {
  final StoreSettingsRemoteDataSource _remote;
  const StoreSettingsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, StoreSettingsEntity>> getStoreSettings() =>
      _wrap(() => _remote.getStoreSettings());

  @override
  Future<Either<Failure, StoreSettingsEntity>> updateStoreSettings(
          Map<String, dynamic> data) =>
      _wrap(() => _remote.updateStoreSettings(data));

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) return const Left(UnauthorizedFailure());
      if (error is ForbiddenException) return const Left(ForbiddenFailure());
      if (error is NetworkException) return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
