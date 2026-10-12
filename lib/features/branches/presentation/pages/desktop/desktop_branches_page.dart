import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../../domain/usecases/branches_usecases.dart';
import '../../cubit/branches_cubit.dart';
import '../../cubit/branches_state.dart';
import '../branch_form_dialog.dart';

class DesktopBranchesPage extends StatelessWidget {
  const DesktopBranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchesCubit(
        get: getIt<GetManagedBranchesUseCase>(),
        create: getIt<CreateBranchUseCase>(),
        update: getIt<UpdateBranchUseCase>(),
        delete: getIt<DeleteBranchUseCase>(),
      )..load(),
      child: const _BranchesContent(),
    );
  }
}

class _BranchesContent extends StatelessWidget {
  const _BranchesContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchesCubit, BranchesState>(
      builder: (context, state) {
        final cubit = context.read<BranchesCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('branchesTitle'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        Text(
                          l10n.t('branchesSubtitle'),
                          style:
                              AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('addBranch'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          showBranchForm(context, cubit, l10n),
                    ),
                  ],
                ),
              ),

              // ── Search ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: AppSearchField(
                    hint: l10n.t('searchBranches'),
                    onChanged: cubit.search,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    BranchesInitial() || BranchesLoading() =>
                      const ShimmerTableRows(),
                    BranchesError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    BranchesLoaded(:final branches)
                        when branches.isEmpty =>
                      AppEmptyState(
                        icon:
                            const Icon(Icons.store_outlined, size: 40),
                        message: l10n.t('noBranches'),
                        subtitle: l10n.t('noBranchesSubtitle'),
                        action: AppButton.primary(
                          label: l10n.t('addBranch'),
                          onPressed: () =>
                              showBranchForm(context, cubit, l10n),
                        ),
                      ),
                    BranchesLoaded(:final branches) => _BranchesTable(
                        branches: branches,
                        isDark: isDark,
                        l10n: l10n,
                        onEdit: (b) => showBranchForm(context, cubit,
                            l10n, editing: b),
                        onDelete: (b) =>
                            confirmDeleteBranch(context, b, cubit, l10n),
                      ),
                  },
                ),
              ),
              const SizedBox(height: AppSizes.desktopContentPadding),
            ],
          ),
        );
      },
    );
  }
}

// ── Branches Table ────────────────────────────────────────────────────────────

class _BranchesTable extends StatelessWidget {
  final List<BranchManagementEntity> branches;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(BranchManagementEntity) onEdit;
  final void Function(BranchManagementEntity) onDelete;

  const _BranchesTable({
    required this.branches,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Header row
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(l10n.t('colBranchName'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(l10n.t('colBranchLocation'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(l10n.t('colBranchTags'),
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: 80),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Data rows
            Expanded(
              child: ListView.separated(
                itemCount: branches.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final b = branches[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        // Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            b.name,
                            style: AppTextStyles.labelSm
                                .copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Location
                        Expanded(
                          flex: 3,
                          child: Text(
                            b.address?.isNotEmpty == true
                                ? b.address!
                                : '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Tags
                        SizedBox(
                          width: 120,
                          child: b.isDefault
                              ? StatusBadge.custom(
                                  label: l10n.t('tagMain'),
                                  color: AppColors.primary,
                                  bgColor: AppColors.primaryMuted,
                                )
                              : const SizedBox.shrink(),
                        ),
                        // Actions
                        SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppIconButton(
                                icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 14),
                                onPressed: () => onEdit(b),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.edit,
                              ),
                              AppIconButton(
                                icon: const Icon(
                                    Icons.delete_outline,
                                    size: 14),
                                onPressed: () => onDelete(b),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.delete,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
