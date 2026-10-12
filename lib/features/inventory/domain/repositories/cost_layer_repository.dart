import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/cost_layer_entities.dart';

abstract class CostLayerRepository {
  Future<Either<Failure, PaginatedResponse<CostLayerEntity>>> getCostLayers({
    String? search,
    String? warehouseId,
    String? branchId,
    String? productId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, List<CostLayerConsumptionEntity>>> getConsumptions(
      String layerId);
}
