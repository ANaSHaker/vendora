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
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/customer_entities.dart';
import '../../cubit/customers_cubit.dart';
import '../../cubit/customers_state.dart';

class DesktopCustomersPage extends StatelessWidget {
  const DesktopCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomersCubit(
        getCustomers: getIt(),
        getCustomerById: getIt(),
        createCustomer: getIt(),
        updateCustomer: getIt(),
        deleteCustomer: getIt(),
      )..load(),
      child: const _CustomersContent(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> _showCustomerForm(
  BuildContext context,
  CustomersCubit cubit,
  AppLocalizations l10n, {
  CustomerEntity? editing,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CustomerFormDialog(
      editing: editing,
      l10n: l10n,
      onSave: (data) async {
        final ok = editing != null
            ? await cubit.updateCustomer(editing.id, data)
            : await cubit.createCustomer(data);
        if (ok && context.mounted) {
          AppSnackbar.success(
            context,
            editing != null
                ? l10n.t('customerUpdated')
                : l10n.t('customerCreated'),
          );
        }
        return ok;
      },
    ),
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  CustomerEntity customer,
  CustomersCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('deleteCustomerTitle'),
    message: l10n.t('deleteCustomerMsg').replaceAll('{name}', customer.name),
    confirmLabel: l10n.delete,
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteCustomer(customer.id);
  if (context.mounted) {
    if (ok) {
      AppSnackbar.success(context, l10n.t('customerDeleted'));
    } else {
      AppSnackbar.error(context, l10n.t('customerDeleteFailed'));
    }
  }
}

// ── Page Content ──────────────────────────────────────────────────────────────

class _CustomersContent extends StatelessWidget {
  const _CustomersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        final cubit = context.read<CustomersCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

        final selectedId =
            state is CustomersLoaded ? state.selectedId : null;
        final selectedDetail =
            state is CustomersLoaded ? state.selectedDetail : null;
        final loadingDetail =
            state is CustomersLoaded ? state.loadingDetail : false;

        return Stack(
          children: [
            ColoredBox(
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
                              l10n.customers,
                              style: AppTextStyles.h4.copyWith(color: fg),
                            ),
                            if (state is CustomersLoaded)
                              Text(
                                '${state.meta.total} ${l10n.t("customersTotal")}',
                                style: AppTextStyles.bodySm
                                    .copyWith(color: muted),
                              ),
                          ],
                        ),
                        const Spacer(),
                        AppButton.primary(
                          label: l10n.t('newCustomer'),
                          size: AppButtonSize.sm,
                          leading: const Icon(Icons.add, size: 16),
                          onPressed: () =>
                              _showCustomerForm(context, cubit, l10n),
                        ),
                      ],
                    ),
                  ),

