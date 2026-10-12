import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../domain/entities/branch_entity.dart';
import '../../../domain/usecases/branches_usecases.dart';
import '../../cubit/branches_cubit.dart';
import '../../cubit/branches_state.dart';
import '../branch_form_dialog.dart';

class MobileBranchesPage extends StatelessWidget {
  const MobileBranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BranchesCubit(
        get: getIt<GetManagedBranchesUseCase>(),
        create: getIt<CreateBranchUseCase>(),
        update: getIt<UpdateBranchUseCase>(),
        delete: getIt<DeleteBranchUseCase>(),
      )..load(),
      child: const _MobileContent(),
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BranchesCubit, BranchesState>(
      builder: (context, state) {
        final cubit = context.read<BranchesCubit>();
        final l10n = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.t('branchesTitle'), style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showBranchForm(context, cubit, l10n),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSearchField(
                  hint: l10n.t('searchBranches'),
                  onChanged: cubit.search,
                ),
              ),
              Expanded(
                child: switch (state) {
                  BranchesInitial() || BranchesLoading() => ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: 5,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 100),
                      ),
                    ),
                  BranchesError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  BranchesLoaded(:final branches) when branches.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.store_outlined, size: 40),
                      message: l10n.t('noBranches'),
                      subtitle: l10n.t('noBranchesSubtitle'),
                    ),
                  BranchesLoaded(:final branches) => ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: branches.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) => _BranchCard(
                        branch: branches[i],
                        l10n: l10n,
                        onEdit: () => showBranchForm(context, cubit, l10n,
                            editing: branches[i]),
                        onDelete: () => confirmDeleteBranch(
                            context, branches[i], cubit, l10n),
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

class _BranchCard extends StatelessWidget {
  final BranchManagementEntity branch;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BranchCard({
    required this.branch,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  branch.name,
                  style: AppTextStyles.labelMd
                      .copyWith(color: AppColors.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (branch.isDefault) ...[
                const SizedBox(width: AppSpacing.xs),
                StatusBadge.custom(
                  label: l10n.t('tagMain'),
                  color: AppColors.primary,
                  bgColor: AppColors.primaryMuted,
                ),
              ],
            ],
          ),
          if (branch.address?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.mutedForeground),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    branch.address!,
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              AppButton.outline(
                label: l10n.edit,
                size: AppButtonSize.sm,
                leading: const Icon(Icons.edit_outlined, size: 14),
                onPressed: onEdit,
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.outline(
                label: l10n.delete,
                size: AppButtonSize.sm,
                leading: const Icon(Icons.delete_outline, size: 14),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
