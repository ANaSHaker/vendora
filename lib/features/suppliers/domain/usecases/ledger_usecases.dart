import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/suppliers_repository.dart';

class GetSupplierLedgerUseCase {
  final LedgerRepository _repo;
  const GetSupplierLedgerUseCase(this._repo);

  Future<Either<Failure, LedgerResult>> call({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 50,
  }) =>
      _repo.getLedger(
        supplierId: supplierId,
        type: type,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        perPage: perPage,
      );
}

class RecordSupplierPaymentUseCase {
  final LedgerRepository _repo;
  const RecordSupplierPaymentUseCase(this._repo);

  Future<Either<Failure, void>> call(
    String supplierId,
    Map<String, dynamic> data,
  ) =>
      _repo.recordPayment(supplierId, data);
}

class ExportSupplierLedgerUseCase {
  final LedgerRepository _repo;
  const ExportSupplierLedgerUseCase(this._repo);

  Future<Either<Failure, List<int>>> call({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
  }) =>
      _repo.exportLedger(
        supplierId: supplierId,
        type: type,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
}
