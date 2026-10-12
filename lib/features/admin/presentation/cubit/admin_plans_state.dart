import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_plan_entity.dart';

sealed class AdminPlansState extends Equatable {
  const AdminPlansState();
  @override
  List<Object?> get props => [];
}

class AdminPlansInitial extends AdminPlansState {
  const AdminPlansInitial();
}

class AdminPlansLoading extends AdminPlansState {
  const AdminPlansLoading();
}

class AdminPlansLoaded extends AdminPlansState {
  final List<AdminPlanEntity> plans;
  final bool isSaving;
  final bool saveSuccess;
  final String? deletingId;

  const AdminPlansLoaded({
    required this.plans,
    this.isSaving = false,
    this.saveSuccess = false,
    this.deletingId,
  });

  AdminPlansLoaded copyWith({
    List<AdminPlanEntity>? plans,
    bool? isSaving,
    bool? saveSuccess,
    String? deletingId,
    bool clearDeletingId = false,
  }) {
    return AdminPlansLoaded(
      plans: plans ?? this.plans,
      isSaving: isSaving ?? this.isSaving,
      saveSuccess: saveSuccess ?? this.saveSuccess,
      deletingId: clearDeletingId ? null : (deletingId ?? this.deletingId),
    );
  }

  @override
  List<Object?> get props => [plans, isSaving, saveSuccess, deletingId];
}

class AdminPlansError extends AdminPlansState {
  final String message;
  const AdminPlansError(this.message);
  @override
  List<Object?> get props => [message];
}
