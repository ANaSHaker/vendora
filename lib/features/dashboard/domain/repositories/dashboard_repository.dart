import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entities.dart';

abstract class DashboardRepository {
  Future<Either<Failure, DashboardDataEntity>> getDashboard({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  });
}
