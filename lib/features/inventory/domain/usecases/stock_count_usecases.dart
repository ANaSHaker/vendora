import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/stock_count_entities.dart';
import '../repositories/stock_count_repository.dart';

class GetStockCountsUseCase {
  final StockCountRepository _repo;
  const GetStockCountsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<StockCountEntity>>> call({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  }) =>
      _repo.getStockCounts(
        status: status,
        search: search,
        page: page,
        perPage: perPage,
      );
}

class GetStockCountByIdUseCase {
  final StockCountRepository _repo;
  const GetStockCountByIdUseCase(this._repo);

  Future<Either<Failure, StockCountEntity>> call(String id) =>
      _repo.getStockCountById(id);
}

class CreateStockCountUseCase {
  final StockCountRepository _repo;
  const CreateStockCountUseCase(this._repo);

  Future<Either<Failure, StockCountEntity>> call(StockCountFormData data) =>
      _repo.createStockCount(data);
}

class PostStockCountUseCase {
  final StockCountRepository _repo;
  const PostStockCountUseCase(this._repo);

  Future<Either<Failure, StockCountEntity>> call(String id) =>
      _repo.postStockCount(id);
}

class DeleteStockCountUseCase {
  final StockCountRepository _repo;
  const DeleteStockCountUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) =>
      _repo.deleteStockCount(id);
}
