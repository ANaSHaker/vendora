import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../domain/entities/admin_analytics_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit(
        getAnalytics: getIt<GetAdminAnalyticsUseCase>(),
        getVendors: getIt<GetAdminVendorsUseCase>(),
      )..load(),
      child: const _AnalyticsContent(),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.t('analytics'),
                    style: AppTextStyles.h4.copyWith(color: fg)),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.t('adminDashboardSubtitle'),
                    style: AppTextStyles.bodySm.copyWith(color: muted)),
                const SizedBox(height: AppSpacing.xl),
                if (state is AdminDashboardLoading)
                  const ShimmerStatCards(count: 4)
                else if (state is AdminDashboardError)
                  AppErrorWidget(
                    message: state.message,
                    onRetry: () => context.read<AdminDashboardCubit>().load(),
                  )
                else if (state is AdminDashboardLoaded) ...[
                  _StatsRow(
                    analytics: state.analytics,
                    isDark: isDark,
                    borderColor: borderColor,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _RevenueChartCard(
                    data: state.analytics.dailyPlatform,
                    isDark: isDark,
                    borderColor: borderColor,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _TopVendorsCard(
                    vendors: state.analytics.topVendors,
                    isDark: isDark,
                    borderColor: borderColor,
                    fg: fg,
                    muted: muted,
                    l10n: l10n,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AdminAnalyticsEntity analytics;
  final bool isDark;
  final Color borderColor;
  final AppLocalizations l10n;

  const _StatsRow({
    required this.analytics,
    required this.isDark,
    required this.borderColor,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.store_rounded,
        label: l10n.t('totalVendors'),
        value: analytics.totalVendors.toString(),
        color: AppColors.primary,
        isDark: isDark,
        borderColor: borderColor,
      ),
      _StatCard(
        icon: Icons.check_circle_rounded,
        label: l10n.t('activeVendors'),
        value: analytics.activeVendors.toString(),
        color: AppColors.statusPaid,
        isDark: isDark,
        borderColor: borderColor,
      ),
      _StatCard(
        icon: Icons.receipt_long_rounded,
        label: l10n.t('totalOrders'),
        value: analytics.totalOrders.toString(),
        color: AppColors.warning,
        isDark: isDark,
        borderColor: borderColor,
      ),
      _StatCard(
        icon: Icons.attach_money_rounded,
        label: l10n.t('totalRevenue'),
        value: AppFormatters.currency(analytics.totalRevenue),
        color: AppColors.primary,
        isDark: isDark,
        borderColor: borderColor,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.2,
          children: cards,
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final Color borderColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: AppTextStyles.labelSm.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Text(value,
                    style: AppTextStyles.h5.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  final List<AdminDailyPlatformEntity> data;
  final bool isDark;
  final Color borderColor;
  final AppLocalizations l10n;

  const _RevenueChartCard({
    required this.data,
    required this.isDark,
    required this.borderColor,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.t('revenueOverTime'),
              style: AppTextStyles.labelLg.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 240,
            child: data.isEmpty
                ? Center(
                    child: Text(l10n.t('noData'),
                        style: AppTextStyles.bodySm.copyWith(color: muted)),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: borderColor,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 44,
                            getTitlesWidget: (value, meta) => Text(
                              AppFormatters.compact(value),
                              style:
                                  AppTextStyles.bodyXs.copyWith(color: muted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: (data.length / 6).clamp(1, 100).toDouble(),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _shortDate(data[i].date),
                                  style: AppTextStyles.bodyXs
                                      .copyWith(color: muted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < data.length; i++)
                              FlSpot(i.toDouble(), data[i].revenue),
                          ],
                          isCurved: true,
                          color: cs.primary,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: cs.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return iso;
    }
  }
}

class _TopVendorsCard extends StatelessWidget {
  final List<AdminTopVendorEntity> vendors;
  final bool isDark;
  final Color borderColor;
  final Color fg;
  final Color muted;
  final AppLocalizations l10n;

  const _TopVendorsCard({
    required this.vendors,
    required this.isDark,
    required this.borderColor,
    required this.fg,
    required this.muted,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.muted;

    Widget headerCell(String key, {int flex = 2, TextAlign align = TextAlign.start}) =>
        Expanded(
          flex: flex,
          child: Text(l10n.t(key),
              textAlign: align,
              style: AppTextStyles.tableHeader.copyWith(color: muted)),
        );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l10n.t('topVendorsByRevenue'),
                  style: AppTextStyles.labelLg.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          if (vendors.isEmpty)
            AppEmptyState(message: l10n.t('noVendors'))
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  headerCell('rank', flex: 1),
                  headerCell('vendor', flex: 4),
                  headerCell('revenue', flex: 2, align: TextAlign.end),
                  headerCell('totalOrders', flex: 2, align: TextAlign.end),
                ],
              ),
            ),
            ...vendors.asMap().entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text('${e.key + 1}',
                            style:
                                AppTextStyles.tableCell.copyWith(color: muted)),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.value.name,
                                style: AppTextStyles.tableCell.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w500,
                                )),
                            if (e.value.email != null)
                              Text(e.value.email!,
                                  style: AppTextStyles.tableCell
                                      .copyWith(color: muted)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          AppFormatters.currency(e.value.totalRevenue),
                          textAlign: TextAlign.end,
                          style: AppTextStyles.numeric.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          e.value.ordersCount.toString(),
                          textAlign: TextAlign.end,
                          style: AppTextStyles.numeric.copyWith(color: fg),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
