import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/usecases/roles_usecases.dart';
import 'roles_state.dart';

class RolesCubit extends Cubit<RolesState> {
  final GetRolesUseCase _get;
  final DeleteRoleUseCase _delete;
  final CloneRoleUseCase _clone;

  String _search = '';

  RolesCubit({
    required GetRolesUseCase get,
    required DeleteRoleUseCase delete,
    required CloneRoleUseCase clone,
  })  : _get = get,
        _delete = delete,
        _clone = clone,
        super(const RolesInitial());

  Future<void> load() async {
    emit(const RolesLoading());
    final result = await _get(search: _search.isEmpty ? null : _search);
    result.fold(
      (f) => emit(RolesError(f.message)),
      (list) => emit(RolesLoaded(roles: list, search: _search)),
    );
  }

  void search(String q) {
    _search = q;
    load();
  }

  void refresh() => load();

  Future<bool> deleteRole(String id) async {
    final result = await _delete(id);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> cloneRole(String id) async {
    final result = await _clone(id);
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }
}

// ── Role Form Cubit ────────────────────────────────────────────────────────────

class RoleFormCubit extends Cubit<RoleFormState> {
  final GetPermissionsUseCase _getPermissions;
  final CreateRoleUseCase _create;
  final UpdateRoleUseCase _update;

  RoleFormCubit({
    required GetPermissionsUseCase getPermissions,
    required CreateRoleUseCase create,
    required UpdateRoleUseCase update,
  })  : _getPermissions = getPermissions,
        _create = create,
        _update = update,
        super(const RoleFormInitial());

  Future<void> init({RoleEntity? editing}) async {
    emit(const RoleFormLoadingPermissions());
    final result = await _getPermissions();
    result.fold(
      (f) => emit(RoleFormError(f.message)),
      (modules) => emit(RoleFormReady(
        modules: modules,
        selectedPermissions: editing != null
            ? Set<String>.from(editing.permissions)
            : <String>{},
        editingRoleId: editing?.id,
      )),
    );
  }

  void togglePermission(String key) {
    final s = state;
    if (s is! RoleFormReady) return;
    final updated = Set<String>.from(s.selectedPermissions);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    emit(s.copyWith(selectedPermissions: updated));
  }

  void toggleModule(PermissionModuleEntity module, bool selectAll) {
    final s = state;
    if (s is! RoleFormReady) return;
    final updated = Set<String>.from(s.selectedPermissions);
    for (final p in module.permissions) {
      if (selectAll) {
        updated.add(p.name);
      } else {
        updated.remove(p.name);
      }
    }
    emit(s.copyWith(selectedPermissions: updated));
  }

  void selectAll() {
    final s = state;
    if (s is! RoleFormReady) return;
    final all = s.modules
        .expand((m) => m.permissions.map((p) => p.name))
        .toSet();
    emit(s.copyWith(selectedPermissions: all));
  }

  void deselectAll() {
    final s = state;
    if (s is! RoleFormReady) return;
    emit(s.copyWith(selectedPermissions: {}));
  }

  // Returns null on success, or an error message string on failure.
  Future<String?> submit(String name, String? description) async {
    final s = state;
    if (s is! RoleFormReady) return 'Invalid state';
    emit(RoleFormSubmitting(
      modules: s.modules,
      selectedPermissions: s.selectedPermissions,
    ));
    final formData = RoleFormData(
      name: name,
      description: description,
      permissions: s.selectedPermissions.toList(),
    );
    final result = s.editingRoleId != null
        ? await _update(s.editingRoleId!, formData)
        : await _create(formData);
    return result.fold(
      (f) {
        emit(RoleFormReady(
          modules: s.modules,
          selectedPermissions: s.selectedPermissions,
          editingRoleId: s.editingRoleId,
        ));
        return f.message;
      },
      (_) {
        emit(const RoleFormSuccess());
        return null;
      },
    );
  }
}
