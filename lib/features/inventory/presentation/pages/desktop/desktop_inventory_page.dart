import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/api/api_response.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../domain/entities/inventory_entities.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../cubit/inventory_stock_cubit.dart';
import '../../cubit/inventory_stock_state.dart';

// ── Sort helpers ──────────────────────────────────────────────────────────────

enum _SortKey { product, warehouse, onHand, reserved, available, avgCost }

List<InventoryBalanceEntity> _sortBalances(
  List<InventoryBalanceEntity> list,
  _SortKey key,
  bool asc,
) {
  final sorted = [...list];
  sorted.sort((a, b) {
    int cmp;
    switch (key) {
      case _SortKey.product:
        cmp = a.productName.compareTo(b.productName);
      case _SortKey.warehouse:
        cmp = a.warehouseName.compareTo(b.warehouseName);
      case _SortKey.onHand:
        cmp = a.onHandQty.compareTo(b.onHandQty);
      case _SortKey.reserved:
        cmp = a.reservedQty.compareTo(b.reservedQty);
      case _SortKey.available:
        cmp = a.availableQty.compareTo(b.availableQty);
      case _SortKey.avgCost:
        cmp = a.averageCost.compareTo(b.averageCost);
    }
    return asc ? cmp : -cmp;
  });
  return sorted;
}

// ── Page ──────────────────────────────────────────────────────────────────────

class DesktopInventoryPage extends StatelessWidget {
  const DesktopInventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryStockCubit(
        getStock: getIt<GetInventoryStockUseCase>(),
        getWarehouses: getIt<GetInventoryWarehouseOptionsUseCase>(),
        getBranches: getIt<GetInventoryBranchOptionsUseCase>(),
      )..load(),
      child: const _InventoryContent(),
    );
  }
}

class _InventoryContent extends StatefulWidget {
  const _InventoryContent();

