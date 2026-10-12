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
import '../../cubit/users_cubit.dart';
import '../../cubit/users_state.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/users_usecases.dart';
import '../user_form_dialog.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class DesktopUsersPage extends StatelessWidget {
  const DesktopUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(
        get: getIt<GetUsersUseCase>(),
        create: getIt<CreateUserUseCase>(),
        update: getIt<UpdateUserUseCase>(),
        delete: getIt<DeleteUserUseCase>(),
      )..load(),
      child: const _DesktopUsersContent(),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _DesktopUsersContent extends StatelessWidget {
  const _DesktopUsersContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        final cubit = context.read<UsersCubit>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page Header ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('users'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        Text(
                          l10n.t('usersSubtitle'),
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('addEmployee'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () => showUserForm(context, cubit, l10n),
                    ),
                  ],
                ),
              ),

              // ── Search bar ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: SizedBox(
                  width: 320,
                  child: AppSearchField(
                    hint: l10n.t('searchEmployees'),
                    onChanged: cubit.search,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table / State ─────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.desktopContentPadding,
                    0,
                    AppSizes.desktopContentPadding,
                    AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    UsersInitial() || UsersLoading() =>
                      const ShimmerTableRows(rows: 7),
                    UsersError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.load,
                      ),
                    UsersLoaded(:final users) when users.isEmpty =>
                      Center(
                        child: AppEmptyState(
                          icon: const Icon(
                            Icons.people_outline_rounded,
                            size: 40,
                          ),
                          message: l10n.t('noEmployees'),
                          subtitle: l10n.t('noEmployeesSubtitle'),
                          action: AppButton.primary(
                            label: l10n.t('addEmployee'),
                            onPressed: () =>
                                showUserForm(context, cubit, l10n),
                          ),
                        ),
                      ),
                    UsersLoaded(:final users) => _UsersTable(
                        users: users,
                        cubit: cubit,
                        l10n: l10n,
                        isDark: isDark,
                      ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Table ───────────────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  final List<UserEntity> users;
  final UsersCubit cubit;
  final AppLocalizations l10n;
  final bool isDark;

  const _UsersTable({
    required this.users,
    required this.cubit,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brLg,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          children: [
            // Header row
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      l10n.t('colEmployee'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.t('colRole'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      l10n.t('colStatus'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.t('colLastLogin'),
                      style: AppTextStyles.tableHeader.copyWith(color: muted),
                    ),
                  ),
                  const SizedBox(width: 88), // actions column
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Data rows
            Expanded(
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: border),
                itemBuilder: (context, i) => _UserRow(
                  user: users[i],
                  cubit: cubit,
                  l10n: l10n,
                  isDark: isDark,
                  border: border,
                  fg: fg,
                  muted: muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Table row ────────────────────────────────────────────────────────────────

class _UserRow extends StatefulWidget {
  final UserEntity user;
  final UsersCubit cubit;
  final AppLocalizations l10n;
  final bool isDark;
  final Color border;
  final Color fg;
  final Color muted;

  const _UserRow({
    required this.user,
    required this.cubit,
    required this.l10n,
    required this.isDark,
    required this.border,
    required this.fg,
    required this.muted,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  String _formatDate(DateTime? dt) {
    if (dt == null) return widget.l10n.t('never');
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final user = widget.user;
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: widget.l10n.t('deleteEmployeeTitle'),
      message: widget.l10n
          .t('deleteEmployeeMsg')
          .replaceAll('{name}', user.name),
      confirmLabel: widget.l10n.delete,
      isDestructive: true,
      onConfirm: () {},
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await widget.cubit.deleteUser(user.id);
    if (context.mounted) {
      if (ok) {
        AppSnackbar.success(context, widget.l10n.t('employeeDeleted'));
      } else {
        AppSnackbar.error(context, widget.l10n.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isDark = widget.isDark;
    final hoverColor = isDark
        ? AppColors.darkMuted.withValues(alpha: 0.5)
        : AppColors.muted.withValues(alpha: 0.5);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? hoverColor : Colors.transparent,
        height: AppSizes.tableRowHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        child: Row(
          children: [
            // Employee cell (avatar + name + email)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _UserAvatar(name: user.name, size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.labelMd
                              .copyWith(color: widget.fg),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: AppTextStyles.bodyXs
                              .copyWith(color: widget.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Roles cell
            Expanded(
              flex: 3,
              child: user.roles.isEmpty
                  ? Text(
                      '—',
                      style: AppTextStyles.tableCell
                          .copyWith(color: widget.muted),
                    )
                  : Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: user.roles
                          .take(3)
                          .map((r) => _RoleBadge(
                                name: r.name,
                                isDark: isDark,
                              ))
                          .toList(),
                    ),
            ),

            // Status cell
            SizedBox(
              width: 100,
              child: Center(
                child: _StatusBadge(
                  isActive: user.isActive,
                  l10n: widget.l10n,
                ),
              ),
            ),

            // Last login cell
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(user.lastLoginAt),
                style: AppTextStyles.tableCell.copyWith(color: widget.muted),
              ),
            ),

            // Actions
            SizedBox(
              width: 88,
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 120),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppIconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmDelete(context),
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      tooltip: widget.l10n.delete,
                    ),
                    AppIconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => showUserForm(
                        context,
                        widget.cubit,
                        widget.l10n,
                        editing: user,
                      ),
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.sm,
                      tooltip: widget.l10n.edit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── User avatar ─────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _UserAvatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.labelSm.copyWith(
            color: AppColors.white,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

// ─── Role badge ──────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String name;
  final bool isDark;

  const _RoleBadge({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkMuted : AppColors.primaryMuted,
        borderRadius: AppRadius.brFull,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryLight,
        ),
      ),
      child: Text(
        name,
        style: AppTextStyles.labelXs.copyWith(
          color: AppColors.primary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final AppLocalizations l10n;

  const _StatusBadge({required this.isActive, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.successLight : AppColors.muted,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        isActive ? l10n.t('statusActive') : l10n.t('statusInactive'),
        style: AppTextStyles.labelXs.copyWith(
          color: isActive
              ? AppColors.successForeground
              : AppColors.mutedForeground,
        ),
      ),
    );
  }
}
