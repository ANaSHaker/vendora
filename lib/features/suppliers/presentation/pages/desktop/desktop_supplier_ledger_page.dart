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
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/ledger_entities.dart';
import '../../../domain/usecases/ledger_usecases.dart';
import '../../../domain/usecases/suppliers_usecases.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import 'supplier_payment_dialog.dart';

class DesktopSupplierLedgerPage extends StatelessWidget {
  const DesktopSupplierLedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LedgerCubit(
        getLedger: getIt<GetSupplierLedgerUseCase>(),
        getSuppliers: getIt<GetSuppliersUseCase>(),
        exportLedger: getIt<ExportSupplierLedgerUseCase>(),
      )..init(),
      child: const _LedgerContent(),
    );
  }
}

// ── Type badge helpers ────────────────────────────────────────────────────────

Color _typeFg(String type) => switch (type) {
      'payment'        => AppColors.successForeground,
      'goods_receipt'  => AppColors.primary,
      'adjustment'     => const Color(0xFFF59E0B),
      'refund'         => AppColors.destructive,
      _                => AppColors.mutedForeground,
    };

Color _typeBg(String type) => switch (type) {
      'payment'        => AppColors.successLight,
      'goods_receipt'  => AppColors.primaryMuted,
      'adjustment'     => const Color(0xFFFEF3C7),
      'refund'         => AppColors.muted,
      _                => AppColors.muted,
    };

// ── Page Content ──────────────────────────────────────────────────────────────

class _LedgerContent extends StatefulWidget {
  const _LedgerContent();

  @override
  State<_LedgerContent> createState() => _LedgerContentState();
}

