import 'dart:io' show Process;

import 'package:fl_chart/fl_chart.dart';
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

class DesktopFinancialReportsPage extends StatelessWidget {
  const DesktopFinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinancialReportCubit(getIt(), getIt())..load(),
      child: const _FinancialReportView(),
    );
  }
}

// ─── Main view ────────────────────────────────────────────────────────────────

class _FinancialReportView extends StatelessWidget {
  const _FinancialReportView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinancialReportCubit, FinancialReportState>(
      builder: (context, state) {
        final cubit = context.read<FinancialReportCubit>();
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.muted;

        final filters = switch (state) {
          FinancialReportLoaded(:final filters) => filters,
          FinancialReportLoading(:final filters) => filters,
          FinancialReportError(:final filters) => filters,
          FinancialReportInitial(:final filters) => filters,
        };

        final activeTab = state is FinancialReportLoaded
            ? state.activeTab
            : FinancialReportTab.pnl;

        return ColoredBox(
          color: bg,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                _PageHeader(
                  cubit: cubit,
                  activeTab: activeTab,
                  filters: filters,
                  isLoaded: state is FinancialReportLoaded,
                  isDark: isDark,
                ),

                // ── Filter bar ──
                _FilterBar(
                  filters: filters,
                  cubit: cubit,
                  isDark: isDark,
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── State content ──
                      switch (state) {
                        FinancialReportInitial() ||
                        FinancialReportLoading() =>
                          const _FinancialShimmer(),
                        FinancialReportError(:final message, :final filters) =>
                          AppErrorWidget(
                            message: message,
                            onRetry: () => cubit.load(filters: filters),
                          ),
                        FinancialReportLoaded(:final data, :final activeTab) =>
                          _FinancialContent(
                            data: data,
                            activeTab: activeTab,
                            cubit: cubit,
                            isDark: isDark,
                          ),
                      },
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Page Header ──────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final FinancialReportCubit cubit;
  final FinancialReportTab activeTab;
  final ReportFilters filters;
  final bool isLoaded;
  final bool isDark;

  const _PageHeader({
    required this.cubit,
    required this.activeTab,
    required this.filters,
    required this.isLoaded,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.desktopContentPadding,
        AppSpacing.xl,
        AppSizes.desktopContentPadding,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.financialReport,
                  style: AppTextStyles.h4.copyWith(color: fg)),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.financialSummary,
                  style: AppTextStyles.bodySm.copyWith(color: muted)),
            ],
          ),
          const Spacer(),

          // Export dropdown (always visible)
          _ExportDropdown(cubit: cubit, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Export Dropdown ──────────────────────────────────────────────────────────

class _ExportDropdown extends StatefulWidget {
  final FinancialReportCubit cubit;
  final bool isDark;

  const _ExportDropdown({required this.cubit, required this.isDark});

  @override
  State<_ExportDropdown> createState() => _ExportDropdownState();
}

class _ExportDropdownState extends State<_ExportDropdown> {
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

  Future<void> _doPrint(BuildContext ctx) async {
    final state = widget.cubit.state;
    if (state is! FinancialReportLoaded) return;
    final l10n = AppLocalizations.of(ctx);
    final data = state.data;
    final s = data.summary;
    final dateFrom = state.filters.dateFrom.toLocal().toString().substring(0, 10);
    final dateTo = state.filters.dateTo.toLocal().toString().substring(0, 10);

    final regular = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();

    await Printing.layoutPdf(onLayout: (_) async {
      final doc = pw.Document();
      final theme = pw.ThemeData.withFont(base: regular, bold: bold);

      doc.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        theme: theme,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context _) => [
          // ── Header ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(l10n.financialReport,
                  textDirection: pw.TextDirection.rtl,
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('$dateFrom - $dateTo',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),

          // ── KPI grid ──
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(),
              1: const pw.FlexColumnWidth(),
              2: const pw.FlexColumnWidth(),
              3: const pw.FlexColumnWidth(),
              4: const pw.FlexColumnWidth(),
              5: const pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(children: [
                _pdfKpi(l10n.grossRevenue, s.grossRevenue, bold: bold),
                _pdfKpi(l10n.costOfGoods, s.totalCost, bold: bold),
                _pdfKpi(l10n.grossProfit, s.grossProfit, bold: bold),
                _pdfKpi(l10n.profitMargin, null,
                    extra: '${s.profitMargin.toStringAsFixed(1)}%', bold: bold),
                _pdfKpi(l10n.netRevenue, s.netRevenue, bold: bold),
                _pdfKpi(l10n.totalRefunds, s.totalRefunds, bold: bold),
              ]),
            ],
          ),

          // ── P&L breakdown ──
          if (data.pnlRows.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(l10n.pnlReport,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
              },
              children: data.pnlRows.map((row) {
                final label = _pdfPnlLabel(row.label, l10n);
                final fw = row.isSubtotal ? pw.FontWeight.bold : pw.FontWeight.normal;
                return pw.TableRow(
                  decoration: row.isSubtotal
                      ? const pw.BoxDecoration(color: PdfColors.grey100)
                      : null,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(label,
                          textDirection: pw.TextDirection.rtl,
                          style: pw.TextStyle(fontSize: 10, fontWeight: fw)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_pdfNum(AppFormatters.currency(row.amount)),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(fontSize: 10, fontWeight: fw)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],

          // ── Top products ──
          if (s.topProfitableProducts.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(l10n.topProfitable,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTh(l10n.productName, rtl: true),
                    _pdfTh(l10n.revenue, align: pw.TextAlign.right),
                    _pdfTh(l10n.profit, align: pw.TextAlign.right),
                    _pdfTh(l10n.colMargin, align: pw.TextAlign.right),
                  ],
                ),
                ...s.topProfitableProducts.map((p) => pw.TableRow(children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(p.productName,
                        textDirection: pw.TextDirection.rtl,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(_pdfNum(AppFormatters.currency(p.revenue)),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(_pdfNum(AppFormatters.currency(p.profit)),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text('${(p.marginPercent ?? 0).toStringAsFixed(1)}%',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9)),
                  ),
                ])),
              ],
            ),
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

  static pw.Widget _pdfTh(String label,
      {pw.TextAlign align = pw.TextAlign.left, bool rtl = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label,
            textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            textAlign: align,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      );

  pw.Widget _pdfKpi(String label, double? value, {String? extra, required pw.Font bold}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 8, bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              textDirection: pw.TextDirection.rtl,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(extra ?? _pdfNum(AppFormatters.currency(value ?? 0)),
              style: pw.TextStyle(fontSize: 11, font: bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final primary = Theme.of(context).colorScheme.primary;

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
          _doPrint(context);
        } else {
          _doExport(item.$1, item.$2);
        }
      },
      offset: const Offset(0, 40),
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brMd,
        side: BorderSide(color: border),
      ),
      itemBuilder: (_) {
        final printItem = PopupMenuItem<(String, String)>(
          value: ('__print__', l10n.printPdf),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('PDF',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.printPdf,
                  style: AppTextStyles.bodySm.copyWith(color: fg)),
            ],
          ),
        );
        return [
          printItem,
          const PopupMenuDivider(),
          ...options.map((opt) {
            final isActive = _exporting == opt.$2;
            return PopupMenuItem(
              value: opt,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'XLS',
                      style: AppTextStyles.caption.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(opt.$2,
                      style: AppTextStyles.bodySm.copyWith(color: fg)),
                  if (isActive) ...[
                    const Spacer(),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5, color: primary),
                    ),
                  ],
                ],
              ),
            );
          }),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _exporting != null
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: primary))
                : Icon(Icons.download_outlined, size: 15, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Text(l10n.exportReport,
                style: AppTextStyles.labelSm.copyWith(color: fg)),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.expand_more_rounded, size: 15, color: muted),
          ],
        ),
      ),
    );
  }

  Color get muted => widget.isDark
      ? AppColors.darkMutedForeground
      : AppColors.mutedForeground;
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  final ReportFilters filters;
  final FinancialReportCubit cubit;
  final bool isDark;

  const _FilterBar({
    required this.filters,
    required this.cubit,
    required this.isDark,
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.desktopContentPadding,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: surface,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          AppDateRangePicker(
            startDate: filters.dateFrom,
            endDate: filters.dateTo,
            activePreset: filters.preset,
            onPresetChanged: widget.cubit.changePreset,
            onCustomRange: widget.cubit.setCustomRange,
          ),
          if (_branches.isNotEmpty)
            _FilterDropdown(
              label: l10n.allBranches,
              value: filters.branchId,
              items: _branches,
              isDark: isDark,
              onChanged: widget.cubit.filterByBranch,
            ),
          if (_warehouses.isNotEmpty)
            _FilterDropdown(
              label: l10n.allWarehouses,
              value: filters.warehouseId,
              items: _warehouses,
              isDark: isDark,
              onChanged: widget.cubit.filterByWarehouse,
            ),
          if (_products.isNotEmpty)
            _FilterDropdown(
              label: l10n.allProducts,
              value: filters.productId,
              items: _products,
              isDark: isDark,
              onChanged: widget.cubit.filterByProduct,
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<({String id, String name})> items;
  final bool isDark;
  final void Function(String?) onChanged;

  const _FilterDropdown({
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
              style: AppTextStyles.bodySm.copyWith(
                  color: item.id == value ? primary : fg)),
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
              displayLabel,
              style: AppTextStyles.labelSm.copyWith(
                  color: isActive ? primary : muted),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 14, color: isActive ? primary : muted),
          ],
        ),
      ),
    );
  }
}

