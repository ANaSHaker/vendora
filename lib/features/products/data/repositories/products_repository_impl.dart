import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entities.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_datasource.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource _remote;

  const ProductsRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedResponse<ProductEntity>>> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) =>
      _wrap(() => _remote.getProducts(
            search: search,
            categoryId: categoryId,
            isActive: isActive,
            page: page,
            perPage: perPage,
          ));

  @override
  Future<Either<Failure, ProductEntity>> createProduct(ProductFormData data) =>
      _wrap(() => _remote.createProduct(data));

  @override
  Future<Either<Failure, ProductEntity>> updateProduct(
          String id, ProductFormData data) =>
      _wrap(() => _remote.updateProduct(id, data));

  @override
  Future<Either<Failure, void>> deleteProduct(String id) =>
      _wrap(() => _remote.deleteProduct(id));

  @override
  Future<Either<Failure, List<int>>> exportProducts() =>
      _wrap(() => _remote.exportProducts());

  @override
  Future<Either<Failure, List<int>>> exportProductsTemplate() =>
      _wrap(() => _remote.exportProductsTemplate());

  @override
  Future<Either<Failure, Map<String, dynamic>>> importProducts(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) =>
      _wrap(() => _remote.importProducts(bytes, filename,
          duplicateMode: duplicateMode));

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() =>
      _wrap(() => _remote.getCategories());

  @override
  Future<Either<Failure, CategoryEntity>> createCategory(
          CategoryFormData data) =>
      _wrap(() => _remote.createCategory(data));

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory(
          String id, CategoryFormData data) =>
      _wrap(() => _remote.updateCategory(id, data));

  @override
  Future<Either<Failure, void>> deleteCategory(String id) =>
      _wrap(() => _remote.deleteCategory(id));

  @override
  Future<Either<Failure, List<int>>> exportCategories() =>
      _wrap(() => _remote.exportCategories());

  @override
  Future<Either<Failure, List<int>>> exportCategoriesTemplate() =>
      _wrap(() => _remote.exportCategoriesTemplate());

  @override
  Future<Either<Failure, Map<String, dynamic>>> importCategories(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) =>
      _wrap(() => _remote.importCategories(bytes, filename,
          duplicateMode: duplicateMode));

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on DioException catch (e) {
      final error = e.error;
      if (error is ValidationException) {
        return Left(ValidationFailure(error.message, errors: error.errors));
      }
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
