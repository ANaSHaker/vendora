import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/product_entities.dart';
import '../../../products/domain/usecases/products_usecases.dart';
import '../../domain/entities/cost_layer_entities.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/entities/warehouse_entities.dart';
import '../../domain/usecases/cost_layer_usecases.dart';
import '../../domain/usecases/inventory_usecases.dart';
import '../../domain/usecases/warehouse_usecases.dart';
import 'cost_layer_state.dart';

class CostLayerCubit extends Cubit<CostLayerState> {
  final GetCostLayersUseCase _getCostLayers;
  final GetManagedWarehousesUseCase _getWarehouses;
  final GetInventoryBranchOptionsUseCase _getBranches;
  final GetProductsUseCase _getProducts;
  final GetCostLayerConsumptionsUseCase _getConsumptions;

  Timer? _debounce;

  CostLayerCubit({
    required GetCostLayersUseCase getCostLayers,
    required GetManagedWarehousesUseCase getWarehouses,
    required GetInventoryBranchOptionsUseCase getBranches,
    required GetProductsUseCase getProducts,
    required GetCostLayerConsumptionsUseCase getConsumptions,
  })  : _getCostLayers = getCostLayers,
        _getWarehouses = getWarehouses,
        _getBranches = getBranches,
        _getProducts = getProducts,
        _getConsumptions = getConsumptions,
        super(const CostLayerInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({
    String search = '',
    String? warehouseId,
    String? branchId,
    String? productId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    final prev = state;
    final prevWarehouses =
        prev is CostLayerLoaded ? prev.warehouses : <WarehouseEntity>[];
    final prevBranches =
        prev is CostLayerLoaded ? prev.branches : <InventoryBranchOptionEntity>[];
    final prevProducts =
        prev is CostLayerLoaded ? prev.products : <ProductEntity>[];
    final prevSort = prev is CostLayerLoaded ? prev.sortColumn : null;
    final prevAsc = prev is CostLayerLoaded ? prev.sortAscending : true;

    emit(const CostLayerLoading());
    final result = await _getCostLayers(
      search: search.isEmpty ? null : search,
      warehouseId: warehouseId,
      branchId: branchId,
      productId: productId,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      perPage: 20,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(CostLayerError(failure.message)),
      (paginated) {
        emit(CostLayerLoaded(
          layers: paginated.data,
          meta: paginated.meta,
          search: search,
          warehouseId: warehouseId,
          branchId: branchId,
          productId: productId,
          dateFrom: dateFrom,
          dateTo: dateTo,
          page: page,
          warehouses: prevWarehouses,
          branches: prevBranches,
          products: prevProducts,
          sortColumn: prevSort,
          sortAscending: prevAsc,
        ));
        if (prevWarehouses.isEmpty) _loadWarehouses();
        if (prevBranches.isEmpty) _loadBranches();
        if (prevProducts.isEmpty) _loadProducts();
      },
    );
  }

  Future<void> _loadWarehouses() async {
    final s = state;
    if (s is! CostLayerLoaded) return;
    emit(s.copyWith(loadingWarehouses: true));
    final result = await _getWarehouses(perPage: 200);
    if (isClosed) return;
    final cur = state;
    if (cur is! CostLayerLoaded) return;
    result.fold(
      (_) => emit(cur.copyWith(loadingWarehouses: false)),
      (paginated) => emit(
          cur.copyWith(warehouses: paginated.data, loadingWarehouses: false)),
    );
  }

  Future<void> _loadBranches() async {
    final s = state;
    if (s is! CostLayerLoaded) return;
    emit(s.copyWith(loadingBranches: true));
    final result = await _getBranches();
    if (isClosed) return;
    final cur = state;
    if (cur is! CostLayerLoaded) return;
    result.fold(
      (_) => emit(cur.copyWith(loadingBranches: false)),
      (list) => emit(cur.copyWith(branches: list, loadingBranches: false)),
    );
  }

  Future<void> _loadProducts() async {
    final s = state;
    if (s is! CostLayerLoaded) return;
    emit(s.copyWith(loadingProducts: true));
    final result = await _getProducts(perPage: 500);
    if (isClosed) return;
    final cur = state;
    if (cur is! CostLayerLoaded) return;
    result.fold(
      (_) => emit(cur.copyWith(loadingProducts: false)),
      (paginated) =>
          emit(cur.copyWith(products: paginated.data, loadingProducts: false)),
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final s = state;
      if (s is CostLayerLoaded) {
        load(
          search: query,
          warehouseId: s.warehouseId,
          branchId: s.branchId,
          productId: s.productId,
          dateFrom: s.dateFrom,
          dateTo: s.dateTo,
          page: 1,
        );
      } else {
        load(search: query, page: 1);
      }
    });
  }

  Future<void> setWarehouse(String? id) async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: id,
        branchId: s.branchId,
        productId: s.productId,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setBranch(String? id) async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        branchId: id,
        productId: s.productId,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setProduct(String? id) async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        branchId: s.branchId,
        productId: id,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setDateFrom(String? date) async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        branchId: s.branchId,
        productId: s.productId,
        dateFrom: date,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setDateTo(String? date) async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        branchId: s.branchId,
        productId: s.productId,
        dateFrom: s.dateFrom,
        dateTo: date,
        page: 1,
      );
    }
  }

  Future<void> clearFilters() async {
    await load();
  }

  void sortBy(String column) {
    final s = state;
    if (s is! CostLayerLoaded) return;
    final same = s.sortColumn == column;
    emit(s.copyWith(
      sortColumn: () => column,
      sortAscending: same ? !s.sortAscending : true,
    ));
  }

  Future<void> toggleConsumptions(String layerId) async {
    final s = state;
    if (s is! CostLayerLoaded) return;

    if (s.expandedLayerId == layerId) {
      emit(s.copyWith(expandedLayerId: () => null));
      return;
    }

    if (s.consumptionsMap.containsKey(layerId)) {
      emit(s.copyWith(expandedLayerId: () => layerId));
      return;
    }

    emit(s.copyWith(
      expandedLayerId: () => layerId,
      loadingConsumptionId: () => layerId,
    ));
    final result = await _getConsumptions(layerId);
    if (isClosed) return;
    final cur = state;
    if (cur is! CostLayerLoaded) return;
    result.fold(
      (_) => emit(cur.copyWith(loadingConsumptionId: () => null)),
      (consumptions) {
        final updated = Map<String, List<CostLayerConsumptionEntity>>.from(
            cur.consumptionsMap);
        updated[layerId] = consumptions;
        emit(cur.copyWith(
          consumptionsMap: updated,
          loadingConsumptionId: () => null,
        ));
      },
    );
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        branchId: s.branchId,
        productId: s.productId,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: page,
      );
    }
  }

  Future<void> refresh() async {
    final s = state;
    if (s is CostLayerLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        branchId: s.branchId,
        productId: s.productId,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: s.page,
      );
    } else {
      await load();
    }
  }
}
