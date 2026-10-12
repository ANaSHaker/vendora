import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../domain/entities/role_entity.dart';
import '../../domain/permission_labels.dart';
import '../../domain/usecases/roles_usecases.dart';
import '../cubit/roles_cubit.dart';
import '../cubit/roles_state.dart';

// ─── Page ──────────────────────────────────────────────────────────────────────

class RoleFormPage extends StatefulWidget {
  final RoleEntity? editing;

  const RoleFormPage({super.key, this.editing});

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String _searchQuery = '';
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.editing?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.editing?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool _validate(AppLocalizations l10n) {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = l10n.roleNameRequired);
      return false;
    }
    setState(() => _nameError = null);
    return true;
  }

  Future<void> _submit(
    BuildContext context,
    RoleFormCubit cubit,
    AppLocalizations l10n,
  ) async {
    if (!_validate(l10n)) return;
    final error = await cubit.submit(
      _nameCtrl.text.trim(),
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    if (error != null && context.mounted) {
      AppSnackbar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RoleFormCubit(
        getPermissions: getIt<GetPermissionsUseCase>(),
        create: getIt<CreateRoleUseCase>(),
        update: getIt<UpdateRoleUseCase>(),
      )..init(editing: widget.editing),
      child: _RoleFormContent(
        editing: widget.editing,
        nameCtrl: _nameCtrl,
        descCtrl: _descCtrl,
        nameError: _nameError,
        searchQuery: _searchQuery,
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        onNameErrorClear: () => setState(() => _nameError = null),
        onSubmit: _submit,
      ),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _RoleFormContent extends StatelessWidget {
  final RoleEntity? editing;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String? nameError;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNameErrorClear;
  final Future<void> Function(
    BuildContext,
    RoleFormCubit,
    AppLocalizations,
  ) onSubmit;

  const _RoleFormContent({
    required this.editing,
    required this.nameCtrl,
    required this.descCtrl,
    required this.nameError,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onNameErrorClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<RoleFormCubit, RoleFormState>(
      listener: (context, state) {
        if (state is RoleFormSuccess) {
          final msg = editing != null ? l10n.roleUpdated : l10n.roleCreated;
          // Pop and pass back the success message so parent can show snackbar
          Navigator.of(context).pop(msg);
        }
      },
      builder: (context, state) {
        final cubit = context.read<RoleFormCubit>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted = isDark
            ? AppColors.darkMutedForeground
            : AppColors.mutedForeground;
        final border = isDark ? AppColors.darkBorder : AppColors.border;

        final isSubmitting = state is RoleFormSubmitting;

        // Build subtitle: "X of Y permissions selected"
        String subtitle = '';
        if (state is RoleFormReady) {
          final total = state.modules
              .fold<int>(0, (s, m) => s + m.permissions.length);
          final selected = state.selectedPermissions.length;
          subtitle = l10n.editRoleSubtitle
              .replaceAll('{selected}', '$selected')
              .replaceAll('{total}', '$total');
        } else if (state is RoleFormSubmitting) {
          final total = state.modules
              .fold<int>(0, (s, m) => s + m.permissions.length);
          final selected = state.selectedPermissions.length;
          subtitle = l10n.editRoleSubtitle
              .replaceAll('{selected}', '$selected')
              .replaceAll('{total}', '$total');
        }

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: fg),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editing != null
                      ? l10n.editRoleTitle
                          .replaceAll('{name}', editing!.name)
                      : l10n.createRole,
                  style: AppTextStyles.h5.copyWith(color: fg),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
              ],
            ),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.only(right: AppSpacing.md),
                child: AppButton.primary(
                  label: editing != null
                      ? l10n.saveChanges
                      : l10n.createRole,
                  size: AppButtonSize.sm,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () => onSubmit(context, cubit, l10n),
                ),
              ),
            ],
          ),
          body: switch (state) {
            RoleFormInitial() || RoleFormLoadingPermissions() =>
              _FormShimmer(isDark: isDark, border: border),
            RoleFormError(:final message) => AppErrorWidget(
                message: message,
                onRetry: () => cubit.init(editing: editing),
              ),
            RoleFormReady() || RoleFormSubmitting() || RoleFormSuccess() =>
              _FormBody(
                cubit: cubit,
                state: state,
                nameCtrl: nameCtrl,
                descCtrl: descCtrl,
                nameError: nameError,
                searchQuery: searchQuery,
                onSearchChanged: onSearchChanged,
                onNameErrorClear: onNameErrorClear,
                isDark: isDark,
                fg: fg,
                muted: muted,
                border: border,
                l10n: l10n,
                isSubmitting: isSubmitting,
              ),
          },
        );
      },
    );
  }
}

