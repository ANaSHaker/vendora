import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/adjustment_entities.dart';

abstract class AdjustmentRepository {
  Future<Either<Failure, PaginatedResponse<AdjustmentEntity>>> getAdjustments({
    String? status,
    String? adjustmentType,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, AdjustmentEntity>> getAdjustmentById(String id);

  Future<Either<Failure, AdjustmentEntity>> createAdjustment(
      AdjustmentFormData data);

  Future<Either<Failure, AdjustmentEntity>> updateAdjustment(
      String id, AdjustmentFormData data);

  Future<Either<Failure, AdjustmentEntity>> approveAdjustment(String id);

  Future<Either<Failure, AdjustmentEntity>> postAdjustment(String id);

  Future<Either<Failure, AdjustmentEntity>> cancelAdjustment(String id);

  Future<Either<Failure, void>> deleteAdjustment(String id);
}
