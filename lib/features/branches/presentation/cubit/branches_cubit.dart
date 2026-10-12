import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/branch_entity.dart';
import '../../domain/usecases/branches_usecases.dart';
import 'branches_state.dart';

class BranchesCubit extends Cubit<BranchesState> {
  final GetManagedBranchesUseCase _get;
  final CreateBranchUseCase _create;
  final UpdateBranchUseCase _update;
  final DeleteBranchUseCase _delete;

  String _search = '';

  BranchesCubit({
    required GetManagedBranchesUseCase get,
    required CreateBranchUseCase create,
    required UpdateBranchUseCase update,
    required DeleteBranchUseCase delete,
  })  : _get = get,
        _create = create,
        _update = update,
        _delete = delete,
        super(const BranchesInitial());

  Future<void> load() async {
    emit(const BranchesLoading());
    final result = await _get(search: _search.isEmpty ? null : _search);
    result.fold(
      (f) => emit(BranchesError(f.message)),
      (list) => emit(BranchesLoaded(branches: list, search: _search)),
    );
  }

  void search(String q) {
    _search = q;
    load();
  }

  void refresh() => load();

  Future<bool> createBranch(BranchFormData data) async {
    final result = await _create(data);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> updateBranch(String id, BranchFormData data) async {
    final result = await _update(id, data);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> deleteBranch(String id) async {
    final result = await _delete(id);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }
}
