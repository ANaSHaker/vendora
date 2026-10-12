import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/adjustment_entities.dart';
import '../../domain/usecases/adjustment_usecases.dart';
import 'adjustment_state.dart';

class AdjustmentCubit extends Cubit<AdjustmentState> {
  final GetAdjustmentsUseCase _getAll;
  final GetAdjustmentByIdUseCase _getById;
  final CreateAdjustmentUseCase _create;
  final UpdateAdjustmentUseCase _update;
  final ApproveAdjustmentUseCase _approve;
  final PostAdjustmentUseCase _post;
  final CancelAdjustmentUseCase _cancel;
  final DeleteAdjustmentUseCase _delete;

  AdjustmentCubit({
    required GetAdjustmentsUseCase getAdjustments,
    required GetAdjustmentByIdUseCase getAdjustmentById,
    required CreateAdjustmentUseCase createAdjustment,
    required UpdateAdjustmentUseCase updateAdjustment,
    required ApproveAdjustmentUseCase approveAdjustment,
    required PostAdjustmentUseCase postAdjustment,
    required CancelAdjustmentUseCase cancelAdjustment,
    required DeleteAdjustmentUseCase deleteAdjustment,
  })  : _getAll = getAdjustments,
        _getById = getAdjustmentById,
        _create = createAdjustment,
        _update = updateAdjustment,
        _approve = approveAdjustment,
        _post = postAdjustment,
        _cancel = cancelAdjustment,
        _delete = deleteAdjustment,
        super(const AdjustmentInitial());

  Future<void> load({
    String? statusFilter,
    String? typeFilter,
    int page = 1,
  }) async {
    emit(const AdjustmentLoading());
    final result = await _getAll(
      status: statusFilter,
      adjustmentType: typeFilter,
      page: page,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(AdjustmentError(failure.message)),
      (paginated) => emit(AdjustmentLoaded(
        adjustments: paginated.data,
        meta: paginated.meta,
        statusFilter: statusFilter,
        typeFilter: typeFilter,
        page: page,
      )),
    );
  }

  Future<void> refresh() async {
    final s = state;
    if (s is AdjustmentLoaded) {
      await load(
        statusFilter: s.statusFilter,
        typeFilter: s.typeFilter,
        page: s.page,
      );
    } else {
      await load();
    }
  }

  Future<void> goToPage(int page) async {
    final s = state;
    if (s is AdjustmentLoaded) {
      await load(statusFilter: s.statusFilter, typeFilter: s.typeFilter, page: page);
    }
  }

  Future<void> filterByStatus(String? status) async {
    final s = state;
    final type = s is AdjustmentLoaded ? s.typeFilter : null;
    await load(statusFilter: status, typeFilter: type, page: 1);
  }

  Future<void> filterByType(String? type) async {
    final s = state;
    final status = s is AdjustmentLoaded ? s.statusFilter : null;
    await load(statusFilter: status, typeFilter: type, page: 1);
  }

  Future<AdjustmentEntity?> loadDetail(String id) async {
    final result = await _getById(id);
    return result.fold((_) => null, (detail) => detail);
  }

  Future<bool> createAdjustment(AdjustmentFormData data) async {
    final result = await _create(data);
    return result.fold(
      (_) => false,
      (_) {
        refresh();
        return true;
      },
    );
  }

  Future<bool> updateAdjustment(String id, AdjustmentFormData data) async {
    final result = await _update(id, data);
    return result.fold(
      (_) => false,
      (updated) {
        final s = state;
        if (s is AdjustmentLoaded) {
          emit(s.copyWith(
            adjustments: s.adjustments
                .map((a) => a.id == id ? updated : a)
                .toList(),
          ));
        }
        return true;
      },
    );
  }

  Future<bool> approveAdjustment(String id) async {
    final result = await _approve(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> postAdjustment(String id) async {
    final result = await _post(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> cancelAdjustment(String id) async {
    final result = await _cancel(id);
    return result.fold(
      (_) => false,
      (updated) {
        _replaceInList(id, updated);
        return true;
      },
    );
  }

  Future<bool> deleteAdjustment(String id) async {
    final result = await _delete(id);
    return result.fold(
      (_) => false,
      (_) {
        final s = state;
        if (s is AdjustmentLoaded) {
          emit(s.copyWith(
            adjustments: s.adjustments.where((a) => a.id != id).toList(),
          ));
        }
        return true;
      },
    );
  }

  void _replaceInList(String id, AdjustmentEntity updated) {
    final s = state;
    if (s is AdjustmentLoaded) {
      emit(s.copyWith(
        adjustments: s.adjustments.map((a) => a.id == id ? updated : a).toList(),
      ));
    }
  }
}
