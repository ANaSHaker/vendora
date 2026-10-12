import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
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
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/order_entity.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';
import '../desktop/widgets/order_refund_modal.dart';

class MobileOrdersPage extends StatelessWidget {
  const MobileOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit(
        getOrders: getIt(),
        getOrderById: getIt(),
        updateStatus: getIt(),
        updateFulfillmentStatus: getIt(),
        refundOrder: getIt(),
        downloadInvoice: getIt(),
        getNetRevenue: getIt(),
      )..load(),
      child: const _MobileOrdersContent(),
    );
  }
}

class _MobileOrdersContent extends StatelessWidget {
  const _MobileOrdersContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(l10n.orders),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      ),
      body: BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          final cubit = context.read<OrdersCubit>();
          final filters = switch (state) {
            OrdersLoaded(:final filters) => filters,
            OrdersLoading(:final filters) => filters,
            OrdersError(:final filters) => filters,
            _ => const OrdersFilters(),
          };

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppSearchField(
                      hint: l10n.searchOrders,
                      onChanged: cubit.search,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MobileChannelTabs(filters: filters, cubit: cubit),
                    const SizedBox(height: AppSpacing.sm),
                    AppSelectField<String>(
                      hint: l10n.allStatuses,
                      value: filters.status,
                      options: [
                        AppSelectOption(value: 'paid', label: l10n.statusPaid),
                        AppSelectOption(value: 'pending', label: l10n.statusPending),
                        AppSelectOption(value: 'refunded', label: l10n.statusRefunded),
                        AppSelectOption(value: 'partially_refunded', label: l10n.statusPartiallyRefunded),
                        AppSelectOption(value: 'void', label: l10n.statusVoid),
                      ],
                      onChanged: cubit.filterByStatus,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: switch (state) {
                  OrdersInitial() || OrdersLoading() => ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: 8,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, __) => const ShimmerBox(height: 80),
                    ),
                  OrdersError(:final message, :final filters) => AppErrorWidget(
                      message: message,
                      onRetry: () => cubit.load(filters: filters),
                    ),
                  OrdersLoaded(:final orders, :final filters) when orders.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.receipt_long_outlined, size: 40),
                      message: filters.hasActiveFilters || filters.channel != null
                          ? l10n.noOrdersFound
                          : l10n.noOrdersYet,
                      subtitle: !filters.hasActiveFilters && filters.channel == null
                          ? l10n.ordersWillAppearHere
                          : null,
                    ),
                  OrdersLoaded(:final orders, :final meta) => Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (ctx, i) => _MobileOrderCard(
                              order: orders[i],
                              isDark: isDark,
                              onTap: () => _showDetail(ctx, orders[i], cubit),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: AppPagination(
                            meta: meta,
                            onPageChanged: cubit.goToPage,
                          ),
                        ),
                      ],
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDetail(BuildContext context, OrderEntity order, OrdersCubit cubit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _MobileOrderDetailSheet(order: order),
      ),
    );
  }
}

class _MobileChannelTabs extends StatelessWidget {
  final OrdersFilters filters;
  final OrdersCubit cubit;

