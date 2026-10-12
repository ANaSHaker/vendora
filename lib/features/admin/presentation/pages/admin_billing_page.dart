import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/tables/app_pagination.dart';
import '../../domain/entities/admin_payment_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_billing_cubit.dart';
import '../cubit/admin_billing_state.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso.length > 10 ? iso.substring(0, 10) : iso;
  }
}

String _fmtMoney(num? n) {
  if (n == null) return r'$0';
  return AppFormatters.currency(n.toDouble());
}

// ── Page Entry ────────────────────────────────────────────────────────────────

class AdminBillingPage extends StatelessWidget {
  const AdminBillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBillingCubit(
        getPayments: getIt<GetAdminPaymentsUseCase>(),
        getInvoices: getIt<GetAdminInvoicesUseCase>(),
        createPayment: getIt<CreateAdminPaymentUseCase>(),
        createInvoice: getIt<CreateAdminInvoiceUseCase>(),
        markPaymentPaid: getIt<MarkAdminPaymentPaidUseCase>(),
        markPaymentFailed: getIt<MarkAdminPaymentFailedUseCase>(),
        voidInvoice: getIt<VoidAdminInvoiceUseCase>(),
      )..load(),
      child: const _BillingContent(),
    );
  }
}

// ── Main Content ──────────────────────────────────────────────────────────────

class _BillingContent extends StatelessWidget {
  const _BillingContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(l10n.t('adminBilling'), style: AppTextStyles.h4.copyWith(color: fg)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.t('adminBillingSubtitle'),
                style: AppTextStyles.bodySm.copyWith(color: muted)),
            const SizedBox(height: AppSpacing.lg),

