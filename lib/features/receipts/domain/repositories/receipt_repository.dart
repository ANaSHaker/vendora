import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';

abstract class ReceiptRepository {
  Future<Either<Failure, PaginatedResponse<ReceiptEntity>>> getReceipts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, ReceiptEntity>> getReceiptById(String id);
  Future<Either<Failure, ReceiptEntity>> postReceipt(String id);
  Future<Either<Failure, ReceiptEntity>> cancelReceipt(String id);
}
