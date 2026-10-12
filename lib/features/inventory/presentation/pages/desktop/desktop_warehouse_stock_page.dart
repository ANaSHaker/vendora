import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/inventory_entities.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../cubit/warehouse_stock_cubit.dart';
import '../../cubit/warehouse_stock_state.dart';

// ── Warehouse type colors ─────────────────────────────────────────────────────

Color _warehouseTypeColor(String type, bool isDark) {
  switch (type) {
    case 'damaged':
      return AppColors.destructive;
    case 'transit':
      return isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    case 'returns':
      return isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    default: // 'main'
      return AppColors.primary;
  }
}

Color _warehouseTypeBg(String type, bool isDark) {
  switch (type) {
    case 'damaged':
      return AppColors.destructive.withValues(alpha: 0.1);
    default:
      return isDark
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.primary.withValues(alpha: 0.08);
  }
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopWarehouseStockPage extends StatelessWidget {
  const DesktopWarehouseStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WarehouseStockCubit(
        getStock: getIt<GetInventoryStockUseCase>(),
        getWarehouses: getIt<GetInventoryWarehouseOptionsUseCase>(),
        getBranches: getIt<GetInventoryBranchOptionsUseCase>(),
      )..load(),
      child: const _WarehouseStockContent(),
    );
  }
}

class _WarehouseStockContent extends StatefulWidget {
  const _WarehouseStockContent();

  @override
  State<_WarehouseStockContent> createState() => _WarehouseStockContentState();
}

