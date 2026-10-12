import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/pos_entities.dart';
import '../repositories/pos_repository.dart';

class GetBranchesUseCase {
  final PosRepository _repo;
  const GetBranchesUseCase(this._repo);
  Future<Either<Failure, List<BranchEntity>>> call() => _repo.getBranches();
}

class GetWarehousesUseCase {
  final PosRepository _repo;
  const GetWarehousesUseCase(this._repo);
  Future<Either<Failure, List<WarehouseEntity>>> call({String? branchId}) =>
      _repo.getWarehouses(branchId: branchId);
}

class GetPosProductsUseCase {
  final PosRepository _repo;
  const GetPosProductsUseCase(this._repo);
  Future<Either<Failure, List<PosProductEntity>>> call({
    String? categoryId,
    String? search,
    String? warehouseId,
    int perPage = 200,
  }) =>
      _repo.getProducts(
        categoryId: categoryId,
        search: search,
        warehouseId: warehouseId,
        perPage: perPage,
      );
}

class GetPosCategoriesUseCase {
  final PosRepository _repo;
  const GetPosCategoriesUseCase(this._repo);
  Future<Either<Failure, List<PosCategoryEntity>>> call() =>
      _repo.getCategories();
}

class SearchPosCustomersUseCase {
  final PosRepository _repo;
  const SearchPosCustomersUseCase(this._repo);
  Future<Either<Failure, List<PosCustomerEntity>>> call(String query) =>
      _repo.searchCustomers(query: query);
}

class CreatePosCustomerUseCase {
  final PosRepository _repo;
  const CreatePosCustomerUseCase(this._repo);

  Future<Either<Failure, PosCustomerEntity>> call({
    required String name,
    String? phone,
  }) =>
      _repo.createCustomer(name: name, phone: phone);
}

class CreateOrderParams extends Equatable {
  final String branchId;
  final String? warehouseId;
  final String? customerId;
  final List<({String productId, double quantity, double discount})> items;
  final double orderDiscount;
  final double taxRate;
  final String note;
  final String paymentMethod;
  final double paymentAmount;

  const CreateOrderParams({
    required this.branchId,
    this.warehouseId,
    this.customerId,
    required this.items,
    this.orderDiscount = 0,
    this.taxRate = 15,
    this.note = '',
    required this.paymentMethod,
    required this.paymentAmount,
  });

  @override
  List<Object?> get props => [
        branchId,
        warehouseId,
        customerId,
        items,
        orderDiscount,
        taxRate,
        note,
        paymentMethod,
        paymentAmount,
      ];
}

class CreateOrderUseCase {
  final PosRepository _repo;
  const CreateOrderUseCase(this._repo);

  Future<Either<Failure, PosOrderEntity>> call(CreateOrderParams params) =>
      _repo.createOrder(
        branchId: params.branchId,
        warehouseId: params.warehouseId?.isNotEmpty == true ? params.warehouseId : null,
        customerId: params.customerId,
        items: params.items,
        orderDiscount: params.orderDiscount,
        taxRate: params.taxRate,
        note: params.note,
        paymentMethod: params.paymentMethod,
        paymentAmount: params.paymentAmount,
      );
}
