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
import '../../../domain/entities/supplier_entities.dart';
import '../../../domain/usecases/suppliers_usecases.dart';
import 'supplier_payment_dialog.dart';
import '../../cubit/suppliers_cubit.dart';
import '../../cubit/suppliers_state.dart';

class DesktopSuppliersPage extends StatelessWidget {
  const DesktopSuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SuppliersCubit(
        getSuppliers: getIt<GetSuppliersUseCase>(),
        createSupplier: getIt<CreateSupplierUseCase>(),
        updateSupplier: getIt<UpdateSupplierUseCase>(),
        deleteSupplier: getIt<DeleteSupplierUseCase>(),
      )..load(),
      child: const _SuppliersContent(),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Future<void> _showSupplierForm(
  BuildContext context,
  SuppliersCubit cubit,
  AppLocalizations l10n, {
  SupplierEntity? editing,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _SupplierFormDialog(
        editing: editing,
        l10n: l10n,
        onSave: (data) async {
          final ok = editing != null
              ? await cubit.updateSupplier(editing.id, data)
              : await cubit.createSupplier(data);
          if (ok && context.mounted) {
            AppSnackbar.success(
              context,
              editing != null
                  ? l10n.t('supplier_updated')
                  : l10n.t('supplier_created'),
            );
          }
          return ok;
        },
      ),
    ),
  );
}

Future<void> _showPaymentModal(
  BuildContext context,
  SupplierEntity supplier,
  AppLocalizations l10n,
) =>
    showSupplierPaymentDialog(context, supplier: supplier, l10n: l10n);

Future<void> _confirmDelete(
  BuildContext context,
  SupplierEntity supplier,
  SuppliersCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('delete_supplier_title'),
    message: l10n
        .t('delete_supplier_msg')
        .replaceAll('{name}', supplier.name),
    confirmLabel: l10n.delete,
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteSupplier(supplier.id);
  if (context.mounted) {
    if (ok) {
      AppSnackbar.success(context, l10n.t('supplier_deleted'));
    } else {
      AppSnackbar.error(context, l10n.t('supplier_delete_failed'));
    }
  }
}

// ── Page Content ──────────────────────────────────────────────────────────────

