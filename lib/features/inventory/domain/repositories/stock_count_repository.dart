import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/stock_count_entities.dart';

abstract class StockCountRepository {
  Future<Either<Failure, PaginatedResponse<StockCountEntity>>> getStockCounts({
    String? status,
    String? search,
    int page = 1,
    int perPage = 20,
  });

  Future<Either<Failure, StockCountEntity>> getStockCountById(String id);

  Future<Either<Failure, StockCountEntity>> createStockCount(
      StockCountFormData data);

  Future<Either<Failure, StockCountEntity>> postStockCount(String id);

  Future<Either<Failure, void>> deleteStockCount(String id);
}
