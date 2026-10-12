import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../cubit/users_cubit.dart';
import '../../cubit/users_state.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/users_usecases.dart';
import '../user_form_dialog.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────

class MobileUsersPage extends StatelessWidget {
  const MobileUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersCubit(
        get: getIt<GetUsersUseCase>(),
        create: getIt<CreateUserUseCase>(),
        update: getIt<UpdateUserUseCase>(),
        delete: getIt<DeleteUserUseCase>(),
      )..load(),
      child: const _MobileUsersContent(),
    );
  }
}

// ─── Content ──────────────────────────────────────────────────────────────────

class _MobileUsersContent extends StatelessWidget {
  const _MobileUsersContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<UsersCubit, UsersState>(
      builder: (context, state) {
        final cubit = context.read<UsersCubit>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor =
            isDark ? AppColors.darkBackground : AppColors.background;
        final surfaceColor =
            isDark ? AppColors.darkSurface : AppColors.surface;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: surfaceColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(
              l10n.t('users'),
              style: AppTextStyles.h6.copyWith(color: fg),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: borderColor),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showUserForm(context, cubit, l10n),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: AppColors.white),
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.base,
                  AppSpacing.xs,
                ),
                child: AppSearchField(
                  hint: l10n.t('searchEmployees'),
                  onChanged: cubit.search,
                ),
              ),

              // List
              Expanded(
                child: switch (state) {
                  UsersInitial() || UsersLoading() => ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      itemCount: 6,
                      itemBuilder: (_, __) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 90),
                      ),
                    ),
                  UsersError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.load,
                    ),
                  UsersLoaded(:final users) when users.isEmpty => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
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
                    ),
                  UsersLoaded(:final users) => RefreshIndicator(
                      onRefresh: () async => cubit.load(),
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.base,
                          AppSpacing.sm,
                          AppSpacing.base,
                          AppSpacing.xl * 4,
                        ),
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => _UserCard(
                          user: users[i],
                          cubit: cubit,
                          l10n: l10n,
                          isDark: isDark,
                        ),
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
}

// ─── User card ────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserEntity user;
  final UsersCubit cubit;
  final AppLocalizations l10n;
  final bool isDark;

  const _UserCard({
    required this.user,
    required this.cubit,
    required this.l10n,
    required this.isDark,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return l10n.t('never');
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar + name + email + status badge
            Row(
              children: [
                _UserAvatar(name: user.name, size: 40),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.labelMd.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.email,
                        style:
                            AppTextStyles.bodyXs.copyWith(color: muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusBadge(isActive: user.isActive, l10n: l10n),
              ],
            ),

            // Row 2: Role chips (if any)
            if (user.roles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: user.roles
                    .take(4)
                    .map((r) => _RoleBadge(name: r.name, isDark: isDark))
                    .toList(),
              ),
            ],

            // Row 3: Last login + edit button
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: muted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${l10n.t("colLastLogin")}: ${_formatDate(user.lastLoginAt)}',
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () =>
                      showUserForm(context, cubit, l10n, editing: user),
                  color: muted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: l10n.edit,
                ),
              ],
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
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.white,
            fontSize: size * 0.38,
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
        style: AppTextStyles.labelXs.copyWith(color: AppColors.primary),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
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

