import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/product_entities.dart';

class ProductsFilters extends Equatable {
  final String search;
  final String? categoryId;
  final bool? isActive;
  final int page;
  final int perPage;

  const ProductsFilters({
    this.search = '',
    this.categoryId,
    this.isActive,
    this.page = 1,
    this.perPage = 15,
  });

  ProductsFilters copyWith({
    String? search,
    String? Function()? categoryId,
    bool? Function()? isActive,
    int? page,
    int? perPage,
  }) {
    return ProductsFilters(
      search: search ?? this.search,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      isActive: isActive != null ? isActive() : this.isActive,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  List<Object?> get props => [search, categoryId, isActive, page, perPage];
}

sealed class ProductsState extends Equatable {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();

  @override
  List<Object?> get props => [];
}

class ProductsLoading extends ProductsState {
  final ProductsFilters filters;
  const ProductsLoading(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ProductsLoaded extends ProductsState {
  final List<ProductEntity> products;
  final PaginationMeta meta;
  final ProductsFilters filters;
  final List<CategoryEntity> categories;

  const ProductsLoaded({
    required this.products,
    required this.meta,
    required this.filters,
    required this.categories,
  });

  @override
  List<Object?> get props => [products, meta, filters, categories];
}

class ProductsError extends ProductsState {
  final String message;
  final ProductsFilters filters;

  const ProductsError(this.message, this.filters);

  @override
  List<Object?> get props => [message, filters];
}
