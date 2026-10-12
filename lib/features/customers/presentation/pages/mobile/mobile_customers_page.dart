import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/customer_entities.dart';
import '../../../domain/usecases/customers_usecases.dart';
import '../../cubit/customers_cubit.dart';
import '../../cubit/customers_state.dart';

class MobileCustomersPage extends StatelessWidget {
  const MobileCustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomersCubit(
        getCustomers: getIt<GetCustomersUseCase>(),
        getCustomerById: getIt<GetCustomerByIdUseCase>(),
        createCustomer: getIt<CreateCustomerUseCase>(),
        updateCustomer: getIt<UpdateCustomerUseCase>(),
        deleteCustomer: getIt<DeleteCustomerUseCase>(),
      )..load(),
      child: const _MobileCustomersContent(),
    );
  }
}

class _MobileCustomersContent extends StatelessWidget {
  const _MobileCustomersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        final cubit = context.read<CustomersCubit>();
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: const Text('Customers', style: AppTextStyles.h6),
            elevation: 0,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, color: AppColors.border),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCustomerForm(context, cubit),
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.person_add_outlined, color: AppColors.white),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSearchField(
                  hint: 'Search customers...',
                  onChanged: cubit.search,
                ),
              ),
              Expanded(
                child: switch (state) {
                  CustomersInitial() || CustomersLoading() => ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: 8,
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ShimmerBox(height: 96),
                      ),
                    ),
                  CustomersError(:final message) => AppErrorWidget(
                      message: message,
                      onRetry: cubit.refresh,
                    ),
                  CustomersLoaded(:final customers) when customers.isEmpty =>
                    AppEmptyState(
                      icon: const Icon(Icons.people_outline, size: 40),
                      message: 'No customers found',
                      action: AppButton.primary(
                        label: 'Add Customer',
                        onPressed: () => _showCustomerForm(context, cubit),
                      ),
                    ),
                  CustomersLoaded(:final customers) => RefreshIndicator(
                      onRefresh: () async => cubit.refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl * 4,
                        ),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, i) => _MobileCustomerCard(
                          customer: customers[i],
                          cubit: cubit,
                        ),
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

class _MobileCustomerCard extends StatelessWidget {
  final CustomerEntity customer;
  final CustomersCubit cubit;

  const _MobileCustomerCard({required this.customer, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCustomerDetail(context, customer, cubit),
      borderRadius: AppRadius.brMd,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: AppRadius.brMd,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _Avatar(name: customer.name, size: 44),
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
                            style: AppTextStyles.labelMd,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        customer.isActive
                            ? StatusBadge.custom(
                                label: 'Active',
                                color: AppColors.successForeground,
                                bgColor: AppColors.successLight,
                              )
                            : StatusBadge.custom(
                                label: 'Inactive',
                                color: AppColors.mutedForeground,
                                bgColor: AppColors.muted,
                              ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (customer.phone != null)
                      Text(
                        customer.phone!,
                        style: AppTextStyles.bodyXs
                            .copyWith(color: AppColors.mutedForeground),
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.shopping_bag_outlined,
                          label: '${customer.ordersCount} orders',
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StatChip(
                          icon: Icons.attach_money,
                          label: AppFormatters.currency(customer.totalSpent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showCustomerForm(context, cubit, customer: customer),
                    color: AppColors.mutedForeground,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => _confirmDelete(context, cubit, customer),
                    color: AppColors.destructive,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedForeground),
        const SizedBox(width: 2),
        Text(
          label,
          style: AppTextStyles.bodyXs.copyWith(color: AppColors.mutedForeground),
        ),
      ],
    );
  }
}

// ─── Customer Detail Sheet ────────────────────────────────────────────────────

void _showCustomerDetail(
  BuildContext context,
  CustomerEntity customer,
  CustomersCubit cubit,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _CustomerDetailSheet(customer: customer),
    ),
  );
}

class _CustomerDetailSheet extends StatefulWidget {
  final CustomerEntity customer;