                  // ── Search ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.desktopContentPadding,
                    ),
                    child: SizedBox(
                      width: 300,
                      child: AppSearchField(
                        hint: l10n.t('searchCustomers'),
                        onChanged: cubit.search,
                      ),
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
                        CustomersInitial() || CustomersLoading() =>
                          const ShimmerTableRows(),
                        CustomersError(:final message) => AppErrorWidget(
                            message: message,
                            onRetry: cubit.refresh,
                          ),
                        CustomersLoaded(:final customers)
                            when customers.isEmpty =>
                          AppEmptyState(
                            icon:
                                const Icon(Icons.people_outline, size: 40),
                            message: l10n.t('noCustomers'),
                            subtitle: l10n.t('addFirstCustomer'),
                            action: AppButton.primary(
                              label: l10n.t('newCustomer'),
                              onPressed: () =>
                                  _showCustomerForm(context, cubit, l10n),
                            ),
                          ),
                        CustomersLoaded(:final customers, :final meta) =>
                          Column(
                            children: [
                              Expanded(
                                child: _CustomersTable(
                                  customers: customers,
                                  cubit: cubit,
                                  isDark: isDark,
                                  l10n: l10n,
                                  selectedId: selectedId,
                                  onEdit: (c) => _showCustomerForm(
                                      context, cubit, l10n,
                                      editing: c),
                                  onDelete: (c) => _confirmDelete(
                                      context, c, cubit, l10n),
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
            ),

            // ── Backdrop ──
            if (selectedId != null)
              GestureDetector(
                onTap: cubit.closeDetail,
                child: Container(color: Colors.black38),
              ),

            // ── Slide-over panel ──
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              top: 0,
              bottom: 0,
              right: selectedId != null ? 0 : -420,
              child: SizedBox(
                width: 400,
                child: _CustomerSlideOver(
                  detail: selectedDetail,
                  loading: loadingDetail,
                  isDark: isDark,
                  l10n: l10n,
                  onClose: cubit.closeDetail,
                  onEdit: (c) {
                    cubit.closeDetail();
                    _showCustomerForm(context, cubit, l10n, editing: c);
                  },
                  onDelete: (c) {
                    cubit.closeDetail();
                    _confirmDelete(context, c, cubit, l10n);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Customers Table ───────────────────────────────────────────────────────────

class _CustomersTable extends StatelessWidget {
  final List<CustomerEntity> customers;
  final CustomersCubit cubit;
  final bool isDark;
  final AppLocalizations l10n;
  final String? selectedId;
  final void Function(CustomerEntity) onEdit;
  final void Function(CustomerEntity) onDelete;

  const _CustomersTable({
    required this.customers,
    required this.cubit,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final selBg = isDark ? AppColors.darkSurface : AppColors.primaryMuted;

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
                      child: Text(l10n.t('colCustomer'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      flex: 2,
                      child: Text(l10n.t('colPhone'),
                          style: AppTextStyles.tableHeader)),
                  Expanded(
                      child: Text(l10n.t('colOrders'),
                          style: AppTextStyles.tableHeader,
                          textAlign: TextAlign.right)),
                  Expanded(
                      child: Text(l10n.t('colTotalSpent'),
                          style: AppTextStyles.tableHeader,
                          textAlign: TextAlign.right)),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.t('colPoints'),
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(l10n.colStatus,
                        style: AppTextStyles.tableHeader,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 72),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final c = customers[i];
                  final isSelected = c.id == selectedId;
                  return InkWell(
                    onTap: () => cubit.selectCustomer(c.id),
                    child: Container(
                      height: AppSizes.tableRowHeight,
                      color: isSelected ? selBg : null,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Row(
                        children: [
                          // Customer (avatar + name + email)
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                _Avatar(name: c.name),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        c.name,
                                        style: AppTextStyles.labelSm
                                            .copyWith(color: fg),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (c.email != null)
                                        Text(
                                          c.email!,
                                          style: AppTextStyles.bodyXs
                                              .copyWith(color: muted),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Phone
                          Expanded(
                            flex: 2,
                            child: Text(
                              c.phone ?? '—',
                              style: AppTextStyles.tableCell
                                  .copyWith(color: muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Orders
                          Expanded(
                            child: Text(
                              '${c.ordersCount}',
                              style:
                                  AppTextStyles.numeric.copyWith(color: fg),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // Total spent
                          Expanded(
                            child: Text(
                              c.totalSpent > 0
                                  ? AppFormatters.currency(c.totalSpent)
                                  : '—',
                              style:
                                  AppTextStyles.numeric.copyWith(color: fg),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // Points
                          SizedBox(
                            width: 80,
                            child: Text(
                              AppFormatters.number(c.loyaltyPoints),
                              style: AppTextStyles.numeric
                                  .copyWith(color: muted),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          // Status
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: c.isActive
                                  ? StatusBadge.custom(
                                      label: l10n.active,
                                      color: AppColors.successForeground,
                                      bgColor: AppColors.successLight,
                                    )
                                  : StatusBadge.custom(
                                      label: l10n.inactive,
                                      color: AppColors.mutedForeground,
                                      bgColor: AppColors.muted,
                                    ),
                            ),
                          ),
                          // Actions
                          SizedBox(
                            width: 72,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AppIconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 14),
                                  onPressed: () => onEdit(c),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.edit,
                                ),
                                AppIconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 14),
                                  onPressed: () => onDelete(c),
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.sm,
                                  tooltip: l10n.delete,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// ── Avatar ────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.labelSm.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Customer Slide-over ───────────────────────────────────────────────────────

class _CustomerSlideOver extends StatelessWidget {
  final CustomerEntity? detail;
  final bool loading;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final void Function(CustomerEntity) onEdit;
  final void Function(CustomerEntity) onDelete;

  const _CustomerSlideOver({
    required this.detail,
    required this.loading,
    required this.isDark,
    required this.l10n,
    required this.onClose,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(left: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 56,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration:
                BoxDecoration(border: Border(bottom: BorderSide(color: border))),
            child: Row(
              children: [
                Text(l10n.t('customerDetail'),
                    style: AppTextStyles.h6.copyWith(color: fg)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: muted, size: 18),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : detail == null
                    ? const SizedBox.shrink()
                    : _CustomerDetailBody(
                        customer: detail!,
                        isDark: isDark,
                        l10n: l10n,
                      ),
          ),

          // Footer
          if (detail != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: border))),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.edit,
                      leading:
                          const Icon(Icons.edit_outlined, size: 14),
                      onPressed: () => onEdit(detail!),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.delete,
                      leading:
                          const Icon(Icons.delete_outline, size: 14),
                      onPressed: () => onDelete(detail!),
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

// ── Customer Detail Body ──────────────────────────────────────────────────────

class _CustomerDetailBody extends StatelessWidget {
  final CustomerEntity customer;
  final bool isDark;
  final AppLocalizations l10n;

  const _CustomerDetailBody({
    required this.customer,
    required this.isDark,
    required this.l10n,
  });

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final bg = isDark ? AppColors.darkMuted : AppColors.muted;
    final primary = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryMuted,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.h5.copyWith(
                            color: primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  customer.name,
                                  style: AppTextStyles.h6
                                      .copyWith(color: fg),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              customer.isActive
                                  ? StatusBadge.custom(
                                      label: l10n.active,
                                      color: AppColors.successForeground,
                                      bgColor: AppColors.successLight,
                                    )
                                  : StatusBadge.custom(
                                      label: l10n.inactive,
                                      color: AppColors.mutedForeground,
                                      bgColor: AppColors.muted,
                                    ),
                            ],
                          ),
                          if (customer.createdAt.isNotEmpty)
                            Text(
                              '${l10n.t("customerSince")} ${_fmtDate(customer.createdAt)}',
                              style: AppTextStyles.bodyXs
                                  .copyWith(color: muted),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      customer.phone ?? l10n.t('noPhone'),
                      style: AppTextStyles.bodySm.copyWith(
                        color:
                            customer.phone != null ? fg : muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 14, color: muted),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        customer.email ?? l10n.t('noEmail'),
                        style: AppTextStyles.bodySm.copyWith(
                          color: customer.email != null ? fg : muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: border),

          // Stats 2x2 grid
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _StatTile(
                        icon: Icons.shopping_bag_outlined,
                        value: '${customer.ordersCount}',
                        label: l10n.t('statTotalOrders'),
                        bg: bg,
                        fg: fg,
                        muted: muted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StatTile(
                        value: AppFormatters.currency(customer.totalSpent),
                        label: l10n.t('statTotalSpent'),
                        bg: bg,
                        fg: fg,
                        muted: muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    children: [
                      _StatTile(
                        icon: Icons.star_outline_rounded,
                        iconColor: Colors.amber,
                        value: AppFormatters.number(customer.loyaltyPoints),
                        label: l10n.t('statPoints'),
                        bg: bg,
                        fg: fg,
                        muted: muted,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StatTile(
                        icon: Icons.calendar_today_outlined,
                        value: customer.lastOrderDate != null
                            ? _fmtDate(customer.lastOrderDate!)
                            : '—',
                        label: l10n.t('statLastOrder'),
                        bg: bg,
                        fg: fg,
                        muted: muted,
                        valueStyle: AppTextStyles.labelSm,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notes
          if (customer.notes != null) ...[
            Divider(height: 1, color: border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 14, color: muted),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.t('labelNotes').toUpperCase(),
                        style: AppTextStyles.bodyXs.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(customer.notes!,
                      style: AppTextStyles.bodySm.copyWith(color: fg)),
                ],
              ),
            ),
          ],

          // Recent orders
          Divider(height: 1, color: border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recentOrders.toUpperCase(),
                  style: AppTextStyles.bodyXs.copyWith(
                      color: muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (customer.recentOrders.isEmpty)
                  Text(
                    l10n.noRecentOrders,
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                  )
                else
                  for (var i = 0;
                      i < customer.recentOrders.length;
                      i++) ...[
                    if (i > 0) Divider(height: 1, color: border),
                    _OrderTile(
                      order: customer.recentOrders[i],
                      l10n: l10n,
                      fg: fg,
                      muted: muted,
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String value;
  final String label;
  final Color bg;
  final Color fg;
  final Color muted;
  final TextStyle? valueStyle;

  const _StatTile({
    this.icon,
    this.iconColor,
    required this.value,
    required this.label,
    required this.bg,
    required this.fg,
    required this.muted,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: iconColor ?? muted),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: (valueStyle ?? AppTextStyles.numericLg).copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label,
              style: AppTextStyles.bodyXs.copyWith(color: muted),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final CustomerOrderEntity order;
  final AppLocalizations l10n;
  final Color fg;
  final Color muted;

  const _OrderTile({
    required this.order,
    required this.l10n,
    required this.fg,
    required this.muted,
  });

  Color get _statusColor => switch (order.status) {
        'paid' => AppColors.successForeground,
        'refunded' || 'partial_refund' => AppColors.destructive,
        _ => AppColors.mutedForeground,
      };

  Color get _statusBg => switch (order.status) {
        'paid' => AppColors.successLight,
        'refunded' || 'partial_refund' => AppColors.muted,
        _ => AppColors.muted,
      };

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.reference,
                  style:
                      AppTextStyles.labelSm.copyWith(color: fg),
                ),
                Text(
                  _fmtDate(order.createdAt),
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
              ],
            ),
          ),
          StatusBadge.custom(
            label: l10n.statusLabel(order.status),
            color: _statusColor,
            bgColor: _statusBg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppFormatters.currency(order.total),
            style: AppTextStyles.numeric
                .copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Customer Form Dialog ──────────────────────────────────────────────────────

class _CustomerFormDialog extends StatefulWidget {
  final CustomerEntity? editing;
  final AppLocalizations l10n;
  final Future<bool> Function(CustomerFormData) onSave;

  const _CustomerFormDialog({
    this.editing,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _notesCtrl;
  late bool _isActive;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _phoneCtrl = TextEditingController(text: e?.phone ?? '');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = widget.l10n.t('nameRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final data = CustomerFormData(
      name: _nameCtrl.text.trim(),
      phone:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email:
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isActive: _isActive,
    );
    final ok = await widget.onSave(data);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _error = widget.l10n.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isEditing = widget.editing != null;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(
                    isEditing
                        ? l10n.t('editCustomer')
                        : l10n.t('newCustomer'),
                    style: AppTextStyles.h5,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.border),

            // Fields
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
              child: Column(
                children: [
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: AppRadius.brSm,
                        border: Border.all(
                            color: AppColors.destructive.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 14, color: AppColors.destructive),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppTextStyles.bodySm
                                  .copyWith(color: AppColors.destructive),
                            ),
                          ),
                        ],
                      ),
                    ),
                  AppTextField(
                    label: '${l10n.t("labelName")} *',
                    hint: l10n.t('namePlaceholder'),
                    controller: _nameCtrl,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: l10n.t('labelPhone'),
                          hint: '+966 5x xxx xxxx',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AppTextField(
                          label: l10n.t('labelEmail'),
                          hint: 'email@example.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.t('labelNotes'),
                    hint: l10n.t('notesPlaceholder'),
                    controller: _notesCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.t('isActive'),
                                style: AppTextStyles.labelMd),
                            Text(
                              l10n.t('isActiveHint'),
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: AppColors.mutedForeground),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: isEditing
                        ? l10n.saveChanges
                        : l10n.t('createCustomer'),
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
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
