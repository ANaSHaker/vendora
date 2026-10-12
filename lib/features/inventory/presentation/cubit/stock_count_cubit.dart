import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/stock_count_entities.dart';
import '../../domain/usecases/stock_count_usecases.dart';
import 'stock_count_state.dart';

class StockCountCubit extends Cubit<StockCountState> {
  final GetStockCountsUseCase _getAll;
  final GetStockCountByIdUseCase _getById;
  final CreateStockCountUseCase _create;
  final PostStockCountUseCase _post;
  final DeleteStockCountUseCase _delete;

  Timer? _debounce;

  StockCountCubit({
    required GetStockCountsUseCase getStockCounts,
    required GetStockCountByIdUseCase getStockCountById,
    required CreateStockCountUseCase createStockCount,
    required PostStockCountUseCase postStockCount,
    required DeleteStockCountUseCase deleteStockCount,
  })  : _getAll = getStockCounts,
        _getById = getStockCountById,
        _create = createStockCount,
        _post = postStockCount,
        _delete = deleteStockCount,
        super(const StockCountInitial());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  Future<void> load({
    String search = '',
    String? statusFilter,
    int page = 1,
  }) async {
    emit(const StockCountLoading());
    final result = await _getAll(
      search: search.isEmpty ? null : search,
      status: statusFilter,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(StockCountError(failure.message)),
      (paginated) => emit(StockCountLoaded(
        counts: paginated.data,
        meta: paginated.meta,
        search: search,
        statusFilter: statusFilter,
        page: page,
      )),
    );
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final s = state;
      final filter = s is StockCountLoaded ? s.statusFilter : null;
      load(search: query, statusFilter: filter, page: 1);
    });
  }

  Future<void> refresh() async {
    final s = state;
    if (s is StockCountLoaded) {
      await load(
          search: s.search, statusFilter: s.statusFilter, page: s.page);
    } else {
      await load();
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is StockCountLoaded) {
      await load(
          search: s.search, statusFilter: s.statusFilter, page: page);
    }
  }

  Future<void> filterByStatus(String? status) async {
    final s = state;
    final search = s is StockCountLoaded ? s.search : '';
    await load(search: search, statusFilter: status, page: 1);
  }

  Future<void> selectCount(String id) async {
    final s = state;
    if (s is! StockCountLoaded) return;

    emit(s.copyWith(
      selectedId: () => id,
      selectedDetail: () => null,
      loadingDetail: true,
    ));

    final result = await _getById(id);
    if (isClosed) return;
    result.fold(
      (_) => emit(s.copyWith(
        selectedId: () => id,
        loadingDetail: false,
      )),
      (detail) {
        final current = state;
        if (current is StockCountLoaded) {
          emit(current.copyWith(
            selectedDetail: () => detail,
            loadingDetail: false,
          ));
        }
      },
    );
  }

  void closeDetail() {
    final s = state;
    if (s is StockCountLoaded) {
      emit(s.copyWith(
        selectedId: () => null,
        selectedDetail: () => null,
      ));
    }
  }

  Future<bool> createStockCount(StockCountFormData data) async {
    final result = await _create(data);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> postCount(String id) async {
    final result = await _post(id);
    return result.fold(
      (_) => false,
      (updated) {
        final s = state;
        if (s is StockCountLoaded) {
          emit(s.copyWith(
            counts: s.counts
                .map((c) => c.id == id ? updated : c)
                .toList(),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> deleteCount(String id) async {
    final result = await _delete(id);
    return result.fold(
      (_) => false,
      (_) {
        final s = state;
        if (s is StockCountLoaded) {
          emit(s.copyWith(
            counts: s.counts.where((c) => c.id != id).toList(),
            selectedId: s.selectedId == id ? () => null : null,
            selectedDetail: s.selectedId == id ? () => null : null,
          ));
        }
        return true;
      },
    );
  }
}
