import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

class GetReceiptsUseCase {
  final ReceiptRepository _repo;
  const GetReceiptsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<ReceiptEntity>>> call({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getReceipts(
          status: status, search: search, page: page, perPage: perPage);
}

class GetReceiptByIdUseCase {
  final ReceiptRepository _repo;
  const GetReceiptByIdUseCase(this._repo);

  Future<Either<Failure, ReceiptEntity>> call(String id) =>
      _repo.getReceiptById(id);
}

class PostReceiptUseCase {
  final ReceiptRepository _repo;
  const PostReceiptUseCase(this._repo);

  Future<Either<Failure, ReceiptEntity>> call(String id) =>
      _repo.postReceipt(id);
}

class CancelReceiptUseCase {
  final ReceiptRepository _repo;
  const CancelReceiptUseCase(this._repo);

  Future<Either<Failure, ReceiptEntity>> call(String id) =>
      _repo.cancelReceipt(id);
}
