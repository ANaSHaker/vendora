import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
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
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/inventory_entities.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../cubit/inventory_movements_cubit.dart';
import '../../cubit/inventory_movements_state.dart';
import '../../../../../features/products/domain/usecases/products_usecases.dart';

// ── Movement type helpers ─────────────────────────────────────────────────────

bool _isDestructiveType(String type) {
  const destructive = {
    'sale', 'transfer_out', 'stock_count_loss', 'adjustment_out', 'damaged',
  };
  return destructive.contains(type);
}

Color _movementColor(String type) =>
    _isDestructiveType(type) ? AppColors.destructive : AppColors.primary;

Color _movementBgColor(String type) => _isDestructiveType(type)
    ? AppColors.destructive.withValues(alpha: 0.1)
    : AppColors.primary.withValues(alpha: 0.1);

const _kMovementTypes = [
  'sale', 'return', 'purchase', 'adjustment', 'transfer_in', 'transfer_out',
  'stock_count', 'stock_count_gain', 'stock_count_loss', 'damaged',
  'adjustment_in', 'adjustment_out',
];

// ── Reference label (matches React referenceLabel()) ─────────────────────────

String _referenceLabel(InventoryMovementEntity m) {
  final short = m.referenceId != null && m.referenceId!.length > 8
      ? m.referenceId!.substring(0, 8)
      : (m.referenceId ?? '');
  final type = m.referenceType;
  if (type == 'Order') return 'Order #$short';
  if (type == 'StockTransfer') return 'Transfer #$short';
  if (type == 'GoodsReceipt') return 'Receipt${short.isNotEmpty ? " #$short" : ""}';
  if (type == 'StockCount') return 'Count #$short';
  if (type == 'StockAdjustment') return 'Adjustment${short.isNotEmpty ? " #$short" : ""}';
  if (type != null) return '$type${short.isNotEmpty ? " #$short" : ""}';
  return '—';
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopMovementsPage extends StatelessWidget {
  const DesktopMovementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryMovementsCubit(
        getMovements: getIt<GetInventoryMovementsUseCase>(),
        getWarehouses: getIt<GetInventoryWarehouseOptionsUseCase>(),
        getProducts: getIt<GetProductsUseCase>(),
      )..load(),
      child: const _MovementsContent(),
    );
  }
}

