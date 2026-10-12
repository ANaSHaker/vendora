import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/homepage_builder_entities.dart';
import '../../domain/repositories/homepage_builder_repository.dart';
import '../datasources/homepage_builder_remote_datasource.dart';

class HomepageBuilderRepositoryImpl implements HomepageBuilderRepository {
  final HomepageBuilderRemoteDataSource _remote;
  const HomepageBuilderRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<HomepageSection>>> getLayout() =>
      _wrap(() => _remote.getLayout());

  @override
  Future<Either<Failure, void>> saveLayout(List<HomepageSection> sections) =>
      _wrap(() => _remote.saveLayout(sections));

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
      if (error is UnauthorizedException) return const Left(UnauthorizedFailure());
      if (error is ForbiddenException)    return const Left(ForbiddenFailure());
      if (error is NetworkException)      return Left(NetworkFailure(error.message));
      if (error is ServerException) {
        return Left(ServerFailure(error.message, statusCode: error.statusCode));
      }
      return const Left(UnknownFailure());
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
