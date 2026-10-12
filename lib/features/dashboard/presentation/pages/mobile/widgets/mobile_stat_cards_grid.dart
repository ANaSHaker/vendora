import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../domain/entities/dashboard_entities.dart';

class MobileStatCardsGrid extends StatelessWidget {
  final DashboardSummaryEntity summary;

  const MobileStatCardsGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      (
        label: l10n.totalOrders,
        value: AppFormatters.number(summary.totalOrders),
        icon: Icons.shopping_cart_outlined,
      ),
      (
        label: l10n.totalSales,
        value: AppFormatters.compact(summary.totalSales),
        icon: Icons.trending_up_rounded,
      ),
      (
        label: l10n.netRevenue,
        value: AppFormatters.compact(summary.netRevenue),
        icon: Icons.account_balance_wallet_rounded,
      ),
      (
        label: l10n.avgOrderValue,
        value: AppFormatters.compact(summary.avgOrderValue),
        icon: Icons.bar_chart_rounded,
      ),
      (
        label: l10n.totalRefunds,
        value: AppFormatters.compact(summary.totalRefunds),
        icon: Icons.replay_rounded,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.7,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards
          .map((c) => _MobileStatCard(label: c.label, value: c.value, icon: c.icon))
          .toList(),
    );
  }
}

class _MobileStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MobileStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

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
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: AppSizes.iconMd, color: muted),
            ],
          ),
          Text(
            value,
            style: AppTextStyles.numericLg.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class MobileStatCardsGridShimmer extends StatelessWidget {
  const MobileStatCardsGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.7,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, (_) => const ShimmerBox(height: double.infinity)),
    );
  }
}