class _MovementsContent extends StatelessWidget {
  const _MovementsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryMovementsCubit, InventoryMovementsState>(
      builder: (context, state) {
        final cubit = context.read<InventoryMovementsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final loaded = state is InventoryMovementsLoaded ? state : null;

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
                      l10n.t('inventoryMovements'),
                      style: AppTextStyles.h4.copyWith(color: fg),
                    ),
                    Text(
                      l10n.t('inventoryMovementsSubtitle'),
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
                      width: 260,
                      child: AppSearchField(
                        hint: l10n.t('searchMovements'),
                        onChanged: cubit.search,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: AppSelectField<String>(
                        hint: l10n.t('allProducts'),
                        value: loaded?.productId,
                        options: [
                          AppSelectOption(value: '', label: l10n.t('allProducts')),
                          ...(loaded?.products ?? []).map((p) =>
                              AppSelectOption(value: p.id, label: p.name)),
                        ],
                        onChanged: (v) =>
                            cubit.setProduct(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: AppSelectField<String>(
                        hint: l10n.t('allWarehouses'),
                        value: loaded?.warehouseId,
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('allWarehouses')),
                          ...(loaded?.warehouses ?? []).map((w) =>
                              AppSelectOption(
                                  value: w.id, label: '${w.name} (${w.code})')),
                        ],
                        onChanged: (v) =>
                            cubit.setWarehouse(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: AppSelectField<String>(
                        hint: l10n.t('allMovementTypes'),
                        value: loaded?.movementType,
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('allMovementTypes')),
                          ..._kMovementTypes.map((t) => AppSelectOption(
                                value: t,
                                label: l10n.t('movementType_$t'),
                              )),
                        ],
                        onChanged: (v) =>
                            cubit.setMovementType(v?.isEmpty ?? true ? null : v),
                      ),
                    ),
                    _MovDateButton(
                      label: l10n.t('dateFrom'),
                      value: loaded?.dateFrom,
                      onChanged: cubit.setDateFrom,
                    ),
                    _MovDateButton(
                      label: l10n.t('dateTo'),
                      value: loaded?.dateTo,
                      onChanged: cubit.setDateTo,
                    ),
                    if (loaded?.hasActiveFilters == true)
                      TextButton(
                        onPressed: cubit.clearFilters,
                        child: Text(
                          l10n.t('clearFilters'),
                          style: AppTextStyles.bodyXs.copyWith(
                              color: muted,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Summary cards ──
              if (loaded?.summary != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: _SummaryCards(
                      summary: loaded!.summary!, isDark: isDark, l10n: l10n),
                ),
              if (loaded?.summary != null)
                const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding),
                  child: switch (state) {
                    InventoryMovementsInitial() ||
                    InventoryMovementsLoading() =>
                      const ShimmerTableRows(),
                    InventoryMovementsError(:final message) =>
                      AppErrorWidget(message: message, onRetry: cubit.refresh),
                    InventoryMovementsLoaded(:final movements)
                        when movements.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.swap_horiz_outlined, size: 40),
                        message: l10n.t('noMovements'),
                      ),
                    InventoryMovementsLoaded(:final movements, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _MovementsTable(
                                movements: movements, isDark: isDark, l10n: l10n),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                              meta: meta, onPageChanged: cubit.goToPage),
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

class _MovDateButton extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _MovDateButton(
      {required this.label, required this.value, required this.onChanged});

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
          initialDate:
              value != null ? DateTime.tryParse(value!) ?? DateTime.now() : DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        height: 40,
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: muted),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                value ?? label,
                style: AppTextStyles.bodySm
                    .copyWith(color: value != null ? fg : muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close, size: 13, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Cards ─────────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  final InventoryMovementsSummary summary;
  final bool isDark;
  final AppLocalizations l10n;

  const _SummaryCards(
      {required this.summary, required this.isDark, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Row(
      children: [
        _SummaryCard(
          label: l10n.t('summaryTotalMovements'),
          value: '${summary.totalMovements}',
          valueColor: fg,
          surface: surface,
          border: border,
          muted: muted,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          label: l10n.t('summaryTotalQtyIn'),
          value: AppFormatters.decimal(summary.totalQtyIn),
          valueColor: AppColors.primary,
          surface: surface,
          border: border,
          muted: muted,
        ),
        const SizedBox(width: AppSpacing.md),
        _SummaryCard(
          label: l10n.t('summaryTotalQtyOut'),
          value: AppFormatters.decimal(summary.totalQtyOut),
          valueColor: AppColors.destructive,
          surface: surface,
          border: border,
          muted: muted,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color surface;
  final Color border;
  final Color muted;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.surface,
    required this.border,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: AppRadius.brMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodyXs.copyWith(color: muted),
                overflow: TextOverflow.ellipsis),
            Text(
              value,
              style: AppTextStyles.numericLg.copyWith(
                  color: valueColor, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Movements Table ───────────────────────────────────────────────────────────

class _MovementsTable extends StatelessWidget {
  final List<InventoryMovementEntity> movements;
  final bool isDark;
  final AppLocalizations l10n;

  const _MovementsTable(
      {required this.movements, required this.isDark, required this.l10n});

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('colDate'),
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 3,
                    child: Text(l10n.t('colProduct'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('colWarehouse'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(l10n.t('colType'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.t('colQtyIn'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.t('colQtyOut'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(l10n.t('colBalance'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('colReference'),
                        style: AppTextStyles.tableHeader),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: movements.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final m = movements[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        // Date
                        SizedBox(
                          width: 110,
                          child: Text(
                            _fmtDate(m.createdAt),
                            style: AppTextStyles.tableCell.copyWith(color: muted),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Product (name + SKU)
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                m.productName,
                                style: AppTextStyles.labelSm.copyWith(color: fg),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (m.productSku != null)
                                Text(
                                  m.productSku!,
                                  style: AppTextStyles.bodyXs
                                      .copyWith(color: muted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Warehouse: Name (Code)
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${m.warehouseName} (${m.warehouseCode})',
                            style: AppTextStyles.tableCell.copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Type badge
                        SizedBox(
                          width: 130,
                          child: StatusBadge.custom(
                            label: l10n.t('movementType_${m.movementType}'),
                            color: _movementColor(m.movementType),
                            bgColor: _movementBgColor(m.movementType),
                          ),
                        ),
                        // Qty In
                        SizedBox(
                          width: 80,
                          child: Text(
                            m.qtyIn > 0
                                ? AppFormatters.decimal(m.qtyIn)
                                : '—',
                            style: AppTextStyles.numeric.copyWith(
                              color: m.qtyIn > 0 ? AppColors.primary : muted,
                              fontWeight: m.qtyIn > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        // Qty Out
                        SizedBox(
                          width: 80,
                          child: Text(
                            m.qtyOut > 0
                                ? AppFormatters.decimal(m.qtyOut)
                                : '—',
                            style: AppTextStyles.numeric.copyWith(
                              color: m.qtyOut > 0
                                  ? AppColors.destructive
                                  : muted,
                              fontWeight: m.qtyOut > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        // Balance after
                        SizedBox(
                          width: 90,
                          child: Text(
                            AppFormatters.decimal(m.balanceAfter),
                            style: AppTextStyles.numeric.copyWith(color: fg),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Reference
                        Expanded(
                          flex: 2,
                          child: Text(
                            _referenceLabel(m),
                            style: AppTextStyles.tableCell.copyWith(
                              color: m.referenceType != null
                                  ? AppColors.primary
                                  : muted,
                            ),
                            overflow: TextOverflow.ellipsis,
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
