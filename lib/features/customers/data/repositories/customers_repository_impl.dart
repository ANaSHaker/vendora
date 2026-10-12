import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/customer_entities.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_datasource.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource _remote;

  const CustomersRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<CustomerEntity>>> getCustomers({
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _wrap(() => _remote.getCustomers(
            search: search,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, CustomerEntity>> getCustomerById(String id) =>
      _wrap(() => _remote.getCustomerById(id));

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer(
          CustomerFormData data) =>
      _wrap(() => _remote.createCustomer(data));

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(
          String id, CustomerFormData data) =>
      _wrap(() => _remote.updateCustomer(id, data));

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) =>
      _wrap(() => _remote.deleteCustomer(id));

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
