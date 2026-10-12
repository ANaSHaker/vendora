import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/aging_entities.dart';
import '../repositories/suppliers_repository.dart';

class GetSupplierAgingUseCase {
  final AgingRepository _repo;
  const GetSupplierAgingUseCase(this._repo);

  Future<Either<Failure, List<AgingRowEntity>>> call({
    String? supplierId,
    String? asOf,
  }) =>
      _repo.getAging(supplierId: supplierId, asOf: asOf);
}

class ExportSupplierAgingUseCase {
  final AgingRepository _repo;
  const ExportSupplierAgingUseCase(this._repo);

  Future<Either<Failure, List<int>>> call({
    String? supplierId,
    String? asOf,
  }) =>
      _repo.exportAging(supplierId: supplierId, asOf: asOf);
}
