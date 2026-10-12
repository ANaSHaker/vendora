import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/cost_layer_entities.dart';
import '../../../domain/usecases/cost_layer_usecases.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../../domain/usecases/warehouse_usecases.dart';
import '../../cubit/cost_layer_cubit.dart';
import '../../cubit/cost_layer_state.dart';
import '../../../../../features/products/domain/usecases/products_usecases.dart';

class DesktopCostLayersPage extends StatelessWidget {
  const DesktopCostLayersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CostLayerCubit(
        getCostLayers: getIt<GetCostLayersUseCase>(),
        getWarehouses: getIt<GetManagedWarehousesUseCase>(),
        getBranches: getIt<GetInventoryBranchOptionsUseCase>(),
        getProducts: getIt<GetProductsUseCase>(),
        getConsumptions: getIt<GetCostLayerConsumptionsUseCase>(),
      )..load(),
      child: const _CostLayersContent(),
    );
  }
}

class _CostLayersContent extends StatelessWidget {
  const _CostLayersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CostLayerCubit, CostLayerState>(
      builder: (context, state) {
        final cubit = context.read<CostLayerCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final loaded = state is CostLayerLoaded ? state : null;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('costLayersTitle'),
                      style: AppTextStyles.h4.copyWith(color: fg),
                    ),
                    if (loaded != null)
                      Text(
                        '${loaded.meta.total} ${l10n.t("costLayersTotal")}',
                        style: AppTextStyles.bodySm.copyWith(color: muted),
                      ),
                  ],
                ),
              ),

              // ── Filters ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: AppSearchField(
                        hint: l10n.t('searchCostLayers'),
                        onChanged: cubit.search,
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: AppSelectField<String>(
                        hint: l10n.t('allWarehouses'),
                        value: loaded?.warehouseId,
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('allWarehouses')),
                          ...(loaded?.warehouses ?? []).map((w) =>
                              AppSelectOption(
                                  value: w.id,
                                  label: '${w.name} (${w.code})')),
                        ],
                        onChanged: (v) =>
                            cubit.setWarehouse(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: AppSelectField<String>(
                        hint: l10n.t('allBranches'),
                        value: loaded?.branchId,
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('allBranches')),
                          ...(loaded?.branches ?? []).map((b) =>
                              AppSelectOption(value: b.id, label: b.name)),
                        ],
                        onChanged: (v) =>
                            cubit.setBranch(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: AppSelectField<String>(
                        hint: l10n.t('allProducts'),
                        value: loaded?.productId,
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('allProducts')),
                          ...(loaded?.products ?? []).map((p) =>
                              AppSelectOption(value: p.id, label: p.name)),
                        ],
                        onChanged: (v) =>
                            cubit.setProduct(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    _DateFilterButton(
                      label: l10n.t('dateFrom'),
                      value: loaded?.dateFrom,
                      onChanged: cubit.setDateFrom,
                    ),
                    _DateFilterButton(
                      label: l10n.t('dateTo'),
                      value: loaded?.dateTo,
                      onChanged: cubit.setDateTo,
                    ),
                    if (loaded?.hasActiveFilters == true)
                      AppButton.outline(
                        label: l10n.t('clearFilters'),
                        size: AppButtonSize.sm,
                        leading: const Icon(Icons.clear, size: 14),
                        onPressed: cubit.clearFilters,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: switch (state) {
                    CostLayerInitial() || CostLayerLoading() =>
                      const ShimmerTableRows(),
                    CostLayerError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    CostLayerLoaded(:final layers) when layers.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.layers_outlined, size: 40),
                        message: l10n.t('noCostLayers'),
                      ),
                    CostLayerLoaded() => Column(
                        children: [
                          Expanded(
                            child: _CostLayersTable(
                              state: state,
                              isDark: isDark,
                              l10n: l10n,
                              cubit: cubit,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                            meta: state.meta,
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

// ── Date Filter Button ────────────────────────────────────────────────────────

class _DateFilterButton extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DateFilterButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null
              ? DateTime.tryParse(value!) ?? DateTime.now()
              : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          final formatted =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      child: Container(
        height: 40,
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: muted),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                value ?? label,
                style: AppTextStyles.bodySm.copyWith(
                    color: value != null ? fg : muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 14, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _CostLayersTable extends StatelessWidget {
  final CostLayerLoaded state;
  final bool isDark;
  final AppLocalizations l10n;
  final CostLayerCubit cubit;

  const _CostLayersTable({
    required this.state,
    required this.isDark,
    required this.l10n,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final layers = state.sortedLayers;

    // Build header row (reusable)
    Widget buildHeader(double tableWidth) => Container(
          height: AppSizes.tableHeaderHeight,
          width: tableWidth,
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _SortHeader(label: l10n.t('colProduct'), column: 'product', state: state, onTap: () => cubit.sortBy('product'), flex: 3),
              _SortHeader(label: l10n.t('colWarehouse'), column: 'warehouse', state: state, onTap: () => cubit.sortBy('warehouse'), flex: 2),
              _SortHeader(label: l10n.t('colOrigQty'), column: 'originalQty', state: state, onTap: () => cubit.sortBy('originalQty'), width: 88, textAlign: TextAlign.end),
              _SortHeader(label: l10n.t('colRemainingQty'), column: 'remainingQty', state: state, onTap: () => cubit.sortBy('remainingQty'), width: 88, textAlign: TextAlign.end),
              _SortHeader(label: l10n.t('colUnitCost'), column: 'unitCost', state: state, onTap: () => cubit.sortBy('unitCost'), width: 96, textAlign: TextAlign.end),
              _SortHeader(label: l10n.t('colTotalValue'), column: 'totalValue', state: state, onTap: () => cubit.sortBy('totalValue'), width: 96, textAlign: TextAlign.end),
              _SortHeader(label: l10n.t('colDate'), column: 'createdAt', state: state, onTap: () => cubit.sortBy('createdAt'), width: 92, textAlign: TextAlign.end),
              _SortHeader(label: l10n.t('colAge'), column: 'ageDays', state: state, onTap: () => cubit.sortBy('ageDays'), width: 60, textAlign: TextAlign.end),
              SizedBox(
                width: 84,
                child: Text(l10n.t('colStatus'),
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 110,
                child: Text(l10n.t('colReference'),
                    style: AppTextStyles.tableHeader,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              SizedBox(
                width: 50,
                child: Text(l10n.t('colConsumption'),
                    style: AppTextStyles.tableHeader,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        const minTableWidth = 1050.0;
        final tableWidth = constraints.maxWidth > minTableWidth
            ? constraints.maxWidth
            : minTableWidth;
        final bodyHeight = constraints.maxHeight -
            AppSizes.tableHeaderHeight -
            1; // divider

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
                // Header + Body share one horizontal scroll controller
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        children: [
                          buildHeader(tableWidth),
                          Divider(height: 1, color: border),
                          SizedBox(
                            height: bodyHeight - 1,
                            child: ListView.separated(
                              itemCount: layers.length,
                              separatorBuilder: (_, __) =>
                                  Divider(height: 1, color: border),
                              itemBuilder: (context, i) {
                                final layer = layers[i];
                                final isExpanded =
                                    state.expandedLayerId == layer.id;
                                final isLoadingC =
                                    state.loadingConsumptionId == layer.id;
                                final consumptions =
                                    state.consumptionsMap[layer.id];

                                return _CostLayerRowExpanded(
                                  layer: layer,
                                  fg: fg,
                                  muted: muted,
                                  border: border,
                                  isDark: isDark,
                                  l10n: l10n,
                                  tableWidth: tableWidth,
                                  isExpanded: isExpanded,
                                  isLoadingConsumptions: isLoadingC,
                                  consumptions: consumptions,
                                  onToggle: () =>
                                      cubit.toggleConsumptions(layer.id),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sort Header ───────────────────────────────────────────────────────────────

class _SortHeader extends StatelessWidget {
  final String label;
  final String column;
  final CostLayerLoaded state;
  final VoidCallback onTap;
  final int? flex;
  final double? width;
  final TextAlign textAlign;

  const _SortHeader({
    required this.label,
    required this.column,
    required this.state,
    required this.onTap,
    this.flex,
    this.width,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = state.sortColumn == column;
    final icon = isActive
        ? (state.sortAscending
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded)
        : null;

    final child = GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.end
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (textAlign != TextAlign.end)
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.tableHeader.copyWith(
                  color: isActive ? AppColors.primary : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (icon != null) ...[
            const SizedBox(width: 2),
            Icon(icon, size: 11,
                color: AppColors.primary),
          ],
          if (textAlign == TextAlign.end)
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.tableHeader.copyWith(
                  color: isActive ? AppColors.primary : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );

    if (flex != null) return Expanded(flex: flex!, child: child);
    return SizedBox(width: width, child: child);
  }
}

// ── Row (expandable) ──────────────────────────────────────────────────────────

class _CostLayerRowExpanded extends StatelessWidget {
  final CostLayerEntity layer;
  final Color fg;
  final Color muted;
  final Color border;
  final bool isDark;
  final AppLocalizations l10n;
  final double tableWidth;
  final bool isExpanded;
  final bool isLoadingConsumptions;
  final List<CostLayerConsumptionEntity>? consumptions;
  final VoidCallback onToggle;

  const _CostLayerRowExpanded({
    required this.layer,
    required this.fg,
    required this.muted,
    required this.border,
    required this.isDark,
    required this.l10n,
    required this.tableWidth,
    required this.isExpanded,
    required this.isLoadingConsumptions,
    required this.consumptions,
    required this.onToggle,
  });

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  // React statusBadge(): full=primary-bg/primary, partial=muted/primary, exhausted=muted/destructive
  Color get _statusColor => switch (layer.status) {
        'full' => AppColors.primary,
        'partial' => AppColors.primary,
        'exhausted' => AppColors.destructive,
        _ => AppColors.mutedForeground,
      };

  Color get _statusBg => switch (layer.status) {
        'full' => AppColors.primaryMuted,
        'partial' => AppColors.muted,
        'exhausted' => AppColors.muted,
        _ => AppColors.muted,
      };

  String _statusLabel(AppLocalizations l10n) => switch (layer.status) {
        'full' => l10n.t('statusFull'),
        'partial' => l10n.t('statusPartial'),
        'exhausted' => l10n.t('statusExhausted'),
        _ => layer.status,
      };

  String _refTypeLabel(String? type) => switch (type?.toLowerCase()) {
        'goodsreceipt' || 'receipt' => l10n.t('refTypeReceipt'),
        'stocktransfer' || 'transfer' => l10n.t('refTypeTransfer'),
        'stockcount' || 'count' => l10n.t('refTypeCount'),
        'stockadjustment' || 'adjustment' => l10n.t('refTypeAdjustment'),
        _ => type ?? '—',
      };

  @override
  Widget build(BuildContext context) {
    final subBg = isDark
        ? AppColors.darkBackground
        : AppColors.primaryMuted.withValues(alpha: 0.4);

    return Column(
      children: [
        // Main row — low-stock highlight (React: remaining_qty <= 0.0001 OR < 10% of original)
        Container(
          constraints: const BoxConstraints(minHeight: AppSizes.tableRowHeight),
          color: (layer.remainingQty <= 0.0001 ||
                  (layer.originalQty > 0 &&
                      layer.remainingQty / layer.originalQty < 0.1))
              ? AppColors.primaryMuted.withValues(alpha: 0.5)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Product
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      layer.productName,
                      style: AppTextStyles.labelSm.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (layer.productSku != null)
                      Text(
                        layer.productSku!,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
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
                      layer.warehouseName,
                      style: AppTextStyles.tableCell.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      layer.warehouseCode,
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Orig. Qty (React: .toFixed(4))
              SizedBox(
                width: 88,
                child: Text(layer.originalQty.toStringAsFixed(4),
                    style: AppTextStyles.numeric.copyWith(color: fg),
                    textAlign: TextAlign.end),
              ),
              // Remaining Qty (React: .toFixed(4))
              SizedBox(
                width: 88,
                child: Text(layer.remainingQty.toStringAsFixed(4),
                    style: AppTextStyles.numeric.copyWith(color: fg),
                    textAlign: TextAlign.end),
              ),
              // Unit Cost (React: .toFixed(4))
              SizedBox(
                width: 96,
                child: Text(layer.unitCost.toStringAsFixed(4),
                    style: AppTextStyles.numeric.copyWith(color: fg),
                    textAlign: TextAlign.end),
              ),
              // Total Value (React: .toFixed(4))
              SizedBox(
                width: 96,
                child: Text(layer.totalValue.toStringAsFixed(4),
                    style: AppTextStyles.numeric.copyWith(color: fg),
                    textAlign: TextAlign.end),
              ),
              // Date
              SizedBox(
                width: 92,
                child: Text(_fmtDate(layer.createdAt),
                    style: AppTextStyles.tableCell.copyWith(color: muted),
                    textAlign: TextAlign.end),
              ),
              // Age (React: number only)
              SizedBox(
                width: 60,
                child: Text('${layer.ageDays}',
                    style: AppTextStyles.numeric.copyWith(color: muted),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis),
              ),
              // Status badge
              SizedBox(
                width: 84,
                child: Center(
                  child: StatusBadge.custom(
                    label: _statusLabel(l10n),
                    color: _statusColor,
                    bgColor: _statusBg,
                  ),
                ),
              ),
              // Reference (React: type + id as link, or "Opening Balance" if null)
              SizedBox(
                width: 110,
                child: layer.referenceType != null
                    ? Text(
                        '${_refTypeLabel(layer.referenceType)}${layer.referenceId != null ? " #${layer.referenceId}" : ""}',
                        style: AppTextStyles.bodyXs
                            .copyWith(color: AppColors.primary),
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(l10n.t('openingBalance'),
                        style: AppTextStyles.tableCell.copyWith(color: muted),
                        overflow: TextOverflow.ellipsis),
              ),
              // "عرض"/"إخفاء" text button (React: text link)
              SizedBox(
                width: 50,
                child: Center(
                  child: isLoadingConsumptions
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : GestureDetector(
                          onTap: onToggle,
                          child: Text(
                            isExpanded
                                ? l10n.t('hideLabel')
                                : l10n.t('colConsumption'),
                            style: AppTextStyles.bodyXs.copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        // Expanded consumption panel
        if (isExpanded)
          Container(
            color: subBg,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('consumptionHistory'),
                  style: AppTextStyles.labelSm
                      .copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (isLoadingConsumptions)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (consumptions == null || consumptions!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    child: Text(
                      l10n.t('noConsumptions'),
                      style: AppTextStyles.bodySm.copyWith(color: muted),
                    ),
                  )
                else
                  _ConsumptionSubTable(
                    consumptions: consumptions!,
                    fg: fg,
                    muted: muted,
                    border: border,
                    l10n: l10n,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Consumption Sub-Table ─────────────────────────────────────────────────────

class _ConsumptionSubTable extends StatelessWidget {
  final List<CostLayerConsumptionEntity> consumptions;
  final Color fg;
  final Color muted;
  final Color border;
  final AppLocalizations l10n;

  const _ConsumptionSubTable({
    required this.consumptions,
    required this.fg,
    required this.muted,
    required this.border,
    required this.l10n,
  });

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _refTypeLabel(String? type) => switch (type?.toLowerCase()) {
        'goodsreceipt' || 'receipt' => l10n.t('refTypeReceipt'),
        'stocktransfer' || 'transfer' => l10n.t('refTypeTransfer'),
        'stockcount' || 'count' => l10n.t('refTypeCount'),
        'stockadjustment' || 'adjustment' => l10n.t('refTypeAdjustment'),
        _ => type ?? '—',
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: border.withValues(alpha: 0.4)),
              children: [
                _th(l10n.t('date')),
                _th(l10n.t('colConsumedQty')),
                _th('Unit Cost'),
                _th('Total Cost'),
                _th(l10n.t('colReference')),
              ],
            ),
            ...consumptions.map(
              (c) => TableRow(
                children: [
                  _td(_fmtDate(c.createdAt), fg),
                  _td(c.consumedQty.toStringAsFixed(4), fg),
                  _td(c.unitCost.toStringAsFixed(4), fg),
                  _td(c.totalCost.toStringAsFixed(4), fg),
                  _td(
                    c.referenceType != null
                        ? '${_refTypeLabel(c.referenceType)}${c.referenceId != null ? " #${c.referenceId}" : ""}'
                        : '—',
                    AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String label) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(label,
            style: AppTextStyles.tableHeader,
            overflow: TextOverflow.ellipsis),
      );

  Widget _td(String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        child: Text(value,
            style: AppTextStyles.tableCell.copyWith(color: color),
            overflow: TextOverflow.ellipsis),
      );
}
