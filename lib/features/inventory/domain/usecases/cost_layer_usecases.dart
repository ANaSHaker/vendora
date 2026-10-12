import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/cost_layer_entities.dart';
import '../repositories/cost_layer_repository.dart';

class GetCostLayersUseCase {
  final CostLayerRepository _repo;
  const GetCostLayersUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<CostLayerEntity>>> call({
    String? search,
    String? warehouseId,
    String? branchId,
    String? productId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getCostLayers(
        search: search,
        warehouseId: warehouseId,
        branchId: branchId,
        productId: productId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: page,
        perPage: perPage,
      );
}

class GetCostLayerConsumptionsUseCase {
  final CostLayerRepository _repo;
  const GetCostLayerConsumptionsUseCase(this._repo);

  Future<Either<Failure, List<CostLayerConsumptionEntity>>> call(
          String layerId) =>
      _repo.getConsumptions(layerId);
}