class _SuppliersContent extends StatelessWidget {
  const _SuppliersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        final cubit = context.read<SuppliersCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

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
                          l10n.t('suppliers'),
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        if (state is SuppliersLoaded)
                          Text(
                            '${state.meta.total} ${l10n.t("suppliers_total")}',
                            style:
                                AppTextStyles.bodySm.copyWith(color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    AppButton.primary(
                      label: l10n.t('new_supplier'),
                      size: AppButtonSize.sm,
                      leading: const Icon(Icons.add, size: 16),
                      onPressed: () =>
                          _showSupplierForm(context, cubit, l10n),
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
                    hint: l10n.t('search_suppliers'),
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
                    SuppliersInitial() ||
                    SuppliersLoading() =>
                      const ShimmerTableRows(),
                    SuppliersError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    SuppliersLoaded(:final suppliers)
                        when suppliers.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(Icons.store_outlined, size: 40),
                        message: l10n.t('no_suppliers'),
                        subtitle: l10n.t('add_first_supplier'),
                        action: AppButton.primary(
                          label: l10n.t('new_supplier'),
                          onPressed: () =>
                              _showSupplierForm(context, cubit, l10n),
                        ),
                      ),
                    SuppliersLoaded(:final suppliers, :final meta) =>
                      Column(
                        children: [
                          Expanded(
                            child: _SuppliersTable(
                              suppliers: suppliers,
                              isDark: isDark,
                              l10n: l10n,
                              onEdit: (s) => _showSupplierForm(
                                  context, cubit, l10n,
                                  editing: s),
                              onDelete: (s) => _confirmDelete(
                                  context, s, cubit, l10n),
                              onPayment: (s) =>
                                  _showPaymentModal(context, s, l10n),
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

// ── Suppliers Table ────────────────────────────────────────────────────────────

class _SuppliersTable extends StatelessWidget {
  final List<SupplierEntity> suppliers;
  final bool isDark;
  final AppLocalizations l10n;
  final void Function(SupplierEntity) onEdit;
  final void Function(SupplierEntity) onDelete;
  final void Function(SupplierEntity) onPayment;

  const _SuppliersTable({
    required this.suppliers,
    required this.isDark,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

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
                    child: Text(l10n.t('col_name'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('col_phone'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('col_email'),
                        style: AppTextStyles.tableHeader),
                  ),
                  Expanded(
                    child: Text(l10n.t('col_tax_no'),
                        style: AppTextStyles.tableHeader),
                  ),
                  SizedBox(
                    width: 130,
                    child: Text(
                      l10n.t('col_opening_balance'),
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      l10n.colStatus,
                      style: AppTextStyles.tableHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 104),
                ],
              ),
            ),
            Divider(height: 1, color: border),
            // Rows
            Expanded(
              child: ListView.separated(
                itemCount: suppliers.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (context, i) {
                  final s = suppliers[i];
                  return Container(
                    height: AppSizes.tableRowHeight,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        // Name
                        Expanded(
                          flex: 3,
                          child: Text(
                            s.name,
                            style:
                                AppTextStyles.labelSm.copyWith(color: fg),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Phone
                        Expanded(
                          flex: 2,
                          child: Text(
                            s.phone ?? '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Email
                        Expanded(
                          flex: 2,
                          child: Text(
                            s.email ?? '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Tax No
                        Expanded(
                          child: Text(
                            s.taxNo ?? '—',
                            style: AppTextStyles.tableCell
                                .copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Opening Balance
                        SizedBox(
                          width: 130,
                          child: Text(
                            AppFormatters.currency(s.openingBalance),
                            style:
                                AppTextStyles.numeric.copyWith(color: fg),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        // Status
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: s.isActive
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
                          width: 104,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppIconButton(
                                icon: const Icon(
                                    Icons.payments_outlined, size: 14),
                                onPressed: () => onPayment(s),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.supplierRecordPayment,
                              ),
                              AppIconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 14),
                                onPressed: () => onEdit(s),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.edit,
                              ),
                              AppIconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 14),
                                onPressed: () => onDelete(s),
                                variant: AppButtonVariant.ghost,
                                size: AppButtonSize.sm,
                                tooltip: l10n.delete,
                              ),
                            ],
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

// ── Supplier Form Dialog ──────────────────────────────────────────────────────

class _SupplierFormDialog extends StatefulWidget {
  final SupplierEntity? editing;
  final AppLocalizations l10n;
  final Future<bool> Function(SupplierFormData) onSave;

  const _SupplierFormDialog({
    this.editing,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _taxNoCtrl;
  late final TextEditingController _balanceCtrl;
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
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _taxNoCtrl = TextEditingController(text: e?.taxNo ?? '');
    _balanceCtrl = TextEditingController(
        text: e != null ? e.openingBalance.toString() : '0');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _taxNoCtrl.dispose();
    _balanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = widget.l10n.t('name_required'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final balance =
        double.tryParse(_balanceCtrl.text.trim()) ?? 0.0;
    final data = SupplierFormData(
      name: _nameCtrl.text.trim(),
      phone:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email:
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      taxNo:
          _taxNoCtrl.text.trim().isEmpty ? null : _taxNoCtrl.text.trim(),
      openingBalance: balance,
      isActive: _isActive,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
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
        width: 520,
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
                        ? l10n.t('edit_supplier')
                        : l10n.t('new_supplier'),
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
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        margin:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.muted,
                          borderRadius: AppRadius.brSm,
                          border: Border.all(
                              color: AppColors.destructive
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 14,
                                color: AppColors.destructive),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppTextStyles.bodySm.copyWith(
                                    color: AppColors.destructive),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Name
                    AppTextField(
                      label: '${l10n.t("label_name")} *',
                      hint: l10n.t('supplier_name_placeholder'),
                      controller: _nameCtrl,
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Phone + Email
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: l10n.t('label_phone'),
                            hint: '+966 5x xxx xxxx',
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: l10n.t('label_email'),
                            hint: 'email@example.com',
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Address
                    AppTextField(
                      label: l10n.t('label_address'),
                      hint: l10n.t('address_placeholder'),
                      controller: _addressCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Tax No + Opening Balance
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: l10n.t('label_tax_number'),
                            hint: l10n.t('tax_no_placeholder'),
                            controller: _taxNoCtrl,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppTextField(
                            label: l10n.t('label_opening_balance'),
                            hint: '0.00',
                            controller: _balanceCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Notes
                    AppTextField(
                      label: l10n.t('label_notes'),
                      hint: l10n.t('notes_placeholder'),
                      controller: _notesCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Active toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.t('is_active'),
                                  style: AppTextStyles.labelMd),
                              Text(
                                l10n.t('is_active_hint'),
                                style: AppTextStyles.bodyXs.copyWith(
                                    color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (v) =>
                              setState(() => _isActive = v),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
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
                        : l10n.t('create_supplier'),
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

