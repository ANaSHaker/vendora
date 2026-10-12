import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/transfer_entities.dart';
import '../../domain/usecases/transfer_usecases.dart';
import 'transfer_state.dart';

class TransferCubit extends Cubit<TransferState> {
  final GetTransfersUseCase _getAll;
  final CreateTransferUseCase _create;
  final ApproveTransferUseCase _approve;
  final PostTransferUseCase _post;
  final ReceiveTransferUseCase _receive;
  final DeleteTransferUseCase _delete;

  Timer? _debounce;

  TransferCubit({
    required GetTransfersUseCase getTransfers,
    required CreateTransferUseCase createTransfer,
    required ApproveTransferUseCase approveTransfer,
    required PostTransferUseCase postTransfer,
    required ReceiveTransferUseCase receiveTransfer,
    required DeleteTransferUseCase deleteTransfer,
  })  : _getAll = getTransfers,
        _create = createTransfer,
        _approve = approveTransfer,
        _post = postTransfer,
        _receive = receiveTransfer,
        _delete = deleteTransfer,
        super(const TransferInitial());

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
    emit(const TransferLoading());
    final result = await _getAll(
      search: search.isEmpty ? null : search,
      status: statusFilter,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(TransferError(failure.message)),
      (paginated) => emit(TransferLoaded(
        transfers: paginated.data,
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
      final filter = s is TransferLoaded ? s.statusFilter : null;
      load(search: query, statusFilter: filter, page: 1);
    });
  }

  Future<void> refresh() async {
    final s = state;
    if (s is TransferLoaded) {
      await load(search: s.search, statusFilter: s.statusFilter, page: s.page);
    } else {
      await load();
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is TransferLoaded) {
      await load(search: s.search, statusFilter: s.statusFilter, page: page);
    }
  }

  Future<void> filterByStatus(String? status) async {
    final s = state;
    final search = s is TransferLoaded ? s.search : '';
    await load(search: search, statusFilter: status, page: 1);
  }

  Future<bool> createTransfer(TransferFormData data) async {
    final result = await _create(data);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> approveTransfer(String id) async {
    final result = await _approve(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> shipTransfer(String id) async {
    final result = await _post(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> receiveTransfer(String id) async {
    final result = await _receive(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> deleteTransfer(String id) async {
    final result = await _delete(id);
    return result.fold(
      (_) => false,
      (_) {
        final s = state;
        if (s is TransferLoaded) {
          emit(s.copyWith(
            transfers: s.transfers.where((t) => t.id != id).toList(),
          ));
        }
        return true;
      },
    );
  }

  void _replaceInList(String id, TransferEntity updated) {
    final s = state;
    if (s is TransferLoaded) {
      emit(s.copyWith(
        transfers: s.transfers.map((t) => t.id == id ? updated : t).toList(),
      ));
    }
  }
}