// ─── Form Body ─────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  final RoleFormCubit cubit;
  final RoleFormState state;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String? nameError;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNameErrorClear;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color border;
  final AppLocalizations l10n;
  final bool isSubmitting;

  const _FormBody({
    required this.cubit,
    required this.state,
    required this.nameCtrl,
    required this.descCtrl,
    required this.nameError,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onNameErrorClear,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.border,
    required this.l10n,
    required this.isSubmitting,
  });

  List<PermissionModuleEntity> get _modules {
    if (state is RoleFormReady) return (state as RoleFormReady).modules;
    if (state is RoleFormSubmitting) {
      return (state as RoleFormSubmitting).modules;
    }
    return [];
  }

  Set<String> get _selectedPermissions {
    if (state is RoleFormReady) {
      return (state as RoleFormReady).selectedPermissions;
    }
    if (state is RoleFormSubmitting) {
      return (state as RoleFormSubmitting).selectedPermissions;
    }
    return {};
  }

  List<PermissionModuleEntity> get _filteredModules {
    if (searchQuery.isEmpty) return _modules;
    final q = searchQuery.toLowerCase();
    return _modules
        .map((module) {
          final filteredPerms = module.permissions
              .where((p) =>
                  p.label.toLowerCase().contains(q) ||
                  p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q))
              .toList();
          if (filteredPerms.isEmpty &&
              !module.label.toLowerCase().contains(q) &&
              !module.description.toLowerCase().contains(q)) {
            return null;
          }
          return PermissionModuleEntity(
            key: module.key,
            label: module.label,
            description: module.description,
            icon: module.icon,
            order: module.order,
            permissions:
                filteredPerms.isEmpty ? module.permissions : filteredPerms,
          );
        })
        .whereType<PermissionModuleEntity>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final filteredModules = _filteredModules;
    final selected = _selectedPermissions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Role Info Card ─────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: l10n.roleName,
                  hint: l10n.roleName,
                  controller: nameCtrl,
                  errorText: nameError,
                  enabled: !isSubmitting,
                  onChanged: (_) {
                    if (nameError != null) onNameErrorClear();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: '${l10n.roleDescription} (${l10n.optional})',
                  hint: l10n.roleDescription,
                  controller: descCtrl,
                  maxLines: 3,
                  enabled: !isSubmitting,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.base),

          // ── Permissions Toolbar ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AppButton.outline(
                      label: l10n.selectAll,
                      size: AppButtonSize.sm,
                      onPressed:
                          isSubmitting ? null : cubit.selectAll,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.outline(
                      label: l10n.deselectAll,
                      size: AppButtonSize.sm,
                      onPressed:
                          isSubmitting ? null : cubit.deselectAll,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSearchField(
                  hint: l10n.searchPermissions,
                  onChanged: onSearchChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Permission Modules ─────────────────────────────────────────────
          if (filteredModules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  l10n.noData,
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
              ),
            )
          else
            ...filteredModules.map(
              (module) => Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PermissionModuleSection(
                  module: module,
                  selectedPermissions: selected,
                  cubit: cubit,
                  isDark: isDark,
                  fg: fg,
                  muted: muted,
                  border: border,
                  surface: surface,
                  l10n: l10n,
                  isSubmitting: isSubmitting,
                ),
              ),
            ),

          // Bottom padding for scroll
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─── Permission Module Section ─────────────────────────────────────────────────

class _PermissionModuleSection extends StatefulWidget {
  final PermissionModuleEntity module;
  final Set<String> selectedPermissions;
  final RoleFormCubit cubit;
  final bool isDark;
  final Color fg;
  final Color muted;
  final Color border;
  final Color surface;
  final AppLocalizations l10n;
  final bool isSubmitting;

  const _PermissionModuleSection({
    required this.module,
    required this.selectedPermissions,
    required this.cubit,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.border,
    required this.surface,
    required this.l10n,
    required this.isSubmitting,
  });

  @override
  State<_PermissionModuleSection> createState() =>
      _PermissionModuleSectionState();
}

