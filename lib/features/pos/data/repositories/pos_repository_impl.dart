import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pos_entities.dart';
import '../../domain/repositories/pos_repository.dart';
import '../datasources/pos_remote_datasource.dart';

class PosRepositoryImpl implements PosRepository {
  final PosRemoteDataSource _remote;

  const PosRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<BranchEntity>>> getBranches() =>
      _wrap(() => _remote.getBranches());

  @override
  Future<Either<Failure, List<WarehouseEntity>>> getWarehouses({
    String? branchId,
  }) =>
      _wrap(() => _remote.getWarehouses(branchId: branchId));

  @override
  Future<Either<Failure, List<PosProductEntity>>> getProducts({
    String? categoryId,
    String? search,
    String? warehouseId,
    int perPage = 200,
  }) =>
      _wrap(() => _remote.getProducts(
            categoryId: categoryId,
            search: search,
            warehouseId: warehouseId,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, List<PosCategoryEntity>>> getCategories() =>
      _wrap(() => _remote.getCategories());

  @override
  Future<Either<Failure, List<PosCustomerEntity>>> searchCustomers({
    required String query,
  }) =>
      _wrap(() => _remote.searchCustomers(query: query));

  @override
  Future<Either<Failure, PosCustomerEntity>> createCustomer({
    required String name,
    String? phone,
  }) =>
      _wrap(() => _remote.createCustomer(name: name, phone: phone));

  @override
  Future<Either<Failure, PosOrderEntity>> createOrder({
    required String branchId,
    String? warehouseId,
    String? customerId,
    required List<({String productId, double quantity, double discount})> items,
    double orderDiscount = 0,
    double taxRate = 15,
    String note = '',
    required String paymentMethod,
    required double paymentAmount,
  }) =>
      _wrap(() => _remote.createOrder({
            'branch_id': branchId,
            if (warehouseId != null && warehouseId.isNotEmpty)
              'warehouse_id': warehouseId,
            if (customerId != null) 'customer_id': customerId,
            if (orderDiscount > 0) 'discount': orderDiscount,
            if (note.isNotEmpty) 'note': note,
            'items': items
                .map((item) => {
                      'product_id': item.productId,
                      'quantity': item.quantity,
                      if (item.discount > 0) 'discount': item.discount,
                    })
                .toList(),
            'payments': [
              {'method': paymentMethod, 'amount': paymentAmount},
            ],
          }));

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) return const Left(UnauthorizedFailure());
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
