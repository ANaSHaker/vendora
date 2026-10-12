import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/usecases/receipt_usecases.dart';
import 'receipt_state.dart';

class ReceiptCubit extends Cubit<ReceiptState> {
  final GetReceiptsUseCase _getAll;
  final GetReceiptByIdUseCase _getById;
  final PostReceiptUseCase _post;
  final CancelReceiptUseCase _cancel;

  ReceiptCubit({
    required GetReceiptsUseCase getReceipts,
    required GetReceiptByIdUseCase getReceiptById,
    required PostReceiptUseCase postReceipt,
    required CancelReceiptUseCase cancelReceipt,
  })  : _getAll = getReceipts,
        _getById = getReceiptById,
        _post = postReceipt,
        _cancel = cancelReceipt,
        super(const ReceiptInitial());

  Future<void> load({
    String? statusFilter,
    String? search,
    int page = 1,
  }) async {
    emit(const ReceiptLoading());
    final result = await _getAll(
      status: statusFilter,
      search: search,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(ReceiptError(failure.message)),
      (paginated) => emit(ReceiptLoaded(
        receipts: paginated.data,
        meta: paginated.meta,
        statusFilter: statusFilter,
        search: search,
        page: page,
      )),
    );
  }

  Future<void> refresh() async {
    final s = state;
    if (s is ReceiptLoaded) {
      await load(statusFilter: s.statusFilter, search: s.search, page: s.page);
    } else {
      await load();
    }
  }

  Future<void> filterByStatus(String? status) async =>
      load(statusFilter: status, page: 1);

  Future<void> search(String q) async {
    final s = state;
    final status = s is ReceiptLoaded ? s.statusFilter : null;
    await load(statusFilter: status, search: q.isEmpty ? null : q, page: 1);
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is ReceiptLoaded) {
      await load(statusFilter: s.statusFilter, search: s.search, page: page);
    }
  }

  Future<ReceiptEntity?> loadDetail(String id) async {
    final result = await _getById(id);
    return result.fold((_) => null, (r) => r);
  }

  Future<bool> postReceipt(String id) async {
    final result = await _post(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> cancelReceipt(String id) async {
    final result = await _cancel(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  void _replaceInList(String id, ReceiptEntity updated) {
    final s = state;
    if (s is ReceiptLoaded) {
      emit(s.copyWith(
        receipts:
            s.receipts.map((r) => r.id == id ? updated : r).toList(),
      ));
    }
  }
}
