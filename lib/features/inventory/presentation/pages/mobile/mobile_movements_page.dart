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
import '../../cubit/inventory_movements_cubit.dart';
import '../../cubit/inventory_movements_state.dart';
import '../../../../../features/products/domain/usecases/products_usecases.dart';

// ── Movement type helpers (shared logic) ─────────────────────────────────────

bool _isDestructiveType(String type) {
  const destructive = {
    'sale',
    'transfer_out',
    'stock_count_loss',
    'adjustment_out',
    'damaged',
  };
  return destructive.contains(type);
}

const _kMovementTypes = [
  'sale',
  'return',
  'purchase',
  'adjustment',
  'transfer_in',
  'transfer_out',
  'stock_count',
  'stock_count_gain',
  'stock_count_loss',
  'damaged',
  'adjustment_in',
  'adjustment_out',
];

// ── Page ──────────────────────────────────────────────────────────────────────

class MobileMovementsPage extends StatefulWidget {
  const MobileMovementsPage({super.key});

  @override
  State<MobileMovementsPage> createState() => _MobileMovementsPageState();
}

class _MobileMovementsPageState extends State<MobileMovementsPage> {
  late final InventoryMovementsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = InventoryMovementsCubit(
      getMovements: getIt<GetInventoryMovementsUseCase>(),
      getWarehouses: getIt<GetInventoryWarehouseOptionsUseCase>(),
      getProducts: getIt<GetProductsUseCase>(),
    )..load();
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
      child: BlocBuilder<InventoryMovementsCubit, InventoryMovementsState>(
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          final selectedType =
              state is InventoryMovementsLoaded ? state.movementType : null;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(l10n.t('inventoryMovements'),
                  style: AppTextStyles.h6),
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
                        hint: l10n.t('searchMovements'),
                        onChanged: _cubit.search,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSelectField<String>(
                        hint: l10n.t('allMovementTypes'),
                        value: selectedType,
                        options: [
                          AppSelectOption(
                            value: '',
                            label: l10n.t('allMovementTypes'),
                          ),
                          ..._kMovementTypes.map(
                            (t) => AppSelectOption(
                              value: t,
                              label: l10n.t('movementType_$t'),
                            ),
                          ),
                        ],
                        onChanged: (v) => _cubit.setMovementType(
                            v == null || v.isEmpty ? null : v),
                      ),
                    ],
                  ),
                ),

                // Summary cards
                if (state is InventoryMovementsLoaded &&
                    state.summary != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: _MobileSummaryRow(
                      summary: state.summary!,
                      l10n: l10n,
                    ),
                  ),

                if (state is InventoryMovementsLoaded &&
                    state.summary != null)
                  const SizedBox(height: AppSpacing.sm),

                // Content
                Expanded(
                  child: switch (state) {
                    InventoryMovementsInitial() ||
                    InventoryMovementsLoading() =>
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        itemCount: 8,
                        itemBuilder: (_, __) => const Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ShimmerBox(height: 104),
                        ),
                      ),
                    InventoryMovementsError(:final message) =>
                      AppErrorWidget(
                        message: message,
                        onRetry: _cubit.refresh,
                      ),
                    InventoryMovementsLoaded(:final movements)
                        when movements.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.swap_horiz_outlined,
                            size: 40),
                        message: l10n.t('noMovements'),
                      ),
                    InventoryMovementsLoaded(:final movements) =>
                      RefreshIndicator(
                        onRefresh: () async => _cubit.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          itemCount: movements.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, i) =>
                              _MovementCard(movement: movements[i], l10n: l10n),
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

// ── Mobile Summary Row ────────────────────────────────────────────────────────

class _MobileSummaryRow extends StatelessWidget {
  final InventoryMovementsSummary summary;
  final AppLocalizations l10n;

  const _MobileSummaryRow({required this.summary, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Row(
      children: [
        _MiniSummaryTile(
          label: l10n.t('summaryTotalMovements'),
          value: '${summary.totalMovements}',
          color: AppColors.primary,
          surface: surface,
          border: border,
          fg: fg,
          muted: muted,
        ),
        const SizedBox(width: AppSpacing.sm),
        _MiniSummaryTile(
          label: l10n.t('summaryTotalQtyIn'),
          value: AppFormatters.decimal(summary.totalQtyIn),
          color: AppColors.successForeground,
          surface: surface,
          border: border,
          fg: AppColors.successForeground,
          muted: muted,
        ),
        const SizedBox(width: AppSpacing.sm),
        _MiniSummaryTile(
          label: l10n.t('summaryTotalQtyOut'),
          value: AppFormatters.decimal(summary.totalQtyOut),
          color: AppColors.destructive,
          surface: surface,
          border: border,
          fg: AppColors.destructive,
          muted: muted,
        ),
      ],
    );
  }
}

class _MiniSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color surface;
  final Color border;
  final Color fg;
  final Color muted;

  const _MiniSummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.surface,
    required this.border,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: AppRadius.brSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              value,
              style: AppTextStyles.labelSm.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Movement Card ─────────────────────────────────────────────────────────────

class _MovementCard extends StatelessWidget {
  final InventoryMovementEntity movement;
  final AppLocalizations l10n;

  const _MovementCard({required this.movement, required this.l10n});

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final isDestructive = _isDestructiveType(movement.movementType);
    final typeColor =
        isDestructive ? AppColors.destructive : AppColors.primary;
    final typeBg = isDestructive
        ? AppColors.destructive.withValues(alpha: 0.1)
        : AppColors.primary.withValues(alpha: 0.1);

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
          // Top row: product name + date
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.productName,
                      style: AppTextStyles.labelMd.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movement.productSku != null)
                      Text(
                        movement.productSku!,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _fmtDate(movement.createdAt),
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Warehouse + type badge
          Row(
            children: [
              StatusBadge.custom(
                label: movement.warehouseCode,
                color: AppColors.primary,
                bgColor: AppColors.primary.withValues(alpha: 0.1),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  movement.warehouseName,
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusBadge.custom(
                label: l10n.t('movementType_${movement.movementType}'),
                color: typeColor,
                bgColor: typeBg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Qty row
          Row(
            children: [
              if (movement.qtyIn > 0) ...[
                Icon(Icons.add, size: 12, color: AppColors.successForeground),
                const SizedBox(width: 2),
                Text(
                  AppFormatters.decimal(movement.qtyIn),
                  style: AppTextStyles.numeric.copyWith(
                    color: AppColors.successForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              if (movement.qtyOut > 0) ...[
                Icon(Icons.remove, size: 12, color: AppColors.destructive),
                const SizedBox(width: 2),
                Text(
                  AppFormatters.decimal(movement.qtyOut),
                  style: AppTextStyles.numeric.copyWith(
                    color: AppColors.destructive,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              const Spacer(),
              Text(
                l10n.t('colBalance'),
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppFormatters.decimal(movement.balanceAfter),
                style: AppTextStyles.numeric.copyWith(color: fg),
              ),
            ],
          ),

          // Notes (if present)
          if (movement.notes != null && movement.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              movement.notes!,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
