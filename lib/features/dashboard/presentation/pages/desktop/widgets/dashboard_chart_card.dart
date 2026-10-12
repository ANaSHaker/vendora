import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/charts/sales_area_chart.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../domain/entities/dashboard_entities.dart';

class DashboardChartCard extends StatelessWidget {
  final List<SalesPerDayEntity> salesPerDay;

  const DashboardChartCard({super.key, required this.salesPerDay});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final chartData = salesPerDay
        .map((e) => SalesDayData(date: e.date, amount: e.totalSales))
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppLocalizations.of(context).salesPerDay, style: AppTextStyles.h6.copyWith(color: fg)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '(${salesPerDay.length})',
                style: AppTextStyles.labelSm.copyWith(color: muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          SalesAreaChart(data: chartData, height: 220),
        ],
      ),
    );
  }
}

class DashboardChartCardShimmer extends StatelessWidget {
  const DashboardChartCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 120, height: 18),
          SizedBox(height: AppSpacing.base),
          ShimmerBox(height: 220),
        ],
      ),
    );
  }
}
