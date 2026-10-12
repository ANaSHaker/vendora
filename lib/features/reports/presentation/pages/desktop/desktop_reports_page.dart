import 'dart:io' show Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/api/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/api/api_endpoints.dart';
import '../../../../../core/api/api_response.dart' show PaginationMeta;
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/cards/stat_card.dart';
import '../../../../../design_system/widgets/charts/sales_area_chart.dart'
    show SalesAreaChart, SalesDayData;
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/report_entities.dart';
import '../../cubit/reports_cubit.dart';
import '../../cubit/reports_state.dart';

class DesktopReportsPage extends StatelessWidget {
  const DesktopReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SalesReportCubit(getIt(), getIt(), getIt())..load(),
      child: const _SalesReportView(),
    );
  }
}

class _SalesReportView extends StatelessWidget {
  const _SalesReportView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesReportCubit, SalesReportState>(
      builder: (context, state) {
        final cubit = context.read<SalesReportCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.muted;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

        final filters = switch (state) {
          SalesReportLoaded(:final filters) => filters,
          SalesReportLoading(:final filters) => filters,
          SalesReportError(:final filters) => filters,
          SalesReportInitial(:final filters) => filters,
        };

        return ColoredBox(
          color: bg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Text(l10n.salesReport, style: AppTextStyles.h4.copyWith(color: fg)),
                    const Spacer(),
                    _ExportDropdown(cubit: cubit, isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    AppDateRangePicker(
                      startDate: filters.dateFrom,
                      endDate: filters.dateTo,
                      activePreset: filters.preset,
                      onPresetChanged: cubit.changePreset,
                      onCustomRange: cubit.setCustomRange,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Filter bar ──
                _SalesFilterBar(
                  filters: filters,
                  cubit: cubit,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Content ──
                switch (state) {
                  SalesReportInitial() || SalesReportLoading() => _SalesReportShimmer(),
                  SalesReportError(:final message, :final filters) => AppErrorWidget(
                      message: message,
                      onRetry: () => cubit.load(filters: filters),
                    ),
                  SalesReportLoaded(:final data, :final orders, :final ordersMeta, :final ordersLoading) =>
                    _SalesReportContent(
                      data: data,
                      orders: orders,
                      ordersMeta: ordersMeta,
                      ordersLoading: ordersLoading,
                      cubit: cubit,
                      isDark: isDark,
                    ),
                },
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Export Dropdown ────────────────────────────────────────────────────────────

class _ExportDropdown extends StatefulWidget {
  final SalesReportCubit cubit;
  final bool isDark;

  const _ExportDropdown({required this.cubit, required this.isDark});

  @override
  State<_ExportDropdown> createState() => _ExportDropdownState();
}

class _ExportDropdownState extends State<_ExportDropdown> {
  bool _exporting = false;

  Future<void> _export(String endpoint) async {
    setState(() => _exporting = true);
    try {
      final path = await widget.cubit.exportFile(endpoint);
      if (!mounted) return;
      setState(() => _exporting = false);
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
      setState(() => _exporting = false);
      AppSnackbar.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return PopupMenuButton<String>(
      onSelected: _export,
      enabled: !_exporting,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: border),
      ),
      itemBuilder: (_) => [
        _menuItem(l10n.exportReport, ApiEndpoints.exportSalesXls, Icons.table_chart_outlined, fg),
        _menuItem('Export Products XLS', ApiEndpoints.exportProductsXls, Icons.inventory_2_outlined, fg),
        _menuItem('Export Sales PDF', ApiEndpoints.exportSalesPdf, Icons.picture_as_pdf_outlined, fg),
        _menuItem('Export Orders PDF', ApiEndpoints.exportOrdersPdf, Icons.receipt_long_outlined, fg),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exporting
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.download_outlined, size: 16, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Text(l10n.exportReport, style: AppTextStyles.labelSm.copyWith(color: fg)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String label, String value, IconData icon, Color fg) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _SalesFilterBar extends StatefulWidget {
  final ReportFilters filters;
  final SalesReportCubit cubit;
  final bool isDark;

  const _SalesFilterBar({
    required this.filters,
    required this.cubit,
    required this.isDark,
  });

  @override
  State<_SalesFilterBar> createState() => _SalesFilterBarState();
}

class _SalesFilterBarState extends State<_SalesFilterBar> {
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
    final filters = widget.filters;

    final paymentItems = [
      (id: 'cash', name: l10n.cash),
      (id: 'card', name: l10n.card),
      (id: 'bank_transfer', name: l10n.bankTransfer),
      (id: 'wallet', name: l10n.wallet),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (_branches.isNotEmpty)
          _SalesFilterDropdown(
            label: l10n.allBranches,
            value: filters.branchId,
            items: _branches,
            isDark: isDark,
            onChanged: widget.cubit.filterByBranch,
          ),
        _SalesFilterDropdown(
          label: l10n.allStatuses,
          value: filters.paymentMethod,
          items: paymentItems,
          isDark: isDark,
          onChanged: widget.cubit.filterByPaymentMethod,
        ),
      ],
    );
  }
}

class _SalesFilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<({String id, String name})> items;
  final bool isDark;
  final void Function(String?) onChanged;

  const _SalesFilterDropdown({
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
      offset: const Offset(0, 36),
      color: surface,
      constraints: const BoxConstraints(maxHeight: 320, minWidth: 180),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: border),
      ),
      onSelected: (v) => onChanged(v == '__all__' ? null : v),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
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
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 14, color: isActive ? primary : muted),
          ],
        ),
      ),
    );
  }
}

// ── Report Content ─────────────────────────────────────────────────────────────

class _SalesReportContent extends StatelessWidget {
  final SalesReportEntity data;
  final List<SalesOrderRowEntity> orders;
  final PaginationMeta? ordersMeta;
  final bool ordersLoading;
  final SalesReportCubit cubit;
  final bool isDark;

