import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../products/domain/entities/product_entities.dart';
import '../../../products/domain/usecases/products_usecases.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/usecases/inventory_usecases.dart';
import 'inventory_movements_state.dart';

class InventoryMovementsCubit extends Cubit<InventoryMovementsState> {
  final GetInventoryMovementsUseCase _getMovements;
  final GetInventoryWarehouseOptionsUseCase _getWarehouses;
  final GetProductsUseCase _getProducts;

  Timer? _debounce;

  InventoryMovementsCubit({
    required GetInventoryMovementsUseCase getMovements,
    required GetInventoryWarehouseOptionsUseCase getWarehouses,
    required GetProductsUseCase getProducts,
  })  : _getMovements = getMovements,
        _getWarehouses = getWarehouses,
        _getProducts = getProducts,
        super(const InventoryMovementsInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({
    String search = '',
    String? warehouseId,
    String? productId,
    String? movementType,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    final prev = state;
    final prevWarehouses =
        prev is InventoryMovementsLoaded ? prev.warehouses : <WarehouseOptionEntity>[];
    final prevProducts =
        prev is InventoryMovementsLoaded ? prev.products : <ProductEntity>[];

    emit(const InventoryMovementsLoading());
    final result = await _getMovements(
      search: search.isEmpty ? null : search,
      warehouseId: warehouseId,
      productId: productId,
      movementType: movementType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      page: page,
      perPage: 20,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(InventoryMovementsError(failure.message)),
      (paginated) {
        final totalQtyIn =
            paginated.data.fold(0.0, (sum, m) => sum + m.qtyIn);
        final totalQtyOut =
            paginated.data.fold(0.0, (sum, m) => sum + m.qtyOut);
        emit(InventoryMovementsLoaded(
          movements: paginated.data,
          meta: paginated.meta,
          search: search,
          warehouseId: warehouseId,
          productId: productId,
          movementType: movementType,
          dateFrom: dateFrom,
          dateTo: dateTo,
          summary: InventoryMovementsSummary(
            totalMovements: paginated.meta.total,
            totalQtyIn: totalQtyIn,
            totalQtyOut: totalQtyOut,
          ),
          warehouses: prevWarehouses,
          products: prevProducts,
        ));
        if (prevWarehouses.isEmpty) _loadWarehouses();
        if (prevProducts.isEmpty) _loadProducts();
      },
    );
  }

  Future<void> _loadWarehouses() async {
    final s = state;
    if (s is! InventoryMovementsLoaded) return;
    emit(s.copyWith(loadingWarehouses: true));
    final result = await _getWarehouses();
    if (isClosed) return;
    final cur = state;
    if (cur is! InventoryMovementsLoaded) return;
    result.fold(
      (_) => emit(cur.copyWith(loadingWarehouses: false)),
      (list) =>
          emit(cur.copyWith(warehouses: list, loadingWarehouses: false)),
    );
  }

  Future<void> _loadProducts() async {
    final s = state;
    if (s is! InventoryMovementsLoaded) return;
    emit(s.copyWith(loadingProducts: true));
    final result = await _getProducts(perPage: 500);
    if (isClosed) return;
    final cur = state;
    if (cur is! InventoryMovementsLoaded) return;
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
      if (s is InventoryMovementsLoaded) {
        load(
          search: query,
          warehouseId: s.warehouseId,
          productId: s.productId,
          movementType: s.movementType,
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
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: id,
        productId: s.productId,
        movementType: s.movementType,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setProduct(String? id) async {
    final s = state;
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        productId: id,
        movementType: s.movementType,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setMovementType(String? type) async {
    final s = state;
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        productId: s.productId,
        movementType: type,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setDateFrom(String? date) async {
    final s = state;
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        productId: s.productId,
        movementType: s.movementType,
        dateFrom: date,
        dateTo: s.dateTo,
        page: 1,
      );
    }
  }

  Future<void> setDateTo(String? date) async {
    final s = state;
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        productId: s.productId,
        movementType: s.movementType,
        dateFrom: s.dateFrom,
        dateTo: date,
        page: 1,
      );
    }
  }

  Future<void> clearFilters() async {
    await load();
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        productId: s.productId,
        movementType: s.movementType,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: page,
      );
    }
  }

  Future<void> refresh() async {
    final s = state;
    if (s is InventoryMovementsLoaded) {
      await load(
        search: s.search,
        warehouseId: s.warehouseId,
        productId: s.productId,
        movementType: s.movementType,
        dateFrom: s.dateFrom,
        dateTo: s.dateTo,
        page: s.meta.currentPage,
      );
    } else {
      await load();
    }
  }
}
