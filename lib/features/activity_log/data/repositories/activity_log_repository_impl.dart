import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../../domain/repositories/activity_log_repository.dart';
import '../datasources/activity_log_remote_datasource.dart';

class ActivityLogRepositoryImpl implements ActivityLogRepository {
  final ActivityLogRemoteDataSource _remote;

  const ActivityLogRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<ActivityLogEntry>>> getActivityLog(
    ActivityLogFilters filters,
  ) =>
      _wrap(() => _remote.getActivityLog(filters));

  @override
  Future<Either<Failure, List<ActivityLogUser>>> getUsers() =>
      _wrap(() => _remote.getUsers());

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) {
        return const Left(UnauthorizedFailure());
      }
      if (error is ForbiddenException) return const Left(ForbiddenFailure());
      if (error is NetworkException) return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(
            ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
