import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/usecases/ledger_usecases.dart';
import '../../../domain/usecases/suppliers_usecases.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import '../desktop/supplier_payment_dialog.dart';

class MobileSupplierLedgerPage extends StatelessWidget {
  const MobileSupplierLedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LedgerCubit(
        getLedger: getIt<GetSupplierLedgerUseCase>(),
        getSuppliers: getIt<GetSuppliersUseCase>(),
      )..init(),
      child: const _MobileLedgerContent(),
    );
  }
}

Color _typeBadgeColor(String type) => switch (type) {
      'opening_balance' => AppColors.mutedForeground,
      'goods_receipt' => AppColors.primary,
      'payment' => AppColors.successForeground,
      'adjustment' => const Color(0xFFF59E0B),
      'refund' => AppColors.destructive,
      _ => AppColors.mutedForeground,
    };

Color _typeBadgeBg(String type) => switch (type) {
      'opening_balance' => AppColors.muted,
      'goods_receipt' => AppColors.primaryMuted,
      'payment' => AppColors.successLight,
      'adjustment' => const Color(0xFFFEF3C7),
      'refund' => AppColors.muted,
      _ => AppColors.muted,
    };

class _MobileLedgerContent extends StatefulWidget {
  const _MobileLedgerContent();

  @override
  State<_MobileLedgerContent> createState() => _MobileLedgerContentState();
}