            // Tab bar
            BlocBuilder<AdminBillingCubit, AdminBillingState>(
              buildWhen: (prev, curr) {
                if (prev is AdminBillingLoaded && curr is AdminBillingLoaded) {
                  return prev.activeTab != curr.activeTab;
                }
                return true;
              },
              builder: (context, state) {
                final activeTab = state is AdminBillingLoaded ? state.activeTab : 0;
                return _TabBar(
                  activeTab: activeTab,
                  isDark: isDark,
                  borderColor: borderColor,
                  fg: fg,
                  muted: muted,
                  onTabChanged: (i) => context.read<AdminBillingCubit>().setActiveTab(i),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            // Content
            Expanded(
              child: BlocBuilder<AdminBillingCubit, AdminBillingState>(
                builder: (context, state) {
                  if (state is AdminBillingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AdminBillingError) {
                    return AppErrorWidget(
                      message: state.message,
                      onRetry: () => context.read<AdminBillingCubit>().load(),
                    );
                  }
                  if (state is AdminBillingLoaded) {
                    return state.activeTab == 0
                        ? _PaymentsTab(state: state, l10n: l10n, isDark: isDark)
                        : _InvoicesTab(state: state, l10n: l10n, isDark: isDark);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int activeTab;
  final bool isDark;
  final Color borderColor;
  final Color fg;
  final Color muted;
  final ValueChanged<int> onTabChanged;

  const _TabBar({
    required this.activeTab,
    required this.isDark,
    required this.borderColor,
    required this.fg,
    required this.muted,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TabButton(
            label: AppLocalizations.of(context).t('payments'),
            icon: Icons.credit_card_outlined,
            isActive: activeTab == 0,
            cs: cs,
            fg: fg,
            muted: muted,
            onTap: () => onTabChanged(0),
          ),
          _TabButton(
            label: AppLocalizations.of(context).t('invoices'),
            icon: Icons.receipt_long_outlined,
            isActive: activeTab == 1,
            cs: cs,
            fg: fg,
            muted: muted,
            onTap: () => onTabChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final ColorScheme cs;
  final Color fg;
  final Color muted;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.cs,
    required this.fg,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? cs.primary : muted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMd.copyWith(
                color: isActive ? fg : muted,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Cards ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color iconColor;
  final bool isDark;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.sub,
    required this.icon,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTextStyles.labelXs.copyWith(color: muted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.h5.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (sub != null)
                  Text(sub!, style: AppTextStyles.labelXs.copyWith(color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Dropdown ───────────────────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          style: AppTextStyles.labelSm.copyWith(color: fg),
          dropdownColor: bg,
          items: items.map((item) => DropdownMenuItem(
            value: item.$1,
            child: Text(item.$2, style: AppTextStyles.labelSm.copyWith(color: fg)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

// ── Payments Tab ──────────────────────────────────────────────────────────────

class _PaymentsTab extends StatelessWidget {
  final AdminBillingLoaded state;
  final AppLocalizations l10n;
  final bool isDark;

  const _PaymentsTab({required this.state, required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary = state.paymentSummary ?? {};

    final collected = (summary['collected'] as num?)?.toDouble() ?? 0;
    final pending = (summary['pending'] as num?)?.toDouble() ?? 0;
    final failed = (summary['failed'] as num?)?.toDouble() ?? 0;
    final pendingCount = (summary['pending_count'] as num?)?.toInt() ?? 0;
    final failedCount = (summary['failed_count'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(
          children: [
            _SummaryCard(
              label: l10n.t('paymentCollected'),
              value: _fmtMoney(collected),
              icon: Icons.attach_money_rounded,
              iconColor: cs.primary,
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.md),
            _SummaryCard(
              label: l10n.t('paymentPending'),
              value: _fmtMoney(pending),
              sub: '$pendingCount ${l10n.t("payments")}',
              icon: Icons.schedule_rounded,
              iconColor: cs.primary,
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.md),
            _SummaryCard(
              label: l10n.t('paymentFailed'),
              value: _fmtMoney(failed),
              sub: '$failedCount ${l10n.t("payments")}',
              icon: Icons.cancel_outlined,
              iconColor: AppColors.destructive,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Toolbar
        Row(
          children: [
            _FilterDropdown(
              value: state.paymentStatusFilter ?? '',
              isDark: isDark,
              items: [
                ('', l10n.t('allStatuses')),
                ('pending', l10n.t('status_pending')),
                ('paid', l10n.t('status_paid')),
                ('failed', l10n.t('status_failed')),
              ],
              onChanged: (v) => context.read<AdminBillingCubit>()
                  .filterPaymentsByStatus(v.isEmpty ? null : v),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FilterDropdown(
              value: state.paymentMethodFilter ?? '',
              isDark: isDark,
              items: [
                ('', l10n.t('allMethods')),
                ('cash', l10n.t('method_cash')),
                ('card', l10n.t('method_card')),
                ('online', l10n.t('method_online')),
                ('stripe', l10n.t('method_stripe')),
              ],
              onChanged: (v) => context.read<AdminBillingCubit>()
                  .filterPaymentsByMethod(v.isEmpty ? null : v),
            ),
            const Spacer(),
            _PrimaryButton(
              label: l10n.t('newPayment'),
              icon: Icons.add_rounded,
              onTap: () => _showCreatePaymentDialog(context, l10n),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Table
        Expanded(
          child: _PaymentsTable(state: state, l10n: l10n, isDark: isDark),
        ),
      ],
    );
  }

  void _showCreatePaymentDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBillingCubit>(),
        child: _CreatePaymentDialog(l10n: l10n, isDark: isDark),
      ),
    );
  }
}

class _PaymentsTable extends StatelessWidget {
  final AdminBillingLoaded state;
  final AppLocalizations l10n;
  final bool isDark;

  const _PaymentsTable({required this.state, required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    if (state.payments.isEmpty) {
      return AppEmptyState(message: l10n.t('noPayments'));
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _PaymentsHeader(l10n: l10n, isDark: isDark, borderColor: borderColor, muted: muted),
          Expanded(
            child: ListView.builder(
              itemCount: state.payments.length,
              itemBuilder: (ctx, i) => _PaymentRow(
                payment: state.payments[i],
                l10n: l10n,
                isDark: isDark,
                borderColor: borderColor,
                fg: fg,
                muted: muted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppPagination(
              meta: state.paymentsMeta,
              onPageChanged: (p) => context.read<AdminBillingCubit>().changePaymentsPage(p),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentsHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color muted;

  const _PaymentsHeader({
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final TextStyle s = AppTextStyles.tableHeader.copyWith(color: muted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.t('colVendor'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('colAmount'), style: s, textAlign: TextAlign.end)),
          Expanded(flex: 2, child: Text(l10n.t('method'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('statusLabel'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('colDate'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('colActions'), style: s, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final AdminPaymentEntity payment;
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color fg;
  final Color muted;

  const _PaymentRow({
    required this.payment,
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final methodLabel = switch (payment.method) {
      'card' => l10n.t('method_card'),
      'cash' => l10n.t('method_cash'),
      'online' => l10n.t('method_online'),
      'stripe' => l10n.t('method_stripe'),
      _ => payment.method ?? '—',
    };
    final dateStr = payment.paidAt != null
        ? _fmtDate(payment.paidAt)
        : _fmtDate(payment.createdAt);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Vendor
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(payment.vendorName,
                    style: AppTextStyles.tableCell.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w500,
                    )),
                if (payment.vendorSlug != null)
                  Text(payment.vendorSlug!,
                      style: AppTextStyles.labelXs.copyWith(
                        color: muted,
                        fontFamily: 'monospace',
                      )),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              _fmtMoney(payment.amount),
              style: AppTextStyles.numeric.copyWith(
                  color: fg, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
          // Method
          Expanded(
            flex: 2,
            child: Text(methodLabel,
                style: AppTextStyles.tableCell.copyWith(color: muted)),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _PayStatusBadge(status: payment.status, l10n: l10n),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(dateStr,
                style: AppTextStyles.tableCell.copyWith(color: muted)),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: payment.status == 'pending'
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _ActionButton(
                        label: l10n.t('markPaid'),
                        icon: Icons.check_circle_outline_rounded,
                        color: cs.primary,
                        bgColor: cs.primary.withValues(alpha: 0.08),
                        onTap: () async {
                          final ok = await context
                              .read<AdminBillingCubit>()
                              .markPaymentPaid(payment.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.t('errorSaving'))),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _ActionButton(
                        label: l10n.t('markFailed'),
                        icon: Icons.cancel_outlined,
                        color: AppColors.destructive,
                        bgColor: AppColors.destructiveLight,
                        onTap: () async {
                          final ok = await context
                              .read<AdminBillingCubit>()
                              .markPaymentFailed(payment.id);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.t('errorSaving'))),
                            );
                          }
                        },
                      ),
                    ],
                  )
                : Align(
                    alignment: Alignment.centerRight,
                    child: Text('—',
                        style: AppTextStyles.tableCell.copyWith(color: muted)),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────

class _InvoicesTab extends StatelessWidget {
  final AdminBillingLoaded state;
  final AppLocalizations l10n;
  final bool isDark;

  const _InvoicesTab({required this.state, required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary = state.invoiceSummary ?? {};

    final outstanding = (summary['outstanding'] as num?)?.toDouble() ?? 0;
    final overdueCount = (summary['overdue_count'] as num?)?.toInt() ?? 0;
    final openCount = (summary['open_count'] as num?)?.toInt() ?? 0;
    final collected = (summary['collected'] as num?)?.toDouble() ?? 0;
    final paidCount = (summary['paid_count'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(
          children: [
            _SummaryCard(
              label: l10n.t('outstandingInvoices'),
              value: _fmtMoney(outstanding),
              sub: '${openCount + overdueCount} ${l10n.t("invoices")}',
              icon: Icons.receipt_long_outlined,
              iconColor: cs.primary,
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.md),
            _SummaryCard(
              label: l10n.t('overdueInvoices'),
              value: overdueCount.toString(),
              icon: Icons.warning_amber_rounded,
              iconColor: AppColors.destructive,
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.md),
            _SummaryCard(
              label: l10n.t('paymentCollected'),
              value: _fmtMoney(collected),
              sub: '$paidCount ${l10n.t("invoices")}',
              icon: Icons.check_circle_outline_rounded,
              iconColor: cs.primary,
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Toolbar
        Row(
          children: [
            _FilterDropdown(
              value: state.invoiceStatusFilter ?? '',
              isDark: isDark,
              items: [
                ('', l10n.t('allStatuses')),
                ('open', l10n.t('status_open')),
                ('overdue', l10n.t('status_overdue')),
                ('paid', l10n.t('status_paid')),
                ('void', l10n.t('status_void')),
              ],
              onChanged: (v) => context.read<AdminBillingCubit>()
                  .filterInvoicesByStatus(v.isEmpty ? null : v),
            ),
            const Spacer(),
            _PrimaryButton(
              label: l10n.t('newInvoice'),
              icon: Icons.add_rounded,
              onTap: () => _showCreateInvoiceDialog(context, l10n),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Table
        Expanded(
          child: _InvoicesTable(state: state, l10n: l10n, isDark: isDark),
        ),
      ],
    );
  }

  void _showCreateInvoiceDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminBillingCubit>(),
        child: _CreateInvoiceDialog(l10n: l10n, isDark: isDark),
      ),
    );
  }
}

class _InvoicesTable extends StatelessWidget {
  final AdminBillingLoaded state;
  final AppLocalizations l10n;
  final bool isDark;

  const _InvoicesTable({required this.state, required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    if (state.invoices.isEmpty) {
      return AppEmptyState(message: l10n.t('noInvoices'));
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _InvoicesHeader(l10n: l10n, isDark: isDark, borderColor: borderColor, muted: muted),
          Expanded(
            child: ListView.builder(
              itemCount: state.invoices.length,
              itemBuilder: (ctx, i) => _InvoiceRow(
                invoice: state.invoices[i],
                l10n: l10n,
                isDark: isDark,
                borderColor: borderColor,
                fg: fg,
                muted: muted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppPagination(
              meta: state.invoicesMeta,
              onPageChanged: (p) => context.read<AdminBillingCubit>().changeInvoicesPage(p),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color muted;

  const _InvoicesHeader({
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final TextStyle s = AppTextStyles.tableHeader.copyWith(color: muted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(l10n.t('colVendor'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('colAmount'), style: s, textAlign: TextAlign.end)),
          Expanded(flex: 2, child: Text(l10n.t('dueDate'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('statusLabel'), style: s)),
          Expanded(flex: 2, child: Text(l10n.t('colActions'), style: s, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final AdminInvoiceEntity invoice;
  final AppLocalizations l10n;
  final bool isDark;
  final Color borderColor;
  final Color fg;
  final Color muted;

  const _InvoiceRow({
    required this.invoice,
    required this.l10n,
    required this.isDark,
    required this.borderColor,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Vendor
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(invoice.vendorName,
                    style: AppTextStyles.tableCell.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w500,
                    )),
                if (invoice.vendorSlug != null)
                  Text(invoice.vendorSlug!,
                      style: AppTextStyles.labelXs.copyWith(
                        color: muted,
                        fontFamily: 'monospace',
                      )),
              ],
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              _fmtMoney(invoice.amount),
              style: AppTextStyles.numeric.copyWith(
                  color: fg, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
          // Due Date
          Expanded(
            flex: 2,
            child: Text(_fmtDate(invoice.dueDate),
                style: AppTextStyles.tableCell.copyWith(color: muted)),
          ),
          // Status
          Expanded(
            flex: 2,
            child: _InvStatusBadge(status: invoice.status, l10n: l10n),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: switch (invoice.status) {
              'open' || 'overdue' => Align(
                  alignment: Alignment.centerRight,
                  child: _ActionButton(
                    label: l10n.t('voidInvoice'),
                    icon: Icons.block_rounded,
                    color: fg,
                    bgColor: Colors.transparent,
                    onTap: () async {
                      final ok = await context
                          .read<AdminBillingCubit>()
                          .voidInvoice(invoice.id);
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.t('errorSaving'))),
                        );
                      }
                    },
                  ),
                ),
              'paid' => Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        invoice.paidAt != null
                            ? _fmtDate(invoice.paidAt)
                            : l10n.t('status_paid'),
                        style: AppTextStyles.labelXs.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                ),
              _ => Align(
                  alignment: Alignment.centerRight,
                  child: Text('—',
                      style: AppTextStyles.tableCell.copyWith(color: muted)),
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ── Status Badges ─────────────────────────────────────────────────────────────

class _PayStatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _PayStatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'paid' => (AppColors.statusPaid, AppColors.statusPaidBg),
      'pending' => (AppColors.statusPending, AppColors.statusPendingBg),
      'failed' => (AppColors.statusCancelled, AppColors.statusCancelledBg),
      _ => (AppColors.statusPending, AppColors.statusPendingBg),
    };
    final label = l10n.t('status_$status');
    return StatusBadge(label: label == 'status_$status' ? status : label, color: color, bgColor: bg);
  }
}

class _InvStatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  const _InvStatusBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final (color, bg) = switch (status) {
      'open' => (AppColors.statusPending, AppColors.statusPendingBg),
      'paid' => (AppColors.statusPaid, AppColors.statusPaidBg),
      'overdue' => (AppColors.statusCancelled, AppColors.statusCancelledBg),
      'void' => (muted, Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkMuted
          : AppColors.muted),
      _ => (AppColors.statusPending, AppColors.statusPendingBg),
    };
    final label = l10n.t('status_$status');
    return StatusBadge(label: label == 'status_$status' ? status : label, color: color, bgColor: bg);
  }
}

// ── Action Buttons ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = color.withValues(alpha: 0.4);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brSm,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: AppTextStyles.labelXs.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppTextStyles.labelSm.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Create Payment Dialog ─────────────────────────────────────────────────────

class _CreatePaymentDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;
  const _CreatePaymentDialog({required this.l10n, required this.isDark});

  @override
  State<_CreatePaymentDialog> createState() => _CreatePaymentDialogState();
}

class _CreatePaymentDialogState extends State<_CreatePaymentDialog> {
  final _amount = TextEditingController();
  final _subscriptionId = TextEditingController();
  final _notes = TextEditingController();
  String _vendorId = '';
  String _method = 'cash';
  bool _saving = false;
  String? _error;
  List<AdminVendorEntity> _vendors = [];
  bool _loadingVendors = true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _amount.dispose();
    _subscriptionId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    final result = await getIt<GetAdminVendorsUseCase>()(perPage: 200);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingVendors = false),
      (resp) => setState(() {
        _vendors = resp.data;
        _loadingVendors = false;
      }),
    );
  }

  Future<void> _submit() async {
    if (_vendorId.isEmpty || _amount.text.isEmpty) return;
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) return;
    setState(() { _saving = true; _error = null; });
    final ok = await context.read<AdminBillingCubit>().createPayment({
      'vendor_id': _vendorId,
      'amount': amount,
      'method': _method,
      if (_subscriptionId.text.isNotEmpty) 'subscription_id': _subscriptionId.text,
      if (_notes.text.isNotEmpty) 'notes': _notes.text,
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() { _saving = false; _error = widget.l10n.t('errorSaving'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: borderColor),
      ),
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.t('createPayment'),
                        style: AppTextStyles.h5.copyWith(color: fg)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    color: muted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),

            // Body
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.destructiveLight,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Text(_error!,
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.destructive)),
                    ),
                  // Vendor
                  _FormLabel(label: l10n.t('colVendor'), fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _loadingVendors
                      ? const LinearProgressIndicator(minHeight: 36)
                      : _VendorDropdown(
                          vendors: _vendors,
                          value: _vendorId,
                          isDark: isDark,
                          placeholder: l10n.t('selectVendorPlaceholder'),
                          onChanged: (v) => setState(() => _vendorId = v),
                        ),
                  const SizedBox(height: AppSpacing.md),
                  // Amount + Method
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: l10n.t('colAmount'), fg: fg),
                            const SizedBox(height: AppSpacing.xs),
                            _TextField(
                              controller: _amount,
                              hint: '0.00',
                              isDark: isDark,
                              inputType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: l10n.t('method'), fg: fg),
                            const SizedBox(height: AppSpacing.xs),
                            _SelectField(
                              value: _method,
                              isDark: isDark,
                              items: [
                                ('cash', l10n.t('method_cash')),
                                ('card', l10n.t('method_card')),
                                ('online', l10n.t('method_online')),
                                ('stripe', l10n.t('method_stripe')),
                              ],
                              onChanged: (v) => setState(() => _method = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Subscription ID
                  _FormLabel(
                    label: l10n.t('subscriptionIdOptional'),
                    fg: fg,
                    optional: true,
                    muted: muted,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _TextField(
                    controller: _subscriptionId,
                    hint: l10n.t('subscriptionIdHint'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Notes
                  _FormLabel(label: l10n.t('notes'), fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _TextField(
                    controller: _notes,
                    hint: l10n.t('optionalPlaceholder'),
                    isDark: isDark,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            Divider(color: borderColor, height: 1),
            // Footer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.t('cancel'),
                        style: AppTextStyles.labelSm.copyWith(color: muted)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PrimaryButton(
                    label: _saving ? l10n.t('saving') : l10n.t('createPayment'),
                    icon: _saving ? Icons.hourglass_empty_rounded : Icons.add_rounded,
                    onTap: _saving ? () {} : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Create Invoice Dialog ─────────────────────────────────────────────────────

class _CreateInvoiceDialog extends StatefulWidget {
  final AppLocalizations l10n;
  final bool isDark;
  const _CreateInvoiceDialog({required this.l10n, required this.isDark});

  @override
  State<_CreateInvoiceDialog> createState() => _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends State<_CreateInvoiceDialog> {
  final _amount = TextEditingController();
  final _dueDate = TextEditingController();
  final _subscriptionId = TextEditingController();
  final _notes = TextEditingController();
  String _vendorId = '';
  bool _saving = false;
  String? _error;
  List<AdminVendorEntity> _vendors = [];
  bool _loadingVendors = true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _amount.dispose();
    _dueDate.dispose();
    _subscriptionId.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    final result = await getIt<GetAdminVendorsUseCase>()(perPage: 200);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _loadingVendors = false),
      (resp) => setState(() {
        _vendors = resp.data;
        _loadingVendors = false;
      }),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      _dueDate.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (_vendorId.isEmpty || _amount.text.isEmpty || _dueDate.text.isEmpty) return;
    final amount = double.tryParse(_amount.text);
    if (amount == null || amount <= 0) return;
    setState(() { _saving = true; _error = null; });
    final ok = await context.read<AdminBillingCubit>().createInvoice({
      'vendor_id': _vendorId,
      'amount': amount,
      'due_date': _dueDate.text,
      if (_subscriptionId.text.isNotEmpty) 'subscription_id': _subscriptionId.text,
      if (_notes.text.isNotEmpty) 'notes': _notes.text,
    });
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() { _saving = false; _error = widget.l10n.t('errorSaving'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = widget.isDark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(color: borderColor),
      ),
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.t('createInvoice'),
                        style: AppTextStyles.h5.copyWith(color: fg)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    color: muted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.destructiveLight,
                        borderRadius: AppRadius.brMd,
                      ),
                      child: Text(_error!,
                          style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.destructive)),
                    ),
                  _FormLabel(label: l10n.t('colVendor'), fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _loadingVendors
                      ? const LinearProgressIndicator(minHeight: 36)
                      : _VendorDropdown(
                          vendors: _vendors,
                          value: _vendorId,
                          isDark: isDark,
                          placeholder: l10n.t('selectVendorPlaceholder'),
                          onChanged: (v) => setState(() => _vendorId = v),
                        ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: l10n.t('colAmount'), fg: fg),
                            const SizedBox(height: AppSpacing.xs),
                            _TextField(
                              controller: _amount,
                              hint: '0.00',
                              isDark: isDark,
                              inputType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FormLabel(label: l10n.t('dueDate'), fg: fg),
                            const SizedBox(height: AppSpacing.xs),
                            GestureDetector(
                              onTap: _pickDate,
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                                  borderRadius: AppRadius.brMd,
                                  border: Border.all(
                                      color: isDark ? AppColors.darkBorder : AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined,
                                        size: 14, color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        _dueDate.text.isEmpty
                                            ? l10n.t('selectDate')
                                            : _dueDate.text,
                                        style: AppTextStyles.labelSm.copyWith(
                                          color: _dueDate.text.isEmpty
                                              ? (isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground)
                                              : (isDark ? AppColors.darkForeground : AppColors.foreground),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormLabel(
                    label: l10n.t('subscriptionIdOptional'),
                    fg: fg,
                    optional: true,
                    muted: muted,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _TextField(
                    controller: _subscriptionId,
                    hint: l10n.t('subscriptionIdHint'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormLabel(label: l10n.t('notes'), fg: fg),
                  const SizedBox(height: AppSpacing.xs),
                  _TextField(
                    controller: _notes,
                    hint: l10n.t('optionalPlaceholder'),
                    isDark: isDark,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.t('cancel'),
                        style: AppTextStyles.labelSm.copyWith(color: muted)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _PrimaryButton(
                    label: _saving ? l10n.t('saving') : l10n.t('createInvoice'),
                    icon: _saving ? Icons.hourglass_empty_rounded : Icons.add_rounded,
                    onTap: _saving ? () {} : _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Form Widgets ───────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String label;
  final Color fg;
  final bool optional;
  final Color? muted;

  const _FormLabel({
    required this.label,
    required this.fg,
    this.optional = false,
    this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.labelSm.copyWith(color: fg, fontWeight: FontWeight.w500)),
        if (optional && muted != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Text('(optional)', style: AppTextStyles.labelXs.copyWith(color: muted)),
        ],
      ],
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final int maxLines;
  final TextInputType? inputType;
  final List<TextInputFormatter>? inputFormatters;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.maxLines = 1,
    this.inputType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      style: AppTextStyles.labelSm.copyWith(color: fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.labelSm.copyWith(color: muted),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  final String value;
  final bool isDark;
  final List<(String, String)> items;
  final ValueChanged<String> onChanged;

  const _SelectField({
    required this.value,
    required this.isDark,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          style: AppTextStyles.labelSm.copyWith(color: fg),
          dropdownColor: bg,
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(
            value: item.$1,
            child: Text(item.$2, style: AppTextStyles.labelSm.copyWith(color: fg)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}

class _VendorDropdown extends StatelessWidget {
  final List<AdminVendorEntity> vendors;
  final String value;
  final bool isDark;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const _VendorDropdown({
    required this.vendors,
    required this.value,
    required this.isDark,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isDense: true,
          isExpanded: true,
          hint: Text(placeholder, style: AppTextStyles.labelSm.copyWith(color: muted)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
          style: AppTextStyles.labelSm.copyWith(color: fg),
          dropdownColor: bg,
          items: vendors.map((v) => DropdownMenuItem(
            value: v.id,
            child: Text(v.name, style: AppTextStyles.labelSm.copyWith(color: fg)),
          )).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ),
    );
  }
}
