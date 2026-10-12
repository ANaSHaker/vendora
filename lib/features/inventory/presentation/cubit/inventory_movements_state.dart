import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../../products/domain/entities/product_entities.dart';
import '../../domain/entities/inventory_entities.dart';

sealed class InventoryMovementsState extends Equatable {
  const InventoryMovementsState();
  @override
  List<Object?> get props => [];
}

class InventoryMovementsInitial extends InventoryMovementsState {
  const InventoryMovementsInitial();
}

class InventoryMovementsLoading extends InventoryMovementsState {
  const InventoryMovementsLoading();
}

class InventoryMovementsSummary extends Equatable {
  final int totalMovements;
  final double totalQtyIn;
  final double totalQtyOut;

  const InventoryMovementsSummary({
    required this.totalMovements,
    required this.totalQtyIn,
    required this.totalQtyOut,
  });

  @override
  List<Object?> get props => [totalMovements, totalQtyIn, totalQtyOut];
}

class InventoryMovementsLoaded extends InventoryMovementsState {
  final List<InventoryMovementEntity> movements;
  final PaginationMeta meta;
  final String search;
  final String? warehouseId;
  final String? productId;
  final String? movementType;
  final String? dateFrom;
  final String? dateTo;
  final InventoryMovementsSummary? summary;
  final List<WarehouseOptionEntity> warehouses;
  final List<ProductEntity> products;
  final bool loadingWarehouses;
  final bool loadingProducts;

  const InventoryMovementsLoaded({
    required this.movements,
    required this.meta,
    this.search = '',
    this.warehouseId,
    this.productId,
    this.movementType,
    this.dateFrom,
    this.dateTo,
    this.summary,
    this.warehouses = const [],
    this.products = const [],
    this.loadingWarehouses = false,
    this.loadingProducts = false,
  });

  bool get hasActiveFilters =>
      warehouseId != null ||
      productId != null ||
      movementType != null ||
      dateFrom != null ||
      dateTo != null ||
      search.isNotEmpty;

  InventoryMovementsLoaded copyWith({
    List<InventoryMovementEntity>? movements,
    PaginationMeta? meta,
    String? search,
    String? Function()? warehouseId,
    String? Function()? productId,
    String? Function()? movementType,
    String? Function()? dateFrom,
    String? Function()? dateTo,
    InventoryMovementsSummary? Function()? summary,
    List<WarehouseOptionEntity>? warehouses,
    List<ProductEntity>? products,
    bool? loadingWarehouses,
    bool? loadingProducts,
  }) {
    return InventoryMovementsLoaded(
      movements: movements ?? this.movements,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      warehouseId: warehouseId != null ? warehouseId() : this.warehouseId,
      productId: productId != null ? productId() : this.productId,
      movementType:
          movementType != null ? movementType() : this.movementType,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      summary: summary != null ? summary() : this.summary,
      warehouses: warehouses ?? this.warehouses,
      products: products ?? this.products,
      loadingWarehouses: loadingWarehouses ?? this.loadingWarehouses,
      loadingProducts: loadingProducts ?? this.loadingProducts,
    );
  }

  @override
  List<Object?> get props => [
        movements, meta, search, warehouseId, productId, movementType,
        dateFrom, dateTo, summary, warehouses, products,
        loadingWarehouses, loadingProducts,
      ];
}

class InventoryMovementsError extends InventoryMovementsState {
  final String message;
  const InventoryMovementsError(this.message);
  @override
  List<Object?> get props => [message];
}
