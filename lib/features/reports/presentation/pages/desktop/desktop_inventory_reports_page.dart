import 'dart:io' show Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
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
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../../domain/entities/report_entities.dart';
import '../../cubit/reports_cubit.dart';
import '../../cubit/reports_state.dart';

class DesktopInventoryReportsPage extends StatelessWidget {
  const DesktopInventoryReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryReportCubit(getIt(), getIt())..load(),
      child: const _InventoryReportView(),
    );
  }
}

// ─── Main View ────────────────────────────────────────────────────────────────

class _InventoryReportView extends StatelessWidget {
  const _InventoryReportView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryReportCubit, InventoryReportState>(
      builder: (context, state) {
        final cubit = context.read<InventoryReportCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.muted;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

        final filters = switch (state) {
          InventoryReportLoaded(:final filters) => filters,
          InventoryReportLoading(:final filters) => filters,
          InventoryReportError(:final filters) => filters,
          InventoryReportInitial(:final filters) => filters,
        };

        final activeTab = switch (state) {
          InventoryReportLoaded(:final activeTab) => activeTab,
          InventoryReportLoading(:final activeTab) => activeTab,
          _ => InventoryReportTab.stock,
        };

        return ColoredBox(
          color: bg,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.desktopContentPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.inventoryReport,
                            style: AppTextStyles.h4.copyWith(color: fg)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.stockByWarehouse,
                            style: AppTextStyles.bodySm.copyWith(
                                color: isDark
                                    ? AppColors.darkMutedForeground
                                    : AppColors.mutedForeground)),
                      ],
                    ),
                    const Spacer(),
                    _ExportDropdown(cubit: cubit, isDark: isDark),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Filter bar ──
                _FilterBar(filters: filters, cubit: cubit, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                // ── Tabs ──
                _TabBar(activeTab: activeTab, cubit: cubit, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),

                // ── Content ──
                switch (state) {
                  InventoryReportInitial() || InventoryReportLoading() =>
                    const ShimmerBox(height: 400),
                  InventoryReportError(:final message, :final filters) =>
                    AppErrorWidget(
                      message: message,
                      onRetry: () => cubit.load(filters: filters),
                    ),
                  InventoryReportLoaded(:final data, :final activeTab) =>
                    _InventoryContent(
                      data: data,
                      activeTab: activeTab,
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

// ─── Export Dropdown ──────────────────────────────────────────────────────────

class _ExportDropdown extends StatefulWidget {
  final InventoryReportCubit cubit;
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
    if (state is! InventoryReportLoaded) return;
    final l10n = AppLocalizations.of(ctx);
    final data = state.data;

    await Printing.layoutPdf(onLayout: (fmt) async {
      final doc = pw.Document();
      final regular = await PdfGoogleFonts.cairoRegular();
      final bold = await PdfGoogleFonts.cairoBold();

      doc.addPage(pw.MultiPage(
        pageFormat: fmt,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (ctx) => [
          // Title
          pw.Text(l10n.inventoryReport,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: bold, fontSize: 18)),
          pw.SizedBox(height: 12),

          // Summary row
          if (data.stock.isNotEmpty) ...[
            pw.Row(children: [
              _pdfKpi(l10n.inventoryValue,
                  data.stock.fold(0.0, (s, e) => s + e.totalValue), bold: bold),
              pw.SizedBox(width: 16),
              _pdfKpi(l10n.onHand,
                  data.stock.fold(0, (s, e) => s + e.onHand).toDouble(),
                  isCount: true, bold: bold),
              pw.SizedBox(width: 16),
              _pdfKpi(l10n.products, data.stock.length.toDouble(),
                  isCount: true, bold: bold),
            ]),
            pw.SizedBox(height: 12),

            // Stock table
            pw.Text(l10n.stockByWarehouse,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: bold, fontSize: 12)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTh(l10n.productName, rtl: true),
                    _pdfTh(l10n.warehouseName, rtl: true),
                    _pdfTh(l10n.onHand, align: pw.TextAlign.right),
                    _pdfTh(l10n.avgCost, align: pw.TextAlign.right),
                    _pdfTh(l10n.totalValue, align: pw.TextAlign.right),
                  ],
                ),
                ...data.stock.map((r) => pw.TableRow(children: [
                  _pdfCell(r.productName, rtl: true),
                  _pdfCell(r.warehouseName, rtl: true),
                  _pdfCell('${r.onHand}', align: pw.TextAlign.right),
                  _pdfCell(_pdfNum(AppFormatters.currency(r.avgCost)),
                      align: pw.TextAlign.right),
                  _pdfCell(_pdfNum(AppFormatters.currency(r.totalValue)),
                      align: pw.TextAlign.right),
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

  static pw.Widget _pdfTh(String label,
      {pw.TextAlign align = pw.TextAlign.left, bool rtl = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label,
            textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            textAlign: align,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _pdfCell(String label,
      {pw.TextAlign align = pw.TextAlign.left, bool rtl = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label,
            textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            textAlign: align,
            style: const pw.TextStyle(fontSize: 9)),
      );

  pw.Widget _pdfKpi(String label, double value,
      {bool isCount = false, required pw.Font bold}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(right: 8, bottom: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                textDirection: pw.TextDirection.rtl,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 2),
            pw.Text(
                isCount
                    ? value.toInt().toString()
                    : _pdfNum(AppFormatters.currency(value)),
                style: pw.TextStyle(fontSize: 11, font: bold)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final primary = Theme.of(context).colorScheme.primary;

    final options = [
      (ApiEndpoints.exportInventoryStockXls, l10n.exportInventory),
      (ApiEndpoints.exportInventoryMovXls, l10n.inventoryMovements),
      ('__print__', l10n.printPdf),
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
          borderRadius: AppRadius.brMd, side: BorderSide(color: border)),
      itemBuilder: (_) => options
          .map((o) => PopupMenuItem<(String, String)>(
                value: o,
                child: Text(o.$2,
                    style: AppTextStyles.bodySm.copyWith(color: fg)),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
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
                : Icon(Icons.download_outlined, size: 16, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Text(
              _exporting ?? l10n.exportReport,
              style: AppTextStyles.labelSm.copyWith(color: fg),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 14, color: muted),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatefulWidget {
  final ReportFilters filters;
  final InventoryReportCubit cubit;
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
      ]);
      if (!mounted) return;
      setState(() {
        _branches = _parseList(results[0].data ?? {});
        _warehouses = _parseList(results[1].data ?? {});
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
              onChanged: (v) => widget.cubit.load(
                  filters: v == null
                      ? filters.copyWith(clearBranch: true)
                      : filters.copyWith(branchId: v)),
            ),
          if (_warehouses.isNotEmpty)
            _FilterDropdown(
              label: l10n.allWarehouses,
              value: filters.warehouseId,
              items: _warehouses,
              isDark: isDark,
              onChanged: widget.cubit.filterByWarehouse,
            ),
          _MovementTypeDropdown(
            value: filters.movementType,
            isDark: isDark,
            onChanged: widget.cubit.filterByMovementType,
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
            Text(displayLabel,
                style: AppTextStyles.labelSm.copyWith(
                    color: isActive ? primary : muted),
                overflow: TextOverflow.ellipsis),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 14, color: isActive ? primary : muted),
          ],
        ),
      ),
    );
  }
}

class _MovementTypeDropdown extends StatelessWidget {
  final String? value;
  final bool isDark;
  final void Function(String?) onChanged;

  const _MovementTypeDropdown({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (id: 'in', name: 'Stock In'),
      (id: 'out', name: 'Stock Out'),
      (id: 'transfer', name: l10n.transfers),
      (id: 'adjustment', name: l10n.adjustments),
    ];
    return _FilterDropdown(
      label: l10n.movements,
      value: value,
      items: items,
      isDark: isDark,
      onChanged: onChanged,
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final InventoryReportTab activeTab;
  final InventoryReportCubit cubit;
  final bool isDark;

  const _TabBar({
    required this.activeTab,
    required this.cubit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final primary = Theme.of(context).colorScheme.primary;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final tabs = [
      (InventoryReportTab.stock, l10n.stockByWarehouse),
      (InventoryReportTab.movements, l10n.inventoryMovements),
      (InventoryReportTab.transfers, l10n.transfers),
      (InventoryReportTab.stockCounts, l10n.stockCounts),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (tab, label) in tabs)
            GestureDetector(
              onTap: () => cubit.switchTab(tab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: activeTab == tab ? primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: activeTab == tab ? Colors.white : muted,
                    fontWeight:
                        activeTab == tab ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Content Router ─────────────────────────────────────────────────────────────

class _InventoryContent extends StatelessWidget {
  final InventoryTabReport data;
  final InventoryReportTab activeTab;
  final bool isDark;

  const _InventoryContent({
    required this.data,
    required this.activeTab,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return switch (activeTab) {
      InventoryReportTab.stock => _StockTab(
          stock: data.stock,
          totalValue: data.totalStockValue,
          isDark: isDark,
        ),
      InventoryReportTab.movements => _MovementsTab(
          movements: data.movements,
          isDark: isDark,
        ),
      InventoryReportTab.transfers => _TransfersTab(
          transfers: data.transfers,
          isDark: isDark,
        ),
      InventoryReportTab.stockCounts => _StockCountsTab(
          counts: data.stockCounts,
          isDark: isDark,
        ),
    };
  }
}

// ── Stock by Warehouse Tab ────────────────────────────────────────────────────

class _StockTab extends StatelessWidget {
  final List<StockByWarehouseEntity> stock;
  final double totalValue;
  final bool isDark;

  const _StockTab({
    required this.stock,
    required this.totalValue,
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
    final primary = Theme.of(context).colorScheme.primary;

    if (stock.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.inventory_2_outlined, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    final totalQty = stock.fold(0, (s, i) => s + i.onHand);

    return Column(
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: l10n.inventoryValue,
                value: AppFormatters.currency(totalValue),
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.success,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSizes.desktopCardGap),
            Expanded(
              child: _KpiCard(
                label: l10n.onHand,
                value: AppFormatters.number(totalQty.toDouble()),
                icon: Icons.inventory_outlined,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: AppSizes.desktopCardGap),
            Expanded(
              child: _KpiCard(
                label: l10n.products,
                value: AppFormatters.number(stock.length.toDouble()),
                icon: Icons.category_outlined,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Table
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.brLg,
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Container(
                height: AppSizes.tableHeaderHeight,
                color: headerBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                        flex: 4,
                        child: Text(l10n.productName,
                            style: AppTextStyles.tableHeader)),
                    Expanded(
                        flex: 3,
                        child: Text(l10n.warehouseName,
                            style: AppTextStyles.tableHeader)),
                    Expanded(
                        flex: 2,
                        child: Text(l10n.branch,
                            style: AppTextStyles.tableHeader)),
                    Expanded(
                        flex: 2,
                        child: Text(l10n.colOnHand,
                            style: AppTextStyles.tableHeader,
                            textAlign: TextAlign.end)),
                    Expanded(
                        flex: 2,
                        child: Text(l10n.colReserved,
                            style: AppTextStyles.tableHeader,
                            textAlign: TextAlign.end)),
                    Expanded(
                        flex: 2,
                        child: Text(l10n.colAvailable,
                            style: AppTextStyles.tableHeader,
                            textAlign: TextAlign.end)),
                    Expanded(
                        flex: 2,
                        child: Text(l10n.avgCost,
                            style: AppTextStyles.tableHeader,
                            textAlign: TextAlign.end)),
                  ],
                ),
              ),
              Divider(height: 1, color: border),
              for (var i = 0; i < stock.length; i++) ...[
                if (i > 0) Divider(height: 1, color: border),
                Container(
                  height: AppSizes.tableRowHeight,
                  color: i.isOdd
                      ? (isDark
                          ? const Color(0xFF0F1120)
                          : const Color(0xFFFAFAFA))
                      : null,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(stock[i].productName,
                            style: AppTextStyles.labelSm.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(stock[i].warehouseName,
                            style: AppTextStyles.bodySm,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(stock[i].branchName ?? '—',
                            style: AppTextStyles.bodySm
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            AppFormatters.number(stock[i].onHand.toDouble()),
                            style: AppTextStyles.numeric.copyWith(
                                color: stock[i].onHand <= 5
                                    ? AppColors.destructive
                                    : primary),
                            textAlign: TextAlign.end),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            AppFormatters.number(stock[i].reserved.toDouble()),
                            style: AppTextStyles.numeric.copyWith(color: muted),
                            textAlign: TextAlign.end),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            AppFormatters.number(stock[i].available.toDouble()),
                            style: AppTextStyles.numeric.copyWith(
                                color: stock[i].available <= 5
                                    ? AppColors.destructive
                                    : fg),
                            textAlign: TextAlign.end),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                            AppFormatters.decimal(stock[i].avgCost),
                            style: AppTextStyles.numeric.copyWith(color: muted),
                            textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Movements Tab ─────────────────────────────────────────────────────────────

class _MovementsTab extends StatelessWidget {
  final List<MovementEntity> movements;
  final bool isDark;

  const _MovementsTab({required this.movements, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    if (movements.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.compare_arrows_rounded, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            height: AppSizes.tableHeaderHeight,
            color: headerBg,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(l10n.productName,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.warehouseName,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    child: Text(l10n.orderStatus,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    child: Text(l10n.quantity,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.dateCreated,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          for (var i = 0; i < movements.length; i++) ...[
            if (i > 0) Divider(height: 1, color: border),
            Container(
              color: i.isOdd
                  ? (isDark
                      ? const Color(0xFF0F1120)
                      : const Color(0xFFFAFAFA))
                  : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(movements[i].productName,
                            style:
                                AppTextStyles.labelSm.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis),
                        if (movements[i].sku != null)
                          Text(movements[i].sku!,
                              style: AppTextStyles.bodyXs
                                  .copyWith(color: muted)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(movements[i].warehouseName,
                        style: AppTextStyles.bodySm,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                      child: _MovementBadge(type: movements[i].type)),
                  Expanded(
                    child: Text('${movements[i].quantity}',
                        style: AppTextStyles.numeric.copyWith(
                          color: movements[i].type == 'in' ||
                                  movements[i].type == 'receipt'
                              ? AppColors.success
                              : AppColors.destructive,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dateFmt
                          .format(movements[i].createdAt.toLocal()),
                      style: AppTextStyles.bodySm.copyWith(color: muted),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Transfers Tab ─────────────────────────────────────────────────────────────

class _TransfersTab extends StatelessWidget {
  final List<TransferRowEntity> transfers;
  final bool isDark;

  const _TransfersTab({required this.transfers, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final dateFmt = DateFormat('dd MMM yyyy');

    if (transfers.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.swap_horiz_rounded, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            height: AppSizes.tableHeaderHeight,
            color: headerBg,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(l10n.reference,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.transfers.split(' ').first,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.warehouseName,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    child: Text(l10n.orderStatus,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    child: Text(l10n.itemsCount,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.dateCreated,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          for (var i = 0; i < transfers.length; i++) ...[
            if (i > 0) Divider(height: 1, color: border),
            Container(
              height: AppSizes.tableRowHeight,
              color: i.isOdd
                  ? (isDark
                      ? const Color(0xFF0F1120)
                      : const Color(0xFFFAFAFA))
                  : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(transfers[i].reference,
                        style: AppTextStyles.labelSm.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(transfers[i].fromWarehouse,
                        style: AppTextStyles.bodySm,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(transfers[i].toWarehouse,
                        style: AppTextStyles.bodySm,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                      child: _StatusBadge(status: transfers[i].status)),
                  Expanded(
                    child: Text('${transfers[i].itemsCount}',
                        style:
                            AppTextStyles.numeric.copyWith(color: fg),
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dateFmt.format(transfers[i].createdAt.toLocal()),
                      style: AppTextStyles.bodySm.copyWith(color: muted),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stock Counts Tab ──────────────────────────────────────────────────────────

class _StockCountsTab extends StatelessWidget {
  final List<StockCountRowEntity> counts;
  final bool isDark;

  const _StockCountsTab({required this.counts, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final dateFmt = DateFormat('dd MMM yyyy');

    if (counts.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.fact_check_outlined, size: 40),
        message: l10n.noDataForPeriod,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Container(
            height: AppSizes.tableHeaderHeight,
            color: headerBg,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text(l10n.reference,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.warehouseName,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    child: Text(l10n.orderStatus,
                        style: AppTextStyles.tableHeader)),
                Expanded(
                    child: Text(l10n.itemsCount,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
                Expanded(
                    flex: 2,
                    child: Text(l10n.dateCreated,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end)),
              ],
            ),
          ),
          Divider(height: 1, color: border),
          for (var i = 0; i < counts.length; i++) ...[
            if (i > 0) Divider(height: 1, color: border),
            Container(
              height: AppSizes.tableRowHeight,
              color: i.isOdd
                  ? (isDark
                      ? const Color(0xFF0F1120)
                      : const Color(0xFFFAFAFA))
                  : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(counts[i].reference,
                        style: AppTextStyles.labelSm.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(counts[i].warehouseName,
                        style: AppTextStyles.bodySm,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                      child: _StatusBadge(status: counts[i].status)),
                  Expanded(
                    child: Text('${counts[i].itemsCount}',
                        style:
                            AppTextStyles.numeric.copyWith(color: fg),
                        textAlign: TextAlign.end),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      dateFmt.format(counts[i].createdAt.toLocal()),
                      style: AppTextStyles.bodySm.copyWith(color: muted),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final bool isDark;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;
    final color = iconColor ?? primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: AppTextStyles.numericLg.copyWith(
                        color: fg, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementBadge extends StatelessWidget {
  final String type;
  const _MovementBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = type.toLowerCase();
    final (color, bg) = switch (t) {
      'in' || 'receipt' || 'purchase' =>
        (AppColors.success, AppColors.success.withValues(alpha: 0.1)),
      'out' || 'sale' =>
        (AppColors.statusPaid, AppColors.statusPaidBg),
      'transfer' || 'transfer_in' || 'transfer_out' =>
        (AppColors.statusPending, AppColors.statusPendingBg),
      'adjustment' || 'adjustment_in' || 'adjustment_out' =>
        (AppColors.statusDraft, AppColors.statusDraftBg),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg),
    };
    final label = l10n.t('movementType_$t');
    return StatusBadge.custom(label: label, color: color, bgColor: bg);
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status.toLowerCase()) {
      'posted' || 'completed' || 'received' =>
        (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'pending' || 'draft' =>
        (AppColors.statusPending, AppColors.statusPendingBg),
      'approved' => (AppColors.statusPaid, AppColors.statusPaidBg),
      'cancelled' =>
        (AppColors.statusCancelled, AppColors.statusCancelledBg),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg),
    };
    return StatusBadge.custom(label: status, color: color, bgColor: bg);
  }
}
