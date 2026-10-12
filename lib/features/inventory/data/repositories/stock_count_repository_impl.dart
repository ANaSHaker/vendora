import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/stock_count_entities.dart';
import '../../domain/repositories/stock_count_repository.dart';
import '../datasources/stock_count_remote_datasource.dart';

class StockCountRepositoryImpl implements StockCountRepository {
  final StockCountRemoteDataSource _remote;

  const StockCountRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<StockCountEntity>>> getStockCounts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getStockCounts(
            status: status,
            search: search,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, StockCountEntity>> getStockCountById(String id) =>
      _wrap(() => _remote.getStockCountById(id));

  @override
  Future<Either<Failure, StockCountEntity>> createStockCount(
          StockCountFormData data) =>
      _wrap(() => _remote.createStockCount(data));

  @override
  Future<Either<Failure, StockCountEntity>> postStockCount(String id) =>
      _wrap(() => _remote.postStockCount(id));

  @override
  Future<Either<Failure, void>> deleteStockCount(String id) =>
      _wrap(() => _remote.deleteStockCount(id));

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
