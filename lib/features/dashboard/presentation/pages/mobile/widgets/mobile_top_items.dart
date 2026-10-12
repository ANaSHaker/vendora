import 'package:flutter/material.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../domain/entities/dashboard_entities.dart';

// ─── Top Products ──────────────────────────────────────────────────────────────

class MobileTopProducts extends StatelessWidget {
  final List<TopProductEntity> products;

  const MobileTopProducts({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Products', style: AppTextStyles.h6.copyWith(color: fg)),
        const SizedBox(height: AppSpacing.sm),
        if (products.isEmpty)
          const AppEmptyState(
            icon: Icon(Icons.inventory_2_outlined),
            message: 'No products yet',
            subtitle: 'Sales data will appear here',
          )
        else
          ...products.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MobileProductRow(rank: e.key + 1, product: e.value),
              )),
      ],
    );
  }
}

class _MobileProductRow extends StatelessWidget {
  final int rank;
  final TopProductEntity product;

  const _MobileProductRow({required this.rank, required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '$rank',
              style: AppTextStyles.labelSm.copyWith(color: muted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              product.productName,
              style: AppTextStyles.labelMd.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '×${product.totalQty}',
            style: AppTextStyles.labelSm.copyWith(color: muted),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            AppFormatters.compact(product.totalRevenue),
            style: AppTextStyles.labelMd.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ─── Top Customers ─────────────────────────────────────────────────────────────

class MobileTopCustomers extends StatelessWidget {
  final List<TopCustomerEntity> customers;

  const MobileTopCustomers({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Customers', style: AppTextStyles.h6.copyWith(color: fg)),
        const SizedBox(height: AppSpacing.sm),
        if (customers.isEmpty)
          const AppEmptyState(
            icon: Icon(Icons.people_outline_rounded),
            message: 'No customers yet',
            subtitle: 'Customer data will appear here',
          )
        else
          ...customers.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MobileCustomerRow(rank: e.key + 1, customer: e.value),
              )),
      ],
    );
  }
}

class _MobileCustomerRow extends StatelessWidget {
  final int rank;
  final TopCustomerEntity customer;

  const _MobileCustomerRow({required this.rank, required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final avatarBg = isDark ? AppColors.darkMuted : AppColors.primaryBg;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: avatarBg,
              borderRadius: AppRadius.brFull,
            ),
            child: Center(
              child: Text(
                AppFormatters.initials(customer.customerName),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customerName,
                  style: AppTextStyles.labelMd.copyWith(color: fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${customer.ordersCount} orders',
                  style: AppTextStyles.caption.copyWith(color: muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.compact(customer.totalSpent),
            style: AppTextStyles.labelMd.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer placeholders ──────────────────────────────────────────────────────

class MobileTopItemsShimmer extends StatelessWidget {
  const MobileTopItemsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: ShimmerBox(height: 48),
        ),
      ),
    );
  }
}
