import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/usecases/inventory_usecases.dart';
import 'warehouse_stock_state.dart';

class WarehouseStockCubit extends Cubit<WarehouseStockState> {
  final GetInventoryStockUseCase _getStock;
  final GetInventoryWarehouseOptionsUseCase _getWarehouses;
  final GetInventoryBranchOptionsUseCase _getBranches;

  Timer? _debounce;

  WarehouseStockCubit({
    required GetInventoryStockUseCase getStock,
    required GetInventoryWarehouseOptionsUseCase getWarehouses,
    required GetInventoryBranchOptionsUseCase getBranches,
  })  : _getStock = getStock,
        _getWarehouses = getWarehouses,
        _getBranches = getBranches,
        super(const WarehouseStockInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({
    String search = '',
    String? branchId,
    String? warehouseId,
    bool lowStockOnly = false,
    int page = 1,
  }) async {
    emit(const WarehouseStockLoading());
    final result = await _getStock(
      search: search.isEmpty ? null : search,
      branchId: branchId,
      warehouseId: warehouseId,
      lowStockOnly: lowStockOnly ? true : null,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(WarehouseStockError(failure.message)),
      (paginated) {
        final current = state;
        final warehouses = current is WarehouseStockLoaded
            ? current.warehouses
            : const <WarehouseOptionEntity>[];
        final branches = current is WarehouseStockLoaded
            ? current.branches
            : const <InventoryBranchOptionEntity>[];
        emit(WarehouseStockLoaded(
          balances: paginated.data,
          meta: paginated.meta,
          search: search,
          branchId: branchId,
          warehouseId: warehouseId,
          lowStockOnly: lowStockOnly,
          warehouses: warehouses,
          branches: branches,
        ));
      },
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final s = state;
      if (s is WarehouseStockLoaded) {
        load(
          search: query,
          branchId: s.branchId,
          warehouseId: s.warehouseId,
          lowStockOnly: s.lowStockOnly,
          page: 1,
        );
      }
    });
  }

  Future<void> setBranch(String? id) async {
    final s = state;
    final search = s is WarehouseStockLoaded ? s.search : '';
    final lowStockOnly = s is WarehouseStockLoaded ? s.lowStockOnly : false;
    await load(search: search, branchId: id, warehouseId: null, lowStockOnly: lowStockOnly, page: 1);
  }

  Future<void> setWarehouse(String? id) async {
    final s = state;
    if (s is WarehouseStockLoaded) {
      await load(
        search: s.search,
        branchId: s.branchId,
        warehouseId: id,
        lowStockOnly: s.lowStockOnly,
        page: 1,
      );
    }
  }

  Future<void> setLowStockOnly(bool value) async {
    final s = state;
    if (s is WarehouseStockLoaded) {
      await load(
        search: s.search,
        branchId: s.branchId,
        warehouseId: s.warehouseId,
        lowStockOnly: value,
        page: 1,
      );
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is WarehouseStockLoaded) {
      await load(
        search: s.search,
        branchId: s.branchId,
        warehouseId: s.warehouseId,
        lowStockOnly: s.lowStockOnly,
        page: page,
      );
    }
  }

  Future<void> refresh() async {
    final s = state;
    if (s is WarehouseStockLoaded) {
      await load(
        search: s.search,
        branchId: s.branchId,
        warehouseId: s.warehouseId,
        lowStockOnly: s.lowStockOnly,
        page: s.meta.currentPage,
      );
    } else {
      await load();
    }
  }

  Future<void> loadWarehouses() async {
    final result = await _getWarehouses();
    if (isClosed) return;
    result.fold((_) {}, (warehouses) {
      final s = state;
      if (s is WarehouseStockLoaded) {
        emit(s.copyWith(warehouses: warehouses));
      }
    });
  }

  Future<void> loadBranches() async {
    final result = await _getBranches();
    if (isClosed) return;
    result.fold((_) {}, (branches) {
      final s = state;
      if (s is WarehouseStockLoaded) {
        emit(s.copyWith(branches: branches));
      }
    });
  }
}
