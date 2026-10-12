import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../roles/domain/entities/role_entity.dart';
import '../../../roles/domain/permission_labels.dart';
import '../../../roles/domain/usecases/roles_usecases.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/users_usecases.dart';
import '../cubit/users_cubit.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────

Future<void> showUserForm(
  BuildContext context,
  UsersCubit cubit,
  AppLocalizations l10n, {
  UserEntity? editing,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _UserFormDialog(editing: editing, l10n: l10n),
    ),
  );
}

// ─── Dialog widget ───────────────────────────────────────────────────────────

class _UserFormDialog extends StatefulWidget {
  final UserEntity? editing;
  final AppLocalizations l10n;

  const _UserFormDialog({this.editing, required this.l10n});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;

  // Basic form state
  bool _obscurePassword = true;
  bool _isActive = true;
  bool _submitting = false;

  // Roles state
  List<RoleEntity> _roles = [];
  bool _rolesLoading = true;
  final Set<String> _selectedRoleIds = {};

  // Direct permissions state
  List<PermissionModuleEntity> _permModules = [];
  bool _permsLoading = true;
  Set<String> _selectedDirectPerms = {};
  bool _directPermsExpanded = false;

  // Validation
  String? _nameError;
  String? _emailError;
  String? _passwordError;

  bool get _isEditing => widget.editing != null;

  // All permissions covered by currently selected roles
  Set<String> get _rolesCoveredPerms {
    final covered = <String>{};
    for (final role in _roles) {
      if (_selectedRoleIds.contains(role.id)) {
        covered.addAll(role.permissions);
      }
    }
    return covered;
  }

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _passwordCtrl = TextEditingController();
    _isActive = e?.isActive ?? true;

    if (e != null) {
      _selectedRoleIds.addAll(e.roles.map((r) => r.id));
      _selectedDirectPerms = Set<String>.from(e.directPermissions);
      // Also fetch full user to get direct_permissions (list endpoint may omit them)
      _loadFullUser(e.id);
    }

    _loadRoles();
    _loadPermissions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFullUser(String id) async {
    final result = await getIt<GetUserByIdUseCase>()(id);
    if (!mounted) return;
    result.fold((_) {}, (user) {
      setState(() {
        _isActive = user.isActive;
        _selectedRoleIds
          ..clear()
          ..addAll(user.roles.map((r) => r.id));
        _selectedDirectPerms = Set<String>.from(user.directPermissions);
      });
    });
  }

  Future<void> _loadRoles() async {
    final result = await getIt<GetRolesUseCase>()();
    if (!mounted) return;
    setState(() {
      _rolesLoading = false;
      result.fold((_) {}, (roles) => _roles = roles);
    });
  }

  Future<void> _loadPermissions() async {
    final result = await getIt<GetPermissionsUseCase>()();
    if (!mounted) return;
    setState(() {
      _permsLoading = false;
      result.fold((_) {}, (modules) => _permModules = modules);
    });
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    String? nameErr;
    String? emailErr;
    String? passErr;

    if (name.isEmpty) nameErr = widget.l10n.t('employeeName');
    if (email.isEmpty || !email.contains('@')) {
      emailErr = widget.l10n.t('employeeEmail');
    }
    if (!_isEditing && password.isEmpty) {
      passErr = widget.l10n.t('employeePassword');
    } else if (password.isNotEmpty && password.length < 8) {
      passErr = widget.l10n.t('employeePasswordHint');
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
    });

    return nameErr == null && emailErr == null && passErr == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    setState(() => _submitting = true);

    final data = UserFormData(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
      roleIds: _selectedRoleIds.toList(),
      isActive: _isActive,
      directPermissions: _selectedDirectPerms.toList(),
    );

