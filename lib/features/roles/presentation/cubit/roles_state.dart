import '../../domain/entities/role_entity.dart';

sealed class RolesState {
  const RolesState();
}

class RolesInitial extends RolesState {
  const RolesInitial();
}

class RolesLoading extends RolesState {
  const RolesLoading();
}

class RolesLoaded extends RolesState {
  final List<RoleEntity> roles;
  final String search;
  const RolesLoaded({required this.roles, this.search = ''});
}

class RolesError extends RolesState {
  final String message;
  const RolesError(this.message);
}

// ── Role Form State ────────────────────────────────────────────────────────────

sealed class RoleFormState {
  const RoleFormState();
}

class RoleFormInitial extends RoleFormState {
  const RoleFormInitial();
}

class RoleFormLoadingPermissions extends RoleFormState {
  const RoleFormLoadingPermissions();
}

class RoleFormReady extends RoleFormState {
  final List<PermissionModuleEntity> modules;
  final Set<String> selectedPermissions;
  final String? editingRoleId;
  const RoleFormReady({
    required this.modules,
    required this.selectedPermissions,
    this.editingRoleId,
  });

  RoleFormReady copyWith({Set<String>? selectedPermissions}) => RoleFormReady(
        modules: modules,
        selectedPermissions: selectedPermissions ?? this.selectedPermissions,
        editingRoleId: editingRoleId,
      );
}

class RoleFormError extends RoleFormState {
  final String message;
  const RoleFormError(this.message);
}

class RoleFormSubmitting extends RoleFormState {
  final List<PermissionModuleEntity> modules;
  final Set<String> selectedPermissions;
  const RoleFormSubmitting({
    required this.modules,
    required this.selectedPermissions,
  });
}

class RoleFormSuccess extends RoleFormState {
  const RoleFormSuccess();
}
