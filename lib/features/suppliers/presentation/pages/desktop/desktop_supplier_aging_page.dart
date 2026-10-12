import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/utils/file_saver.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../domain/entities/aging_entities.dart';
import '../../../domain/usecases/aging_usecases.dart';
import '../../../domain/usecases/suppliers_usecases.dart';
import '../../cubit/aging_cubit.dart';

class DesktopSupplierAgingPage extends StatelessWidget {
  const DesktopSupplierAgingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgingCubit(
        getAging: getIt<GetSupplierAgingUseCase>(),
        exportAging: getIt<ExportSupplierAgingUseCase>(),
        getSuppliers: getIt<GetSuppliersUseCase>(),
      )..init(),
      child: const _AgingContent(),
    );
  }
}

// ── Page Content ──────────────────────────────────────────────────────────────

class _AgingContent extends StatefulWidget {
  const _AgingContent();

  @override
  State<_AgingContent> createState() => _AgingContentState();
}

class _AgingContentState extends State<_AgingContent> {
  final _asOfCtrl = TextEditingController();
  bool _exporting = false;

  @override
  void dispose() {
    _asOfCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAsOf(BuildContext ctx) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: ctx,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null && mounted) {
      _asOfCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ctx.read<AgingCubit>().setAsOf(_asOfCtrl.text.trim());
    }
  }

  Future<void> _doExport(BuildContext ctx) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ctx.read<AgingCubit>().exportAging();
      if (!mounted) return;
      setState(() => _exporting = false);
      if (bytes != null && bytes.isNotEmpty) {
        final ts = DateTime.now();
        final name =
            'suppliers_aging_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}.xlsx';
        final path = await saveExportFile(bytes, name);
        if (!mounted) return;
        if (path != null) {
          AppSnackbar.success(ctx, path);
        } else {
          AppSnackbar.error(ctx, AppLocalizations.of(ctx).error);
        }
      } else {
        AppSnackbar.error(ctx, AppLocalizations.of(ctx).error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _exporting = false);
      AppSnackbar.error(ctx, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgingCubit, AgingState>(
      builder: (context, state) {
        final cubit = context.read<AgingCubit>();
        final l10n  = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg    = isDark ? AppColors.darkBackground : AppColors.background;
        final fg    = isDark ? AppColors.darkForeground  : AppColors.foreground;
        final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final supplierList = switch (state) {
          AgingInitial(:final supplierList) => supplierList,
          AgingLoading(:final supplierList) => supplierList,
          AgingLoaded(:final supplierList)  => supplierList,
          AgingError(:final supplierList)   => supplierList,
        };

        final currentSupplierId =
            state is AgingLoaded ? state.supplierId : null;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.supplierAgingTitle,
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        Text(
                          l10n.supplierAgingSubtitle,
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.outline(
                      label: l10n.supplierAgingExport,
                      size: AppButtonSize.sm,
                      leading: _exporting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined, size: 16),
                      isLoading: _exporting,
                      onPressed: _exporting ? null : () => _doExport(context),
                    ),
                  ],
                ),
              ),

              // ── Filters ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // As Of date
                    SizedBox(
                      width: 170,
                      child: _DateField(
                        hint: l10n.supplierAgingAsOf,
                        controller: _asOfCtrl,
                        isDark: isDark,
                        onPick: () => _pickAsOf(context),
                      ),
                    ),
                    // Supplier filter
                    SizedBox(
                      width: 240,
                      child: AppSelectField<String>(
                        value: currentSupplierId ?? '',
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('all_suppliers')),
                          ...supplierList.map(
                            (s) => AppSelectOption(
                                value: s.id, label: s.name),
                          ),
                        ],
                        onChanged: (v) => cubit.setSupplier(
                            (v == null || v.isEmpty) ? null : v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── Aging note ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding),
                child: Text(
                  l10n.supplierAgingNote,
                  style: AppTextStyles.bodyXs
                      .copyWith(color: muted, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: AppSizes.desktopContentPadding,
                    right: AppSizes.desktopContentPadding,
                    bottom: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    AgingInitial() || AgingLoading() =>
                      const ShimmerTableRows(),
                    AgingError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.init,
                      ),
                    AgingLoaded(:final rows)
                        when rows.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.access_time_outlined, size: 40),
                        message: l10n.supplierAgingNoData,
                      ),
                    AgingLoaded(:final rows, :final totals) =>
                      _AgingTable(
                        rows: rows,
                        totals: totals,
                        isDark: isDark,
                        l10n: l10n,
                        fg: fg,
                        muted: muted,
                      ),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Date Field ────────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onPick;

  const _DateField({
    required this.hint,
    required this.controller,
    required this.isDark,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: muted, fontSize: 13),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: border),
            ),
            filled: true,
            fillColor: bg,
            suffixIcon: Icon(Icons.calendar_today_outlined,
                size: 14, color: muted),
          ),
        ),
      ),
    );
  }
}

