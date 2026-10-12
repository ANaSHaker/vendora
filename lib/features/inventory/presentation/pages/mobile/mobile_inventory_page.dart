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
import '../../cubit/inventory_stock_cubit.dart';
import '../../cubit/inventory_stock_state.dart';

class MobileInventoryPage extends StatefulWidget {
  const MobileInventoryPage({super.key});

  @override
  State<MobileInventoryPage> createState() => _MobileInventoryPageState();
}

class _MobileInventoryPageState extends State<MobileInventoryPage> {
  late final InventoryStockCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = InventoryStockCubit(
      getStock: getIt<GetInventoryStockUseCase>(),
      getWarehouses: getIt<GetInventoryWarehouseOptionsUseCase>(),
      getBranches: getIt<GetInventoryBranchOptionsUseCase>(),
    )..load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cubit.loadWarehouses();
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
      child: BlocBuilder<InventoryStockCubit, InventoryStockState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final warehouses = state is InventoryStockLoaded
              ? state.warehouses
              : <WarehouseOptionEntity>[];
          final selectedWarehouseId =
              state is InventoryStockLoaded ? state.warehouseId : null;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l10n.t('inventoryStock'), style: AppTextStyles.h6),
              elevation: 0,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(height: 1, color: AppColors.border),
              ),
            ),
            body: Column(
              children: [
                // Filters
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
                              label: '${w.code} – ${w.name}',
                            ),
                          ),
                        ],
                        onChanged: (v) => _cubit.setWarehouse(
                            v == null || v.isEmpty ? null : v),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: switch (state) {
                    InventoryStockInitial() ||
                    InventoryStockLoading() =>
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: 8,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ShimmerBox(height: 96),
                        ),
                      ),
                    InventoryStockError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: _cubit.refresh,
                      ),
                    InventoryStockLoaded(:final balances)
                        when balances.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.inventory_2_outlined,
                            size: 40),
                        message: l10n.t('noInventoryItems'),
                      ),
                    InventoryStockLoaded(:final balances) =>
                      RefreshIndicator(
                        onRefresh: () async => _cubit.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          itemCount: balances.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) =>
                              _BalanceCard(balance: balances[i], l10n: l10n),
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

// ── Balance Card ──────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final InventoryBalanceEntity balance;
  final AppLocalizations l10n;

  const _BalanceCard({required this.balance, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

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
          // Product name + SKU
          Row(
            children: [
              Expanded(
                child: Text(
                  balance.productName,
                  style: AppTextStyles.labelMd.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (balance.productSku != null)
                Text(
                  balance.productSku!,
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Warehouse
          Row(
            children: [
              StatusBadge.custom(
                label: balance.warehouseCode,
                color: AppColors.primary,
                bgColor: AppColors.primary.withValues(alpha: 0.1),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                balance.warehouseName,
                style: AppTextStyles.bodySm.copyWith(color: muted),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Qty row
          Row(
            children: [
              _QtyItem(
                label: l10n.t('colOnHand'),
                value: AppFormatters.decimal(balance.onHandQty),
                fg: fg,
                muted: muted,
              ),
              const SizedBox(width: AppSpacing.md),
              _QtyItem(
                label: l10n.t('colReserved'),
                value: AppFormatters.decimal(balance.reservedQty),
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
  final Color fg;
  final Color muted;

  const _QtyItem({
    required this.label,
    required this.value,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyXs.copyWith(color: muted),
        ),
        Text(
          value,
          style: AppTextStyles.numeric.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