  const _MobileChannelTabs({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final tabs = [
      (null, l10n.allChannels),
      ('pos', l10n.channelPos),
      ('online', l10n.channelOnline),
    ];

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: tabs.map((tab) {
          final isActive = filters.channel == tab.$1;
          return GestureDetector(
            onTap: () => cubit.filterByChannel(tab.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                border: Border.all(color: isActive ? cs.primary : border),
                borderRadius: AppRadius.brFull,
              ),
              child: Text(
                tab.$2,
                style: AppTextStyles.labelXs.copyWith(
                  color: isActive ? cs.primary : muted,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MobileOrderCard extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final VoidCallback onTap;

  const _MobileOrderCard({
    required this.order,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final dateFmt = DateFormat('dd MMM yyyy');

    final (statusColor, statusBg, statusLabel) = switch (order.status) {
      'paid' => (AppColors.statusPaid, AppColors.statusPaidBg, l10n.statusPaid),
      'refunded' => (AppColors.statusRefunded, AppColors.statusRefundedBg, l10n.statusRefunded),
      'partially_refunded' => (AppColors.statusPartialRefund, AppColors.statusPartialRefundBg, l10n.statusPartiallyRefunded),
      'void' => (AppColors.statusDraft, AppColors.statusDraftBg, l10n.statusVoid),
      'cancelled' => (AppColors.statusCancelled, AppColors.statusCancelledBg, l10n.statusCancelled),
      'pending' => (AppColors.statusPending, AppColors.statusPendingBg, l10n.statusPending),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg, order.status),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  child: Text(
                    order.reference,
                    style: AppTextStyles.labelSm.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge.custom(
                  label: statusLabel,
                  color: statusColor,
                  bgColor: statusBg,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.displayCustomerName ?? l10n.noCustomer,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateFmt.format(order.createdAt.toLocal()),
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} ${l10n.itemsCount}',
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
                Text(
                  AppFormatters.currency(order.total),
                  style: AppTextStyles.labelMd.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileOrderDetailSheet extends StatelessWidget {
  final OrderEntity order;

  const _MobileOrderDetailSheet({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<OrdersCubit>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    final (statusColor, statusBg, statusLabel) = switch (order.status) {
      'paid' => (AppColors.statusPaid, AppColors.statusPaidBg, l10n.statusPaid),
      'refunded' => (AppColors.statusRefunded, AppColors.statusRefundedBg, l10n.statusRefunded),
      'partially_refunded' => (AppColors.statusPartialRefund, AppColors.statusPartialRefundBg, l10n.statusPartiallyRefunded),
      'void' => (AppColors.statusDraft, AppColors.statusDraftBg, l10n.statusVoid),
      'cancelled' => (AppColors.statusCancelled, AppColors.statusCancelledBg, l10n.statusCancelled),
      'pending' => (AppColors.statusPending, AppColors.statusPendingBg, l10n.statusPending),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg, order.status),
    };

    return Container(
      color: bg,
      padding: const EdgeInsets.all(AppSpacing.md),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.reference, style: AppTextStyles.h5.copyWith(color: fg)),
                      Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt.toLocal()),
                        style: AppTextStyles.bodySm.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
                StatusBadge.custom(label: statusLabel, color: statusColor, bgColor: statusBg),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _MobileDetailRow(label: l10n.customer, value: order.displayCustomerName ?? l10n.noCustomer, muted: muted, fg: fg),
            _MobileDetailRow(label: l10n.branch, value: order.branchName, muted: muted, fg: fg),
            if (order.cashierName != null)
              _MobileDetailRow(label: l10n.cashier, value: order.cashierName!, muted: muted, fg: fg),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.orderItems, style: AppTextStyles.labelMd.copyWith(color: fg, fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.productName, style: AppTextStyles.labelSm.copyWith(color: fg)),
                    ),
                    Text(
                      '×${item.quantity}  ${AppFormatters.currency(item.lineTotal)}',
                      style: AppTextStyles.tableCell.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            _MobileTotalRow(label: l10n.subtotal, value: AppFormatters.currency(order.subtotal), muted: muted, fg: fg),
            if (order.discountAmount > 0)
              _MobileTotalRow(label: l10n.discount, value: '-${AppFormatters.currency(order.discountAmount)}', muted: muted, fg: AppColors.success),
            _MobileTotalRow(label: l10n.tax, value: AppFormatters.currency(order.taxAmount), muted: muted, fg: muted),
            const Divider(),
            _MobileTotalRow(label: l10n.total, value: AppFormatters.currency(order.total), muted: muted, fg: fg, bold: true),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.print_outlined, size: 16),
                label: Text(l10n.printInvoice),
                onPressed: () async {
                  final bytes = await cubit.getInvoiceBytes(order.id);
                  if (!context.mounted) return;
                  if (bytes == null || bytes.isEmpty) {
                    AppSnackbar.error(context, l10n.invoiceError);
                    return;
                  }
                  await Printing.layoutPdf(
                    onLayout: (_) async => Uint8List.fromList(bytes),
                    name: 'invoice-${order.reference}',
                  );
                },
              ),
            ),
            if (!order.isTerminalStatus && order.status != 'cancelled') ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.undo_rounded, size: 16),
                  label: Text(l10n.orderRefund),
                  onPressed: () async {
                    final ok = await OrderRefundModal.show(
                      context,
                      order: order,
                      cubit: cubit,
                    );
                    if (!context.mounted || !ok) return;
                    Navigator.of(context).pop();
                    AppSnackbar.success(context, l10n.refundSuccess);
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _MobileDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;
  final Color fg;

  const _MobileDetailRow({
    required this.label,
    required this.value,
    required this.muted,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: muted)),
          Text(value, style: AppTextStyles.labelSm.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _MobileTotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color muted;
  final Color fg;
  final bool bold;

  const _MobileTotalRow({
    required this.label,
    required this.value,
    required this.muted,
    required this.fg,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTextStyles.labelMd.copyWith(color: fg, fontWeight: FontWeight.w700)
                : AppTextStyles.bodySm.copyWith(color: muted),
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.numericLg.copyWith(color: fg, fontWeight: FontWeight.w700)
                : AppTextStyles.numeric.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