class _PermissionModuleSectionState
    extends State<_PermissionModuleSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final selected = widget.selectedPermissions;
    final modulePerms = module.permissions;
    final selectedInModule =
        modulePerms.where((p) => selected.contains(p.name)).length;
    final allSelected = selectedInModule == modulePerms.length;

    return Container(
      decoration: BoxDecoration(
        color: widget.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: widget.border),
      ),
      child: Column(
        children: [
          // ── Module Header ────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: _expanded
                ? const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  )
                : AppRadius.brLg,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Module icon (using text icon from module.icon as emoji fallback)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? AppColors.darkMuted
                          : AppColors.primaryMuted,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.tune_rounded,
                        size: AppSizes.iconMd,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Module name + description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          PermissionLabels.translateModule(module.key, module.label),
                          style: AppTextStyles.h6
                              .copyWith(color: widget.fg),
                        ),
                        if (module.description.isNotEmpty)
                          Text(
                            module.description,
                            style: AppTextStyles.bodyXs
                                .copyWith(color: widget.muted),
                          ),
                      ],
                    ),
                  ),
                  // X/Y badge
                  _CountBadge(
                    selected: selectedInModule,
                    total: modulePerms.length,
                    isDark: widget.isDark,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Select all checkbox
                  Tooltip(
                    message: widget.l10n.selectAllModule,
                    child: Checkbox(
                      value: allSelected
                          ? true
                          : selectedInModule > 0
                              ? null
                              : false,
                      tristate: true,
                      activeColor: AppColors.primary,
                      onChanged: widget.isSubmitting
                          ? null
                          : (v) => widget.cubit.toggleModule(
                                module,
                                v ?? true,
                              ),
                    ),
                  ),
                  // Expand/collapse chevron
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: AppSizes.iconMd,
                    color: widget.muted,
                  ),
                ],
              ),
            ),
          ),

          // ── Permissions List ──────────────────────────────────────────────
          if (_expanded) ...[
            Divider(height: 1, color: widget.border),
            ...modulePerms.asMap().entries.map((entry) {
              final i = entry.key;
              final perm = entry.value;
              final isChecked = selected.contains(perm.name);
              return Column(
                children: [
                  _PermissionRow(
                    permission: perm,
                    isChecked: isChecked,
                    isDark: widget.isDark,
                    fg: widget.fg,
                    muted: widget.muted,
                    isSubmitting: widget.isSubmitting,
                    onChanged: (_) =>
                        widget.cubit.togglePermission(perm.name),
                  ),
                  if (i < modulePerms.length - 1)
                    Divider(
                        height: 1,
                        color: widget.border,
                        indent: AppSpacing.base,
                        endIndent: AppSpacing.base),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ─── Permission Row ────────────────────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final PermissionEntity permission;
  final bool isChecked;
  final bool isDark;
  final Color fg;
  final Color muted;
  final bool isSubmitting;
  final ValueChanged<bool?> onChanged;

  const _PermissionRow({
    required this.permission,
    required this.isChecked,
    required this.isDark,
    required this.fg,
    required this.muted,
    required this.isSubmitting,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: isSubmitting ? null : onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        PermissionLabels.translatePermission(permission.name, permission.label),
        style: AppTextStyles.labelMd.copyWith(color: fg),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            permission.name,
            style: AppTextStyles.bodyXs.copyWith(
              color: muted,
              fontFamily: 'monospace',
            ),
          ),
          if (permission.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.px2),
              child: Text(
                permission.description,
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
            ),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

// ─── Count Badge ──────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int selected;
  final int total;
  final bool isDark;

  const _CountBadge({
    required this.selected,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selected > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.px2,
      ),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppColors.primaryMuted
            : isDark
                ? AppColors.darkMuted
                : AppColors.muted,
        borderRadius: AppRadius.brFull,
        border: Border.all(
          color: hasSelection
              ? AppColors.primaryLight
              : isDark
                  ? AppColors.darkBorder
                  : AppColors.border,
        ),
      ),
      child: Text(
        '$selected/$total',
        style: AppTextStyles.labelXs.copyWith(
          color:
              hasSelection ? AppColors.primary : AppColors.mutedForeground,
        ),
      ),
    );
  }
}

// ─── Form Shimmer ──────────────────────────────────────────────────────────────

class _FormShimmer extends StatelessWidget {
  final bool isDark;
  final Color border;

  const _FormShimmer({required this.isDark, required this.border});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        children: [
          const ShimmerBox(height: 120),
          const SizedBox(height: AppSpacing.base),
          const ShimmerBox(height: 80),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(height: 200),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(height: 200),
          const SizedBox(height: AppSpacing.sm),
          const ShimmerBox(height: 200),
        ],
      ),
    );
  }
}
