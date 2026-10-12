import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/supplier_entities.dart';
import '../../domain/repositories/suppliers_repository.dart';
import '../datasources/ledger_remote_datasource.dart';
import '../datasources/suppliers_remote_datasource.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  final SuppliersRemoteDataSource _remote;

  const SuppliersRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<SupplierEntity>>> getSuppliers({
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getSuppliers(
            search: search,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, SupplierEntity>> getSupplierById(String id) =>
      _wrap(() => _remote.getSupplierById(id));

  @override
  Future<Either<Failure, SupplierEntity>> createSupplier(
          SupplierFormData data) =>
      _wrap(() => _remote.createSupplier(data));

  @override
  Future<Either<Failure, SupplierEntity>> updateSupplier(
          String id, SupplierFormData data) =>
      _wrap(() => _remote.updateSupplier(id, data));

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) =>
      _wrap(() => _remote.deleteSupplier(id));

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

class LedgerRepositoryImpl implements LedgerRepository {
  final LedgerRemoteDataSource _remote;

  const LedgerRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, LedgerResult>> getLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 50,
  }) =>
      _wrap(() async {
        final result = await _remote.getLedger(
          supplierId: supplierId,
          type: type,
          dateFrom: dateFrom,
          dateTo: dateTo,
          page: page,
          perPage: perPage,
        );
        return LedgerResult(
          entries: result.entries,
          meta: result.meta,
          summary: result.summary,
        );
      });

  @override
  Future<Either<Failure, void>> recordPayment(
    String supplierId,
    Map<String, dynamic> data,
  ) =>
      _wrap(() => _remote.recordPayment(supplierId, data));

  @override
  Future<Either<Failure, List<int>>> exportLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
  }) =>
      _wrap(() => _remote.exportLedger(
            supplierId: supplierId,
            type: type,
            dateFrom: dateFrom,
            dateTo: dateTo,
          ));

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
