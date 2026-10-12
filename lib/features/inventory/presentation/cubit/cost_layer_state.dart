import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../../products/domain/entities/product_entities.dart';
import '../../domain/entities/cost_layer_entities.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/entities/warehouse_entities.dart';

sealed class CostLayerState extends Equatable {
  const CostLayerState();
  @override
  List<Object?> get props => [];
}

class CostLayerInitial extends CostLayerState {
  const CostLayerInitial();
}

class CostLayerLoading extends CostLayerState {
  const CostLayerLoading();
}

class CostLayerLoaded extends CostLayerState {
  final List<CostLayerEntity> layers;
  final PaginationMeta meta;
  final String search;
  final String? warehouseId;
  final String? branchId;
  final String? productId;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final List<WarehouseEntity> warehouses;
  final List<InventoryBranchOptionEntity> branches;
  final List<ProductEntity> products;
  final bool loadingWarehouses;
  final bool loadingBranches;
  final bool loadingProducts;
  final String? sortColumn;
  final bool sortAscending;
  final String? expandedLayerId;
  final Map<String, List<CostLayerConsumptionEntity>> consumptionsMap;
  final String? loadingConsumptionId;

  const CostLayerLoaded({
    required this.layers,
    required this.meta,
    this.search = '',
    this.warehouseId,
    this.branchId,
    this.productId,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.warehouses = const [],
    this.branches = const [],
    this.products = const [],
    this.loadingWarehouses = false,
    this.loadingBranches = false,
    this.loadingProducts = false,
    this.sortColumn,
    this.sortAscending = true,
    this.expandedLayerId,
    this.consumptionsMap = const {},
    this.loadingConsumptionId,
  });

  List<CostLayerEntity> get sortedLayers {
    if (sortColumn == null) return layers;
    final sorted = List<CostLayerEntity>.from(layers);
    sorted.sort((a, b) {
      final cmp = switch (sortColumn) {
        'product' => a.productName.compareTo(b.productName),
        'warehouse' => a.warehouseName.compareTo(b.warehouseName),
        'originalQty' => a.originalQty.compareTo(b.originalQty),
        'remainingQty' => a.remainingQty.compareTo(b.remainingQty),
        'unitCost' => a.unitCost.compareTo(b.unitCost),
        'totalValue' => a.totalValue.compareTo(b.totalValue),
        'ageDays' => a.ageDays.compareTo(b.ageDays),
        'createdAt' => a.createdAt.compareTo(b.createdAt),
        _ => 0,
      };
      return sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  bool get hasActiveFilters =>
      warehouseId != null ||
      branchId != null ||
      productId != null ||
      dateFrom != null ||
      dateTo != null ||
      search.isNotEmpty;

  CostLayerLoaded copyWith({
    List<CostLayerEntity>? layers,
    PaginationMeta? meta,
    String? search,
    String? Function()? warehouseId,
    String? Function()? branchId,
    String? Function()? productId,
    String? Function()? dateFrom,
    String? Function()? dateTo,
    int? page,
    List<WarehouseEntity>? warehouses,
    List<InventoryBranchOptionEntity>? branches,
    List<ProductEntity>? products,
    bool? loadingWarehouses,
    bool? loadingBranches,
    bool? loadingProducts,
    String? Function()? sortColumn,
    bool? sortAscending,
    String? Function()? expandedLayerId,
    Map<String, List<CostLayerConsumptionEntity>>? consumptionsMap,
    String? Function()? loadingConsumptionId,
  }) {
    return CostLayerLoaded(
      layers: layers ?? this.layers,
      meta: meta ?? this.meta,
      search: search ?? this.search,
      warehouseId: warehouseId != null ? warehouseId() : this.warehouseId,
      branchId: branchId != null ? branchId() : this.branchId,
      productId: productId != null ? productId() : this.productId,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      page: page ?? this.page,
      warehouses: warehouses ?? this.warehouses,
      branches: branches ?? this.branches,
      products: products ?? this.products,
      loadingWarehouses: loadingWarehouses ?? this.loadingWarehouses,
      loadingBranches: loadingBranches ?? this.loadingBranches,
      loadingProducts: loadingProducts ?? this.loadingProducts,
      sortColumn: sortColumn != null ? sortColumn() : this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
      expandedLayerId:
          expandedLayerId != null ? expandedLayerId() : this.expandedLayerId,
      consumptionsMap: consumptionsMap ?? this.consumptionsMap,
      loadingConsumptionId: loadingConsumptionId != null
          ? loadingConsumptionId()
          : this.loadingConsumptionId,
    );
  }

  @override
  List<Object?> get props => [
        layers, meta, search, warehouseId, branchId, productId,
        dateFrom, dateTo, page, warehouses, branches, products,
        loadingWarehouses, loadingBranches, loadingProducts,
        sortColumn, sortAscending, expandedLayerId,
        consumptionsMap, loadingConsumptionId,
      ];
}

class CostLayerError extends CostLayerState {
  final String message;
  const CostLayerError(this.message);
  @override
  List<Object?> get props => [message];
}
