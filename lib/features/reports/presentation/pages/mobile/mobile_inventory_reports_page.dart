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

class MobileInventoryReportsPage extends StatelessWidget {
  const MobileInventoryReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InventoryReportCubit(getIt(), getIt())..load(),
      child: const _MobileInventoryView(),
    );
  }
}

class _MobileInventoryView extends StatelessWidget {
  const _MobileInventoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.inventoryReport),
        backgroundColor: surface,
        actions: [
          BlocBuilder<InventoryReportCubit, InventoryReportState>(
            builder: (context, state) {
              if (state is! InventoryReportLoaded) return const SizedBox();
              return _MobileExportButton(
                cubit: context.read<InventoryReportCubit>(),
                isDark: isDark,
                data: state.data,
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<InventoryReportCubit, InventoryReportState>(
        builder: (context, state) {
          final cubit = context.read<InventoryReportCubit>();

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

          if (state is InventoryReportInitial || state is InventoryReportLoading) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: const [
                ShimmerBox(height: 80),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(height: 70),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(height: 70),
                SizedBox(height: AppSpacing.sm),
                ShimmerBox(height: 70),
              ],
            );
          }

          if (state is InventoryReportError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => cubit.load(filters: state.filters),
            );
          }

          final data = (state as InventoryReportLoaded).data;

          return Column(
            children: [
              // ── Filter strip ──
              _MobileFilterStrip(
                  filters: filters, cubit: cubit, isDark: isDark),

              // ── Tab bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: _MobileTabBar(
                  activeTab: activeTab,
                  onTabChanged: cubit.switchTab,
                  isDark: isDark,
                ),
              ),

              // ── Content ──
              Expanded(
                child: switch (activeTab) {
                  InventoryReportTab.stock => _MobileStockTab(
                      stock: data.stock,
                      totalValue: data.totalStockValue,
                      isDark: isDark,
                    ),
                  InventoryReportTab.movements => _MobileMovementsTab(
                      movements: data.movements,
                      isDark: isDark,
                    ),
                  InventoryReportTab.transfers => _MobileTransfersTab(
                      transfers: data.transfers,
                      isDark: isDark,
                    ),
                  InventoryReportTab.stockCounts => _MobileStockCountsTab(
                      counts: data.stockCounts,
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
  final InventoryReportCubit cubit;
  final bool isDark;
  final InventoryTabReport data;

  const _MobileExportButton({
    required this.cubit,
    required this.isDark,
    required this.data,
  });

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
    final l10n = AppLocalizations.of(context);
    final data = widget.data;

    await Printing.layoutPdf(onLayout: (fmt) async {
      final doc = pw.Document();
      final regular = await PdfGoogleFonts.cairoRegular();
      final bold = await PdfGoogleFonts.cairoBold();

      doc.addPage(pw.MultiPage(
        pageFormat: fmt,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        build: (ctx) => [
          pw.Text(l10n.inventoryReport,
              textDirection: pw.TextDirection.rtl,
              style: pw.TextStyle(font: bold, fontSize: 16)),
          pw.SizedBox(height: 10),
          if (data.stock.isNotEmpty) ...[
            pw.Text(l10n.stockByWarehouse,
                textDirection: pw.TextDirection.rtl,
                style: pw.TextStyle(font: bold, fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Table(
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfTh(l10n.productName, rtl: true),
                    _pdfTh(l10n.warehouseName, rtl: true),
                    _pdfTh(l10n.onHand, align: pw.TextAlign.right),
                    _pdfTh(l10n.totalValue, align: pw.TextAlign.right),
                  ],
                ),
                ...data.stock.map((r) => pw.TableRow(children: [
                  _pdfCell(r.productName, rtl: true),
                  _pdfCell(r.warehouseName, rtl: true),
                  _pdfCell('${r.onHand}', align: pw.TextAlign.right),
                  _pdfCell(
                      _pdfNum(AppFormatters.currency(r.totalValue)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = widget.isDark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
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
    );
  }
}

// ─── Mobile Filter Strip ──────────────────────────────────────────────────────

class _MobileFilterStrip extends StatefulWidget {
  final ReportFilters filters;
  final InventoryReportCubit cubit;
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
  List<({String id, String name})> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final client = GetIt.I<ApiClient>();
      final res = await client.get<Map<String, dynamic>>(ApiEndpoints.warehouses);
      if (!mounted) return;
      final raw = res.data?['data'];
      if (raw is List) {
        setState(() {
          _warehouses = raw
              .whereType<Map<String, dynamic>>()
              .map((e) =>
                  (id: e['id']?.toString() ?? '', name: e['name'] as String? ?? ''))
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
            if (_warehouses.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              _MobileFilterChip(
                label: l10n.allWarehouses,
                value: filters.warehouseId,
                items: _warehouses,
                isDark: isDark,
                onChanged: widget.cubit.filterByWarehouse,
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            _MobileMovTypeChip(
              value: filters.movementType,
              isDark: isDark,
              onChanged: widget.cubit.filterByMovementType,
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
          child: Text(label, style: AppTextStyles.bodySm.copyWith(color: muted)),
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

class _MobileMovTypeChip extends StatelessWidget {
  final String? value;
  final bool isDark;
  final void Function(String?) onChanged;

  const _MobileMovTypeChip({
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
    return _MobileFilterChip(
      label: l10n.movements,
      value: value,
      items: items,
      isDark: isDark,
      onChanged: onChanged,
    );
  }
}

// ─── Tab Bar ──────────────────────────────────────────────────────────────────

class _MobileTabBar extends StatelessWidget {
  final InventoryReportTab activeTab;
  final ValueChanged<InventoryReportTab> onTabChanged;
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
        children: tabs.map((tab) {
          final isActive = activeTab == tab.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(tab.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 36,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : Colors.transparent,
                  borderRadius: AppRadius.brSm,
                ),
                child: Center(
                  child: Text(
                    tab.$2,
                    style: AppTextStyles.labelXs.copyWith(
                      color: isActive
                          ? Colors.white
                          : (isDark
                              ? AppColors.darkMutedForeground
                              : AppColors.mutedForeground),
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Stock Tab ────────────────────────────────────────────────────────────────

class _MobileStockTab extends StatelessWidget {
  final List<StockByWarehouseEntity> stock;
  final double totalValue;
  final bool isDark;

  const _MobileStockTab({
    required this.stock,
    required this.totalValue,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs = Theme.of(context).colorScheme;

    if (stock.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.inventory_2_outlined, size: 40),
        message: l10n.noData,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Summary card
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.inventoryValue,
                        style: AppTextStyles.bodyXs.copyWith(color: muted)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppFormatters.currency(totalValue),
                      style: AppTextStyles.numericLg.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(l10n.products,
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${stock.length}',
                    style: AppTextStyles.numericLg
                        .copyWith(color: fg, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        ...stock.map((item) {
          final isLow = item.onHand <= 5;
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
                      child: Text(item.productName,
                          style: AppTextStyles.labelSm.copyWith(color: fg),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: isLow
                            ? AppColors.destructive.withValues(alpha: 0.12)
                            : AppColors.success.withValues(alpha: 0.12),
                        borderRadius: AppRadius.brSm,
                      ),
                      child: Text(
                        '${item.onHand} ${l10n.onHand}',
                        style: AppTextStyles.labelXs.copyWith(
                          color: isLow
                              ? AppColors.destructive
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(item.warehouseName,
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (item.branchName != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text('·',
                          style: AppTextStyles.bodyXs.copyWith(color: muted)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(item.branchName!,
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(spacing: AppSpacing.sm, children: [
                      Text('${l10n.colAvailable}: ${item.available}',
                          style: AppTextStyles.bodyXs.copyWith(color: muted)),
                      if (item.reserved > 0)
                        Text('${l10n.colReserved}: ${item.reserved}',
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.warning)),
                    ]),
                    Text(
                      AppFormatters.decimal(item.avgCost),
                      style: AppTextStyles.numeric
                          .copyWith(color: fg, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Movements Tab ────────────────────────────────────────────────────────────

class _MobileMovementsTab extends StatelessWidget {
  final List<MovementEntity> movements;
  final bool isDark;

  const _MobileMovementsTab({required this.movements, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (movements.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.swap_horiz_outlined, size: 40),
        message: l10n.noData,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: movements.map((m) {
        final isPositive = m.type == 'in' || m.type == 'receipt';
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.productName,
                            style: AppTextStyles.labelSm.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis),
                        if (m.sku != null)
                          Text(m.sku!,
                              style:
                                  AppTextStyles.bodyXs.copyWith(color: muted)),
                      ],
                    ),
                  ),
                  _MobileMovBadge(type: m.type),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(m.warehouseName,
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
                  Text(
                    '${isPositive ? '+' : ''}${m.quantity}',
                    style: AppTextStyles.numeric.copyWith(
                      color: isPositive
                          ? AppColors.success
                          : AppColors.destructive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (m.reference != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(m.reference!,
                    style: AppTextStyles.bodyXs.copyWith(color: muted)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MobileMovBadge extends StatelessWidget {
  final String type;
  const _MobileMovBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = type.toLowerCase();
    final (bg, fg) = switch (t) {
      'in' || 'receipt' || 'purchase' => (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success
        ),
      'out' || 'sale' => (
          AppColors.destructive.withValues(alpha: 0.12),
          AppColors.destructive
        ),
      'transfer' || 'transfer_in' || 'transfer_out' => (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning
        ),
      'adjustment' || 'adjustment_in' || 'adjustment_out' => (
          AppColors.statusDraftBg,
          AppColors.statusDraft
        ),
      _ => (AppColors.muted, AppColors.mutedForeground),
    };
    final label = l10n.t('movementType_$t');
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brSm,
      ),
      child: Text(label,
          style: AppTextStyles.labelXs.copyWith(
              color: fg, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Transfers Tab ────────────────────────────────────────────────────────────

class _MobileTransfersTab extends StatelessWidget {
  final List<TransferRowEntity> transfers;
  final bool isDark;

  const _MobileTransfersTab({required this.transfers, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (transfers.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.local_shipping_outlined, size: 40),
        message: l10n.noData,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: transfers.map((t) {
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
                    child: Text(t.reference,
                        style: AppTextStyles.labelSm.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  _MobileStatusBadge(status: t.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(Icons.arrow_forward, size: 14, color: muted),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${t.fromWarehouse} - ${t.toWarehouse}',
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${t.itemsCount} ${l10n.itemsCount}',
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Stock Counts Tab ─────────────────────────────────────────────────────────

class _MobileStockCountsTab extends StatelessWidget {
  final List<StockCountRowEntity> counts;
  final bool isDark;

  const _MobileStockCountsTab({required this.counts, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (counts.isEmpty) {
      return AppEmptyState(
        icon: const Icon(Icons.fact_check_outlined, size: 40),
        message: l10n.noData,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: counts.map((c) {
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
                    child: Text(c.reference,
                        style: AppTextStyles.labelSm.copyWith(
                            color: Theme.of(context).colorScheme.primary),
                        overflow: TextOverflow.ellipsis),
                  ),
                  _MobileStatusBadge(status: c.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c.warehouseName,
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
                  Text('${c.itemsCount} ${l10n.itemsCount}',
                      style: AppTextStyles.bodyXs.copyWith(color: muted)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _MobileStatusBadge extends StatelessWidget {
  final String status;
  const _MobileStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status.toLowerCase()) {
      'completed' || 'received' || 'posted' => (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success
        ),
      'pending' || 'draft' => (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning
        ),
      'cancelled' => (
          AppColors.destructive.withValues(alpha: 0.12),
          AppColors.destructive
        ),
      _ => (AppColors.muted, AppColors.mutedForeground),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brSm),
      child: Text(status,
          style: AppTextStyles.labelXs
              .copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
