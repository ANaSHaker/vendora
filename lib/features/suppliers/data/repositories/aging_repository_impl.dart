import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/aging_entities.dart';
import '../../domain/repositories/suppliers_repository.dart';
import '../datasources/aging_remote_datasource.dart';

class AgingRepositoryImpl implements AgingRepository {
  final AgingRemoteDataSource _remote;
  const AgingRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<AgingRowEntity>>> getAging({
    String? supplierId,
    String? asOf,
  }) =>
      _wrap(() => _remote.getAging(supplierId: supplierId, asOf: asOf));

  @override
  Future<Either<Failure, List<int>>> exportAging({
    String? supplierId,
    String? asOf,
  }) =>
      _wrap(() => _remote.exportAging(supplierId: supplierId, asOf: asOf));

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) return const Left(UnauthorizedFailure());
      if (error is ForbiddenException)    return const Left(ForbiddenFailure());
      if (error is NetworkException)      return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
