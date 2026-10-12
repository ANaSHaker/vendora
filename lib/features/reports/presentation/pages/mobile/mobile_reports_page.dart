import 'dart:io' show Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../../domain/entities/report_entities.dart';
import '../../cubit/reports_cubit.dart';
import '../../cubit/reports_state.dart';

class MobileReportsPage extends StatelessWidget {
  const MobileReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesReportCubit(getIt(), getIt(), getIt())..load(),
      child: const _MobileSalesReportView(),
    );
  }
}

class _MobileSalesReportView extends StatelessWidget {
  const _MobileSalesReportView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.salesReport),
        backgroundColor: surface,
        actions: [
          BlocBuilder<SalesReportCubit, SalesReportState>(
            builder: (context, state) {
              return _MobileExportButton(
                cubit: context.read<SalesReportCubit>(),
                isDark: isDark,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<SalesReportCubit, SalesReportState>(
        builder: (context, state) {
          final cubit = context.read<SalesReportCubit>();
          final filters = switch (state) {
            SalesReportLoaded(:final filters) => filters,
            SalesReportLoading(:final filters) => filters,
            SalesReportError(:final filters) => filters,
            SalesReportInitial(:final filters) => filters,
          };

          return Column(
            children: [
              _MobileFilterStrip(
                  filters: filters, cubit: cubit, isDark: isDark),
              Expanded(
                child: switch (state) {
                  SalesReportInitial() || SalesReportLoading() => ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: const [
                        ShimmerBox(height: 80),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerBox(height: 80),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerBox(height: 80),
                        SizedBox(height: AppSpacing.sm),
                        ShimmerBox(height: 80),
                        SizedBox(height: AppSpacing.md),
                        ShimmerBox(height: 200),
                      ],
                    ),
                  SalesReportError(:final message, :final filters) =>
                    AppErrorWidget(
                      message: message,
                      onRetry: () => cubit.load(filters: filters),
                    ),
                  SalesReportLoaded(:final data) => _MobileSalesContent(
                      data: data,
                      isDark: isDark,
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Mobile Export Button ─────────────────────────────────────────────────────

class _MobileExportButton extends StatefulWidget {
  final SalesReportCubit cubit;
  final bool isDark;

  const _MobileExportButton({required this.cubit, required this.isDark});

  @override
  State<_MobileExportButton> createState() => _MobileExportButtonState();
}

class _MobileExportButtonState extends State<_MobileExportButton> {
  String? _exporting;

  Future<void> _doExport(String endpoint, String label) async {
    setState(() => _exporting = label);
    try {
      final path = await widget.cubit.exportFile(endpoint);
      if (!mounted) return;
      setState(() => _exporting = null);
      if (path != null) {
        AppSnackbar.success(context, 'Saved: $path');
        try {
          if (!kIsWeb) {
            await Process.run('explorer.exe', ['/select,', path]);
          }
        } catch (_) {}
      } else {
        AppSnackbar.error(context, AppLocalizations.of(context).error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = null);
      AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final primary = Theme.of(context).colorScheme.primary;

    return PopupMenuButton<(String, String)>(
      enabled: _exporting == null,
      onSelected: (item) => _doExport(item.$1, item.$2),
      icon: _exporting != null
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary))
          : Icon(Icons.download_outlined, color: fg),
      color: surface,
      shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd, side: BorderSide(color: border)),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: (ApiEndpoints.exportSalesXls, l10n.exportSales),
          child: Text(l10n.exportSales,
              style: AppTextStyles.bodySm.copyWith(color: fg)),
        ),
        PopupMenuItem(
          value: (ApiEndpoints.exportProductsXls, l10n.exportReport),
          child: Text(l10n.exportReport,
              style: AppTextStyles.bodySm.copyWith(color: fg)),
        ),
        PopupMenuItem(
          value: (ApiEndpoints.exportSalesPdf, 'PDF'),
          child: Text('PDF', style: AppTextStyles.bodySm.copyWith(color: fg)),
        ),
      ],
    );
  }
}

// ─── Mobile Filter Strip ──────────────────────────────────────────────────────

class _MobileFilterStrip extends StatefulWidget {
  final ReportFilters filters;
  final SalesReportCubit cubit;
  final bool isDark;

  const _MobileFilterStrip({
    required this.filters,
    required this.cubit,
    required this.isDark,
  });

  @override
  State<_MobileFilterStrip> createState() => _MobileFilterStripState();
}

class _MobileFilterStripState extends State<_MobileFilterStrip> {
  List<({String id, String name})> _branches = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final client = GetIt.I<ApiClient>();
      final res = await client.get<Map<String, dynamic>>(ApiEndpoints.branches);
      if (!mounted) return;
      final raw = res.data?['data'];
      if (raw is List) {
        setState(() {
          _branches = raw
              .whereType<Map<String, dynamic>>()
              .map((e) => (
                    id: e['id']?.toString() ?? '',
                    name: e['name'] as String? ?? ''
                  ))
              .where((e) => e.id.isNotEmpty)
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final filters = widget.filters;

    final paymentItems = [
      (id: 'cash', name: l10n.cash),
      (id: 'card', name: l10n.card),
      (id: 'bank_transfer', name: l10n.bankTransfer),
      (id: 'wallet', name: l10n.wallet),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppDateRangePicker(
              startDate: filters.dateFrom,
              endDate: filters.dateTo,
              activePreset: filters.preset,
              onPresetChanged: widget.cubit.changePreset,
              onCustomRange: widget.cubit.setCustomRange,
            ),
            if (_branches.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              _MobileFilterChip(
                label: l10n.allBranches,
                value: filters.branchId,
                items: _branches,
                isDark: isDark,
                onChanged: widget.cubit.filterByBranch,
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            _MobileFilterChip(
              label: l10n.allStatuses,
              value: filters.paymentMethod,
              items: paymentItems,
              isDark: isDark,
              onChanged: widget.cubit.filterByPaymentMethod,
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<({String id, String name})> items;
  final bool isDark;
  final void Function(String?) onChanged;

  const _MobileFilterChip({
    required this.label,
    required this.value,
    required this.items,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;
    final selected = items.where((e) => e.id == value).firstOrNull;
    final isActive = value != null;

    return PopupMenuButton<String>(
      onSelected: (v) => onChanged(v == '__all__' ? null : v),
      color: surface,
      shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brMd, side: BorderSide(color: border)),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text(label,
              style: AppTextStyles.bodySm.copyWith(color: muted)),
        ),
        ...items.map((item) => PopupMenuItem<String>(
          value: item.id,
          child: Text(item.name,
              style: AppTextStyles.bodySm
                  .copyWith(color: item.id == value ? primary : fg)),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? primary.withValues(alpha: 0.08) : surface,
          border: Border.all(
              color: isActive ? primary.withValues(alpha: 0.4) : border),
          borderRadius: AppRadius.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected?.name ?? label,
              style: AppTextStyles.labelSm
                  .copyWith(color: isActive ? primary : muted),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                size: 14, color: isActive ? primary : muted),
          ],
        ),
      ),
    );
  }
}

// ─── Mobile Sales Content ─────────────────────────────────────────────────────

class _MobileSalesContent extends StatelessWidget {
  final SalesReportEntity data;
  final bool isDark;

  const _MobileSalesContent({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = data.summary;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // KPI cards 2×2
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n.totalSales,
                value: AppFormatters.currency(s.totalSales),
                color: cs.primary,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiCard(
                title: l10n.totalOrders,
                value: AppFormatters.number(s.totalOrders.toDouble()),
                color: cs.primary,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                title: l10n.totalRefunds,
                value: AppFormatters.currency(s.totalRefunds),
                color: AppColors.destructive,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiCard(
                title: l10n.netRevenue,
                value: AppFormatters.currency(s.netRevenue),
                color: AppColors.success,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Top Products
        if (data.topProducts.isNotEmpty) ...[
          Text(
            l10n.topSellingProducts,
            style: AppTextStyles.labelLg
                .copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...data.topProducts.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: border),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: AppRadius.brSm,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: AppTextStyles.labelXs.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.productName,
                            style: AppTextStyles.labelSm.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis),
                        if (p.sku != null)
                          Text(p.sku!,
                              style: AppTextStyles.bodyXs
                                  .copyWith(color: muted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppFormatters.currency(p.totalRevenue),
                        style: AppTextStyles.numeric
                            .copyWith(color: fg, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${AppFormatters.number(p.unitsSold.toDouble())} ${l10n.unitsSold}',
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ] else
          AppEmptyState(
            icon: const Icon(Icons.bar_chart_outlined, size: 40),
            message: l10n.noDataForPeriod,
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final bool isDark;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyXs.copyWith(color: muted)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.numericLg
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
