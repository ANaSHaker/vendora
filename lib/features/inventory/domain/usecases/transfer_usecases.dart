import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/transfer_entities.dart';
import '../repositories/transfer_repository.dart';

class GetTransfersUseCase {
  final TransferRepository _repo;
  const GetTransfersUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<TransferEntity>>> call({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getTransfers(
        status: status,
        search: search,
        page: page,
        perPage: perPage,
      );
}

class GetTransferByIdUseCase {
  final TransferRepository _repo;
  const GetTransferByIdUseCase(this._repo);

  Future<Either<Failure, TransferEntity>> call(String id) =>
      _repo.getTransferById(id);
}

class CreateTransferUseCase {
  final TransferRepository _repo;
  const CreateTransferUseCase(this._repo);

  Future<Either<Failure, TransferEntity>> call(TransferFormData data) =>
      _repo.createTransfer(data);
}

class ApproveTransferUseCase {
  final TransferRepository _repo;
  const ApproveTransferUseCase(this._repo);

  Future<Either<Failure, TransferEntity>> call(String id) =>
      _repo.approveTransfer(id);
}

class PostTransferUseCase {
  final TransferRepository _repo;
  const PostTransferUseCase(this._repo);

  Future<Either<Failure, TransferEntity>> call(String id) =>
      _repo.postTransfer(id);
}

class ReceiveTransferUseCase {
  final TransferRepository _repo;
  const ReceiveTransferUseCase(this._repo);

  Future<Either<Failure, TransferEntity>> call(String id) =>
      _repo.receiveTransfer(id);
}

class DeleteTransferUseCase {
  final TransferRepository _repo;
  const DeleteTransferUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) =>
      _repo.deleteTransfer(id);
}
