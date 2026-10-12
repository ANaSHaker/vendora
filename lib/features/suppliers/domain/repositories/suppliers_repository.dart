import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/aging_entities.dart';
import '../entities/ledger_entities.dart';
import '../entities/supplier_entities.dart';

abstract class AgingRepository {
  Future<Either<Failure, List<AgingRowEntity>>> getAging({
    String? supplierId,
    String? asOf,
  });

  Future<Either<Failure, List<int>>> exportAging({
    String? supplierId,
    String? asOf,
  });
}

abstract class SuppliersRepository {
  Future<Either<Failure, PaginatedResponse<SupplierEntity>>> getSuppliers({
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, SupplierEntity>> getSupplierById(String id);

  Future<Either<Failure, SupplierEntity>> createSupplier(SupplierFormData data);

  Future<Either<Failure, SupplierEntity>> updateSupplier(
      String id, SupplierFormData data);

  Future<Either<Failure, void>> deleteSupplier(String id);
}

class LedgerResult {
  final List<LedgerEntryEntity> entries;
  final PaginationMeta meta;
  final LedgerSummary summary;

  const LedgerResult({
    required this.entries,
    required this.meta,
    required this.summary,
  });
}

abstract class LedgerRepository {
  Future<Either<Failure, LedgerResult>> getLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 50,
  });

  Future<Either<Failure, void>> recordPayment(
    String supplierId,
    Map<String, dynamic> data,
  );

  Future<Either<Failure, List<int>>> exportLedger({
    String? supplierId,
    String? type,
    String? dateFrom,
    String? dateTo,
  });
}