    final cubit = context.read<UsersCubit>();
    bool ok;
    if (_isEditing) {
      ok = await cubit.updateUser(widget.editing!.id, data);
    } else {
      ok = await cubit.createUser(data);
    }

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing
                              ? l10n.t('editEmployeeTitle')
                              : l10n.t('addEmployeeTitle'),
                          style: AppTextStyles.h5.copyWith(color: fg),
                        ),
                        if (_isEditing)
                          Text(
                            widget.editing!.name,
                            style: AppTextStyles.bodyXs.copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.brMd,
                          border: Border.all(color: border),
                        ),
                        child: Icon(Icons.close_rounded, size: 16, color: muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // ── Scrollable body ──────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name
                    AppTextField(
                      label: '${l10n.t('employeeName')} *',
                      hint: l10n.t('employeeName'),
                      controller: _nameCtrl,
                      errorText: _nameError,
                      autofocus: true,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Email
                    AppTextField(
                      label: '${l10n.t('employeeEmail')} *',
                      hint: l10n.t('employeeEmail'),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password
                    AppTextField(
                      label: _isEditing
                          ? l10n.t('employeePassword')
                          : '${l10n.t('employeePassword')} *',
                      hint: l10n.t('employeePasswordHint'),
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      errorText: _passwordError,
                      onChanged: (_) => setState(() => _passwordError = null),
                      suffix: GestureDetector(
                        onTap: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Roles section ────────────────────────────────────────
                    Text(
                      l10n.t('employeeRoles'),
                      style: AppTextStyles.labelMd.copyWith(color: fg),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.t('rolesSelectHint'),
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Role list
                    _rolesLoading
                        ? Column(
                            children: List.generate(
                              3,
                              (_) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: const ShimmerBox(height: 56),
                              ),
                            ),
                          )
                        : _roles.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  border: Border.all(color: border),
                                  borderRadius: AppRadius.brMd,
                                ),
                                child: Text(
                                  l10n.noData,
                                  style: AppTextStyles.bodyXs
                                      .copyWith(color: muted),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : Column(
                                children: _roles.map((role) {
                                  final selected =
                                      _selectedRoleIds.contains(role.id);
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.xs,
                                    ),
                                    child: _RoleItem(
                                      role: role,
                                      selected: selected,
                                      isDark: isDark,
                                      border: border,
                                      fg: fg,
                                      muted: muted,
                                      l10n: l10n,
                                      onToggle: () {
                                        setState(() {
                                          if (selected) {
                                            _selectedRoleIds.remove(role.id);
                                          } else {
                                            _selectedRoleIds.add(role.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Active toggle ────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkMuted : AppColors.muted,
                        borderRadius: AppRadius.brMd,
                        border: Border.all(color: border),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 2,
                        ),
                        title: Text(
                          l10n.t('employeeActive'),
                          style: AppTextStyles.labelSm.copyWith(color: fg),
                        ),
                        subtitle: Text(
                          l10n.t('employeeActiveHint'),
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                        ),
                        value: _isActive,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // ── Advanced: direct permissions ─────────────────────────
                    _DirectPermsSection(
                      expanded: _directPermsExpanded,
                      loading: _permsLoading,
                      modules: _permModules,
                      selectedDirectPerms: _selectedDirectPerms,
                      rolesCoveredPerms: _rolesCoveredPerms,
                      isDark: isDark,
                      border: border,
                      fg: fg,
                      muted: muted,
                      l10n: l10n,
                      onToggleExpand: () => setState(
                        () => _directPermsExpanded = !_directPermsExpanded,
                      ),
                      onTogglePerm: (name) => setState(() {
                        if (_selectedDirectPerms.contains(name)) {
                          _selectedDirectPerms.remove(name);
                        } else {
                          _selectedDirectPerms.add(name);
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    size: AppButtonSize.sm,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: l10n.save,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
                    size: AppButtonSize.sm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Advanced: direct permissions section ────────────────────────────────────

class _DirectPermsSection extends StatelessWidget {
  final bool expanded;
  final bool loading;
  final List<PermissionModuleEntity> modules;
  final Set<String> selectedDirectPerms;
  final Set<String> rolesCoveredPerms;
  final bool isDark;
  final Color border;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback onToggleExpand;
  final ValueChanged<String> onTogglePerm;

  const _DirectPermsSection({
    required this.expanded,
    required this.loading,
    required this.modules,
    required this.selectedDirectPerms,
    required this.rolesCoveredPerms,
    required this.isDark,
    required this.border,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onToggleExpand,
    required this.onTogglePerm,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        children: [
          // ── Header (always visible) ──────────────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            borderRadius: expanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.md),
                    topRight: Radius.circular(AppRadius.md),
                  )
                : AppRadius.brMd,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Icon(Icons.tune_outlined, size: 16, color: muted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.t('advancedDirectPerms'),
                      style: AppTextStyles.labelSm.copyWith(color: muted),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body ────────────────────────────────────────────────
          if (expanded) ...[
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                l10n.t('directPermissionsHint'),
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
            ),
            if (loading)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: const ShimmerBox(height: 40),
                    ),
                  ),
                ),
              )
            else
              ...modules.map(
                (module) => _DirectPermModule(
                  module: module,
                  selectedDirectPerms: selectedDirectPerms,
                  rolesCoveredPerms: rolesCoveredPerms,
                  isDark: isDark,
                  surface: surface,
                  border: border,
                  fg: fg,
                  muted: muted,
                  l10n: l10n,
                  onToggle: onTogglePerm,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─── Permission module group ──────────────────────────────────────────────────

class _DirectPermModule extends StatelessWidget {
  final PermissionModuleEntity module;
  final Set<String> selectedDirectPerms;
  final Set<String> rolesCoveredPerms;
  final bool isDark;
  final Color surface;
  final Color border;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final ValueChanged<String> onToggle;

  const _DirectPermModule({
    required this.module,
    required this.selectedDirectPerms,
    required this.rolesCoveredPerms,
    required this.isDark,
    required this.surface,
    required this.border,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module label
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            PermissionLabels.translateModule(module.key, module.label).toUpperCase(),
            style: AppTextStyles.labelXs.copyWith(
              color: muted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        // Permissions
        ...module.permissions.map((perm) {
          final fromRole = rolesCoveredPerms.contains(perm.name);
          final directSelected = selectedDirectPerms.contains(perm.name);
          return _DirectPermRow(
            permission: perm,
            fromRole: fromRole,
            directSelected: directSelected,
            isDark: isDark,
            border: border,
            fg: fg,
            muted: muted,
            l10n: l10n,
            onToggle: fromRole ? null : () => onToggle(perm.name),
          );
        }),
        Divider(height: 1, color: border),
      ],
    );
  }
}

// ─── Single permission row ────────────────────────────────────────────────────

class _DirectPermRow extends StatelessWidget {
  final PermissionEntity permission;
  final bool fromRole;
  final bool directSelected;
  final bool isDark;
  final Color border;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback? onToggle;

  const _DirectPermRow({
    required this.permission,
    required this.fromRole,
    required this.directSelected,
    required this.isDark,
    required this.border,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = fromRole || directSelected;
    final labelColor = fromRole ? muted : fg;

    return InkWell(
      onTap: fromRole ? null : onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: effectiveSelected,
                onChanged: fromRole ? null : (_) => onToggle?.call(),
                activeColor: fromRole ? muted : AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          PermissionLabels.translatePermission(permission.name, permission.label),
                          style: AppTextStyles.labelSm.copyWith(
                            color: labelColor,
                          ),
                        ),
                      ),
                      if (fromRole) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkMuted
                                : AppColors.muted,
                            borderRadius: AppRadius.brXs,
                          ),
                          child: Text(
                            l10n.t('fromRole'),
                            style: AppTextStyles.labelXs.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    permission.name,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: muted,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Role item ───────────────────────────────────────────────────────────────

class _RoleItem extends StatelessWidget {
  final RoleEntity role;
  final bool selected;
  final bool isDark;
  final Color border;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback onToggle;

  const _RoleItem({
    required this.role,
    required this.selected,
    required this.isDark,
    required this.border,
    required this.fg,
    required this.muted,
    required this.l10n,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activeBorder = selected ? AppColors.primary : border;
    final activeBg = selected
        ? (isDark
            ? AppColors.primaryMuted.withValues(alpha: 0.15)
            : AppColors.primaryMuted)
        : Colors.transparent;

    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: activeBorder),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: AppTextStyles.labelMd.copyWith(color: fg),
                    ),
                    Text(
                      role.description != null && role.description!.isNotEmpty
                          ? role.description!
                          : '${role.permissions.length} ${l10n.t('permissionsCount')}',
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
