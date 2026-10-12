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
import '../../../domain/entities/inventory_entities.dart';
import '../../../domain/usecases/inventory_usecases.dart';
import '../../cubit/warehouse_stock_cubit.dart';
import '../../cubit/warehouse_stock_state.dart';

class MobileWarehouseStockPage extends StatefulWidget {
  const MobileWarehouseStockPage({super.key});

  @override
  State<MobileWarehouseStockPage> createState() =>
      _MobileWarehouseStockPageState();
}

class _MobileWarehouseStockPageState extends State<MobileWarehouseStockPage> {
  late final WarehouseStockCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = WarehouseStockCubit(
      getStock: getIt<GetInventoryStockUseCase>(),
      getWarehouses: getIt<GetInventoryWarehouseOptionsUseCase>(),
      getBranches: getIt<GetInventoryBranchOptionsUseCase>(),
    )..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.loadWarehouses();
      _cubit.loadBranches();
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<WarehouseStockCubit, WarehouseStockState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final warehouses = state is WarehouseStockLoaded
              ? state.warehouses
              : <WarehouseOptionEntity>[];
          final branches = state is WarehouseStockLoaded
              ? state.branches
              : <InventoryBranchOptionEntity>[];
          final selectedWarehouseId =
              state is WarehouseStockLoaded ? state.warehouseId : null;
          final selectedBranchId =
              state is WarehouseStockLoaded ? state.branchId : null;
          final lowStockOnly =
              state is WarehouseStockLoaded ? state.lowStockOnly : false;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l10n.t('warehouseStock'), style: AppTextStyles.h6),
              elevation: 0,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.border),
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      AppSearchField(
                        hint: l10n.t('searchInventory'),
                        onChanged: _cubit.search,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (branches.isNotEmpty)
                        AppSelectField<String>(
                          hint: l10n.t('allBranches'),
                          value: selectedBranchId,
                          options: [
                            AppSelectOption(
                              value: '',
                              label: l10n.t('allBranches'),
                            ),
                            ...branches.map(
                              (b) => AppSelectOption(
                                value: b.id,
                                label: b.name,
                              ),
                            ),
                          ],
                          onChanged: (v) => _cubit.setBranch(
                              v == null || v.isEmpty ? null : v),
                        ),
                      if (branches.isNotEmpty)
                        const SizedBox(height: AppSpacing.sm),
                      AppSelectField<String>(
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
                        onChanged: (v) => _cubit.setWarehouse(
                            v == null || v.isEmpty ? null : v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => _cubit.setLowStockOnly(!lowStockOnly),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: lowStockOnly
                                ? AppColors.destructive.withValues(alpha: 0.1)
                                : AppColors.surface,
                            border: Border.all(
                              color: lowStockOnly
                                  ? AppColors.destructive
                                  : AppColors.border,
                            ),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: lowStockOnly
                                    ? AppColors.destructive
                                    : AppColors.mutedForeground,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                l10n.t('lowStockOnly'),
                                style: AppTextStyles.bodySm.copyWith(
                                  color: lowStockOnly
                                      ? AppColors.destructive
                                      : AppColors.mutedForeground,
                                  fontWeight: lowStockOnly
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (state) {
                    WarehouseStockInitial() ||
                    WarehouseStockLoading() =>
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: 8,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ShimmerBox(height: 112),
                        ),
                      ),
                    WarehouseStockError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: _cubit.refresh,
                      ),
                    WarehouseStockLoaded(:final balances)
                        when balances.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.store_mall_directory_outlined,
                            size: 40),
                        message: l10n.t('noInventoryItems'),
                      ),
                    WarehouseStockLoaded(:final balances) =>
                      RefreshIndicator(
                        onRefresh: () async => _cubit.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          itemCount: balances.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) => _StockCard(
                            balance: balances[i],
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
      ),
    );
  }
}

// ── Stock Card ────────────────────────────────────────────────────────────────

Color _warehouseTypeColor(String type) => switch (type) {
      'main' => AppColors.primary,
      'transit' => AppColors.mutedForeground,
      'returns' => AppColors.mutedForeground,
      'damaged' => AppColors.destructive,
      _ => AppColors.primary,
    };

class _StockCard extends StatelessWidget {
  final InventoryBalanceEntity balance;
  final AppLocalizations l10n;

  const _StockCard({required this.balance, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final badgeColor = _warehouseTypeColor(balance.warehouseType);
    final status = balance.stockStatus;

    Color statusColor;
    String statusLabel;
    if (status == 'out') {
      statusColor = AppColors.destructive;
      statusLabel = l10n.t('stockOut');
    } else if (status == 'low') {
      statusColor = Colors.amber.shade700;
      statusLabel = l10n.t('stockLow');
    } else {
      statusColor = AppColors.success;
      statusLabel = l10n.t('stockOk');
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  balance.productName,
                  style: AppTextStyles.labelMd.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge.custom(
                label: statusLabel,
                color: statusColor,
                bgColor: statusColor.withValues(alpha: 0.1),
              ),
            ],
          ),
          if (balance.productSku != null) ...[
            const SizedBox(height: 2),
            Text(
              balance.productSku!,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              StatusBadge.custom(
                label: balance.warehouseCode,
                color: badgeColor,
                bgColor: badgeColor.withValues(alpha: 0.1),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  balance.warehouseName,
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (balance.branchName != null)
                Text(
                  balance.branchName!,
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _QtyItem(
                label: l10n.t('colOnHand'),
                value: AppFormatters.decimal(balance.onHandQty),
                suffix: balance.productUnit,
                fg: fg,
                muted: muted,
              ),
              const SizedBox(width: AppSpacing.md),
              _QtyItem(
                label: l10n.t('colReserved'),
                value: balance.reservedQty > 0
                    ? AppFormatters.decimal(balance.reservedQty)
                    : '—',
                fg: muted,
                muted: muted,
              ),
              const SizedBox(width: AppSpacing.md),
              _QtyItem(
                label: l10n.t('colAvailable'),
                value: AppFormatters.decimal(balance.availableQty),
                fg: balance.availableQty <= 0
                    ? AppColors.destructive
                    : fg,
                muted: muted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyItem extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final Color fg;
  final Color muted;

  const _QtyItem({
    required this.label,
    required this.value,
    this.suffix,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyXs.copyWith(color: muted)),
        Row(
          children: [
            Text(
              value,
              style: AppTextStyles.numeric.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 2),
              Text(
                suffix!,
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
