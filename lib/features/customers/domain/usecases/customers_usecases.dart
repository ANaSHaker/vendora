import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entities.dart';
import '../repositories/customers_repository.dart';

class GetCustomersUseCase {
  final CustomersRepository _repo;
  const GetCustomersUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<CustomerEntity>>> call({
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getCustomers(search: search, page: page, perPage: perPage);
}

class GetCustomerByIdUseCase {
  final CustomersRepository _repo;
  const GetCustomerByIdUseCase(this._repo);

  Future<Either<Failure, CustomerEntity>> call(String id) =>
      _repo.getCustomerById(id);
}

class CreateCustomerUseCase {
  final CustomersRepository _repo;
  const CreateCustomerUseCase(this._repo);

  Future<Either<Failure, CustomerEntity>> call(CustomerFormData data) =>
      _repo.createCustomer(data);
}

class UpdateCustomerUseCase {
  final CustomersRepository _repo;
  const UpdateCustomerUseCase(this._repo);

  Future<Either<Failure, CustomerEntity>> call(
          String id, CustomerFormData data) =>
      _repo.updateCustomer(id, data);
}

class DeleteCustomerUseCase {
  final CustomersRepository _repo;
  const DeleteCustomerUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteCustomer(id);
}