// ── Aging Table ───────────────────────────────────────────────────────────────

class _AgingTable extends StatelessWidget {
  final List<AgingRowEntity> rows;
  final AgingTotals totals;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;

  const _AgingTable({
    required this.rows,
    required this.totals,
    required this.isDark,
    required this.l10n,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.darkSurface  : AppColors.surface;
    final border   = isDark ? AppColors.darkBorder   : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted    : AppColors.primaryMuted;
    final totalsBg = isDark ? AppColors.darkMuted    : const Color(0xFFF5F7FF);

    Widget _numCell(double val, {Color? color, bool bold = false}) => Text(
          val > 0 ? AppFormatters.currency(val) : '—',
          style: AppTextStyles.numeric.copyWith(
            color: val > 0 ? (color ?? fg) : muted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
          textAlign: TextAlign.end,
        );

    Widget _totalCell(double val, {Color? color}) => Text(
          AppFormatters.currency(val),
          style: AppTextStyles.numeric.copyWith(
            color: color ?? fg,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.end,
        );

    const colW = 110.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // Header
            Container(
              height: AppSizes.tableHeaderHeight,
              color: headerBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(l10n.supplierAgingColSupplier,
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: colW,
                    child: Text(l10n.supplierAgingColCurrent,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: colW,
                    child: Text(l10n.supplierAgingCol1_30,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: colW,
                    child: Text(l10n.supplierAgingCol31_60,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: colW,
                    child: Text(l10n.supplierAgingCol61_90,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: colW,
                    child: Text(l10n.supplierAgingColOver90,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  SizedBox(
                    width: colW,
                    child: Text(l10n.supplierAgingColTotal,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: border),

            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            r.supplierName,
                            style: AppTextStyles.labelSm.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: colW, child: _numCell(r.current)),
                        SizedBox(width: colW, child: _numCell(r.bucket1to30)),
                        SizedBox(width: colW, child: _numCell(r.bucket31to60)),
                        SizedBox(
                            width: colW,
                            child: _numCell(r.bucket61to90,
                                color: AppColors.primary)),
                        SizedBox(
                            width: colW,
                            child: _numCell(r.over90,
                                color: AppColors.destructive)),
                        SizedBox(
                            width: colW,
                            child: _numCell(r.totalBalance,
                                color: AppColors.primary, bold: true)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Totals row
            Divider(height: 2, color: border, thickness: 2),
            Container(
              height: AppSizes.tableRowHeight,
              color: totalsBg,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.t('total'),
                      style: AppTextStyles.labelSm
                          .copyWith(color: fg, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: colW, child: _totalCell(totals.current)),
                  SizedBox(width: colW, child: _totalCell(totals.bucket1to30)),
                  SizedBox(width: colW, child: _totalCell(totals.bucket31to60)),
                  SizedBox(
                      width: colW,
                      child: _totalCell(totals.bucket61to90,
                          color: AppColors.primary)),
                  SizedBox(
                      width: colW,
                      child: _totalCell(totals.over90,
                          color: AppColors.destructive)),
                  SizedBox(
                      width: colW,
                      child: _totalCell(totals.totalBalance,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
