import 'package:dartz/dartz.dart';
import '../../../../core/api/api_response.dart';
import '../../../../core/error/failures.dart';
import '../entities/product_entities.dart';
import '../repositories/products_repository.dart';

class GetProductsUseCase {
  final ProductsRepository _repo;
  const GetProductsUseCase(this._repo);

  Future<Either<Failure, PaginatedResponse<ProductEntity>>> call({
    String? search,
    String? categoryId,
    bool? isActive,
    int page = 1,
    int perPage = 15,
  }) =>
      _repo.getProducts(
        search: search,
        categoryId: categoryId,
        isActive: isActive,
        page: page,
        perPage: perPage,
      );
}

class CreateProductUseCase {
  final ProductsRepository _repo;
  const CreateProductUseCase(this._repo);

  Future<Either<Failure, ProductEntity>> call(ProductFormData data) =>
      _repo.createProduct(data);
}

class UpdateProductUseCase {
  final ProductsRepository _repo;
  const UpdateProductUseCase(this._repo);

  Future<Either<Failure, ProductEntity>> call(String id, ProductFormData data) =>
      _repo.updateProduct(id, data);
}

class DeleteProductUseCase {
  final ProductsRepository _repo;
  const DeleteProductUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteProduct(id);
}

class ExportProductsUseCase {
  final ProductsRepository _repo;
  const ExportProductsUseCase(this._repo);

  Future<Either<Failure, List<int>>> call({bool template = false}) =>
      template ? _repo.exportProductsTemplate() : _repo.exportProducts();
}

class ImportProductsUseCase {
  final ProductsRepository _repo;
  const ImportProductsUseCase(this._repo);

  Future<Either<Failure, Map<String, dynamic>>> call(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) =>
      _repo.importProducts(bytes, filename, duplicateMode: duplicateMode);
}

class GetCategoriesUseCase {
  final ProductsRepository _repo;
  const GetCategoriesUseCase(this._repo);

  Future<Either<Failure, List<CategoryEntity>>> call() => _repo.getCategories();
}

class CreateCategoryUseCase {
  final ProductsRepository _repo;
  const CreateCategoryUseCase(this._repo);

  Future<Either<Failure, CategoryEntity>> call(CategoryFormData data) =>
      _repo.createCategory(data);
}

class UpdateCategoryUseCase {
  final ProductsRepository _repo;
  const UpdateCategoryUseCase(this._repo);

  Future<Either<Failure, CategoryEntity>> call(String id, CategoryFormData data) =>
      _repo.updateCategory(id, data);
}

class DeleteCategoryUseCase {
  final ProductsRepository _repo;
  const DeleteCategoryUseCase(this._repo);

  Future<Either<Failure, void>> call(String id) => _repo.deleteCategory(id);
}

class ExportCategoriesUseCase {
  final ProductsRepository _repo;
  const ExportCategoriesUseCase(this._repo);

  Future<Either<Failure, List<int>>> call({bool template = false}) =>
      template ? _repo.exportCategoriesTemplate() : _repo.exportCategories();
}

class ImportCategoriesUseCase {
  final ProductsRepository _repo;
  const ImportCategoriesUseCase(this._repo);

  Future<Either<Failure, Map<String, dynamic>>> call(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) =>
      _repo.importCategories(bytes, filename, duplicateMode: duplicateMode);
}
