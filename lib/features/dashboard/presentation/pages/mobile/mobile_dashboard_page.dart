import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/charts/sales_area_chart.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../cubit/dashboard_state.dart';
import 'widgets/mobile_stat_cards_grid.dart';
import 'widgets/mobile_top_items.dart';

class MobileDashboardPage extends StatelessWidget {
  const MobileDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(getIt())..load(),
      child: const _MobileDashboardView(),
    );
  }
}

class _MobileDashboardView extends StatelessWidget {
  const _MobileDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final cubit = context.read<DashboardCubit>();
        final filters = _filtersFrom(state);

        return RefreshIndicator(
          onRefresh: cubit.refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _MobileHeader(
                  filters: filters,
                  cubit: cubit,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.base,
                  AppSpacing.sm,
                  AppSpacing.base,
                  AppSpacing.xl4 + AppSpacing.xl,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStats(state),
                    const SizedBox(height: AppSpacing.base),
                    _buildChart(context, state),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTopProducts(state),
                    const SizedBox(height: AppSpacing.xl),
                    _buildTopCustomers(state),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  DashboardFilters _filtersFrom(DashboardState state) {
    if (state is DashboardLoading) return state.filters;
    if (state is DashboardLoaded) return state.filters;
    if (state is DashboardError) return state.filters;
    return const DashboardFilters(period: DashboardPeriodFilter.month);
  }

  Widget _buildStats(DashboardState state) {
    if (state is DashboardLoaded) {
      return MobileStatCardsGrid(summary: state.data.summary);
    }
    if (state is DashboardError) {
      return AppErrorWidget(
        message: 'Failed to load',
        subtitle: state.message,
        height: 120,
      );
    }
    return const MobileStatCardsGridShimmer();
  }

  Widget _buildChart(BuildContext context, DashboardState state) {
    if (state is DashboardLoaded) {
      final chartData = state.data.salesPerDay
          .map((e) => SalesDayData(date: e.date, amount: e.totalSales))
          .toList();
      final dark = Theme.of(context).brightness == Brightness.dark;
      final surface = dark ? AppColors.darkSurface : AppColors.surface;
      final border = dark ? AppColors.darkBorder : AppColors.border;
      final fg = dark ? AppColors.darkForeground : AppColors.foreground;
      final l10n = AppLocalizations.of(context);

      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.salesPerDay, style: AppTextStyles.h6.copyWith(color: fg)),
            const SizedBox(height: AppSpacing.md),
            SalesAreaChart(data: chartData, height: 180),
          ],
        ),
      );
    }
    if (state is DashboardError) {
      return AppErrorWidget(
        message: 'Chart unavailable',
        subtitle: state.message,
        height: 200,
      );
    }
    return const ShimmerBox(height: 220);
  }

  Widget _buildTopProducts(DashboardState state) {
    if (state is DashboardLoaded) {
      return MobileTopProducts(products: state.data.topProducts);
    }
    if (state is DashboardError) return const SizedBox.shrink();
    return const MobileTopItemsShimmer();
  }

  Widget _buildTopCustomers(DashboardState state) {
    if (state is DashboardLoaded) {
      return MobileTopCustomers(customers: state.data.topCustomers);
    }
    if (state is DashboardError) return const SizedBox.shrink();
    return const MobileTopItemsShimmer();
  }
}

// ─── Mobile Header ────────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  final DashboardFilters filters;
  final DashboardCubit cubit;

  const _MobileHeader({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.md,
        bottom: AppSpacing.sm,
        left: AppSpacing.base,
        right: AppSpacing.base,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashboard, style: AppTextStyles.h5.copyWith(color: fg)),
          const SizedBox(height: AppSpacing.sm),
          _MobilePeriodChips(
            filters: filters,
            onChanged: cubit.changePeriod,
            onCustomRange: cubit.changeCustomPeriod,
          ),
        ],
      ),
    );
  }
}

class _MobilePeriodChips extends StatelessWidget {
  final DashboardFilters filters;
  final void Function(DashboardPeriodFilter) onChanged;
  final Future<void> Function(DateTime from, DateTime to) onCustomRange;

  const _MobilePeriodChips({
    required this.filters,
    required this.onChanged,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final locale = AppLocalizations.of(context).locale.languageCode;
    final todayLabel = DashboardFilters(period: DashboardPeriodFilter.today)
        .chipDateLabelFor(locale);
    final weekLabel = DashboardFilters(period: DashboardPeriodFilter.week)
        .chipDateLabelFor(locale);
    final monthLabel = DashboardFilters(period: DashboardPeriodFilter.month)
        .chipDateLabelFor(locale);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _MobileChip(
            label: l10n.today,
            dateLabel: todayLabel,
            value: DashboardPeriodFilter.today,
            current: filters.period,
            onChanged: onChanged,
          ),
          const SizedBox(width: AppSpacing.sm),
          _MobileChip(
            label: l10n.thisWeek,
            dateLabel: weekLabel,
            value: DashboardPeriodFilter.week,
            current: filters.period,
            onChanged: onChanged,
          ),
          const SizedBox(width: AppSpacing.sm),
          _MobileChip(
            label: l10n.thisMonth,
            dateLabel: monthLabel,
            value: DashboardPeriodFilter.month,
            current: filters.period,
            onChanged: onChanged,
          ),
          const SizedBox(width: AppSpacing.sm),
          _MobileCustomChip(
            filters: filters,
            onCustomRange: onCustomRange,
          ),
        ],
      ),
    );
  }
}

class _MobileChip extends StatelessWidget {
  final String label;
  final String dateLabel;
  final DashboardPeriodFilter value;
  final DashboardPeriodFilter current;
  final void Function(DashboardPeriodFilter) onChanged;

  const _MobileChip({
    required this.label,
    required this.dateLabel,
    required this.value,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = value == current;
    const activeBg = AppColors.primary;
    final inactiveBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    const activeFg = AppColors.white;
    final inactiveFg =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return GestureDetector(
      onTap: isActive ? null : () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: AppRadius.brFull,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: isActive ? activeFg : inactiveFg,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            Text(
              dateLabel,
              style: AppTextStyles.caption.copyWith(
                color: isActive ? activeFg.withOpacity(0.8) : inactiveFg,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileCustomChip extends StatelessWidget {
  final DashboardFilters filters;
  final Future<void> Function(DateTime from, DateTime to) onCustomRange;

  const _MobileCustomChip({
    required this.filters,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = filters.period == DashboardPeriodFilter.custom;
    const activeBg = AppColors.primary;
    final inactiveBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    const activeFg = AppColors.white;
    final inactiveFg =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => _pickRange(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: AppRadius.brFull,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 11,
                  color: isActive ? activeFg : inactiveFg,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.customRange,
                  style: AppTextStyles.labelSm.copyWith(
                    color: isActive ? activeFg : inactiveFg,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
            if (isActive)
              Text(
                filters.chipDateLabelFor(
                    AppLocalizations.of(context).locale.languageCode),
                style: AppTextStyles.caption.copyWith(
                  color: activeFg.withOpacity(0.8),
                  fontSize: 9,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final primary = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: filters.period == DashboardPeriodFilter.custom &&
              filters.customFrom != null &&
              filters.customTo != null
          ? DateTimeRange(start: filters.customFrom!, end: filters.customTo!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: primary),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      await onCustomRange(result.start, result.end);
    }
  }
}