  const _CustomerDetailSheet({required this.customer});

  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  CustomerEntity? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final cubit = context.read<CustomersCubit>();
    await cubit.selectCustomer(widget.customer.id);
    if (!mounted) return;
    final s = cubit.state;
    if (s is CustomersLoaded && s.selectedDetail != null) {
      setState(() {
        _detail = s.selectedDetail;
        _loading = false;
      });
    } else {
      setState(() {
        _detail = widget.customer;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = _detail ?? widget.customer;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.brSm,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm,
            ),
            child: Row(
              children: [
                _Avatar(name: customer.name, size: 48),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: AppTextStyles.h6),
                      if (customer.email != null)
                        Text(
                          customer.email!,
                          style: AppTextStyles.bodyXs
                              .copyWith(color: AppColors.mutedForeground),
                        ),
                    ],
                  ),
                ),
                customer.isActive
                    ? StatusBadge.custom(
                        label: 'Active',
                        color: AppColors.successForeground,
                        bgColor: AppColors.successLight,
                      )
                    : StatusBadge.custom(
                        label: 'Inactive',
                        color: AppColors.mutedForeground,
                        bgColor: AppColors.muted,
                      ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    context.read<CustomersCubit>().closeDetail();
                    Navigator.pop(context);
                  },
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: controller,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _StatsGrid(customer: customer),
                      if (customer.phone != null || customer.email != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _ContactInfo(customer: customer),
                      ],
                      if (customer.notes != null &&
                          customer.notes!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _NotesCard(notes: customer.notes!),
                      ],
                      if (customer.recentOrders.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _RecentOrdersList(orders: customer.recentOrders),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg +
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.outline(
                    label: 'Edit',
                    onPressed: () {
                      Navigator.pop(context);
                      _showCustomerForm(
                        context,
                        context.read<CustomersCubit>(),
                        customer: customer,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton.primary(
                    label: 'Delete',
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(
                        context,
                        context.read<CustomersCubit>(),
                        customer,
                      );
                    },
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

class _StatsGrid extends StatelessWidget {
  final CustomerEntity customer;

  const _StatsGrid({required this.customer});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: [
        _StatCard(
          label: 'Total Spent',
          value: AppFormatters.currency(customer.totalSpent),
          icon: Icons.attach_money,
        ),
        _StatCard(
          label: 'Orders',
          value: customer.ordersCount.toString(),
          icon: Icons.shopping_bag_outlined,
        ),
        _StatCard(
          label: 'Loyalty Points',
          value: customer.loyaltyPoints.toString(),
          icon: Icons.star_outline,
        ),
        _StatCard(
          label: 'Last Order',
          value: customer.lastOrderDate != null
              ? AppFormatters.dateShort(DateTime.tryParse(customer.lastOrderDate!) ?? DateTime.now())
              : '—',
          icon: Icons.calendar_today_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.labelMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: AppTextStyles.bodyXs
                        .copyWith(color: AppColors.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _ContactInfo extends StatelessWidget {
  final CustomerEntity customer;

  const _ContactInfo({required this.customer});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.sm),
            if (customer.phone != null)
              _ContactRow(
                icon: Icons.phone_outlined,
                label: customer.phone!,
              ),
            if (customer.phone != null && customer.email != null)
              const SizedBox(height: AppSpacing.xs),
            if (customer.email != null)
              _ContactRow(
                icon: Icons.email_outlined,
                label: customer.email!,
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ContactRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.mutedForeground),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: AppTextStyles.bodySm),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.xs),
            Text(notes, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  final List<CustomerOrderEntity> orders;

  const _RecentOrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brMd,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Orders', style: AppTextStyles.labelSm),
            const SizedBox(height: AppSpacing.sm),
            ...orders.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(o.reference, style: AppTextStyles.labelXs),
                          Text(
                            AppFormatters.dateShort(DateTime.tryParse(o.createdAt) ?? DateTime.now()),
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.custom(
                      label: o.status,
                      color: AppColors.mutedForeground,
                      bgColor: AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppFormatters.currency(o.total),
                      style: AppTextStyles.numeric.copyWith(fontSize: 13),
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

// ─── Customer Form ────────────────────────────────────────────────────────────

void _showCustomerForm(
  BuildContext context,
  CustomersCubit cubit, {
  CustomerEntity? customer,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _CustomerFormSheet(customer: customer),
    ),
  );
}

class _CustomerFormSheet extends StatefulWidget {
  final CustomerEntity? customer;

  const _CustomerFormSheet({this.customer});

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameCtrl.text = widget.customer!.name;
      _phoneCtrl.text = widget.customer!.phone ?? '';
      _emailCtrl.text = widget.customer!.email ?? '';
      _notesCtrl.text = widget.customer!.notes ?? '';
      _isActive = widget.customer!.isActive;
    }
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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Name is required');
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });

    final data = CustomerFormData(
      name: name,
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isActive: _isActive,
    );

    final cubit = context.read<CustomersCubit>();
    bool ok;
    if (widget.customer != null) {
      ok = await cubit.updateCustomer(widget.customer!.id, data);
    } else {
      ok = await cubit.createCustomer(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      AppSnackbar.success(
        context,
        widget.customer != null ? 'Customer updated' : 'Customer created',
      );
    } else {
      AppSnackbar.error(context, 'Failed to save customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: AppRadius.brSm,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.sm, AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Customer' : 'Add Customer',
                  style: AppTextStyles.h6,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Full Name *',
                  controller: _nameCtrl,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Phone',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Notes',
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
                          Text('Active', style: AppTextStyles.labelSm),
                          Text(
                            'Customer can be assigned to orders',
                            style: AppTextStyles.bodyXs
                                .copyWith(color: AppColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: _saving
                        ? 'Saving...'
                        : (isEditing ? 'Save Changes' : 'Create Customer'),
                    onPressed: _saving ? null : _submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confirm Delete ───────────────────────────────────────────────────────────

void _confirmDelete(
  BuildContext context,
  CustomersCubit cubit,
  CustomerEntity customer,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: 'Delete Customer',
    message: 'Delete "${customer.name}"? This cannot be undone.',
    confirmLabel: 'Delete',
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteCustomer(customer.id);
  if (context.mounted) {
    if (ok) {
      AppSnackbar.success(context, 'Customer deleted');
    } else {
      AppSnackbar.error(context, 'Failed to delete customer');
    }
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final double size;

  const _Avatar({required this.name, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryMuted,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: AppTextStyles.labelMd.copyWith(color: AppColors.primary),
      ),
    );
  }
}
