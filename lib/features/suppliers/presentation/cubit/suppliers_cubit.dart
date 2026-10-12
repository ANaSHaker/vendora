import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/supplier_entities.dart';
import '../../domain/usecases/suppliers_usecases.dart';
import 'suppliers_state.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  final GetSuppliersUseCase _getSuppliers;
  final CreateSupplierUseCase _create;
  final UpdateSupplierUseCase _update;
  final DeleteSupplierUseCase _delete;

  Timer? _debounce;

  SuppliersCubit({
    required GetSuppliersUseCase getSuppliers,
    required CreateSupplierUseCase createSupplier,
    required UpdateSupplierUseCase updateSupplier,
    required DeleteSupplierUseCase deleteSupplier,
  })  : _getSuppliers = getSuppliers,
        _create = createSupplier,
        _update = updateSupplier,
        _delete = deleteSupplier,
        super(const SuppliersInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({String search = '', int page = 1}) async {
    emit(const SuppliersLoading());
    final result = await _getSuppliers(
      search: search.isEmpty ? null : search,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(SuppliersError(failure.message)),
      (paginated) => emit(SuppliersLoaded(
        suppliers: paginated.data,
        meta: paginated.meta,
        search: search,
        page: page,
      )),
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      load(search: query, page: 1);
    });
  }

  Future<void> refresh() async {
    final s = state;
    if (s is SuppliersLoaded) {
      await load(search: s.search, page: s.page);
    } else {
      await load();
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is SuppliersLoaded) {
      await load(search: s.search, page: page);
    }
  }

  Future<bool> createSupplier(SupplierFormData data) async {
    final result = await _create(data);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> updateSupplier(String id, SupplierFormData data) async {
    final result = await _update(id, data);
    return result.fold(
      (_) => false,
      (updated) {
        final s = state;
        if (s is SuppliersLoaded) {
          emit(s.copyWith(
            suppliers:
                s.suppliers.map((c) => c.id == id ? updated : c).toList(),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> deleteSupplier(String id) async {
    final result = await _delete(id);
    return result.fold(
      (_) => false,
      (_) {
        final s = state;
        if (s is SuppliersLoaded) {
          emit(s.copyWith(
            suppliers: s.suppliers.where((c) => c.id != id).toList(),
          ));
        }
        return true;
      },
    );
  }
}