class _WarehouseStockContentState extends State<_WarehouseStockContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<WarehouseStockCubit>();
      cubit.loadWarehouses();
      cubit.loadBranches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehouseStockCubit, WarehouseStockState>(
      builder: (context, state) {
        final cubit = context.read<WarehouseStockCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final branches =
            state is WarehouseStockLoaded ? state.branches : <InventoryBranchOptionEntity>[];
        final warehouses =
            state is WarehouseStockLoaded ? state.warehouses : <WarehouseOptionEntity>[];
        final selectedBranchId =
            state is WarehouseStockLoaded ? state.branchId : null;
        final selectedWarehouseId =
            state is WarehouseStockLoaded ? state.warehouseId : null;
        final lowStockOnly =
            state is WarehouseStockLoaded ? state.lowStockOnly : false;

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
                      l10n.t('warehouseStockTitle'),
                      style: AppTextStyles.h4.copyWith(color: fg),
                    ),
                    Text(
                      l10n.t('warehouseStockSubtitle'),
                      style: AppTextStyles.bodySm.copyWith(color: muted),
                    ),
                  ],
                ),
              ),

              // ── Filters ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: AppSearchField(
                        hint: l10n.t('searchInventory'),
                        onChanged: cubit.search,
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: AppSelectField<String>(
                        hint: l10n.t('allBranches'),
                        value: selectedBranchId,
                        options: [
                          AppSelectOption(value: '', label: l10n.t('allBranches')),
                          ...branches.map(
                            (b) => AppSelectOption(value: b.id, label: b.name),
                          ),
                        ],
                        onChanged: (v) =>
                            cubit.setBranch(v == null || v.isEmpty ? null : v),
                      ),
                    ),
                    SizedBox(
                      width: 190,
                      child: AppSelectField<String>(
                        hint: l10n.t('allWarehouses'),
                        value: selectedWarehouseId,
                        options: [
                          AppSelectOption(value: '', label: l10n.t('allWarehouses')),
                          ...warehouses.map(
                            (w) => AppSelectOption(
                              value: w.id,
                              label: '${w.name} (${w.code})',
                            ),
                          ),
                        ],
                        onChanged: (v) =>
                            cubit.setWarehouse(v == null || v.isEmpty ? null : v),
                      ),
                    ),
                    _LowStockToggle(
                      value: lowStockOnly,
                      label: l10n.t('lowStockOnly'),
                      isDark: isDark,
                      onChanged: cubit.setLowStockOnly,
                    ),
                  ],
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
                    WarehouseStockInitial() || WarehouseStockLoading() =>
                      const ShimmerTableRows(),
                    WarehouseStockError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    WarehouseStockLoaded(:final balances)
                        when balances.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.warehouse_outlined, size: 40),
                        message: l10n.t('noInventoryItems'),
                      ),
                    WarehouseStockLoaded(:final balances, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _WarehouseStockTable(
                              balances: balances,
                              isDark: isDark,
                              l10n: l10n,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                            meta: meta,
                            onPageChanged: cubit.goToPage,
                          ),
                          const SizedBox(height: AppSizes.desktopContentPadding),
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

// ── Low Stock Toggle ──────────────────────────────────────────────────────────

class _LowStockToggle extends StatelessWidget {
  final bool value;
  final String label;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _LowStockToggle({
    required this.value,
    required this.label,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: value
              ? AppColors.primary.withValues(alpha: 0.08)
              : surface,
          border: Border.all(
            color: value ? AppColors.primary : border,
          ),
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: value ? AppColors.primary : AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: value ? AppColors.primary : fg,
                fontWeight: value ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Table ─────────────────────────────────────────────────────────────────────

class _WarehouseStockTable extends StatelessWidget {
  final List<InventoryBalanceEntity> balances;
  final bool isDark;
  final AppLocalizations l10n;

  const _WarehouseStockTable({
    required this.balances,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;

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
                  Expanded(
                    child: Text(l10n.t('colBranch'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    child: Text(l10n.t('colOnHand'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    child: Text(l10n.t('colReserved'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    child: Text(l10n.t('colAvailable'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('colAvgCost'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.t('colStatus'),
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
                itemCount: balances.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) => _WarehouseStockRow(
                  balance: balances[i],
                  isDark: isDark,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehouseStockRow extends StatelessWidget {
  final InventoryBalanceEntity balance;
  final bool isDark;
  final AppLocalizations l10n;

  const _WarehouseStockRow({
    required this.balance,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final status = balance.stockStatus;

    return Container(
      height: AppSizes.tableRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Product (name + SKU)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  balance.productName,
                  style: AppTextStyles.labelSm.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
                if (balance.productSku != null)
                  Text(
                    balance.productSku!,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Warehouse (type-colored code badge + name)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _warehouseTypeBg(balance.warehouseType, isDark),
                    borderRadius: AppRadius.brSm,
                    border: Border.all(
                      color: _warehouseTypeColor(balance.warehouseType, isDark)
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    balance.warehouseCode,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: _warehouseTypeColor(balance.warehouseType, isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    balance.warehouseName,
                    style: AppTextStyles.tableCell.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Branch
          Expanded(
            child: Text(
              balance.branchName ?? '—',
              style: AppTextStyles.tableCell.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // On Hand + unit
          Expanded(
            child: Text(
              balance.productUnit != null
                  ? '${AppFormatters.decimal(balance.onHandQty)} ${balance.productUnit}'
                  : AppFormatters.decimal(balance.onHandQty),
              style: AppTextStyles.numeric.copyWith(color: fg),
              textAlign: TextAlign.end,
            ),
          ),
          // Reserved ('—' if zero)
          Expanded(
            child: Text(
              balance.reservedQty > 0
                  ? AppFormatters.decimal(balance.reservedQty)
                  : '—',
              style: AppTextStyles.numeric.copyWith(color: muted),
              textAlign: TextAlign.end,
            ),
          ),
          // Available (red if ≤ 0)
          Expanded(
            child: Text(
              AppFormatters.decimal(balance.availableQty),
              style: AppTextStyles.numeric.copyWith(
                color: balance.availableQty <= 0 ? AppColors.destructive : fg,
                fontWeight: balance.availableQty <= 0
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          // Avg Cost ('—' if zero)
          SizedBox(
            width: 100,
            child: Text(
              balance.averageCost > 0
                  ? balance.averageCost.toStringAsFixed(4)
                  : '—',
              style: AppTextStyles.numeric.copyWith(color: fg),
              textAlign: TextAlign.end,
            ),
          ),
          // Status badge
          SizedBox(
            width: 80,
            child: Center(
              child: _StatusBadge(status: status, l10n: l10n),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _StatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'out':
        return _badge(
          l10n.t('stockOut'),
          AppColors.destructive,
          AppColors.destructive.withValues(alpha: 0.1),
        );
      case 'low':
        return _badge(
          l10n.t('stockLow'),
          AppColors.warningForeground,
          AppColors.warningLight,
        );
      default:
        return _badge(
          l10n.t('stockOk'),
          AppColors.successForeground,
          AppColors.successLight,
        );
    }
  }

  Widget _badge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyXs.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
