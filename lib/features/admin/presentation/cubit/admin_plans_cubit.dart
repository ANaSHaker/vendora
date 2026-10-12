import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_plans_state.dart';

class AdminPlansCubit extends Cubit<AdminPlansState> {
  final GetAdminPlansUseCase _getPlans;
  final CreateAdminPlanUseCase _createPlan;
  final UpdateAdminPlanUseCase _updatePlan;
  final DeleteAdminPlanUseCase _deletePlan;

  AdminPlansCubit({
    required GetAdminPlansUseCase getPlans,
    required CreateAdminPlanUseCase createPlan,
    required UpdateAdminPlanUseCase updatePlan,
    required DeleteAdminPlanUseCase deletePlan,
  })  : _getPlans = getPlans,
        _createPlan = createPlan,
        _updatePlan = updatePlan,
        _deletePlan = deletePlan,
        super(const AdminPlansInitial());

  Future<void> load() async {
    emit(const AdminPlansLoading());
    final result = await _getPlans();
    result.fold(
      (failure) => emit(AdminPlansError(failure.message)),
      (plans) => emit(AdminPlansLoaded(plans: plans)),
    );
  }

  Future<bool> createPlan(Map<String, dynamic> data) async {
    final current = state;
    if (current is! AdminPlansLoaded) return false;
    if (current.isSaving) return false;
    emit(current.copyWith(isSaving: true, saveSuccess: false));
    final result = await _createPlan(data);
    return result.fold(
      (failure) {
        final s = state;
        if (s is AdminPlansLoaded) emit(s.copyWith(isSaving: false));
        return false;
      },
      (plan) {
        final s = state;
        if (s is AdminPlansLoaded) {
          emit(s.copyWith(
            plans: [...s.plans, plan],
            isSaving: false,
            saveSuccess: true,
          ));
        }
        return true;
      },
    );
  }

  Future<bool> updatePlan(String id, Map<String, dynamic> data) async {
    final current = state;
    if (current is! AdminPlansLoaded) return false;
    if (current.isSaving) return false;
    emit(current.copyWith(isSaving: true, saveSuccess: false));
    final result = await _updatePlan(id, data);
    return result.fold(
      (failure) {
        final s = state;
        if (s is AdminPlansLoaded) emit(s.copyWith(isSaving: false));
        return false;
      },
      (updated) {
        final s = state;
        if (s is AdminPlansLoaded) {
          final plans = s.plans.map((p) => p.id == id ? updated : p).toList();
          emit(s.copyWith(plans: plans, isSaving: false, saveSuccess: true));
        }
        return true;
      },
    );
  }

  Future<bool> deletePlan(String id) async {
    final current = state;
    if (current is! AdminPlansLoaded) return false;
    if (current.deletingId != null) return false;
    emit(current.copyWith(deletingId: id));
    final result = await _deletePlan(id);
    return result.fold(
      (failure) {
        final s = state;
        if (s is AdminPlansLoaded) emit(s.copyWith(clearDeletingId: true));
        return false;
      },
      (_) {
        final s = state;
        if (s is AdminPlansLoaded) {
          final plans = s.plans.where((p) => p.id != id).toList();
          emit(s.copyWith(plans: plans, clearDeletingId: true));
        }
        return true;
      },
    );
  }
}