class _MobileLedgerContentState extends State<_MobileLedgerContent> {
  final _fromCtrl = TextEditingController();
  final _toCtrl   = TextEditingController();

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
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
    if (picked != null && mounted) {
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
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final surface = isDark ? AppColors.darkSurface : AppColors.surface;
        final border = isDark ? AppColors.darkBorder : AppColors.border;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final supplierList = switch (state) {
          LedgerInitial(:final supplierList) => supplierList,
          LedgerLoading(:final supplierList) => supplierList,
          LedgerLoaded(:final supplierList) => supplierList,
          LedgerError(:final supplierList) => supplierList,
        };

        final currentSupplierId =
            state is LedgerLoaded ? state.supplierId : null;
        final currentType = state is LedgerLoaded ? state.type : null;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              l10n.t('supplier_ledger'),
              style: AppTextStyles.h6.copyWith(color: fg),
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: border),
            ),
          ),
          floatingActionButton: currentSupplierId != null &&
                  currentSupplierId.isNotEmpty
              ? FloatingActionButton.extended(
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
                  backgroundColor: AppColors.primary,
                  icon: const Icon(Icons.payments_outlined,
                      color: Colors.white),
                  label: Text(l10n.supplierRecordPayment,
                      style: const TextStyle(color: Colors.white)),
                )
              : null,
          body: Column(
            children: [
              // ── Filters ──
              Container(
                color: surface,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppSelectField<String>(
                      label: l10n.t('filter_supplier'),
                      value: currentSupplierId ?? '',
                      options: [
                        AppSelectOption(
                            value: '', label: l10n.t('all_suppliers')),
                        ...supplierList.map(
                          (s) => AppSelectOption(
                              value: s.id, label: s.name),
                        ),
                      ],
                      onChanged: (v) =>
                          cubit.setSupplier((v == null || v.isEmpty) ? null : v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSelectField<String>(
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
                      onChanged: (v) =>
                          cubit.setType((v == null || v.isEmpty) ? null : v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _MobileDateField(
                            hint: l10n.supplierLedgerDateFrom,
                            controller: _fromCtrl,
                            isDark: isDark,
                            onPick: () => _pickDate(_fromCtrl, () {
                              cubit.setDates(
                                  _fromCtrl.text.trim(),
                                  _toCtrl.text.trim());
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MobileDateField(
                            hint: l10n.supplierLedgerDateTo,
                            controller: _toCtrl,
                            isDark: isDark,
                            onPick: () => _pickDate(_toCtrl, () {
                              cubit.setDates(
                                  _fromCtrl.text.trim(),
                                  _toCtrl.text.trim());
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: border),

              // ── Body ──
              Expanded(
                child: switch (state) {
                  LedgerInitial() => ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 100),
                      ),
                    ),
                  LedgerLoading() => ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: 6,
                      itemBuilder: (_, __) => const Padding(
                        padding:
                            EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 100),
                      ),
                    ),
                  LedgerError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  LedgerLoaded(:final entries) when entries.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.receipt_long_outlined,
                          size: 40),
                      message: l10n.t('no_ledger_entries'),
                    ),
                  LedgerLoaded(
                    :final entries,
                    :final meta,
                    :final summary
                  ) =>
                    RefreshIndicator(
                      onRefresh: () async => cubit.refresh(),
                      child: CustomScrollView(
                        slivers: [
                          // Summary cards
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MobileSummaryTile(
                                          label:
                                              l10n.t('total_debit'),
                                          value:
                                              AppFormatters.currency(
                                                  summary.totalDebit),
                                          valueColor:
                                              AppColors.destructive,
                                          isDark: isDark,
                                        ),
                                      ),
                                      const SizedBox(
                                          width: AppSpacing.sm),
                                      Expanded(
                                        child: _MobileSummaryTile(
                                          label: l10n
                                              .t('total_credit'),
                                          value:
                                              AppFormatters.currency(
                                                  summary.totalCredit),
                                          valueColor: AppColors
                                              .successForeground,
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _MobileSummaryTile(
                                    label:
                                        l10n.t('current_balance'),
                                    value: AppFormatters.currency(
                                        summary.currentBalance),
                                    valueColor:
                                        summary.currentBalance >= 0
                                            ? AppColors.successForeground
                                            : AppColors.destructive,
                                    isDark: isDark,
                                    bold: true,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Entry cards
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md),
                            sliver: SliverList.separated(
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.sm),
                              itemBuilder: (context, i) {
                                final e = entries[i];
                                final date =
                                    DateTime.tryParse(e.entryDate);
                                final dateStr = date != null
                                    ? AppFormatters.dateShort(date)
                                    : e.entryDate;
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: surface,
                                    border:
                                        Border.all(color: border),
                                    borderRadius: AppRadius.brMd,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        AppSpacing.md),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            StatusBadge.custom(
                                              label: l10n.t(
                                                  'type_${e.type}'),
                                              color: _typeBadgeColor(
                                                  e.type),
                                              bgColor: _typeBadgeBg(
                                                  e.type),
                                            ),
                                            const Spacer(),
                                            Text(
                                              dateStr,
                                              style: AppTextStyles
                                                  .bodyXs
                                                  .copyWith(
                                                      color: muted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.xs),
                                        Text(
                                          e.supplierName,
                                          style: AppTextStyles.labelSm
                                              .copyWith(color: fg),
                                        ),
                                        if (e.description != null) ...[
                                          const SizedBox(
                                              height: 2),
                                          Text(
                                            e.description!,
                                            style: AppTextStyles.bodySm
                                                .copyWith(color: muted),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(
                                            height: AppSpacing.sm),
                                        Row(
                                          children: [
                                            if (e.debit > 0) ...[
                                              Text(
                                                l10n.t('col_debit'),
                                                style: AppTextStyles
                                                    .bodyXs
                                                    .copyWith(
                                                        color: muted),
                                              ),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                AppFormatters.currency(
                                                    e.debit),
                                                style: AppTextStyles
                                                    .numeric
                                                    .copyWith(
                                                        color: AppColors
                                                            .destructive),
                                              ),
                                              const SizedBox(
                                                  width:
                                                      AppSpacing.md),
                                            ],
                                            if (e.credit > 0) ...[
                                              Text(
                                                l10n.t('col_credit'),
                                                style: AppTextStyles
                                                    .bodyXs
                                                    .copyWith(
                                                        color: muted),
                                              ),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                AppFormatters.currency(
                                                    e.credit),
                                                style: AppTextStyles
                                                    .numeric
                                                    .copyWith(
                                                        color: AppColors
                                                            .successForeground),
                                              ),
                                              const SizedBox(
                                                  width:
                                                      AppSpacing.md),
                                            ],
                                            const Spacer(),
                                            Text(
                                              l10n.t('col_balance'),
                                              style: AppTextStyles
                                                  .bodyXs
                                                  .copyWith(
                                                      color: muted),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              AppFormatters.currency(
                                                  e.balanceAfter),
                                              style: AppTextStyles
                                                  .numeric
                                                  .copyWith(
                                                    color: fg,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Pagination
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  AppSpacing.md),
                              child: AppPagination(
                                meta: meta,
                                onPageChanged: cubit.goToPage,
                              ),
                            ),
                          ),
                        ],
                      ),
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

// ── Mobile Date Field ─────────────────────────────────────────────────────────

class _MobileDateField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onPick;

  const _MobileDateField({
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
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            suffixIcon:
                Icon(Icons.calendar_today_outlined, size: 14, color: muted),
          ),
        ),
      ),
    );
  }
}

// ── Mobile Summary Tile ────────────────────────────────────────────────────────

class _MobileSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;
  final bool isDark;

  const _MobileSummaryTile({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodyXs.copyWith(color: muted)),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTextStyles.numeric.copyWith(
                color: valueColor,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
