import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entities.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardParams extends Equatable {
  final DateTime dateFrom;
  final DateTime dateTo;
  final String? branchId;

  const GetDashboardParams({
    required this.dateFrom,
    required this.dateTo,
    this.branchId,
  });

  @override
  List<Object?> get props => [dateFrom, dateTo, branchId];
}

class GetDashboardUseCase {
  final DashboardRepository _repository;

  const GetDashboardUseCase(this._repository);

  Future<Either<Failure, DashboardDataEntity>> call(
    GetDashboardParams params,
  ) {
    return _repository.getDashboard(
      dateFrom: params.dateFrom,
      dateTo: params.dateTo,
      branchId: params.branchId,
    );
  }
}
