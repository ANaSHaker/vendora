import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/inventory_entities.dart';
import '../../domain/entities/warehouse_entities.dart';
import '../../domain/usecases/inventory_usecases.dart';
import '../../domain/usecases/warehouse_usecases.dart';
import 'warehouse_state.dart';

class WarehouseCubit extends Cubit<WarehouseState> {
  final GetManagedWarehousesUseCase _getWarehouses;
  final CreateWarehouseUseCase _create;
  final UpdateWarehouseUseCase _update;
  final DeleteWarehouseUseCase _delete;
  final SetDefaultWarehouseUseCase _setDefault;
  final GetInventoryBranchOptionsUseCase _getBranches;

  Timer? _debounce;

  WarehouseCubit({
    required GetManagedWarehousesUseCase getWarehouses,
    required CreateWarehouseUseCase createWarehouse,
    required UpdateWarehouseUseCase updateWarehouse,
    required DeleteWarehouseUseCase deleteWarehouse,
    required SetDefaultWarehouseUseCase setDefaultWarehouse,
    required GetInventoryBranchOptionsUseCase getBranches,
  })  : _getWarehouses = getWarehouses,
        _create = createWarehouse,
        _update = updateWarehouse,
        _delete = deleteWarehouse,
        _setDefault = setDefaultWarehouse,
        _getBranches = getBranches,
        super(const WarehouseInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({
    String search = '',
    String? branchId,
    int page = 1,
  }) async {
    final prev = state;
    final prevBranches =
        prev is WarehouseLoaded ? prev.branches : <InventoryBranchOptionEntity>[];

    emit(const WarehouseLoading());
    final result = await _getWarehouses(
      search: search.isEmpty ? null : search,
      branchId: branchId,
      page: page,
      perPage: 25,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(WarehouseError(failure.message)),
      (paginated) {
        emit(WarehouseLoaded(
          warehouses: paginated.data,
          meta: paginated.meta,
          search: search,
          branchId: branchId,
          page: page,
          branches: prevBranches,
        ));
        if (prevBranches.isEmpty) _loadBranches();
      },
    );
  }

  Future<void> _loadBranches() async {
    final s = state;
    if (s is! WarehouseLoaded) return;
    emit(s.copyWith(loadingBranches: true));
    final result = await _getBranches();
    if (isClosed) return;
    final cur = state;
    if (cur is! WarehouseLoaded) return;
    result.fold(
      (_) => emit(cur.copyWith(loadingBranches: false)),
      (list) => emit(cur.copyWith(branches: list, loadingBranches: false)),
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final s = state;
      final branchId = s is WarehouseLoaded ? s.branchId : null;
      load(search: query, branchId: branchId, page: 1);
    });
  }

  Future<void> setBranch(String? id) async {
    final s = state;
    final search = s is WarehouseLoaded ? s.search : '';
    await load(search: search, branchId: id, page: 1);
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is WarehouseLoaded) {
      await load(search: s.search, branchId: s.branchId, page: page);
    }
  }

  Future<void> refresh() async {
    final s = state;
    if (s is WarehouseLoaded) {
      await load(search: s.search, branchId: s.branchId, page: s.page);
    } else {
      await load();
    }
  }

  Future<bool> createWarehouse(WarehouseFormData data) async {
    final result = await _create(data);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> updateWarehouse(String id, WarehouseFormData data) async {
    final result = await _update(id, data);
    return result.fold(
      (_) => false,
      (updated) {
        final s = state;
        if (s is WarehouseLoaded) {
          emit(s.copyWith(
            warehouses:
                s.warehouses.map((w) => w.id == id ? updated : w).toList(),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> deleteWarehouse(String id) async {
    final result = await _delete(id);
    return result.fold(
      (_) => false,
      (_) {
        final s = state;
        if (s is WarehouseLoaded) {
          emit(s.copyWith(
            warehouses: s.warehouses.where((w) => w.id != id).toList(),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> setDefault(String id) async {
    final result = await _setDefault(id);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }
}
