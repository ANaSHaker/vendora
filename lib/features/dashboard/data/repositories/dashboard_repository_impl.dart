import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _remote;

  const DashboardRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, DashboardDataEntity>> getDashboard({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  }) async {
    try {
      final data = await _remote.getDashboard(
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
      );
      return Right(data);
    } on DioException catch (e) {
      final error = e.error;
      if (error is UnauthorizedException) return const Left(UnauthorizedFailure());
      if (error is ForbiddenException) return const Left(ForbiddenFailure());
      if (error is NetworkException) return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
