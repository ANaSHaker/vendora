import 'dart:io' show Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

class MobileFinancialReportsPage extends StatelessWidget {
  const MobileFinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinancialReportCubit(getIt(), getIt())..load(),
      child: const _MobileFinancialView(),
    );
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────

class _MobileFinancialView extends StatelessWidget {
  const _MobileFinancialView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return BlocBuilder<FinancialReportCubit, FinancialReportState>(
      builder: (context, state) {
        final cubit = context.read<FinancialReportCubit>();
        final filters = switch (state) {
          FinancialReportLoaded(:final filters) => filters,
          FinancialReportLoading(:final filters) => filters,
          FinancialReportError(:final filters) => filters,
          FinancialReportInitial(:final filters) => filters,
        };

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: surface,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(l10n.financialReport,
                style: AppTextStyles.h5.copyWith(color: fg)),
            actions: [
              _MobileExportButton(cubit: cubit, isDark: isDark),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: Column(
            children: [
              // ── Filter bar ──
              _MobileFilterBar(
                filters: filters,
                cubit: cubit,
                isDark: isDark,
              ),

              // ── Tab bar (when loaded) ──
              if (state is FinancialReportLoaded)
                _MobileTabBar(
                  activeTab: state.activeTab,
                  onTabChanged: cubit.switchTab,
                  isDark: isDark,
                ),

              // ── Content ──
              Expanded(
                child: switch (state) {
                  FinancialReportInitial() ||
                  FinancialReportLoading() =>
                    const _MobileShimmer(),
                  FinancialReportError(:final message, :final filters) =>
                    AppErrorWidget(
                      message: message,
                      onRetry: () => cubit.load(filters: filters),
                    ),
                  FinancialReportLoaded(:final data, :final activeTab) =>
                    _MobileContent(
                      data: data,
                      activeTab: activeTab,
                      isDark: isDark,
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Mobile Export Button ─────────────────────────────────────────────────────

class _MobileExportButton extends StatefulWidget {
  final FinancialReportCubit cubit;
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

  Future<void> _doPrint() async {
    final state = widget.cubit.state;
    if (state is! FinancialReportLoaded) return;
    final l10n = AppLocalizations.of(context);
    final s = state.data.summary;
    final data = state.data;
    final dateFrom = state.filters.dateFrom.toLocal().toString().substring(0, 10);
    final dateTo = state.filters.dateTo.toLocal().toString().substring(0, 10);

    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context _) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(l10n.financialReport,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text('$dateFrom - $dateTo',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              1: const pw.FlexColumnWidth(),
              2: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _pdfKpi(l10n.grossRevenue, s.grossRevenue, bold: bold),
                _pdfKpi(l10n.costOfGoods, s.totalCost, bold: bold),
                _pdfKpi(l10n.grossProfit, s.grossProfit, bold: bold),
              ]),
              pw.TableRow(children: [
                _pdfKpi(l10n.profitMargin, null,
                    extra: '${s.profitMargin.toStringAsFixed(1)}%', bold: bold),
                _pdfKpi(l10n.netRevenue, s.netRevenue, bold: bold),
                _pdfKpi(l10n.totalRefunds, s.totalRefunds, bold: bold),
              ]),
            ],
          ),
          if (data.pnlRows.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(l10n.pnlReport,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: data.pnlRows.map((row) {
                final fw = row.isSubtotal ? pw.FontWeight.bold : pw.FontWeight.normal;
                return pw.TableRow(
                  decoration: row.isSubtotal
                      ? const pw.BoxDecoration(color: PdfColors.grey100)
                      : null,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(_pdfPnlLabel(row.label, l10n),
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(fontSize: 9, fontWeight: fw)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(_pdfNum(AppFormatters.currency(row.amount)),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 9, fontWeight: fw)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          if (s.topProfitableProducts.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(l10n.topProfitable,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            ...s.topProfitableProducts.asMap().entries.map((e) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text('${e.key + 1}.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                ),
                pw.Expanded(
                  child: pw.Text(e.value.productName,
                      textDirection: pw.TextDirection.rtl,
                      style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Text(_pdfNum(AppFormatters.currency(e.value.profit)),
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ]),
            )),
          ],
        ],
      ));
      return doc.save();
    });
  }

  static String _pdfNum(String s) =>
      s.replaceAll(RegExp('\u200e|\u200f|[\u202a-\u202e]'), '');

  static String _pdfPnlLabel(String key, AppLocalizations l10n) => switch (key) {
    'revenue' => l10n.grossRevenue,
    'cogs' => l10n.costOfGoods,
    'grossProfit' => l10n.grossProfit,
    'grossMargin' => l10n.profitMargin,
    _ => key,
  };

  pw.Widget _pdfKpi(String label, double? value, {String? extra, required pw.Font bold}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8, right: 6),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(label,
              textDirection: pw.TextDirection.rtl,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(extra ?? _pdfNum(AppFormatters.currency(value ?? 0)),
              style: pw.TextStyle(fontSize: 11, font: bold)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final fg = widget.isDark ? AppColors.darkForeground : AppColors.foreground;
    final textStyle = AppTextStyles.bodySm.copyWith(
        color: widget.isDark ? AppColors.darkForeground : AppColors.foreground);

    final options = [
      (ApiEndpoints.exportFinancialPnlXls, l10n.exportPnl),
      (ApiEndpoints.exportFinancialSalesXls, l10n.exportSales),
      (ApiEndpoints.exportFinancialInventoryXls, l10n.exportInventory),
      (ApiEndpoints.exportFinancialFifoXls, l10n.exportFifo),
    ];

    return PopupMenuButton<(String, String)>(
      enabled: _exporting == null,
      onSelected: (item) {
        if (item.$1 == '__print__') {
          _doPrint();
        } else {
          _doExport(item.$1, item.$2);
        }
      },
      icon: _exporting != null
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: primary))
          : Icon(Icons.more_vert_rounded, color: fg),
      itemBuilder: (_) => [
        PopupMenuItem<(String, String)>(
          value: ('__print__', l10n.printPdf),
          child: Row(children: [
            const Icon(Icons.print_outlined, size: 16),
            const SizedBox(width: 8),
            Text(l10n.printPdf, style: textStyle),
          ]),
        ),
        const PopupMenuDivider(),
        ...options.map((opt) => PopupMenuItem(
          value: opt,
          child: Text(opt.$2, style: textStyle),
        )),
      ],
    );
  }
}

// ─── Mobile Filter Bar ───────────────────────────────────────────────────────

class _MobileFilterBar extends StatefulWidget {
  final ReportFilters filters;
  final FinancialReportCubit cubit;
  final bool isDark;

  const _MobileFilterBar({
    required this.filters,
    required this.cubit,
    required this.isDark,
  });

  @override
  State<_MobileFilterBar> createState() => _MobileFilterBarState();
}

class _MobileFilterBarState extends State<_MobileFilterBar> {
  List<({String id, String name})> _branches = [];
  List<({String id, String name})> _warehouses = [];
  List<({String id, String name})> _products = [];

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final client = GetIt.I<ApiClient>();
      final results = await Future.wait([
        client.get<Map<String, dynamic>>(ApiEndpoints.branches),
        client.get<Map<String, dynamic>>(ApiEndpoints.warehouses),
        client.get<Map<String, dynamic>>(ApiEndpoints.products,
            queryParameters: {'per_page': 200, 'active_only': '1'}),
      ]);
      if (!mounted) return;
      setState(() {
        _branches = _parseList(results[0].data ?? {});
        _warehouses = _parseList(results[1].data ?? {});
        _products = _parseList(results[2].data ?? {});
      });
    } catch (_) {}
  }

  List<({String id, String name})> _parseList(Map<String, dynamic> body) {
    final raw = body['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => (id: e['id']?.toString() ?? '', name: e['name'] as String? ?? ''))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final filters = widget.filters;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: AppDateRangePicker(
              startDate: filters.dateFrom,
              endDate: filters.dateTo,
              activePreset: filters.preset,
              onPresetChanged: widget.cubit.changePreset,
              onCustomRange: widget.cubit.setCustomRange,
            ),
          ),
          if (_branches.isNotEmpty || _warehouses.isNotEmpty || _products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_branches.isNotEmpty)
                      _MobileFilterChip(
                        label: l10n.allBranches,
                        value: filters.branchId,
                        items: _branches,
                        isDark: isDark,
                        onChanged: widget.cubit.filterByBranch,
                      ),
                    if (_warehouses.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _MobileFilterChip(
                        label: l10n.allWarehouses,
                        value: filters.warehouseId,
                        items: _warehouses,
                        isDark: isDark,
                        onChanged: widget.cubit.filterByWarehouse,
                      ),
                    ],
                    if (_products.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _MobileFilterChip(
                        label: l10n.allProducts,
                        value: filters.productId,
                        items: _products,
                        isDark: isDark,
                        onChanged: widget.cubit.filterByProduct,
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileFilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final List<({String id, String name})> items;
  final bool isDark;
  final void Function(String?) onChanged; // null = clear filter

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
    final displayLabel = selected?.name ?? label;
    final isActive = value != null;

    return PopupMenuButton<String>(
      offset: const Offset(0, 32),
      color: surface,
      constraints: const BoxConstraints(maxHeight: 280, minWidth: 160),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: border),
      ),
      onSelected: (v) => onChanged(v == '__all__' ? null : v),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text(label, style: AppTextStyles.bodySm.copyWith(color: muted)),
        ),
        ...items.map((item) => PopupMenuItem<String>(
          value: item.id,
          child: Text(item.name,
              style: AppTextStyles.bodySm.copyWith(
                  color: item.id == value ? primary : fg)),
        )),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
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
              displayLabel,
              style: AppTextStyles.caption.copyWith(
                  color: isActive ? primary : muted),
            ),
            const SizedBox(width: 3),
            Icon(Icons.expand_more_rounded, size: 12,
                color: isActive ? primary : muted),
          ],
        ),
      ),
    );
  }
}

