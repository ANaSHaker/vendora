import '../../domain/entities/branch_entity.dart';

sealed class BranchesState {
  const BranchesState();
}

class BranchesInitial extends BranchesState {
  const BranchesInitial();
}

class BranchesLoading extends BranchesState {
  const BranchesLoading();
}

class BranchesLoaded extends BranchesState {
  final List<BranchManagementEntity> branches;
  final String search;
  const BranchesLoaded({required this.branches, this.search = ''});
}

class BranchesError extends BranchesState {
  final String message;
  const BranchesError(this.message);
}