class _LedgerContentState extends State<_LedgerContent> {
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();
  bool _exporting = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _doExport(BuildContext ctx) async {
    setState(() => _exporting = true);
    try {
      final cubit = ctx.read<LedgerCubit>();
      final bytes = await cubit.exportLedger();
      if (!mounted) return;
      setState(() => _exporting = false);
      if (bytes != null && bytes.isNotEmpty) {
        final ts = DateTime.now();
        final name =
            'suppliers_ledger_${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}.xlsx';
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

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController ctrl,
    void Function() onPicked,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      onPicked();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LedgerCubit, LedgerState>(
      builder: (context, state) {
        final cubit = context.read<LedgerCubit>();
        final l10n  = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg   = isDark ? AppColors.darkBackground : AppColors.background;
        final fg   = isDark ? AppColors.darkForeground  : AppColors.foreground;
        final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final supplierList = switch (state) {
          LedgerInitial(:final supplierList)  => supplierList,
          LedgerLoading(:final supplierList)  => supplierList,
          LedgerLoaded(:final supplierList)   => supplierList,
          LedgerError(:final supplierList)    => supplierList,
        };

        final loaded           = state is LedgerLoaded ? state : null;
        final currentSupplierId = loaded?.supplierId;
        final currentType      = loaded?.type;

        void applyDates() => cubit.setDates(
              _fromCtrl.text.trim(),
              _toCtrl.text.trim(),
            );

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
                          l10n.t('supplier_ledger'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        Text(
                          l10n.supplierLedgerSubtitle,
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Export button
                    AppButton.outline(
                      label: l10n.supplierLedgerExport,
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
                    // Record Payment (when supplier selected)
                    if (currentSupplierId != null &&
                        currentSupplierId.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppButton.primary(
                        label: l10n.supplierRecordPayment,
                        size: AppButtonSize.sm,
                        leading: const Icon(Icons.payments_outlined, size: 16),
                        onPressed: () {
                          final s = supplierList
                              .where((x) => x.id == currentSupplierId)
                              .firstOrNull;
                          if (s == null) return;
                          showSupplierPaymentDialog(
                            context,
                            supplier: s,
                            l10n: l10n,
                            onSuccess: cubit.refresh,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),

              // ── Summary Cards ──
              if (loaded != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: l10n.t('total_debit'),
                          value: AppFormatters.currency(
                              loaded.summary.totalDebit),
                          valueColor: AppColors.destructive,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryCard(
                          label: l10n.t('total_credit'),
                          value: AppFormatters.currency(
                              loaded.summary.totalCredit),
                          valueColor: AppColors.successForeground,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _SummaryCard(
                          label: l10n.t('current_balance'),
                          value: AppFormatters.currency(
                              loaded.summary.currentBalance),
                          valueColor: loaded.summary.currentBalance >= 0
                              ? AppColors.successForeground
                              : AppColors.destructive,
                          bold: true,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
              if (loaded != null) const SizedBox(height: AppSpacing.md),

              // ── Filters ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Supplier filter
                    SizedBox(
                      width: 240,
                      child: AppSelectField<String>(
                        label: l10n.t('filter_supplier'),
                        value: currentSupplierId ?? '',
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('all_suppliers')),
                          ...supplierList.map(
                            (s) =>
                                AppSelectOption(value: s.id, label: s.name),
                          ),
                        ],
                        onChanged: (v) => cubit.setSupplier(
                            (v == null || v.isEmpty) ? null : v),
                      ),
                    ),
                    // Type filter
                    SizedBox(
                      width: 190,
                      child: AppSelectField<String>(
                        label: l10n.t('filter_type'),
                        value: currentType ?? '',
                        options: [
                          AppSelectOption(
                              value: '', label: l10n.t('all_types')),
                          AppSelectOption(
                              value: 'opening_balance',
                              label: l10n.t('type_opening_balance')),
                          AppSelectOption(
                              value: 'goods_receipt',
                              label: l10n.t('type_goods_receipt')),
                          AppSelectOption(
                              value: 'payment',
                              label: l10n.t('type_payment')),
                          AppSelectOption(
                              value: 'adjustment',
                              label: l10n.t('type_adjustment')),
                          AppSelectOption(
                              value: 'refund',
                              label: l10n.t('type_refund')),
                        ],
                        onChanged: (v) => cubit
                            .setType((v == null || v.isEmpty) ? null : v),
                      ),
                    ),
                    // Date From
                    SizedBox(
                      width: 155,
                      child: _DateField(
                        hint: l10n.supplierLedgerDateFrom,
                        controller: _fromCtrl,
                        isDark: isDark,
                        onPick: () => _pickDate(
                            context, _fromCtrl, applyDates),
                        onChanged: (_) => applyDates(),
                      ),
                    ),
                    // Date To
                    SizedBox(
                      width: 155,
                      child: _DateField(
                        hint: l10n.supplierLedgerDateTo,
                        controller: _toCtrl,
                        isDark: isDark,
                        onPick: () => _pickDate(
                            context, _toCtrl, applyDates),
                        onChanged: (_) => applyDates(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Table ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    LedgerInitial() || LedgerLoading() =>
                      const ShimmerTableRows(),
                    LedgerError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    LedgerLoaded(:final entries)
                        when entries.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(
                            Icons.menu_book_outlined, size: 40),
                        message: l10n.supplierLedgerNoEntries,
                      ),
                    LedgerLoaded(:final entries, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _LedgerTable(
                              entries: entries,
                              isDark: isDark,
                              l10n: l10n,
                              muted: muted,
                              fg: fg,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppPagination(
                            meta: meta,
                            onPageChanged: cubit.goToPage,
                          ),
                          const SizedBox(
                              height: AppSizes.desktopContentPadding),
                        ],
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

// ── Date Filter Field ─────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onPick;
  final ValueChanged<String> onChanged;

  const _DateField({
    required this.hint,
    required this.controller,
    required this.isDark,
    required this.onPick,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? AppColors.darkBorder : AppColors.border;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final muted  =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          onChanged: onChanged,
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

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted  =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySm.copyWith(color: muted)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTextStyles.numericLg.copyWith(
                color: valueColor,
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ledger Table ──────────────────────────────────────────────────────────────

class _LedgerTable extends StatelessWidget {
  final List<LedgerEntryEntity> entries;
  final bool isDark;
  final AppLocalizations l10n;
  final Color muted;
  final Color fg;

  const _LedgerTable({
    required this.entries,
    required this.isDark,
    required this.l10n,
    required this.muted,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final surface  = isDark ? AppColors.darkSurface  : AppColors.surface;
    final border   = isDark ? AppColors.darkBorder   : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted    : AppColors.primaryMuted;

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
                  SizedBox(
                    width: 100,
                    child: Text(l10n.t('col_date'),
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('col_supplier'),
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 130,
                    child: Text(l10n.t('col_type'),
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.supplierLedgerColReference,
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('col_description'),
                        style: AppTextStyles.tableHeader),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 95,
                    child: Text(l10n.t('col_debit'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 95,
                    child: Text(l10n.t('col_credit'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.end),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 110,
                    child: Text(l10n.t('col_balance'),
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
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final date = DateTime.tryParse(e.entryDate);
                  final dateStr = date != null
                      ? AppFormatters.dateShort(date)
                      : e.entryDate.length >= 10
                          ? e.entryDate.substring(0, 10)
                          : e.entryDate;

                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        // Date
                        SizedBox(
                          width: 100,
                          child: Text(dateStr,
                              style: AppTextStyles.tableCell
                                  .copyWith(color: muted),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Supplier
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.supplierName,
                            style: AppTextStyles.labelSm
                                .copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Type badge
                        SizedBox(
                          width: 130,
                          child: StatusBadge.custom(
                            label: l10n.t('type_${e.type}'),
                            color: _typeFg(e.type),
                            bgColor: _typeBg(e.type),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Reference
                        SizedBox(
                          width: 110,
                          child: Text(
                            e.referenceId ?? '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Description
                        Expanded(
                          flex: 2,
                          child: Text(
                            e.description ?? '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Debit
                        SizedBox(
                          width: 95,
                          child: Text(
                            e.debit > 0
                                ? AppFormatters.currency(e.debit)
                                : '—',
                            style: AppTextStyles.numeric.copyWith(
                                color: e.debit > 0
                                    ? AppColors.destructive
                                    : muted),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Credit
                        SizedBox(
                          width: 95,
                          child: Text(
                            e.credit > 0
                                ? AppFormatters.currency(e.credit)
                                : '—',
                            style: AppTextStyles.numeric.copyWith(
                                color: e.credit > 0
                                    ? AppColors.successForeground
                                    : muted),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Balance
                        SizedBox(
                          width: 110,
                          child: Text(
                            AppFormatters.currency(e.balanceAfter),
                            style: AppTextStyles.numeric.copyWith(
                              color: fg,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
