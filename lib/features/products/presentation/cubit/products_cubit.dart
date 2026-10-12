import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/file_saver.dart';
import '../../domain/entities/product_entities.dart';
import '../../domain/usecases/products_usecases.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final GetProductsUseCase _getProducts;
  final GetCategoriesUseCase _getCategories;
  final DeleteProductUseCase _deleteProduct;
  final UpdateProductUseCase _updateProduct;
  final ExportProductsUseCase _exportProducts;
  final ImportProductsUseCase _importProducts;

  Timer? _searchDebounce;

  ProductsCubit({
    required GetProductsUseCase getProducts,
    required GetCategoriesUseCase getCategories,
    required DeleteProductUseCase deleteProduct,
    required UpdateProductUseCase updateProduct,
    required ExportProductsUseCase exportProducts,
    required ImportProductsUseCase importProducts,
  })  : _getProducts = getProducts,
        _getCategories = getCategories,
        _deleteProduct = deleteProduct,
        _updateProduct = updateProduct,
        _exportProducts = exportProducts,
        _importProducts = importProducts,
        super(const ProductsInitial());

  List<CategoryEntity> _cachedCategories = [];

  Future<void> load({ProductsFilters? filters}) async {
    final active = filters ?? const ProductsFilters();
    emit(ProductsLoading(active));

    if (_cachedCategories.isEmpty) {
      final cats = await _getCategories();
      cats.fold((_) {}, (c) => _cachedCategories = c);
    }

    final result = await _getProducts(
      search: active.search,
      categoryId: active.categoryId,
      isActive: active.isActive,
      page: active.page,
      perPage: active.perPage,
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(ProductsError(failure.message, active)),
      (paged) => emit(ProductsLoaded(
        products: paged.data,
        meta: paged.meta,
        filters: active,
        categories: _cachedCategories,
      )),
    );
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      load(filters: _currentFilters.copyWith(search: query, page: 1));
    });
  }

  void filterByCategory(String? categoryId) {
    load(filters: _currentFilters.copyWith(
      categoryId: () => categoryId,
      page: 1,
    ));
  }

  void filterByStatus(bool? isActive) {
    load(filters: _currentFilters.copyWith(
      isActive: () => isActive,
      page: 1,
    ));
  }

  void goToPage(int page) {
    load(filters: _currentFilters.copyWith(page: page));
  }

  void refresh() {
    _cachedCategories = [];
    load(filters: _currentFilters);
  }

  Future<bool> deleteProduct(String id) async {
    final result = await _deleteProduct(id);
    if (isClosed) return false;
    return result.fold((_) => false, (_) {
      refresh();
      return true;
    });
  }

  Future<void> toggleOnline(String productId, bool isOnline) async {
    final prevState = state;
    if (prevState is! ProductsLoaded) return;

    ProductEntity? product;
    for (final p in prevState.products) {
      if (p.id == productId) { product = p; break; }
    }
    if (product == null) return;

    // Optimistic update
    final optimistic = prevState.products.map((p) {
      if (p.id != productId) return p;
      return ProductEntity(
        id: p.id, name: p.name, sku: p.sku, barcode: p.barcode,
        price: p.price, categoryId: p.categoryId, categoryName: p.categoryName,
        stock: p.stock, isActive: p.isActive, isOnline: isOnline,
        isPublished: isOnline, isFeatured: p.isFeatured, imageUrl: p.imageUrl,
        description: p.description, unit: p.unit, trackStock: p.trackStock,
        hasOptions: p.hasOptions,
      );
    }).toList();
    emit(ProductsLoaded(
      products: optimistic, meta: prevState.meta,
      filters: prevState.filters, categories: prevState.categories,
    ));

    final data = ProductFormData(
      name: product.name, sku: product.sku, barcode: product.barcode,
      price: product.price, categoryId: product.categoryId,
      description: product.description, isOnline: isOnline, isPublished: isOnline,
      isFeatured: product.isFeatured, unit: product.unit, trackStock: product.trackStock,
    );
    final result = await _updateProduct(productId, data);
    if (isClosed) return;
    result.fold(
      (_) { if (!isClosed) emit(prevState); }, // revert on error
      (_) {},
    );
  }

  void onProductSaved() => refresh();

  Future<String?> exportFile({bool template = false}) async {
    final result = await _exportProducts(template: template);
    return result.fold(
      (_) => null,
      (bytes) => saveExportFile(
        bytes,
        template ? 'products-template.xlsx' : 'products-export.xlsx',
      ),
    );
  }

  Future<Map<String, dynamic>?> importFile(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) async {
    final result =
        await _importProducts(bytes, filename, duplicateMode: duplicateMode);
    return result.fold((_) => null, (data) {
      refresh();
      return data;
    });
  }

  ProductsFilters get _currentFilters {
    final s = state;
    if (s is ProductsLoaded) return s.filters;
    if (s is ProductsLoading) return s.filters;
    if (s is ProductsError) return s.filters;
    return const ProductsFilters();
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
