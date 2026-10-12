import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/warehouse_entities.dart';
import '../../domain/repositories/warehouse_repository.dart';
import '../datasources/warehouse_remote_datasource.dart';

class WarehouseRepositoryImpl implements WarehouseRepository {
  final WarehouseRemoteDataSource _remote;

  const WarehouseRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<WarehouseEntity>>> getWarehouses({
    String? search,
    String? branchId,
    int page = 1,
    int perPage = 25,
  }) =>
      _wrap(() => _remote.getWarehouses(
            search: search,
            branchId: branchId,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, WarehouseEntity>> createWarehouse(
          WarehouseFormData data) =>
      _wrap(() => _remote.createWarehouse(data));

  @override
  Future<Either<Failure, WarehouseEntity>> updateWarehouse(
          String id, WarehouseFormData data) =>
      _wrap(() => _remote.updateWarehouse(id, data));

  @override
  Future<Either<Failure, void>> deleteWarehouse(String id) =>
      _wrap(() => _remote.deleteWarehouse(id));

  @override
  Future<Either<Failure, void>> setDefaultWarehouse(String id) =>
      _wrap(() => _remote.setDefault(id));

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
