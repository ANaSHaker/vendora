import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../domain/entities/dashboard_entities.dart';

class DashboardTopProducts extends StatelessWidget {
  final List<TopProductEntity> products;

  const DashboardTopProducts({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final maxRevenue = products.isEmpty
        ? 1.0
        : products.map((p) => p.totalRevenue).reduce((a, b) => a > b ? a : b);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.md,
            ),
            child: Text(
              AppLocalizations.of(context).topProducts,
              style: AppTextStyles.h6.copyWith(color: fg),
            ),
          ),
          Divider(color: border, height: 1),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl3),
              child: AppEmptyState(
                icon: const Icon(Icons.inventory_2_outlined),
                message: AppLocalizations.of(context).noProductsYet,
                subtitle: AppLocalizations.of(context).salesDataWillAppearHere,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                children: [
                  for (int i = 0; i < products.length; i++) ...[
                    _ProductRow(
                      rank: i + 1,
                      product: products[i],
                      maxRevenue: maxRevenue,
                      muted: muted,
                    ),
                    if (i < products.length - 1)
                      const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final TopProductEntity product;
  final double maxRevenue;
  final Color muted;

  const _ProductRow({
    required this.rank,
    required this.product,
    required this.maxRevenue,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final barBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final pct = maxRevenue > 0 ? (product.totalRevenue / maxRevenue).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: AppTextStyles.labelSm.copyWith(color: muted),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                product.productName,
                style: AppTextStyles.tableCellMd.copyWith(color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '×${AppFormatters.number(product.totalQty)}',
              style: AppTextStyles.labelSm.copyWith(color: muted),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 76,
              child: Text(
                AppFormatters.compact(product.totalRevenue),
                style: AppTextStyles.labelMd.copyWith(color: fg),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (_, constraints) => Stack(
            children: [
              Container(
                height: 4,
                width: constraints.maxWidth,
                decoration: BoxDecoration(
                  color: barBg,
                  borderRadius: AppRadius.brFull,
                ),
              ),
              Container(
                height: 4,
                width: constraints.maxWidth * pct,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: AppRadius.brFull,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DashboardTopProductsShimmer extends StatelessWidget {
  const DashboardTopProductsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 100, height: 16),
          const SizedBox(height: AppSpacing.base),
          for (int i = 0; i < 5; i++) ...[
            const ShimmerBox(height: 14),
            const SizedBox(height: AppSpacing.xs),
            const ShimmerBox(height: 4),
            if (i < 4) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
