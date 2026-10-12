import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../domain/entities/cost_layer_entities.dart';
import '../../../domain/usecases/cost_layer_usecases.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../../domain/usecases/warehouse_usecases.dart';
import '../../cubit/cost_layer_cubit.dart';
import '../../cubit/cost_layer_state.dart';
import '../../../../../features/products/domain/usecases/products_usecases.dart';

class MobileCostLayersPage extends StatelessWidget {
  const MobileCostLayersPage({super.key});

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
      child: const _MobileCostLayersContent(),
    );
  }
}

class _MobileCostLayersContent extends StatelessWidget {
  const _MobileCostLayersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CostLayerCubit, CostLayerState>(
      builder: (context, state) {
        final cubit = context.read<CostLayerCubit>();
        final l10n = AppLocalizations.of(context);
        final loaded = state is CostLayerLoaded ? state : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.t('costLayersTitle'), style: AppTextStyles.h6),
            elevation: 0,
            actions: [
              if (loaded?.hasActiveFilters == true)
                TextButton(
                  onPressed: cubit.clearFilters,
                  child: Text(l10n.t('clearFilters'),
                      style: AppTextStyles.bodySm
                          .copyWith(color: AppColors.destructive)),
                ),
            ],
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          body: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: AppSearchField(
                  hint: l10n.t('searchCostLayers'),
                  onChanged: cubit.search,
                ),
              ),
              // Warehouse filter
              if (loaded?.warehouses.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: AppSelectField<String>(
                    hint: l10n.t('allWarehouses'),
                    value: loaded?.warehouseId,
                    options: [
                      AppSelectOption(
                          value: '', label: l10n.t('allWarehouses')),
                      ...loaded!.warehouses.map((w) => AppSelectOption(
                          value: w.id, label: '${w.name} (${w.code})')),
                    ],
                    onChanged: (v) =>
                        cubit.setWarehouse(v?.isEmpty ?? true ? null : v),
                  ),
                ),
              // Branch filter
              if (loaded?.branches.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: AppSelectField<String>(
                    hint: l10n.t('allBranches'),
                    value: loaded?.branchId,
                    options: [
                      AppSelectOption(
                          value: '', label: l10n.t('allBranches')),
                      ...loaded!.branches.map((b) =>
                          AppSelectOption(value: b.id, label: b.name)),
                    ],
                    onChanged: (v) =>
                        cubit.setBranch(v?.isEmpty ?? true ? null : v),
                  ),
                ),
              // Product filter
              if (loaded?.products.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: AppSelectField<String>(
                    hint: l10n.t('allProducts'),
                    value: loaded?.productId,
                    options: [
                      AppSelectOption(
                          value: '', label: l10n.t('allProducts')),
                      ...loaded!.products.map((p) =>
                          AppSelectOption(value: p.id, label: p.name)),
                    ],
                    onChanged: (v) =>
                        cubit.setProduct(v?.isEmpty ?? true ? null : v),
                  ),
                ),
              // Date filters row
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _MobileDateButton(
                        label: l10n.t('dateFrom'),
                        value: loaded?.dateFrom,
                        onChanged: cubit.setDateFrom,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MobileDateButton(
                        label: l10n.t('dateTo'),
                        value: loaded?.dateTo,
                        onChanged: cubit.setDateTo,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Expanded(
                child: switch (state) {
                  CostLayerInitial() || CostLayerLoading() =>
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 110),
                      ),
                    ),
                  CostLayerError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  CostLayerLoaded(:final layers) when layers.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.layers_outlined, size: 40),
                      message: l10n.t('noCostLayers'),
                    ),
                  CostLayerLoaded() => RefreshIndicator(
                      onRefresh: () async => cubit.refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xl * 2,
                        ),
                        itemCount: state.sortedLayers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, i) => _MobileCostLayerCard(
                          layer: state.sortedLayers[i],
                          state: state,
                          cubit: cubit,
                          l10n: l10n,
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

// ── Mobile Date Button ────────────────────────────────────────────────────────

class _MobileDateButton extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _MobileDateButton({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          final fmt =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          onChanged(fmt);
        }
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 13, color: AppColors.mutedForeground),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                value ?? label,
                style: AppTextStyles.bodySm.copyWith(
                  color: value != null
                      ? AppColors.foreground
                      : AppColors.mutedForeground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close,
                    size: 13, color: AppColors.mutedForeground),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _MobileCostLayerCard extends StatelessWidget {
  final CostLayerEntity layer;
  final CostLayerLoaded state;
  final CostLayerCubit cubit;
  final AppLocalizations l10n;

  const _MobileCostLayerCard({
    required this.layer,
    required this.state,
    required this.cubit,
    required this.l10n,
  });

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
    final isExpanded = state.expandedLayerId == layer.id;
    final isLoadingC = state.loadingConsumptionId == layer.id;
    final consumptions = state.consumptionsMap[layer.id];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product + status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            layer.productName,
                            style: AppTextStyles.labelMd,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (layer.productSku != null)
                            Text(
                              layer.productSku!,
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: AppColors.mutedForeground),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge.custom(
                      label: _statusLabel(l10n),
                      color: _statusColor,
                      bgColor: _statusBg,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // Warehouse
                Row(
                  children: [
                    Icon(Icons.warehouse_outlined,
                        size: 13, color: AppColors.mutedForeground),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${layer.warehouseName} (${layer.warehouseCode})',
                        style: AppTextStyles.bodySm
                            .copyWith(color: AppColors.mutedForeground),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Reference
                if (layer.referenceType != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_refTypeLabel(layer.referenceType)}${layer.referenceId != null ? " #${layer.referenceId}" : ""}',
                    style: AppTextStyles.bodyXs
                        .copyWith(color: AppColors.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Qty chips
                Row(
                  children: [
                    _InfoChip(
                      label: l10n.t('colOrigQty'),
                      value: layer.originalQty.toStringAsFixed(4),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _InfoChip(
                      label: l10n.t('colRemainingQty'),
                      value: layer.remainingQty.toStringAsFixed(4),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _InfoChip(
                      label: l10n.t('colUnitCost'),
                      value: layer.unitCost.toStringAsFixed(4),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${l10n.t("colTotalValue")}: ${layer.totalValue.toStringAsFixed(4)}',
                      style: AppTextStyles.labelSm,
                    ),
                    Text(
                      '${layer.ageDays}d · ${_fmtDate(layer.createdAt)}',
                      style: AppTextStyles.bodyXs
                          .copyWith(color: AppColors.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                // Consumption toggle
                GestureDetector(
                  onTap: () => cubit.toggleConsumptions(layer.id),
                  child: Row(
                    children: [
                      if (isLoadingC)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      else
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.t('consumptionHistory'),
                        style: AppTextStyles.bodyXs
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Consumption panel
          if (isExpanded) ...[
            Divider(height: 1, color: AppColors.border),
            if (isLoadingC)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (consumptions == null || consumptions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.t('noConsumptions'),
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.mutedForeground),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: consumptions.map((c) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fmtDate(c.createdAt),
                                  style: AppTextStyles.bodyXs.copyWith(
                                      color: AppColors.mutedForeground),
                                ),
                                if (c.referenceType != null)
                                  Text(
                                    _refTypeLabel(c.referenceType),
                                    style: AppTextStyles.bodyXs
                                        .copyWith(color: AppColors.primary),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${l10n.t("colConsumedQty")}: ${c.consumedQty.toStringAsFixed(4)}',
                                style: AppTextStyles.numeric,
                              ),
                              Text(
                                'Total: ${c.totalCost.toStringAsFixed(4)}',
                                style: AppTextStyles.bodyXs.copyWith(
                                    color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
              AppTextStyles.bodyXs.copyWith(color: AppColors.mutedForeground),
        ),
        Text(value, style: AppTextStyles.numeric),
      ],
    );
  }
}
