import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/cost_layer_entities.dart';
import '../../domain/repositories/cost_layer_repository.dart';
import '../datasources/cost_layer_remote_datasource.dart';

class CostLayerRepositoryImpl implements CostLayerRepository {
  final CostLayerRemoteDataSource _remote;

  const CostLayerRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<CostLayerEntity>>> getCostLayers({
    String? search,
    String? warehouseId,
    String? branchId,
    String? productId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getCostLayers(
            search: search,
            warehouseId: warehouseId,
            branchId: branchId,
            productId: productId,
            dateFrom: dateFrom,
            dateTo: dateTo,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, List<CostLayerConsumptionEntity>>> getConsumptions(
          String layerId) =>
      _wrap(() => _remote.getConsumptions(layerId));

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
