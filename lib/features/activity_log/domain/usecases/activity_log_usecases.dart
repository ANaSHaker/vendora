import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/activity_log_entity.dart';
import '../repositories/activity_log_repository.dart';

class GetActivityLogUseCase {
  final ActivityLogRepository _repo;
  const GetActivityLogUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<ActivityLogEntry>>> call(
    ActivityLogFilters filters,
  ) =>
      _repo.getActivityLog(filters);
}

class GetActivityLogUsersUseCase {
  final ActivityLogRepository _repo;
  const GetActivityLogUsersUseCase(this._repo);

  Future<Either<Failure, List<ActivityLogUser>>> call() => _repo.getUsers();
}