// ─── Financial Content ────────────────────────────────────────────────────────

class _FinancialContent extends StatelessWidget {
  final FinancialReportEntity data;
  final FinancialReportTab activeTab;
  final FinancialReportCubit cubit;
  final bool isDark;

  const _FinancialContent({
    required this.data,
    required this.activeTab,
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
        // ── KPI strip row 1 ──
        Row(children: [
          Expanded(
            child: _AccentStatCard(
              label: l10n.grossRevenue,
              value: AppFormatters.currency(s.grossRevenue),
              icon: Icons.trending_up_rounded,
              accentColor: primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: _AccentStatCard(
              label: l10n.costOfGoods,
              value: AppFormatters.currency(s.totalCost),
              icon: Icons.inventory_2_outlined,
              accentColor: AppColors.warning,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: _AccentStatCard(
              label: l10n.grossProfit,
              value: AppFormatters.currency(s.grossProfit),
              icon: Icons.savings_outlined,
              accentColor: AppColors.success,
              subLabel: '${s.profitMargin.toStringAsFixed(1)}% ${l10n.profitMargin}',
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: AppSizes.desktopCardGap),

        // ── KPI strip row 2 ──
        Row(children: [
          Expanded(
            child: _AccentStatCard(
              label: l10n.netRevenue,
              value: AppFormatters.currency(s.netRevenue),
              icon: Icons.payments_outlined,
              accentColor: AppColors.info,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: _AccentStatCard(
              label: l10n.totalRefunds,
              value: AppFormatters.currency(s.totalRefunds),
              icon: Icons.reply_outlined,
              accentColor: AppColors.destructive,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: _AccentStatCard(
              label: l10n.totalOrders,
              value: AppFormatters.number(s.totalOrders),
              icon: Icons.receipt_long_outlined,
              accentColor: AppColors.mutedForeground,
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),

        // ── Tab bar ──
        _UnderlineTabBar(activeTab: activeTab, cubit: cubit, isDark: isDark),
        const SizedBox(height: AppSpacing.xl),

        // ── Tab content ──
        switch (activeTab) {
          FinancialReportTab.pnl =>
            _PnlTab(summary: s, pnlRows: data.pnlRows, isDark: isDark),
          FinancialReportTab.sales =>
            _SalesTab(
              rows: data.salesRows,
              topProducts: s.topProfitableProducts,
              worstProducts: s.worstMarginProducts,
              isDark: isDark,
            ),
          FinancialReportTab.inventory =>
            _InventoryTab(
              rows: data.inventoryRows,
              topProducts: s.topProfitableProducts,
              worstProducts: s.worstMarginProducts,
              isDark: isDark,
            ),
          FinancialReportTab.fifo =>
            _FifoTab(
              rows: data.fifoRows,
              topProducts: s.topProfitableProducts,
              worstProducts: s.worstMarginProducts,
              isDark: isDark,
            ),
        },

        const SizedBox(height: AppSpacing.xl2),
        _RefundNote(isDark: isDark),
      ],
    );
  }
}

// ─── Accent Stat Card ─────────────────────────────────────────────────────────

class _AccentStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? subLabel;
  final bool isDark;

  const _AccentStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.isDark,
    this.subLabel,
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
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Colored left accent
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(label,
                              style: AppTextStyles.labelSm.copyWith(color: muted)),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: AppRadius.brSm,
                          ),
                          child: Icon(icon, size: 15, color: accentColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(value,
                        style: AppTextStyles.numericXl.copyWith(color: fg)),
                    if (subLabel != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(subLabel!,
                          style: AppTextStyles.caption.copyWith(color: muted)),
                    ],
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

// ─── Underline Tab Bar ────────────────────────────────────────────────────────

class _UnderlineTabBar extends StatelessWidget {
  final FinancialReportTab activeTab;
  final FinancialReportCubit cubit;
  final bool isDark;

  const _UnderlineTabBar({
    required this.activeTab,
    required this.cubit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final primary = Theme.of(context).colorScheme.primary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final tabs = [
      (FinancialReportTab.pnl, l10n.pnl, Icons.balance_outlined),
      (FinancialReportTab.sales, l10n.navSales, Icons.point_of_sale_outlined),
      (FinancialReportTab.inventory, l10n.inventory, Icons.inventory_outlined),
      (FinancialReportTab.fifo, l10n.fifoProfit, Icons.stacked_bar_chart_rounded),
    ];

    return Column(
      children: [
        Row(
          children: tabs.map((tab) {
            final isActive = activeTab == tab.$1;
            return GestureDetector(
              onTap: () => cubit.switchTab(tab.$1),
              child: Padding(
                padding:
                    const EdgeInsets.only(right: AppSpacing.lg),
                child: Column(
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: AppTextStyles.labelMd.copyWith(
                        color: isActive ? primary : muted,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            tab.$3,
                            size: 15,
                            color: isActive ? primary : muted,
                          ),
                          const SizedBox(width: 6),
                          Text(tab.$2),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: isActive ? 60 : 0,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        Divider(height: 1, color: border),
      ],
    );
  }
}

// ─── P&L Tab ──────────────────────────────────────────────────────────────────

class _PnlTab extends StatelessWidget {
  final FinancialSummaryEntity summary;
  final List<PnlRowEntity> pnlRows;
  final bool isDark;

  const _PnlTab({
    required this.summary,
    required this.pnlRows,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = summary;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Revenue basis indicator
        Row(
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: AppColors.mutedForeground),
            const SizedBox(width: 6),
            Text(
              '${l10n.revenueBasisLabel}:',
              style: AppTextStyles.labelSm
                  .copyWith(color: AppColors.mutedForeground),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.px2),
              decoration: BoxDecoration(
                color: AppColors.primaryMuted,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                s.revenueBasis == 'line_items'
                    ? l10n.basisLineItems
                    : l10n.basisOrderTotal,
                style: AppTextStyles.caption.copyWith(
                    color: primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4 KPI cards in 2x2
        Row(children: [
          Expanded(
            child: _PnlMetricCard(
              label: l10n.revenue,
              value: AppFormatters.currency(s.grossRevenue),
              icon: Icons.trending_up_rounded,
              iconColor: primary,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: _PnlMetricCard(
              label: l10n.costOfGoods,
              value: AppFormatters.currency(s.totalCost),
              icon: Icons.inventory_2_outlined,
              iconColor: AppColors.warning,
              isDark: isDark,
            ),
          ),
        ]),
        const SizedBox(height: AppSizes.desktopCardGap),
        Row(children: [
          Expanded(
            child: _PnlMetricCard(
              label: l10n.grossProfit,
              value: AppFormatters.currency(s.grossProfit),
              icon: Icons.savings_outlined,
              iconColor: AppColors.success,
              highlight: true,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: AppSizes.desktopCardGap),
          Expanded(
            child: _PnlMarginCard(
              label: l10n.profitMargin,
              percent: s.profitMargin,
              isDark: isDark,
            ),
          ),
        ]),

        if (pnlRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(title: l10n.pnlReport, isDark: isDark),
          const SizedBox(height: AppSpacing.md),
          _PnlTable(rows: pnlRows, isDark: isDark),
        ],

        if (s.topProfitableProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl2),
          _SummaryTopSection(
            topProducts: s.topProfitableProducts,
            worstProducts: s.worstMarginProducts,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class _PnlMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool highlight;
  final bool isDark;

  const _PnlMetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: highlight
            ? iconColor.withValues(alpha: isDark ? 0.08 : 0.05)
            : surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: highlight
              ? iconColor.withValues(alpha: 0.25)
              : border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySm.copyWith(color: muted)),
                const SizedBox(height: AppSpacing.px4),
                Text(
                  value,
                  style: AppTextStyles.numericLg.copyWith(
                    color: highlight ? iconColor : fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PnlMarginCard extends StatelessWidget {
  final String label;
  final double percent;
  final bool isDark;

  const _PnlMarginCard({
    required this.label,
    required this.percent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final barBg = isDark ? AppColors.darkMuted : AppColors.muted;
    final primary = Theme.of(context).colorScheme.primary;
    final progressColor =
        percent >= 30 ? AppColors.success : percent >= 10 ? AppColors.warning : AppColors.destructive;
    final clampedPercent = percent.clamp(0.0, 100.0) / 100.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(Icons.percent_rounded, size: 18, color: primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodySm.copyWith(color: muted)),
                const SizedBox(height: AppSpacing.px4),
                Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: AppTextStyles.numericLg.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: clampedPercent,
                    backgroundColor: barBg,
                    color: progressColor,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PnlTable extends StatelessWidget {
  final List<PnlRowEntity> rows;
  final bool isDark;

  const _PnlTable({required this.rows, required this.isDark});

  static String _translateLabel(String key, AppLocalizations l10n) =>
      switch (key) {
        'revenue' => l10n.grossRevenue,
        'cogs' => l10n.costOfGoods,
        'grossProfit' => l10n.grossProfit,
        'grossMargin' => l10n.profitMargin,
        _ => key,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final subtotalBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          final isNegative = row.amount < 0;

          return Container(
            padding: EdgeInsets.only(
              left: row.isSubtotal ? AppSpacing.lg : AppSpacing.xl2,
              right: AppSpacing.lg,
              top: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: row.isSubtotal ? subtotalBg : Colors.transparent,
              border: i > 0
                  ? Border(top: BorderSide(color: border, width: 0.5))
                  : null,
              borderRadius: i == rows.length - 1
                  ? const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _translateLabel(row.label, l10n),
                  style: row.isSubtotal
                      ? AppTextStyles.labelMd
                          .copyWith(color: fg, fontWeight: FontWeight.w600)
                      : AppTextStyles.bodySm.copyWith(color: muted),
                ),
                Text(
                  AppFormatters.currency(row.amount),
                  style: row.isSubtotal
                      ? AppTextStyles.numericLg.copyWith(
                          color: isNegative
                              ? AppColors.destructive
                              : primary,
                          fontWeight: FontWeight.w700,
                        )
                      : AppTextStyles.numeric.copyWith(
                          color: isNegative
                              ? AppColors.destructive
                              : fg,
                        ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Sales Tab ────────────────────────────────────────────────────────────────

class _SalesTab extends StatelessWidget {
  final List<FinancialSalesRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _SalesTab({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DataTableContainer(
          isDark: isDark,
          header: _TableRowWidget(
            cells: [
              _TableCell(label: l10n.orderId, flex: 4, isHeader: true),
              _TableCell(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.xl),
                  child: Text(l10n.productName,
                      style: AppTextStyles.tableHeader.copyWith(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground)),
                ),
                flex: 4,
                isHeader: true,
              ),
              _TableCell(label: l10n.quantity, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colSalePrice, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colUnitCost, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.revenue, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.totalCost, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.profit, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colMargin, flex: 2, isHeader: true, align: TextAlign.end),
            ],
            isDark: isDark,
            isHeader: true,
          ),
          rows: rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
            final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
            final profitColor = r.profit >= 0 ? AppColors.success : AppColors.destructive;

            return _TableRowWidget(
              isAlt: i.isOdd,
              cells: [
                _TableCell(
                  child: Text(r.orderId ?? '—',
                      style: AppTextStyles.caption.copyWith(color: mutedFg)),
                  flex: 4,
                ),
                _TableCell(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.xl),
                    child: Text(r.productName,
                        style: AppTextStyles.labelSm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis),
                  ),
                  flex: 4,
                ),
                _TableCell(
                  child: Text('${r.qty}',
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.salePrice),
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.decimal(r.unitCost),
                      style: AppTextStyles.numeric.copyWith(color: mutedFg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.revenue),
                      style: AppTextStyles.numeric.copyWith(
                          fontWeight: FontWeight.w600, color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.totalCost),
                      style: AppTextStyles.numeric.copyWith(color: mutedFg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.profit),
                      style: AppTextStyles.numeric.copyWith(
                          color: profitColor, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: _MarginBadge(percent: r.marginPercent),
                  flex: 2,
                  align: TextAlign.end,
                ),
              ],
              isDark: isDark,
            );
          }).toList(),
        ),
        if (topProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl2),
          _SummaryTopSection(
            topProducts: topProducts,
            worstProducts: worstProducts,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

// ─── Inventory Tab ────────────────────────────────────────────────────────────

class _InventoryTab extends StatelessWidget {
  final List<FinancialInventoryRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _InventoryTab({
    required this.rows,
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (rows.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.inventory_2_outlined, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.access_time_rounded, size: 13, color: muted),
          const SizedBox(width: AppSpacing.px4),
          Text(
            '${l10n.inventoryValuationAt} ${AppFormatters.dateTime(DateTime.now())}',
            style: AppTextStyles.caption.copyWith(color: muted),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _DataTableContainer(
          isDark: isDark,
          header: _TableRowWidget(
            cells: [
              _TableCell(label: l10n.productName, flex: 4, isHeader: true),
              _TableCell(label: l10n.warehouseName, flex: 3, isHeader: true),
              _TableCell(label: l10n.onHand, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.avgCost, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.totalValue, flex: 2, isHeader: true, align: TextAlign.end),
            ],
            isDark: isDark,
            isHeader: true,
          ),
          rows: rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
            final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
            final primary = Theme.of(context).colorScheme.primary;

            return _TableRowWidget(
              isAlt: i.isOdd,
              cells: [
                _TableCell(
                  child: Text(r.productName,
                      style: AppTextStyles.labelSm.copyWith(color: fg),
                      overflow: TextOverflow.ellipsis),
                  flex: 4,
                ),
                _TableCell(
                  child: Text(r.warehouseName,
                      style: AppTextStyles.bodySm.copyWith(color: mutedFg),
                      overflow: TextOverflow.ellipsis),
                  flex: 3,
                ),
                _TableCell(
                  child: Text(AppFormatters.number(r.qtyOnHand.toDouble()),
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.decimal(r.avgCost),
                      style: AppTextStyles.numeric.copyWith(color: mutedFg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.totalValue),
                      style: AppTextStyles.numeric.copyWith(
                          color: primary, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
              ],
              isDark: isDark,
            );
          }).toList(),
        ),
        if (topProducts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl2),
          _SummaryTopSection(
            topProducts: topProducts,
            worstProducts: worstProducts,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

// ─── FIFO Tab ─────────────────────────────────────────────────────────────────

class _FifoTab extends StatelessWidget {
  final List<FifoProfitRowEntity> rows;
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _FifoTab({
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
        icon: const Icon(Icons.stacked_bar_chart_rounded, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── FIFO Table ──
        _DataTableContainer(
          isDark: isDark,
          header: _TableRowWidget(
            cells: [
              _TableCell(label: l10n.orderId, flex: 4, isHeader: true),
              _TableCell(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: AppSpacing.xl),
                  child: Text(l10n.productName,
                      style: AppTextStyles.tableHeader.copyWith(
                          color: isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground)),
                ),
                flex: 4,
                isHeader: true,
              ),
              _TableCell(label: l10n.quantity, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colSalePrice, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colLineRevenue, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colFifoCost, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.profit, flex: 2, isHeader: true, align: TextAlign.end),
              _TableCell(label: l10n.colMargin, flex: 2, isHeader: true, align: TextAlign.end),
            ],
            isDark: isDark,
            isHeader: true,
          ),
          rows: rows.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
            final mutedFg = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
            final profitColor = r.profit >= 0 ? AppColors.success : AppColors.destructive;

            return _TableRowWidget(
              isAlt: i.isOdd,
              cells: [
                _TableCell(
                  child: Text(r.orderId ?? '—',
                      style: AppTextStyles.caption.copyWith(color: mutedFg)),
                  flex: 4,
                ),
                _TableCell(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(start: AppSpacing.xl),
                    child: Text(r.productName,
                        style: AppTextStyles.labelSm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis),
                  ),
                  flex: 4,
                ),
                _TableCell(
                  child: Text('${r.unitsSold}',
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.salePrice),
                      style: AppTextStyles.numeric.copyWith(color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.revenue),
                      style: AppTextStyles.numeric.copyWith(
                          fontWeight: FontWeight.w600, color: fg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.cost),
                      style: AppTextStyles.numeric.copyWith(color: mutedFg),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: Text(AppFormatters.currency(r.profit),
                      style: AppTextStyles.numeric.copyWith(
                          color: profitColor, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.end),
                  flex: 2,
                  align: TextAlign.end,
                ),
                _TableCell(
                  child: _MarginBadge(percent: r.margin),
                  flex: 2,
                  align: TextAlign.end,
                ),
              ],
              isDark: isDark,
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl2),

        // ── Summary top/worst (from summary API) or derived from rows ──
        _SummaryTopSection(
          topProducts: topProducts.isNotEmpty
              ? topProducts
              : _deriveTop(rows),
          worstProducts: worstProducts.isNotEmpty
              ? worstProducts
              : _deriveWorst(rows),
          isDark: isDark,
        ),
      ],
    );
  }

  List<TopProductEntity> _deriveTop(List<FifoProfitRowEntity> rows) =>
      (List.of(rows)..sort((a, b) => b.profit.compareTo(a.profit)))
          .take(8)
          .map((r) => TopProductEntity(
                productId: '',
                productName: r.productName,
                revenue: r.revenue,
                cogs: r.cost,
                profit: r.profit,
                marginPercent: r.margin,
              ))
          .toList();

  List<TopProductEntity> _deriveWorst(List<FifoProfitRowEntity> rows) =>
      (List.of(rows)..sort((a, b) => a.margin.compareTo(b.margin)))
          .take(8)
          .map((r) => TopProductEntity(
                productId: '',
                productName: r.productName,
                revenue: r.revenue,
                cogs: r.cost,
                profit: r.profit,
                marginPercent: r.margin,
              ))
          .toList();
}

// ─── Summary Top Products Section ────────────────────────────────────────────

class _SummaryTopSection extends StatelessWidget {
  final List<TopProductEntity> topProducts;
  final List<TopProductEntity> worstProducts;
  final bool isDark;

  const _SummaryTopSection({
    required this.topProducts,
    required this.worstProducts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final top8 = topProducts.take(8).toList();
    final worst8 = worstProducts.take(8).toList();
    final maxProfit = top8.isEmpty ? 1.0 : top8.first.profit.abs();
    final maxWorst = worst8.isEmpty ? 100.0 : worst8.map((e) => (e.marginPercent ?? 0).abs()).fold(0.0, (a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (top8.isNotEmpty) ...[
          _SectionHeader(title: l10n.topProfitableChart, isDark: isDark),
          const SizedBox(height: AppSpacing.md),
          _SummaryBarChart(rows: top8, isDark: isDark),
          const SizedBox(height: AppSpacing.xl2),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (top8.isNotEmpty)
              Expanded(
                child: _SummaryRankedList(
                  title: l10n.topProfitable,
                  rows: top8,
                  maxValue: maxProfit,
                  getValue: (r) => AppFormatters.currency(r.profit),
                  getValueColor: (r) =>
                      r.profit >= 0 ? AppColors.success : AppColors.destructive,
                  isDark: isDark,
                ),
              ),
            if (top8.isNotEmpty && worst8.isNotEmpty)
              const SizedBox(width: AppSizes.desktopCardGap),
            if (worst8.isNotEmpty)
              Expanded(
                child: _SummaryRankedList(
                  title: l10n.worstMargin,
                  rows: worst8,
                  maxValue: maxWorst > 0 ? maxWorst : 100.0,
                  getValue: (r) => '${(r.marginPercent ?? 0).toStringAsFixed(1)}%',
                  getValueColor: (r) => (r.marginPercent ?? 0) < 0
                      ? AppColors.destructive
                      : AppColors.mutedForeground,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SummaryBarChart extends StatelessWidget {
  final List<TopProductEntity> rows;
  final bool isDark;

  const _SummaryBarChart({required this.rows, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final gridColor = isDark ? AppColors.darkBorder : AppColors.border;
    final labelColor = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final barGroups = rows.asMap().entries.map((e) {
      final profit = e.value.profit;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: profit,
            color: profit >= 0 ? primary : AppColors.destructive,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: gridColor, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (val, _) => Text(
                  AppFormatters.compact(val),
                  style: AppTextStyles.caption.copyWith(color: labelColor),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (val, _) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= rows.length) return const SizedBox();
                  final name = rows[idx].productName;
                  final truncated = name.length > 12 ? '${name.substring(0, 12)}…' : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(truncated,
                        style: AppTextStyles.caption.copyWith(color: labelColor),
                        overflow: TextOverflow.ellipsis),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${rows[group.x].productName}\n${AppFormatters.currency(rod.toY)}',
                AppTextStyles.caption.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryRankedList extends StatelessWidget {
  final String title;
  final List<TopProductEntity> rows;
  final double maxValue;
  final String Function(TopProductEntity) getValue;
  final Color Function(TopProductEntity) getValueColor;
  final bool isDark;

  const _SummaryRankedList({
    required this.title,
    required this.rows,
    required this.maxValue,
    required this.getValue,
    required this.getValueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final barBg = isDark ? AppColors.darkBorder : AppColors.muted;
    final primary = Theme.of(context).colorScheme.primary;

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
            child: Text(title,
                style: AppTextStyles.labelMd.copyWith(color: fg)),
          ),
          Divider(height: 1, color: border),
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  _RankBadge(rank: i + 1, isTop: i == 0, isDark: isDark),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].productName,
                          style: AppTextStyles.labelSm.copyWith(color: fg),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.px4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: maxValue > 0
                                ? (rows[i].profit.abs() / maxValue).clamp(0.05, 1.0)
                                : 0,
                            backgroundColor: barBg,
                            color: primary.withValues(alpha: 0.4),
                            minHeight: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    getValue(rows[i]),
                    style: AppTextStyles.numeric.copyWith(
                      color: getValueColor(rows[i]),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1) Divider(height: 1, color: border),
          ],
        ],
      ),
    );
  }
}

// ─── Refund Note ──────────────────────────────────────────────────────────────

class _RefundNote extends StatelessWidget {
  final bool isDark;

  const _RefundNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: muted),
          const SizedBox(width: AppSpacing.sm),
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

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(title,
            style: AppTextStyles.labelLg.copyWith(color: fg)),
      ],
    );
  }
}

// ─── Data Table Container ─────────────────────────────────────────────────────

class _DataTableContainer extends StatelessWidget {
  final bool isDark;
  final Widget header;
  final List<Widget> rows;

  const _DataTableContainer({
    required this.isDark,
    required this.header,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          header,
          Divider(height: 1, color: border),
          ...rows.asMap().entries.map((e) {
            return Column(
              children: [
                if (e.key > 0) Divider(height: 1, color: border),
                e.value,
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TableCell {
  final String? label;
  final Widget? child;
  final int flex;
  final TextAlign align;
  final bool isHeader;

  const _TableCell({
    this.label,
    this.child,
    this.flex = 1,
    this.align = TextAlign.start,
    this.isHeader = false,
  });
}

class _TableRowWidget extends StatelessWidget {
  final List<_TableCell> cells;
  final bool isDark;
  final bool isHeader;
  final bool isAlt;

  const _TableRowWidget({
    required this.cells,
    required this.isDark,
    this.isHeader = false,
    this.isAlt = false,
  });

  @override
  Widget build(BuildContext context) {
    final headerBg =
        isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final altBg =
        isDark ? const Color(0xFF0F1120) : const Color(0xFFFAFAFA);
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      height: isHeader ? AppSizes.tableHeaderHeight : AppSizes.tableRowHeight,
      color: isHeader ? headerBg : (isAlt ? altBg : null),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: cells.map((cell) {
          Widget content;
          if (cell.child != null) {
            content = cell.child!;
          } else {
            content = Text(
              cell.label ?? '',
              style: AppTextStyles.tableHeader.copyWith(color: muted),
              textAlign: cell.align,
            );
          }
          return Expanded(
            flex: cell.flex,
            child: Align(
              alignment: cell.align == TextAlign.end
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: content,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Rank Badge ───────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  final bool isTop;
  final bool isDark;

  const _RankBadge({
    required this.rank,
    required this.isTop,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final mutedBg = isDark ? AppColors.darkBorder : AppColors.muted;

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isTop ? AppColors.primaryMuted : mutedBg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: AppTextStyles.caption.copyWith(
          color: isTop ? primary : muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Margin Badge ─────────────────────────────────────────────────────────────

class _MarginBadge extends StatelessWidget {
  final double percent;

  const _MarginBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isPos = percent >= 0;
    final bg = isPos ? AppColors.successLight : AppColors.destructiveLight;
    final fg = isPos ? AppColors.success : AppColors.destructive;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${percent.toStringAsFixed(1)}%',
          style: AppTextStyles.caption.copyWith(
              color: fg, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _FinancialShimmer extends StatelessWidget {
  const _FinancialShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: const [
          Expanded(child: ShimmerBox(height: 110)),
          SizedBox(width: 16),
          Expanded(child: ShimmerBox(height: 110)),
          SizedBox(width: 16),
          Expanded(child: ShimmerBox(height: 110)),
        ]),
        const SizedBox(height: 16),
        Row(children: const [
          Expanded(child: ShimmerBox(height: 110)),
          SizedBox(width: 16),
          Expanded(child: ShimmerBox(height: 110)),
          SizedBox(width: 16),
          Expanded(child: ShimmerBox(height: 110)),
        ]),
        const SizedBox(height: 20),
        const ShimmerBox(height: 40, width: 400),
        const SizedBox(height: 16),
        const ShimmerBox(height: 400),
      ],
    );
  }
}
