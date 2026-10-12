import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_entities.dart';

abstract class ProductsRepository {
  Future<Either<Failure, PaginatedResponse<ProductEntity>>> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  });

  Future<Either<Failure, ProductEntity>> createProduct(ProductFormData data);

  Future<Either<Failure, ProductEntity>> updateProduct(
    String id,
    ProductFormData data,
  );

  Future<Either<Failure, void>> deleteProduct(String id);

  Future<Either<Failure, List<int>>> exportProducts();
  Future<Either<Failure, List<int>>> exportProductsTemplate();
  Future<Either<Failure, Map<String, dynamic>>> importProducts(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  });

  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  Future<Either<Failure, CategoryEntity>> createCategory(CategoryFormData data);
  Future<Either<Failure, CategoryEntity>> updateCategory(String id, CategoryFormData data);
  Future<Either<Failure, void>> deleteCategory(String id);

  Future<Either<Failure, List<int>>> exportCategories();
  Future<Either<Failure, List<int>>> exportCategoriesTemplate();
  Future<Either<Failure, Map<String, dynamic>>> importCategories(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  });
}
