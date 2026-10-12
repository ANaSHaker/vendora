import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/receipt_remote_datasource.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final ReceiptRemoteDataSource _remote;
  const ReceiptRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<ReceiptEntity>>> getReceipts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getReceipts(
            status: status,
            search: search,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, ReceiptEntity>> getReceiptById(String id) =>
      _wrap(() => _remote.getReceiptById(id));

  @override
  Future<Either<Failure, ReceiptEntity>> postReceipt(String id) =>
      _wrap(() => _remote.postReceipt(id));

  @override
  Future<Either<Failure, ReceiptEntity>> cancelReceipt(String id) =>
      _wrap(() => _remote.cancelReceipt(id));

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
