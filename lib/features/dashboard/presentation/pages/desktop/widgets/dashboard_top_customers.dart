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

class DashboardTopCustomers extends StatelessWidget {
  final List<TopCustomerEntity> customers;

  const DashboardTopCustomers({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final maxSpent = customers.isEmpty
        ? 1.0
        : customers.map((c) => c.totalSpent).reduce((a, b) => a > b ? a : b);

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
              AppLocalizations.of(context).topCustomers,
              style: AppTextStyles.h6.copyWith(color: fg),
            ),
          ),
          Divider(color: border, height: 1),
          if (customers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl3),
              child: AppEmptyState(
                icon: const Icon(Icons.people_outline_rounded),
                message: AppLocalizations.of(context).noCustomersYet,
                subtitle: AppLocalizations.of(context).customerDataWillAppearHere,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(AppSpacing.base),
              child: Column(
                children: [
                  for (int i = 0; i < customers.length; i++) ...[
                    _CustomerRow(
                      rank: i + 1,
                      customer: customers[i],
                      maxSpent: maxSpent,
                      muted: muted,
                    ),
                    if (i < customers.length - 1)
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

class _CustomerRow extends StatelessWidget {
  final int rank;
  final TopCustomerEntity customer;
  final double maxSpent;
  final Color muted;

  const _CustomerRow({
    required this.rank,
    required this.customer,
    required this.maxSpent,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final barBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final avatarBg = isDark ? AppColors.darkMuted : AppColors.primaryBg;
    final pct =
        maxSpent > 0 ? (customer.totalSpent / maxSpent).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: avatarBg,
                borderRadius: AppRadius.brFull,
              ),
              child: Center(
                child: Text(
                  AppFormatters.initials(customer.customerName),
                  style: AppTextStyles.labelXs.copyWith(
                    color: cs.primary,
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
                    style: AppTextStyles.tableCellMd.copyWith(color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${customer.ordersCount} ${l10n.orders}',
                    style: AppTextStyles.caption.copyWith(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 76,
              child: Text(
                AppFormatters.compact(customer.totalSpent),
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

class DashboardTopCustomersShimmer extends StatelessWidget {
  const DashboardTopCustomersShimmer({super.key});

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
          const ShimmerBox(width: 110, height: 16),
          const SizedBox(height: AppSpacing.base),
          for (int i = 0; i < 5; i++) ...[
            const Row(
              children: [
                ShimmerBox(width: 28, height: 28, borderRadius: AppRadius.brFull),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: ShimmerBox(height: 14)),
                SizedBox(width: AppSpacing.sm),
                ShimmerBox(width: 60, height: 14),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const ShimmerBox(height: 4),
            if (i < 4) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
