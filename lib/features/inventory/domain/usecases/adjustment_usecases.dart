import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/adjustment_entities.dart';
import '../repositories/adjustment_repository.dart';

class GetAdjustmentsUseCase {
  final AdjustmentRepository _repo;
  const GetAdjustmentsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<AdjustmentEntity>>> call({
    String? status,
    String? adjustmentType,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getAdjustments(
        status: status,
        adjustmentType: adjustmentType,
        page: page,
        perPage: perPage,
      );
}

class GetAdjustmentByIdUseCase {
  final AdjustmentRepository _repo;
  const GetAdjustmentByIdUseCase(this._repo);

  Future<Either<Failure, AdjustmentEntity>> call(String id) =>
      _repo.getAdjustmentById(id);
}

class CreateAdjustmentUseCase {
  final AdjustmentRepository _repo;
  const CreateAdjustmentUseCase(this._repo);

  Future<Either<Failure, AdjustmentEntity>> call(AdjustmentFormData data) =>
      _repo.createAdjustment(data);
}

class UpdateAdjustmentUseCase {
  final AdjustmentRepository _repo;
  const UpdateAdjustmentUseCase(this._repo);

  Future<Either<Failure, AdjustmentEntity>> call(
          String id, AdjustmentFormData data) =>
      _repo.updateAdjustment(id, data);
}

class ApproveAdjustmentUseCase {
  final AdjustmentRepository _repo;
  const ApproveAdjustmentUseCase(this._repo);

  Future<Either<Failure, AdjustmentEntity>> call(String id) =>
      _repo.approveAdjustment(id);
}

class PostAdjustmentUseCase {
  final AdjustmentRepository _repo;
  const PostAdjustmentUseCase(this._repo);

  Future<Either<Failure, AdjustmentEntity>> call(String id) =>
      _repo.postAdjustment(id);
}

class CancelAdjustmentUseCase {
  final AdjustmentRepository _repo;
  const CancelAdjustmentUseCase(this._repo);

  Future<Either<Failure, AdjustmentEntity>> call(String id) =>
      _repo.cancelAdjustment(id);
}

class DeleteAdjustmentUseCase {
  final AdjustmentRepository _repo;
  const DeleteAdjustmentUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) =>
      _repo.deleteAdjustment(id);
}
