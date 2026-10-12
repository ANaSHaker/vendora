import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/customer_entities.dart';

abstract class CustomersRepository {
  Future<Either<Failure, PaginatedResponse<CustomerEntity>>> getCustomers({
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, CustomerEntity>> getCustomerById(String id);

  Future<Either<Failure, CustomerEntity>> createCustomer(CustomerFormData data);

  Future<Either<Failure, CustomerEntity>> updateCustomer(
      String id, CustomerFormData data);

  Future<Either<Failure, void>> deleteCustomer(String id);
}
