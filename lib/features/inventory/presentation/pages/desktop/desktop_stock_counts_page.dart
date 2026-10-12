import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/stock_count_entities.dart';
import '../../cubit/stock_count_cubit.dart';
import '../../cubit/stock_count_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String iso) {
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

StatusBadge _stockCountStatusBadge(String status, AppLocalizations l10n) {
  final label = switch (status) {
    'draft' => l10n.t('statusDraft'),
    'posted' => l10n.t('statusPosted'),
    'cancelled' => l10n.t('statusCancelled'),
    _ => status,
  };
  return switch (status) {
    'posted' => StatusBadge.custom(
        label: label,
        color: AppColors.primary,
        bgColor: AppColors.primaryMuted,
      ),
    'cancelled' => StatusBadge.custom(
        label: label,
        color: AppColors.destructive,
        bgColor: AppColors.destructive.withValues(alpha: 0.1),
      ),
    _ => StatusBadge.custom(
        label: label,
        color: AppColors.mutedForeground,
        bgColor: AppColors.muted,
      ),
  };
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopStockCountsPage extends StatelessWidget {
  const DesktopStockCountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StockCountCubit(
        getStockCounts: getIt(),
        getStockCountById: getIt(),
        createStockCount: getIt(),
        postStockCount: getIt(),
        deleteStockCount: getIt(),
      )..load(),
      child: const _StockCountsContent(),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _StockCountsContent extends StatelessWidget {
  const _StockCountsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StockCountCubit, StockCountState>(
      builder: (context, state) {
        final cubit = context.read<StockCountCubit>();
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('stockCounts'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        if (state is StockCountLoaded)
                          Text(
                            '${state.meta.total} ${l10n.t("stockCountsTotal")}',
                            style: AppTextStyles.bodySm
                                .copyWith(color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('newStockCount'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () => context.go('/stock-counts/create'),
                    ),
                  ],
                ),
              ),

              // Toolbar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: Row(
                  children: [
                    SizedBox(
                      width: 280,
                      child: AppSearchField(
                        hint: l10n.t('searchStockCounts'),
                        onChanged: cubit.search,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 180,
                      child: AppSelectField<String?>(
                        hint: l10n.t('allStatuses'),
                        value: state is StockCountLoaded
                            ? state.statusFilter
                            : null,
                        options: [
                          AppSelectOption(
                              value: null,
                              label: l10n.t('allStatuses')),
                          AppSelectOption(
                              value: 'draft',
                              label: l10n.t('statusDraft')),
                          AppSelectOption(
                              value: 'posted',
                              label: l10n.t('statusPosted')),
                          AppSelectOption(
                              value: 'cancelled',
                              label: l10n.t('statusCancelled')),
                        ],
                        onChanged: cubit.filterByStatus,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: switch (state) {
                    StockCountInitial() || StockCountLoading() =>
                      const ShimmerTableRows(),
                    StockCountError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    StockCountLoaded(:final counts)
                        when counts.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.inventory_2_outlined,
                            size: 40),
                        message: l10n.t('noStockCounts'),
                        action: AppButton.primary(
                          label: l10n.t('newStockCount'),
                          onPressed: () =>
                              context.go('/stock-counts/create'),
                        ),
                      ),
                    StockCountLoaded(:final counts, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _StockCountsTable(
                              counts: counts,
                              isDark: isDark,
                              l10n: l10n,
                              onPost: (c) =>
                                  _confirmPost(context, c, cubit, l10n),
                              onDelete: (c) =>
                                  _confirmDelete(context, c, cubit, l10n),
                              onView: (c) =>
                                  context.go('/stock-counts/${c.id}'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                            meta: meta,
                            onPageChanged: cubit.goToPage,
                          ),
                          const SizedBox(
                              height: AppSizes.desktopContentPadding),
                        ],
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

// ── Table ─────────────────────────────────────────────────────────────────────

class _StockCountsTable extends StatelessWidget {
  final List<StockCountEntity> counts;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(StockCountEntity) onPost;
  final void Function(StockCountEntity) onDelete;
  final void Function(StockCountEntity) onView;

  const _StockCountsTable({
    required this.counts,
    required this.isDark,
    required this.l10n,
    required this.onPost,
    required this.onDelete,
    required this.onView,
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
            // Header
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                      flex: 2,
                      child: Text(l10n.t('colReference'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.t('colWarehouse'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      child: Text(l10n.t('colBranch'),
                          style: AppTextStyles.tableHeader)),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colStatus'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colCreated'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colActions'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: counts.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final c = counts[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        // Reference
                        Expanded(
                          flex: 2,
                          child: Text(
                            c.reference.isNotEmpty ? c.reference : '—',
                            style: AppTextStyles.numeric
                                .copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Warehouse
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.warehouseName,
                                style: AppTextStyles.tableCell
                                    .copyWith(color: fg),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (c.warehouseCode.isNotEmpty)
                                Text(
                                  c.warehouseCode,
                                  style: AppTextStyles.bodyXs
                                      .copyWith(color: muted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Branch
                        Expanded(
                          child: Text(
                            c.branchName ?? '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Status
                        SizedBox(
                          width: 110,
                          child: Center(
                            child: _stockCountStatusBadge(c.status, l10n),
                          ),
                        ),
                        // Created
                        SizedBox(
                          width: 100,
                          child: Text(
                            _fmtDate(c.createdAt),
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                          ),
                        ),
                        // Actions
                        SizedBox(
                          width: 110,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIconButton(
                                icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 14),
                                onPressed: () => onView(c),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.t('viewDetail'),
                              ),
                              if (c.status == 'draft') ...[
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 14),
                                  onPressed: () => onPost(c),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.t('postCount'),
                                ),
                                AppIconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      size: 14),
                                  onPressed: () => onDelete(c),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.delete,
                                ),
                              ],
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

// ── Dialogs / Confirm ─────────────────────────────────────────────────────────

Future<void> _confirmPost(
  BuildContext context,
  StockCountEntity count,
  StockCountCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('postCountTitle'),
    message: l10n.t('postCountMsg'),
    confirmLabel: l10n.t('postCount'),
    isDestructive: false,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.postCount(count.id);
  if (context.mounted) {
    if (ok) {
      AppSnackbar.success(context, l10n.t('stockCountPosted'));
    } else {
      AppSnackbar.error(context, l10n.t('actionFailed'));
    }
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  StockCountEntity count,
  StockCountCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('deleteStockCountTitle'),
    message: l10n.t('deleteStockCountMsg'),
    confirmLabel: l10n.delete,
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteCount(count.id);
  if (context.mounted) {
    if (ok) {
      AppSnackbar.success(context, l10n.t('stockCountDeleted'));
    } else {
      AppSnackbar.error(context, l10n.t('actionFailed'));
    }
  }
}
