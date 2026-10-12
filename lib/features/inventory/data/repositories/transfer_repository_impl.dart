import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/transfer_entities.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../datasources/transfer_remote_datasource.dart';

class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource _remote;

  const TransferRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<TransferEntity>>> getTransfers({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getTransfers(
            status: status,
            search: search,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, TransferEntity>> getTransferById(String id) =>
      _wrap(() => _remote.getTransferById(id));

  @override
  Future<Either<Failure, TransferEntity>> createTransfer(
          TransferFormData data) =>
      _wrap(() => _remote.createTransfer(data));

  @override
  Future<Either<Failure, TransferEntity>> approveTransfer(String id) =>
      _wrap(() => _remote.approveTransfer(id));

  @override
  Future<Either<Failure, TransferEntity>> postTransfer(String id) =>
      _wrap(() => _remote.postTransfer(id));

  @override
  Future<Either<Failure, TransferEntity>> receiveTransfer(String id) =>
      _wrap(() => _remote.receiveTransfer(id));

  @override
  Future<Either<Failure, void>> deleteTransfer(String id) =>
      _wrap(() => _remote.deleteTransfer(id));

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
