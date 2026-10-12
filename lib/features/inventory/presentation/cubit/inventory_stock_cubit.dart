import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/usecases/inventory_usecases.dart';
import 'inventory_stock_state.dart';

class InventoryStockCubit extends Cubit<InventoryStockState> {
  final GetInventoryStockUseCase _getStock;
  final GetInventoryWarehouseOptionsUseCase _getWarehouses;
  final GetInventoryBranchOptionsUseCase _getBranches;

  Timer? _debounce;

  InventoryStockCubit({
    required GetInventoryStockUseCase getStock,
    required GetInventoryWarehouseOptionsUseCase getWarehouses,
    required GetInventoryBranchOptionsUseCase getBranches,
  })  : _getStock = getStock,
        _getWarehouses = getWarehouses,
        _getBranches = getBranches,
        super(const InventoryStockInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({
    String search = '',
    String? branchId,
    String? warehouseId,
    int page = 1,
  }) async {
    final current = state;
    if (current is InventoryStockLoaded) {
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const InventoryStockLoading());
    }
    final result = await _getStock(
      search: search.isEmpty ? null : search,
      branchId: branchId,
      warehouseId: warehouseId,
      page: page,
      perPage: 20,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(InventoryStockError(failure.message)),
      (paginated) {
        final s = state;
        final warehouses = s is InventoryStockLoaded
            ? s.warehouses
            : const <WarehouseOptionEntity>[];
        final branches = s is InventoryStockLoaded
            ? s.branches
            : const <InventoryBranchOptionEntity>[];
        emit(InventoryStockLoaded(
          balances: paginated.data,
          meta: paginated.meta,
          search: search,
          branchId: branchId,
          warehouseId: warehouseId,
          warehouses: warehouses,
          branches: branches,
          isRefreshing: false,
        ));
      },
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final s = state;
      final branchId = s is InventoryStockLoaded ? s.branchId : null;
      final warehouseId = s is InventoryStockLoaded ? s.warehouseId : null;
      load(search: query, branchId: branchId, warehouseId: warehouseId, page: 1);
    });
  }

  Future<void> setBranch(String? id) async {
    final s = state;
    final search = s is InventoryStockLoaded ? s.search : '';
    await load(search: search, branchId: id, warehouseId: null, page: 1);
  }

  Future<void> setWarehouse(String? id) async {
    final s = state;
    final search = s is InventoryStockLoaded ? s.search : '';
    final branchId = s is InventoryStockLoaded ? s.branchId : null;
    await load(search: search, branchId: branchId, warehouseId: id, page: 1);
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is InventoryStockLoaded) {
      await load(
        search: s.search,
        branchId: s.branchId,
        warehouseId: s.warehouseId,
        page: page,
      );
    }
  }

  Future<void> refresh() async {
    final s = state;
    if (s is InventoryStockLoaded) {
      await load(
        search: s.search,
        branchId: s.branchId,
        warehouseId: s.warehouseId,
        page: s.meta.currentPage,
      );
    } else {
      await load();
    }
  }

  Future<void> loadWarehouses() async {
    final result = await _getWarehouses();
    if (isClosed) return;
    result.fold(
      (_) {},
      (warehouses) {
        final s = state;
        if (s is InventoryStockLoaded) {
          emit(s.copyWith(warehouses: warehouses));
        }
      },
    );
  }

  Future<void> loadBranches() async {
    final result = await _getBranches();
    if (isClosed) return;
    result.fold(
      (_) {},
      (branches) {
        final s = state;
        if (s is InventoryStockLoaded) {
          emit(s.copyWith(branches: branches));
        }
      },
    );
  }
}
