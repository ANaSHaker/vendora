import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/widgets/cards/stat_card.dart';
import '../../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../domain/entities/dashboard_entities.dart';

class DashboardKpiCards extends StatelessWidget {
  final DashboardSummaryEntity summary;

  const DashboardKpiCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: l10n.totalOrders,
            value: AppFormatters.number(summary.totalOrders),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ),
        const SizedBox(width: AppSizes.desktopCardGap),
        Expanded(
          child: StatCard(
            label: l10n.totalSales,
            value: AppFormatters.compact(summary.totalSales),
            icon: const Icon(Icons.trending_up_rounded),
          ),
        ),
        const SizedBox(width: AppSizes.desktopCardGap),
        Expanded(
          child: StatCard(
            label: l10n.avgOrderValue,
            value: AppFormatters.compact(summary.avgOrderValue),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
        ),
        const SizedBox(width: AppSizes.desktopCardGap),
        Expanded(
          child: StatCard(
            label: l10n.netRevenue,
            value: AppFormatters.compact(summary.netRevenue),
            icon: const Icon(Icons.account_balance_wallet_rounded),
          ),
        ),
        const SizedBox(width: AppSizes.desktopCardGap),
        Expanded(
          child: StatCard(
            label: l10n.totalRefunds,
            value: AppFormatters.compact(summary.totalRefunds),
            icon: const Icon(Icons.replay_rounded),
          ),
        ),
      ],
    );
  }
}

class DashboardKpiCardsShimmer extends StatelessWidget {
  const DashboardKpiCardsShimmer({super.key});

  @override
  Widget build(BuildContext context) => const ShimmerStatCards();
}
