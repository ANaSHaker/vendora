import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/pos_entities.dart';

abstract class PosRepository {
  Future<Either<Failure, List<BranchEntity>>> getBranches();

  Future<Either<Failure, List<WarehouseEntity>>> getWarehouses({
    String? branchId,
  });

  Future<Either<Failure, List<PosProductEntity>>> getProducts({
    String? categoryId,
    String? search,
    String? warehouseId,
    int perPage = 200,
  });

  Future<Either<Failure, List<PosCategoryEntity>>> getCategories();

  Future<Either<Failure, List<PosCustomerEntity>>> searchCustomers({
    required String query,
  });

  Future<Either<Failure, PosCustomerEntity>> createCustomer({
    required String name,
    String? phone,
  });

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
  });
}
