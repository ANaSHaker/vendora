import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../cubit/dashboard_cubit.dart';
import '../../cubit/dashboard_state.dart';
import 'widgets/dashboard_chart_card.dart';
import 'widgets/dashboard_kpi_cards.dart';
import 'widgets/dashboard_top_customers.dart';
import 'widgets/dashboard_top_products.dart';

class DesktopDashboardPage extends StatelessWidget {
  const DesktopDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit(getIt())..load(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.muted;

    return ColoredBox(
      color: bg,
      child: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final filters = _filtersFrom(state);
          final cubit = context.read<DashboardCubit>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(filters: filters, cubit: cubit),
                const SizedBox(height: AppSpacing.xl),
                _buildKpiSection(context, state, cubit),
                const SizedBox(height: AppSizes.desktopCardGap),
                _buildChartSection(context, state, cubit),
                const SizedBox(height: AppSizes.desktopCardGap),
                _buildBottomRow(state),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  DashboardFilters _filtersFrom(DashboardState state) {
    if (state is DashboardLoading) return state.filters;
    if (state is DashboardLoaded) return state.filters;
    if (state is DashboardError) return state.filters;
    return const DashboardFilters(period: DashboardPeriodFilter.month);
  }

  Widget _buildKpiSection(
    BuildContext context,
    DashboardState state,
    DashboardCubit cubit,
  ) {
    if (state is DashboardLoaded) {
      return DashboardKpiCards(summary: state.data.summary);
    }
    if (state is DashboardError) {
      return _SectionError(message: state.message, onRetry: cubit.refresh);
    }
    return const DashboardKpiCardsShimmer();
  }

  Widget _buildChartSection(
    BuildContext context,
    DashboardState state,
    DashboardCubit cubit,
  ) {
    if (state is DashboardLoaded) {
      return DashboardChartCard(salesPerDay: state.data.salesPerDay);
    }
    if (state is DashboardError) {
      return _CardError(
        message: state.message,
        height: 280,
        onRetry: cubit.refresh,
      );
    }
    return const DashboardChartCardShimmer();
  }

  Widget _buildBottomRow(DashboardState state) {
    if (state is DashboardLoaded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DashboardTopProducts(products: state.data.topProducts),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: DashboardTopCustomers(customers: state.data.topCustomers),
          ),
        ],
      );
    }
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: DashboardTopProductsShimmer()),
        SizedBox(width: AppSizes.desktopCardGap),
        Expanded(child: DashboardTopCustomersShimmer()),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final DashboardFilters filters;
  final DashboardCubit cubit;

  const _Header({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Row(
      children: [
        Text(
          AppLocalizations.of(context).dashboard,
          style: AppTextStyles.h4.copyWith(color: fg),
        ),
        const Spacer(),
        _PeriodFilterBar(
          filters: filters,
          onChanged: cubit.changePeriod,
          onCustomRange: cubit.changeCustomPeriod,
        ),
      ],
    );
  }
}

// ─── Period Filter Bar ────────────────────────────────────────────────────────

class _PeriodFilterBar extends StatelessWidget {
  final DashboardFilters filters;
  final void Function(DashboardPeriodFilter) onChanged;
  final Future<void> Function(DateTime from, DateTime to) onCustomRange;

  const _PeriodFilterBar({
    required this.filters,
    required this.onChanged,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final l10n = AppLocalizations.of(context);

    // Pre-compute date labels for each preset using the current locale
    final locale = AppLocalizations.of(context).locale.languageCode;
    final todayLabel = DashboardFilters(period: DashboardPeriodFilter.today)
        .chipDateLabelFor(locale);
    final weekLabel = DashboardFilters(period: DashboardPeriodFilter.week)
        .chipDateLabelFor(locale);
    final monthLabel = DashboardFilters(period: DashboardPeriodFilter.month)
        .chipDateLabelFor(locale);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterChip(
            label: l10n.today,
            dateLabel: todayLabel,
            value: DashboardPeriodFilter.today,
            current: filters.period,
            onChanged: onChanged,
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: l10n.thisWeek,
            dateLabel: weekLabel,
            value: DashboardPeriodFilter.week,
            current: filters.period,
            onChanged: onChanged,
          ),
          const SizedBox(width: AppSpacing.xs),
          _FilterChip(
            label: l10n.thisMonth,
            dateLabel: monthLabel,
            value: DashboardPeriodFilter.month,
            current: filters.period,
            onChanged: onChanged,
          ),
          const SizedBox(width: AppSpacing.xs),
          _CustomFilterChip(
            filters: filters,
            onCustomRange: onCustomRange,
          ),
        ],
      ),
    );
  }
}

// ─── Filter Chip (preset) ─────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final String dateLabel;
  final DashboardPeriodFilter value;
  final DashboardPeriodFilter current;
  final void Function(DashboardPeriodFilter) onChanged;

  const _FilterChip({
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
    final activeBg = isDark ? AppColors.darkMuted : AppColors.primaryBg;
    final activeFg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final inactiveFg =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isActive ? null : () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: AppRadius.brMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(
                  color: isActive ? activeFg : inactiveFg,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: AppTextStyles.caption.copyWith(
                  color: inactiveFg,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Custom Date Range Chip ───────────────────────────────────────────────────

class _CustomFilterChip extends StatelessWidget {
  final DashboardFilters filters;
  final Future<void> Function(DateTime from, DateTime to) onCustomRange;

  const _CustomFilterChip({
    required this.filters,
    required this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = filters.period == DashboardPeriodFilter.custom;
    final activeBg = isDark ? AppColors.darkMuted : AppColors.primaryBg;
    final activeFg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final inactiveFg =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final l10n = AppLocalizations.of(context);

    final locale = AppLocalizations.of(context).locale.languageCode;
    final dateSubLabel = isActive ? filters.chipDateLabelFor(locale) : '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _pickRange(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: AppRadius.brMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: isActive ? activeFg : inactiveFg,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.customRange,
                    style: AppTextStyles.labelMd.copyWith(
                      color: isActive ? activeFg : inactiveFg,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              if (isActive && dateSubLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  dateSubLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: inactiveFg,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
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

// ─── Error helpers ────────────────────────────────────────────────────────────

class _SectionError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SectionError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: AppErrorWidget(
        message: AppLocalizations.of(context).failedToLoadDashboard,
        subtitle: message,
        onRetry: onRetry,
        height: AppSizes.statCardHeight,
      ),
    );
  }
}

class _CardError extends StatelessWidget {
  final String message;
  final double height;
  final VoidCallback onRetry;

  const _CardError({
    required this.message,
    required this.height,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: AppErrorWidget(
        message: AppLocalizations.of(context).failedToLoad,
        subtitle: message,
        onRetry: onRetry,
        height: height,
      ),
    );
  }
}
