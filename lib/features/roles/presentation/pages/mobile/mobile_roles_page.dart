import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../domain/entities/role_entity.dart';
import '../../../domain/usecases/roles_usecases.dart';
import '../../cubit/roles_cubit.dart';
import '../../cubit/roles_state.dart';
import '../role_form_page.dart';

// ─── Page ──────────────────────────────────────────────────────────────────────

class MobileRolesPage extends StatelessWidget {
  const MobileRolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RolesCubit(
        get: getIt<GetRolesUseCase>(),
        delete: getIt<DeleteRoleUseCase>(),
        clone: getIt<CloneRoleUseCase>(),
      )..load(),
      child: const _MobileRolesContent(),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _MobileRolesContent extends StatelessWidget {
  const _MobileRolesContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<RolesCubit>();

    return BlocBuilder<RolesCubit, RolesState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted = isDark
            ? AppColors.darkMutedForeground
            : AppColors.mutedForeground;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: bg,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.rolesAndPermissions,
                  style: AppTextStyles.h5.copyWith(color: fg),
                ),
                Text(
                  l10n.rolesSubtitle,
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
            actions: [
              Padding(
                padding:
                    const EdgeInsets.only(right: AppSpacing.md),
                child: AppButton.primary(
                  label: l10n.newRole,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.add, size: 14),
                  onPressed: () => _navigateToForm(context, cubit),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Search ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.sm,
                  AppSpacing.base,
                  AppSpacing.sm,
                ),
                child: AppSearchField(
                  hint: l10n.searchRoles,
                  onChanged: cubit.search,
                ),
              ),

              // ── List / State ───────────────────────────────────────────────
              Expanded(
                child: switch (state) {
                  RolesInitial() || RolesLoading() =>
                    ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      itemCount: 5,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, __) =>
                          const ShimmerBox(height: 160),
                    ),
                  RolesError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.load,
                    ),
                  RolesLoaded(:final roles) when roles.isEmpty =>
                    Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(AppSpacing.xl),
                        child: AppEmptyState(
                          icon: const Icon(
                            Icons.shield_outlined,
                            size: 40,
                          ),
                          message: l10n.noRolesFound,
                          subtitle: l10n.noRolesFoundSubtitle,
                          action: AppButton.primary(
                            label: l10n.newRole,
                            onPressed: () =>
                                _navigateToForm(context, cubit),
                          ),
                        ),
                      ),
                    ),
                  RolesLoaded(:final roles) => ListView.separated(
                      padding:
                          const EdgeInsets.all(AppSpacing.base),
                      itemCount: roles.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => _MobileRoleCard(
                        role: roles[i],
                        cubit: cubit,
                        l10n: l10n,
                        isDark: isDark,
                      ),
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _navigateToForm(
    BuildContext context,
    RolesCubit cubit, {
    RoleEntity? editing,
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RoleFormPage(editing: editing),
      ),
    );
    if (!context.mounted) return;
    cubit.refresh();
    if (result != null) {
      AppSnackbar.success(context, result);
    }
  }
}

// ─── Mobile Role Card ──────────────────────────────────────────────────────────

class _MobileRoleCard extends StatefulWidget {
  final RoleEntity role;
  final RolesCubit cubit;
  final AppLocalizations l10n;
  final bool isDark;

  const _MobileRoleCard({
    required this.role,
    required this.cubit,
    required this.l10n,
    required this.isDark,
  });

  @override
  State<_MobileRoleCard> createState() => _MobileRoleCardState();
}

class _MobileRoleCardState extends State<_MobileRoleCard> {
  bool _cloning = false;
  bool _deleting = false;

  Future<void> _handleEdit() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RoleFormPage(editing: widget.role),
      ),
    );
    if (!context.mounted) return;
    widget.cubit.refresh();
    if (result != null) {
      AppSnackbar.success(context, result);
    }
  }

  Future<void> _handleClone() async {
    setState(() => _cloning = true);
    final ok = await widget.cubit.cloneRole(widget.role.id);
    if (mounted) {
      setState(() => _cloning = false);
      if (ok) {
        AppSnackbar.success(context, widget.l10n.roleCloningSuccess);
      } else {
        AppSnackbar.error(context, widget.l10n.error);
      }
    }
  }

  Future<void> _handleDelete() async {
    final role = widget.role;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: widget.l10n.deleteRoleTitle,
      message: widget.l10n.deleteRoleMsg
          .replaceAll('{name}', role.name),
      confirmLabel: widget.l10n.delete,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    final ok = await widget.cubit.deleteRole(role.id);
    if (mounted) {
      setState(() => _deleting = false);
      if (ok) {
        AppSnackbar.success(context, widget.l10n.roleDeleted);
      } else {
        AppSnackbar.error(context, widget.l10n.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final isDark = widget.isDark;
    final l10n = widget.l10n;

    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMuted,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Center(
                    child: Icon(
                      role.isOwner || role.isProtected
                          ? Icons.lock_rounded
                          : Icons.shield_outlined,
                      size: AppSizes.iconXl,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              role.name,
                              style:
                                  AppTextStyles.h6.copyWith(color: fg),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (role.isSystem) ...[
                            const SizedBox(width: AppSpacing.xs),
                            _SystemBadge(
                                label: l10n.roleSystem,
                                isDark: isDark),
                          ],
                        ],
                      ),
                      if (role.description != null &&
                          role.description!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          role.description!,
                          style: AppTextStyles.bodySm
                              .copyWith(color: muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Divider(height: 1, color: border),

          // ── Stats Row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: AppSizes.iconMd, color: muted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${role.usersCount}',
                  style: AppTextStyles.labelMd.copyWith(color: fg),
                ),
                const SizedBox(width: AppSpacing.px2),
                Text(
                  l10n.roleEmployees,
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: border,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                ),
                Icon(Icons.key_outlined,
                    size: AppSizes.iconMd, color: muted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  role.isOwner
                      ? l10n.allPermissions
                      : '${role.permissions.length}',
                  style: AppTextStyles.labelMd.copyWith(color: fg),
                ),
                if (!role.isOwner) ...[
                  const SizedBox(width: AppSpacing.px2),
                  Text(
                    l10n.rolePermissions,
                    style:
                        AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Divider(height: 1, color: border),

          // ── Footer Actions ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!role.isOwner && !role.isProtected) ...[
                  AppIconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: _deleting ? null : _handleDelete,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    tooltip: l10n.deleteRoleAction,
                    isLoading: _deleting,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: _cloning ? null : _handleClone,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    tooltip: l10n.cloneRole,
                    isLoading: _cloning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppIconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _handleEdit,
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.sm,
                    tooltip: l10n.editRole,
                  ),
                ] else ...[
                  if (!role.isOwner)
                    AppIconButton(
                      icon: const Icon(Icons.copy_outlined),
                      onPressed: _cloning ? null : _handleClone,
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      tooltip: l10n.cloneRole,
                      isLoading: _cloning,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── System Badge ──────────────────────────────────────────────────────────────

class _SystemBadge extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SystemBadge({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.px2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMuted : AppColors.primaryMuted,
        borderRadius: AppRadius.brFull,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryLight,
        ),
      ),
      child: Text(
        label,
        style:
            AppTextStyles.labelXs.copyWith(color: AppColors.primary),
      ),
    );
  }
}
