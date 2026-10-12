import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/adjustment_entities.dart';
import '../../domain/repositories/adjustment_repository.dart';
import '../datasources/adjustment_remote_datasource.dart';

class AdjustmentRepositoryImpl implements AdjustmentRepository {
  final AdjustmentRemoteDataSource _remote;

  const AdjustmentRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<AdjustmentEntity>>> getAdjustments({
    String? status,
    String? adjustmentType,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getAdjustments(
            status: status,
            adjustmentType: adjustmentType,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, AdjustmentEntity>> getAdjustmentById(String id) =>
      _wrap(() => _remote.getAdjustmentById(id));

  @override
  Future<Either<Failure, AdjustmentEntity>> createAdjustment(
          AdjustmentFormData data) =>
      _wrap(() => _remote.createAdjustment(data));

  @override
  Future<Either<Failure, AdjustmentEntity>> updateAdjustment(
          String id, AdjustmentFormData data) =>
      _wrap(() => _remote.updateAdjustment(id, data));

  @override
  Future<Either<Failure, AdjustmentEntity>> approveAdjustment(String id) =>
      _wrap(() => _remote.approveAdjustment(id));

  @override
  Future<Either<Failure, AdjustmentEntity>> postAdjustment(String id) =>
      _wrap(() => _remote.postAdjustment(id));

  @override
  Future<Either<Failure, AdjustmentEntity>> cancelAdjustment(String id) =>
      _wrap(() => _remote.cancelAdjustment(id));

  @override
  Future<Either<Failure, void>> deleteAdjustment(String id) =>
      _wrap(() => _remote.deleteAdjustment(id));

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
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