// ─── Mobile Tab Bar ───────────────────────────────────────────────────────────

class _MobileTabBar extends StatelessWidget {
  final FinancialReportTab activeTab;
  final ValueChanged<FinancialReportTab> onTabChanged;
  final bool isDark;

  const _MobileTabBar({
    required this.activeTab,
    required this.onTabChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final tabs = [
      (FinancialReportTab.pnl, l10n.pnl),
      (FinancialReportTab.sales, l10n.navSales),
      (FinancialReportTab.inventory, l10n.inventory),
      (FinancialReportTab.fifo, l10n.fifoProfit),
    ];

    return Container(
      color: surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Row(
              children: tabs.map((tab) {
                final isActive = activeTab == tab.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTabChanged(tab.$1),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Column(
                        children: [
                          Text(
                            tab.$2,
                            style: AppTextStyles.labelXs.copyWith(
                              color: isActive
                                  ? cs.primary
                                  : (isDark
                                      ? AppColors.darkMutedForeground
                                      : AppColors.mutedForeground),
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 2,
                            width: isActive ? 32 : 0,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(height: 1, color: border),
        ],
      ),
    );
  }
}

// ─── Mobile Content ───────────────────────────────────────────────────────────

class _MobileContent extends StatelessWidget {
  final FinancialReportEntity data;
  final FinancialReportTab activeTab;
  final bool isDark;

  const _MobileContent({
    required this.data,
    required this.activeTab,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final s = data.summary;
    return switch (activeTab) {
      FinancialReportTab.pnl =>
        _MobilePnlTab(
          summary: s,
          rows: data.pnlRows,
          topProducts: s.topProfitableProducts,
          worstProducts: s.worstMarginProducts,
          isDark: isDark,
        ),
      FinancialReportTab.sales =>
        _MobileSalesTab(
          rows: data.salesRows,
          topProducts: s.topProfitableProducts,
          worstProducts: s.worstMarginProducts,
          isDark: isDark,
        ),
      FinancialReportTab.inventory =>
        _MobileInventoryTab(
          rows: data.inventoryRows,
          topProducts: s.topProfitableProducts,
          worstProducts: s.worstMarginProducts,
          isDark: isDark,
        ),
      FinancialReportTab.fifo =>
        _MobileFifoTab(
          rows: data.fifoRows,
          topProducts: s.topProfitableProducts,
          worstProducts: s.worstMarginProducts,
          isDark: isDark,
        ),
    };
  }
}

// ─── P&L Tab ─────────────────────────────────────────────────────────────────

class _MobilePnlTab extends StatelessWidget {
  final FinancialSummaryEntity summary;
  final List<PnlRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _MobilePnlTab({
    required this.summary,
    required this.rows,
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final subtotalBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final progressBg = isDark ? AppColors.darkBorder : AppColors.muted;
    final s = summary;
    final marginColor = s.profitMargin >= 30
        ? AppColors.success
        : s.profitMargin >= 10
            ? AppColors.warning
            : AppColors.destructive;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Revenue basis
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            borderRadius: AppRadius.brSm,
            border: Border.all(
                color: cs.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 13, color: cs.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${l10n.revenueBasisLabel}: ${s.revenueBasis == 'line_items' ? l10n.basisLineItems : l10n.basisOrderTotal}',
                style: AppTextStyles.caption.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2x2 KPI cards
        Row(children: [
          Expanded(
            child: _MobileMetricCard(
              label: l10n.grossRevenue,
              value: AppFormatters.currency(s.grossRevenue),
              accentColor: cs.primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MobileMetricCard(
              label: l10n.costOfGoods,
              value: AppFormatters.currency(s.totalCost),
              accentColor: AppColors.warning,
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Expanded(
            child: _MobileMetricCard(
              label: l10n.grossProfit,
              value: AppFormatters.currency(s.grossProfit),
              accentColor: AppColors.success,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profitMargin,
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${s.profitMargin.toStringAsFixed(1)}%',
                    style: AppTextStyles.numericLg.copyWith(
                      color: marginColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (s.profitMargin / 100).clamp(0.0, 1.0),
                      backgroundColor: progressBg,
                      color: marginColor,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ]),

        if (rows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          // P&L breakdown
          Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(color: border),
            ),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                final isNegative = row.amount < 0;

                return Container(
                  padding: EdgeInsets.only(
                    left: row.isSubtotal
                        ? AppSpacing.md
                        : AppSpacing.xl,
                    right: AppSpacing.md,
                    top: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: row.isSubtotal ? subtotalBg : null,
                    border: i > 0
                        ? Border(top: BorderSide(color: border, width: 0.5))
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _pnlLabel(row.label, l10n),
                          style: (row.isSubtotal
                                  ? AppTextStyles.labelSm
                                  : AppTextStyles.bodySm)
                              .copyWith(
                            color: row.isSubtotal ? fg : muted,
                            fontWeight: row.isSubtotal
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        AppFormatters.currency(row.amount),
                        style: AppTextStyles.numeric.copyWith(
                          color: isNegative
                              ? AppColors.destructive
                              : (row.isSubtotal ? cs.primary : fg),
                          fontWeight: row.isSubtotal
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        // Additional KPIs row
        Row(children: [
          Expanded(
            child: _MobileMetricCard(
              label: l10n.netRevenue,
              value: AppFormatters.currency(s.netRevenue),
              accentColor: AppColors.info,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _MobileMetricCard(
              label: l10n.totalRefunds,
              value: AppFormatters.currency(s.totalRefunds),
              accentColor: AppColors.destructive,
              isDark: isDark,
            ),
          ),
        ]),
        if (topProducts.isNotEmpty || worstProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _MobileSummaryRankSection(
            topProducts: topProducts,
            worstProducts: worstProducts,
            isDark: isDark,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        _MobileRefundNote(isDark: isDark),
      ],
    );
  }
}

// ─── Sales Tab ────────────────────────────────────────────────────────────────

class _MobileSalesTab extends StatelessWidget {
  final List<FinancialSalesRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _MobileSalesTab({
    required this.rows,
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (rows.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.bar_chart_outlined, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length + (topProducts.isNotEmpty || worstProducts.isNotEmpty ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == rows.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _MobileSummaryRankSection(
              topProducts: topProducts,
              worstProducts: worstProducts,
              isDark: isDark,
            ),
          );
        }
        return _SalesCard(row: rows[i], isDark: isDark);
      },
    );
  }
}

class _SalesCard extends StatelessWidget {
  final FinancialSalesRowEntity row;
  final bool isDark;

  const _SalesCard({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final profitColor = row.profit >= 0 ? AppColors.success : AppColors.destructive;
    final marginBg = row.marginPercent >= 0 ? AppColors.successLight : AppColors.destructiveLight;
    final marginFg = row.marginPercent >= 0 ? AppColors.success : AppColors.destructive;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.productName,
                        style: AppTextStyles.labelSm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis),
                    if (row.orderId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '# ${row.orderId}',
                        style: AppTextStyles.caption.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currency(row.profit),
                    style: AppTextStyles.numeric.copyWith(
                      color: profitColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: marginBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${row.marginPercent.toStringAsFixed(1)}%',
                      style: AppTextStyles.caption.copyWith(
                          color: marginFg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: border),
          const SizedBox(height: AppSpacing.sm),
          // Details row
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: l10n.quantity,
                  value: '${row.qty}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.salePrice,
                  value: AppFormatters.currency(row.salePrice),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.colUnitCost,
                  value: AppFormatters.decimal(row.unitCost),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.revenue,
                  value: AppFormatters.currency(row.revenue),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.totalCost,
                  value: AppFormatters.currency(row.totalCost),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Inventory Tab ────────────────────────────────────────────────────────────

class _MobileInventoryTab extends StatelessWidget {
  final List<FinancialInventoryRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _MobileInventoryTab({
    required this.rows,
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final hasRankSection = topProducts.isNotEmpty || worstProducts.isNotEmpty;

    if (rows.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.inventory_2_outlined, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length + 1 + (hasRankSection ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(children: [
              Icon(Icons.access_time_rounded, size: 12, color: muted),
              const SizedBox(width: AppSpacing.px4),
              Text(
                '${l10n.inventoryValuationAt} ${AppFormatters.dateTime(DateTime.now())}',
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ]),
          );
        }
        if (hasRankSection && i == rows.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _MobileSummaryRankSection(
              topProducts: topProducts,
              worstProducts: worstProducts,
              isDark: isDark,
            ),
          );
        }
        return _InventoryCard(row: rows[i - 1], isDark: isDark);
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final FinancialInventoryRowEntity row;
  final bool isDark;

  const _InventoryCard({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.productName,
                    style: AppTextStyles.labelSm.copyWith(color: fg),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                AppFormatters.currency(row.totalValue),
                style: AppTextStyles.numeric.copyWith(
                    color: primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            row.warehouseName,
            style: AppTextStyles.bodyXs.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: l10n.onHand,
                  value: AppFormatters.number(row.qtyOnHand.toDouble()),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.avgCost,
                  value: AppFormatters.decimal(row.avgCost),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.totalValue,
                  value: AppFormatters.currency(row.totalValue),
                  isDark: isDark,
                  valueColor: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── FIFO Tab ─────────────────────────────────────────────────────────────────

class _MobileFifoTab extends StatelessWidget {
  final List<FifoProfitRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _MobileFifoTab({
    required this.rows,
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  List<TopProductEntity> _deriveTop(List<FifoProfitRowEntity> r) =>
      (List.of(r)..sort((a, b) => b.profit.compareTo(a.profit)))
          .take(5)
          .map((e) => TopProductEntity(
                productId: e.productName,
                productName: e.productName,
                revenue: e.revenue,
                cogs: e.cost,
                profit: e.profit,
                marginPercent: e.margin,
              ))
          .toList();

  List<TopProductEntity> _deriveWorst(List<FifoProfitRowEntity> r) =>
      (List.of(r)..sort((a, b) => a.margin.compareTo(b.margin)))
          .take(5)
          .map((e) => TopProductEntity(
                productId: e.productName,
                productName: e.productName,
                revenue: e.revenue,
                cogs: e.cost,
                profit: e.profit,
                marginPercent: e.margin,
              ))
          .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (rows.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.stacked_bar_chart_rounded, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    final effectiveTop = topProducts.isNotEmpty ? topProducts : _deriveTop(rows);
    final effectiveWorst = worstProducts.isNotEmpty ? worstProducts : _deriveWorst(rows);

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: rows.length + 2,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Column(
            children: [
              _MobileSummaryRankSection(
                topProducts: effectiveTop,
                worstProducts: effectiveWorst,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.md),
              _MobileSectionDivider(
                label: l10n.fifoReport,
                isDark: isDark,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        }
        if (i == rows.length + 1) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _MobileRefundNote(isDark: isDark),
          );
        }
        return _FifoCard(row: rows[i - 1], isDark: isDark);
      },
    );
  }
}

class _MobileSummaryRankSection extends StatelessWidget {
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _MobileSummaryRankSection({
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (topProducts.isNotEmpty) ...[
          _MobileSummaryRankList(
            title: l10n.topProfitable,
            items: topProducts,
            getValue: (e) => AppFormatters.currency(e.profit),
            getColor: (e) =>
                e.profit >= 0 ? AppColors.success : AppColors.destructive,
            icon: Icons.trending_up_rounded,
            isDark: isDark,
          ),
          if (worstProducts.isNotEmpty) const SizedBox(height: AppSpacing.md),
        ],
        if (worstProducts.isNotEmpty)
          _MobileSummaryRankList(
            title: l10n.worstMargin,
            items: worstProducts,
            getValue: (e) => '${(e.marginPercent ?? 0).toStringAsFixed(1)}%',
            getColor: (e) => (e.marginPercent ?? 0) < 0
                ? AppColors.destructive
                : AppColors.mutedForeground,
            icon: Icons.trending_down_rounded,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _MobileSummaryRankList extends StatelessWidget {
  final String title;
  final List<TopProductEntity> items;
  final String Function(TopProductEntity) getValue;
  final Color Function(TopProductEntity) getColor;
  final IconData icon;
  final bool isDark;

  const _MobileSummaryRankList({
    required this.title,
    required this.items,
    required this.getValue,
    required this.getColor,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 14, color: muted),
                const SizedBox(width: AppSpacing.xs),
                Text(title, style: AppTextStyles.labelSm.copyWith(color: fg)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: i == 0 ? AppColors.primaryMuted : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: i == 0 ? primary : muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(items[i].productName,
                        style: AppTextStyles.bodySm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text(
                    getValue(items[i]),
                    style: AppTextStyles.numeric.copyWith(
                        color: getColor(items[i]), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (i < items.length - 1) Divider(height: 1, color: border),
          ],
        ],
      ),
    );
  }
}

class _FifoCard extends StatelessWidget {
  final FifoProfitRowEntity row;
  final bool isDark;

  const _FifoCard({required this.row, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final profitColor = row.profit >= 0 ? AppColors.success : AppColors.destructive;
    final marginBg = row.margin >= 0 ? AppColors.successLight : AppColors.destructiveLight;
    final marginFg = row.margin >= 0 ? AppColors.success : AppColors.destructive;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.productName,
                        style: AppTextStyles.labelSm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis),
                    if (row.orderId != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '# ${row.orderId}',
                        style: AppTextStyles.caption.copyWith(color: muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppFormatters.currency(row.profit),
                    style: AppTextStyles.numeric.copyWith(
                        color: profitColor, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: marginBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${row.margin.toStringAsFixed(1)}%',
                      style: AppTextStyles.caption.copyWith(
                          color: marginFg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Divider(height: 1, color: border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: l10n.unitsSold,
                  value: '${row.unitsSold}',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.colSalePrice,
                  value: AppFormatters.currency(row.salePrice),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.revenue,
                  value: AppFormatters.currency(row.revenue),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _InfoChip(
                  label: l10n.totalCost,
                  value: AppFormatters.currency(row.cost),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _MobileMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final bool isDark;

  const _MobileMetricCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      value,
                      style: AppTextStyles.numericLg.copyWith(
                          color: fg, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: muted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodyXs.copyWith(
            color: valueColor ?? fg,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MobileSectionDivider extends StatelessWidget {
  final String label;
  final bool isDark;

  const _MobileSectionDivider({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Row(
      children: [
        Expanded(child: Divider(color: border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(label,
              style: AppTextStyles.caption.copyWith(color: muted)),
        ),
        Expanded(child: Divider(color: border)),
      ],
    );
  }
}

class _MobileRefundNote extends StatelessWidget {
  final bool isDark;

  const _MobileRefundNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 13, color: muted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.refundNote,
              style: AppTextStyles.caption.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

String _pnlLabel(String key, AppLocalizations l10n) => switch (key) {
  'revenue' => l10n.grossRevenue,
  'cogs' => l10n.costOfGoods,
  'grossProfit' => l10n.grossProfit,
  'grossMargin' => l10n.profitMargin,
  _ => key,
};

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _MobileShimmer extends StatelessWidget {
  const _MobileShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        Row(children: [
          Expanded(child: ShimmerBox(height: 90)),
          SizedBox(width: 8),
          Expanded(child: ShimmerBox(height: 90)),
        ]),
        SizedBox(height: 8),
        Row(children: [
          Expanded(child: ShimmerBox(height: 90)),
          SizedBox(width: 8),
          Expanded(child: ShimmerBox(height: 90)),
        ]),
        SizedBox(height: 16),
        ShimmerBox(height: 200),
        SizedBox(height: 8),
        ShimmerBox(height: 80),
        SizedBox(height: 8),
        ShimmerBox(height: 80),
        SizedBox(height: 8),
        ShimmerBox(height: 80),
      ],
    );
  }
}