  const _SalesReportContent({
    required this.data,
    required this.orders,
    required this.ordersMeta,
    required this.ordersLoading,
    required this.cubit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = data.summary;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPI Cards ──
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.totalOrders,
                value: AppFormatters.number(s.totalOrders.toDouble()),
                icon: const Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(width: AppSizes.desktopCardGap),
            Expanded(
              child: StatCard(
                label: l10n.totalSales,
                value: AppFormatters.currency(s.totalSales),
                icon: const Icon(Icons.trending_up_rounded),
              ),
            ),
            const SizedBox(width: AppSizes.desktopCardGap),
            Expanded(
              child: StatCard(
                label: l10n.netRevenue,
                value: AppFormatters.currency(s.netRevenue),
                subLabel: '${l10n.totalRefunds}: ${AppFormatters.currency(s.totalRefunds)}',
                icon: const Icon(Icons.account_balance_wallet_outlined),
                iconColor: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSizes.desktopCardGap),
            Expanded(
              child: StatCard(
                label: l10n.avgOrderValue,
                value: AppFormatters.currency(s.avgOrderValue),
                icon: const Icon(Icons.bar_chart_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.desktopCardGap),

        // ── Revenue Chart ──
        if (data.salesByDay.isNotEmpty) ...[
          _ReportCard(
            title: l10n.salesByDay,
            child: SizedBox(
              height: 260,
              child: SalesAreaChart(
                data: data.salesByDay
                    .map((e) => SalesDayData(date: e.date, amount: e.totalSales))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.desktopCardGap),
        ],

        // ── Top Products with progress bars ──
        if (data.topProducts.isNotEmpty) ...[
          _TopProductsList(
            products: data.topProducts,
            isDark: isDark,
            primary: primary,
          ),
          const SizedBox(height: AppSizes.desktopCardGap),
        ],

        // ── Orders Table ──
        _OrdersTable(
          orders: orders,
          isLoading: ordersLoading,
          meta: ordersMeta,
          cubit: cubit,
          isDark: isDark,
        ),
      ],
    );
  }
}

// ── Report Card Shell ──────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.labelLg.copyWith(color: fg, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ── Top Products List ──────────────────────────────────────────────────────────

class _TopProductsList extends StatelessWidget {
  final List<TopSellingProductEntity> products;
  final bool isDark;
  final Color primary;

  const _TopProductsList({
    required this.products,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final maxRevenue =
        products.isNotEmpty ? products.map((p) => p.totalRevenue).reduce((a, b) => a > b ? a : b) : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.topProducts,
              style: AppTextStyles.labelLg.copyWith(color: fg, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            _ProductProgressRow(
              rank: i + 1,
              product: products[i],
              sharePercent: maxRevenue > 0 ? products[i].totalRevenue / maxRevenue : 0,
              isDark: isDark,
              primary: primary,
              fg: fg,
              muted: muted,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductProgressRow extends StatelessWidget {
  final int rank;
  final TopSellingProductEntity product;
  final double sharePercent;
  final bool isDark;
  final Color primary;
  final Color fg;
  final Color muted;

  const _ProductProgressRow({
    required this.rank,
    required this.product,
    required this.sharePercent,
    required this.isDark,
    required this.primary,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            '$rank',
            style: AppTextStyles.labelSm.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.productName,
                  style: AppTextStyles.labelSm.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: sharePercent.clamp(0.0, 1.0),
                  backgroundColor: primary.withAlpha(25),
                  valueColor: AlwaysStoppedAnimation<Color>(primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppFormatters.currency(product.totalRevenue),
                style: AppTextStyles.numeric.copyWith(color: fg)),
            Text('${product.unitsSold} ${AppLocalizations.of(context).unitsSold}',
                style: AppTextStyles.bodyXs.copyWith(color: muted)),
          ],
        ),
      ],
    );
  }
}

// ── Orders Table ───────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  final List<SalesOrderRowEntity> orders;
  final bool isLoading;
  final PaginationMeta? meta;
  final SalesReportCubit cubit;
  final bool isDark;

  const _OrdersTable({
    required this.orders,
    required this.isLoading,
    required this.meta,
    required this.cubit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (isLoading) {
      return const ShimmerBox(height: 300);
    }

    if (orders.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.receipt_long_outlined, size: 40),
        message: l10n.noOrdersFound,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Text(l10n.recentOrders,
                style:
                    AppTextStyles.labelLg.copyWith(color: fg, fontWeight: FontWeight.w600)),
          ),
          Container(
            height: 40,
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(l10n.reference, style: AppTextStyles.tableHeader)),
                Expanded(flex: 2, child: Text(l10n.customer, style: AppTextStyles.tableHeader)),
                Expanded(flex: 2, child: Text(l10n.paymentMethod, style: AppTextStyles.tableHeader)),
                Expanded(flex: 2, child: Text(l10n.orderStatus, style: AppTextStyles.tableHeader)),
                Expanded(
                  flex: 1,
                  child: Text(l10n.total, style: AppTextStyles.tableHeader, textAlign: TextAlign.right),
                ),
                Expanded(
                  flex: 2,
                  child: Text(l10n.dateCreated, style: AppTextStyles.tableHeader, textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          for (var i = 0; i < orders.length; i++) ...[
            if (i > 0) Divider(height: 1, color: border),
            _OrderRow(order: orders[i], isDark: isDark, fg: fg, muted: muted),
          ],
          if (meta case final m?) ...[
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: AppPagination(meta: m, onPageChanged: cubit.loadOrdersPage),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final SalesOrderRowEntity order;
  final bool isDark;
  final Color fg;
  final Color muted;

  const _OrderRow({
    required this.order,
    required this.isDark,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    final (statusColor, statusBg, statusLabel) = switch (order.status) {
      'paid' => (AppColors.statusPaid, AppColors.statusPaidBg, l10n.statusPaid),
      'refunded' => (AppColors.statusRefunded, AppColors.statusRefundedBg, l10n.statusRefunded),
      'cancelled' => (AppColors.statusCancelled, AppColors.statusCancelledBg, l10n.statusCancelled),
      'pending' => (AppColors.statusPending, AppColors.statusPendingBg, l10n.statusPending),
      _ => (AppColors.statusCompleted, AppColors.statusCompletedBg, l10n.statusCompleted),
    };

    final paymentLabel = switch (order.paymentMethod) {
      'cash' => l10n.cash,
      'card' => l10n.card,
      'bank_transfer' => l10n.bankTransfer,
      'wallet' => l10n.wallet,
      _ => order.paymentMethod,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              order.reference,
              style: AppTextStyles.labelSm
                  .copyWith(color: primary, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              order.customerName ?? l10n.noCustomer,
              style: AppTextStyles.tableCell,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(paymentLabel, style: AppTextStyles.tableCell, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: StatusBadge.custom(label: statusLabel, color: statusColor, bgColor: statusBg),
          ),
          Expanded(
            child: Text(
              AppFormatters.currency(order.total),
              style: AppTextStyles.numeric,
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(order.createdAt.toLocal()),
              style: AppTextStyles.tableCell.copyWith(color: muted),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesReportShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(child: ShimmerBox(height: 100)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 100)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 100)),
            SizedBox(width: 12),
            Expanded(child: ShimmerBox(height: 100)),
          ],
        ),
        SizedBox(height: 12),
        ShimmerBox(height: 280),
        SizedBox(height: 12),
        ShimmerBox(height: 200),
        SizedBox(height: 12),
        ShimmerBox(height: 300),
      ],
    );
  }
}
