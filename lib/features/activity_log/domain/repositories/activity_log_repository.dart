import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_log_entity.dart';

abstract class ActivityLogRepository {
  Future<Either<Failure, PaginatedResponse<ActivityLogEntry>>> getActivityLog(
    ActivityLogFilters filters,
  );

  Future<Either<Failure, List<ActivityLogUser>>> getUsers();
}
