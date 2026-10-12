import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/transfer_entities.dart';

abstract class TransferRepository {
  Future<Either<Failure, PaginatedResponse<TransferEntity>>> getTransfers({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, TransferEntity>> getTransferById(String id);

  Future<Either<Failure, TransferEntity>> createTransfer(
      TransferFormData data);

  Future<Either<Failure, TransferEntity>> approveTransfer(String id);

  Future<Either<Failure, TransferEntity>> postTransfer(String id);

  Future<Either<Failure, TransferEntity>> receiveTransfer(String id);

  Future<Either<Failure, void>> deleteTransfer(String id);
}