  @override
  State<_InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<_InventoryContent> {
  _SortKey _sortKey = _SortKey.product;
  bool _sortAsc = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<InventoryStockCubit>();
      cubit.loadWarehouses();
      cubit.loadBranches();
    });
  }

  void _onSort(_SortKey key) {
    setState(() {
      if (_sortKey == key) {
        _sortAsc = !_sortAsc;
      } else {
        _sortKey = key;
        _sortAsc = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryStockCubit, InventoryStockState>(
      builder: (context, state) {
        final cubit = context.read<InventoryStockCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final branches = state is InventoryStockLoaded
            ? state.branches
            : <InventoryBranchOptionEntity>[];
        final warehouses = state is InventoryStockLoaded
            ? state.warehouses
            : <WarehouseOptionEntity>[];
        final selectedBranchId =
            state is InventoryStockLoaded ? state.branchId : null;
        final selectedWarehouseId =
            state is InventoryStockLoaded ? state.warehouseId : null;

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
                      l10n.t('inventoryDashboardTitle'),
                      style: AppTextStyles.h4.copyWith(color: fg),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.t('inventoryDashboardSubtitle'),
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
                child: Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child: AppSearchField(
                        hint: l10n.t('searchInventory'),
                        onChanged: cubit.search,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 180,
                      child: AppSelectField<String>(
                        hint: l10n.t('allBranches'),
                        value: selectedBranchId,
                        options: [
                          AppSelectOption(
                            value: '',
                            label: l10n.t('allBranches'),
                          ),
                          ...branches.map(
                            (b) => AppSelectOption(value: b.id, label: b.name),
                          ),
                        ],
                        onChanged: (v) =>
                            cubit.setBranch(v == null || v.isEmpty ? null : v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 200,
                      child: AppSelectField<String>(
                        hint: l10n.t('allWarehouses'),
                        value: selectedWarehouseId,
                        options: [
                          AppSelectOption(
                            value: '',
                            label: l10n.t('allWarehouses'),
                          ),
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
                    InventoryStockInitial() || InventoryStockLoading() =>
                      const ShimmerTableRows(),
                    InventoryStockError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    InventoryStockLoaded(:final balances)
                        when balances.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                        ),
                        message: l10n.t('noInventoryItems'),
                      ),
                    InventoryStockLoaded(:final balances, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _StockTable(
                              balances: _sortBalances(
                                  balances, _sortKey, _sortAsc),
                              isDark: isDark,
                              l10n: l10n,
                              sortKey: _sortKey,
                              sortAsc: _sortAsc,
                              onSort: _onSort,
                            ),
                          ),
                          if (meta.lastPage > 1) ...[
                            const SizedBox(height: AppSpacing.md),
                            _PaginationBar(
                              count: balances.length,
                              meta: meta,
                              isDark: isDark,
                              muted: muted,
                              l10n: l10n,
                              onPrev: meta.currentPage > 1
                                  ? () => cubit.goToPage(meta.currentPage - 1)
                                  : null,
                              onNext: meta.currentPage < meta.lastPage
                                  ? () => cubit.goToPage(meta.currentPage + 1)
                                  : null,
                            ),
                          ],
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

// ── Pagination Bar ────────────────────────────────────────────────────────────

class _PaginationBar extends StatelessWidget {
  final int count;
  final PaginationMeta meta;
  final bool isDark;
  final Color muted;
  final AppLocalizations l10n;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.count,
    required this.meta,
    required this.isDark,
    required this.muted,
    required this.l10n,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    final showingText = l10n
        .t('inventoryShowingOf')
        .replaceAll('{{count}}', '$count')
        .replaceAll('{{total}}', '${meta.total}');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          showingText,
          style: AppTextStyles.bodySm.copyWith(color: muted),
        ),
        Row(
          children: [
            _PageButton(
              label: l10n.t('prev'),
              enabled: onPrev != null,
              onTap: onPrev,
              border: border,
              surface: surface,
              muted: muted,
            ),
            const SizedBox(width: AppSpacing.sm),
            _PageButton(
              label: l10n.t('next'),
              enabled: onNext != null,
              onTap: onNext,
              border: border,
              surface: surface,
              muted: muted,
            ),
          ],
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  final Color border;
  final Color surface;
  final Color muted;

  const _PageButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    required this.border,
    required this.surface,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          decoration: BoxDecoration(
            color: surface,
            border: Border.all(color: border),
            borderRadius: AppRadius.brSm,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySm.copyWith(color: muted),
          ),
        ),
      ),
    );
  }
}

// ── Stock Table ───────────────────────────────────────────────────────────────

class _StockTable extends StatelessWidget {
  final List<InventoryBalanceEntity> balances;
  final bool isDark;
  final AppLocalizations l10n;
  final _SortKey sortKey;
  final bool sortAsc;
  final void Function(_SortKey) onSort;

  const _StockTable({
    required this.balances,
    required this.isDark,
    required this.l10n,
    required this.sortKey,
    required this.sortAsc,
    required this.onSort,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _SortHeader(
                      label: l10n.t('colProduct'),
                      sortKey: _SortKey.product,
                      activeSortKey: sortKey,
                      sortAsc: sortAsc,
                      onSort: onSort,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _SortHeader(
                      label: l10n.t('colWarehouse'),
                      sortKey: _SortKey.warehouse,
                      activeSortKey: sortKey,
                      sortAsc: sortAsc,
                      onSort: onSort,
                    ),
                  ),
                  Expanded(
                    child: _SortHeader(
                      label: l10n.t('colOnHand'),
                      sortKey: _SortKey.onHand,
                      activeSortKey: sortKey,
                      sortAsc: sortAsc,
                      onSort: onSort,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: _SortHeader(
                      label: l10n.t('colReserved'),
                      sortKey: _SortKey.reserved,
                      activeSortKey: sortKey,
                      sortAsc: sortAsc,
                      onSort: onSort,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: _SortHeader(
                      label: l10n.t('colAvailable'),
                      sortKey: _SortKey.available,
                      activeSortKey: sortKey,
                      sortAsc: sortAsc,
                      onSort: onSort,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: _SortHeader(
                      label: l10n.t('colAvgCost'),
                      sortKey: _SortKey.avgCost,
                      activeSortKey: sortKey,
                      sortAsc: sortAsc,
                      onSort: onSort,
                      textAlign: TextAlign.right,
                    ),
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
                itemBuilder: (context, i) => _StockRow(
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

// ── Sort Header ───────────────────────────────────────────────────────────────

class _SortHeader extends StatelessWidget {
  final String label;
  final _SortKey sortKey;
  final _SortKey activeSortKey;
  final bool sortAsc;
  final void Function(_SortKey) onSort;
  final TextAlign textAlign;

  const _SortHeader({
    required this.label,
    required this.sortKey,
    required this.activeSortKey,
    required this.sortAsc,
    required this.onSort,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final isActive = sortKey == activeSortKey;

    return GestureDetector(
      onTap: () => onSort(sortKey),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: textAlign == TextAlign.right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.tableHeader.copyWith(
              color: isActive ? AppColors.primary : null,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            isActive
                ? (sortAsc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded)
                : Icons.unfold_more_rounded,
            size: 13,
            color: isActive ? AppColors.primary : muted,
          ),
        ],
      ),
    );
  }
}

// ── Stock Row ─────────────────────────────────────────────────────────────────

class _StockRow extends StatelessWidget {
  final InventoryBalanceEntity balance;
  final bool isDark;
  final AppLocalizations l10n;

  const _StockRow({
    required this.balance,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final lowStock = balance.isLowStock;
    final rowBg = lowStock
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.04))
        : Colors.transparent;

    return Container(
      height: AppSizes.tableRowHeight,
      color: rowBg,
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
          // Warehouse — plain text "Name (CODE)" matching Vue
          Expanded(
            flex: 2,
            child: Text(
              balance.warehouseId.isNotEmpty
                  ? '${balance.warehouseName} (${balance.warehouseCode})'
                  : '—',
              style: AppTextStyles.tableCell.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // On Hand — toFixed(2), no unit
          Expanded(
            child: Text(
              balance.onHandQty.toStringAsFixed(2),
              style: AppTextStyles.numeric.copyWith(color: fg),
              textAlign: TextAlign.end,
            ),
          ),
          // Reserved — always show toFixed(2)
          Expanded(
            child: Text(
              balance.reservedQty.toStringAsFixed(2),
              style: AppTextStyles.numeric.copyWith(color: muted),
              textAlign: TextAlign.end,
            ),
          ),
          // Available — primary + icon if low stock, normal fg otherwise
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (lowStock)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 2),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                  ),
                Text(
                  balance.availableQty.toStringAsFixed(2),
                  style: AppTextStyles.numeric.copyWith(
                    color: lowStock ? AppColors.primary : fg,
                    fontWeight:
                        lowStock ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Avg Cost — always show toFixed(4)
          SizedBox(
            width: 120,
            child: Text(
              balance.averageCost.toStringAsFixed(4),
              style: AppTextStyles.numeric.copyWith(color: fg),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
