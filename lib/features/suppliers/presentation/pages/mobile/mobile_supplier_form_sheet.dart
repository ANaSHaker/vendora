import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/supplier_entities.dart';
import '../../cubit/suppliers_cubit.dart';

Future<void> showMobileSupplierForm(
  BuildContext context,
  SuppliersCubit cubit,
  AppLocalizations l10n, {
  SupplierEntity? editing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _MobileSupplierFormSheet(editing: editing, l10n: l10n),
    ),
  );
}

class _MobileSupplierFormSheet extends StatefulWidget {
  final SupplierEntity? editing;
  final AppLocalizations l10n;

  const _MobileSupplierFormSheet({
    this.editing,
    required this.l10n,
  });

  @override
  State<_MobileSupplierFormSheet> createState() =>
      _MobileSupplierFormSheetState();
}

class _MobileSupplierFormSheetState
    extends State<_MobileSupplierFormSheet> {
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
    final balance = double.tryParse(_balanceCtrl.text.trim()) ?? 0.0;
    final data = SupplierFormData(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      taxNo: _taxNoCtrl.text.trim().isEmpty ? null : _taxNoCtrl.text.trim(),
      openingBalance: balance,
      isActive: _isActive,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final cubit = context.read<SuppliersCubit>();
    final ok = widget.editing != null
        ? await cubit.updateSupplier(widget.editing!.id, data)
        : await cubit.createSupplier(data);

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      AppSnackbar.success(
        context,
        widget.editing != null
            ? widget.l10n.t('supplier_updated')
            : widget.l10n.t('supplier_created'),
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        color: surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    isEditing
                        ? l10n.t('edit_supplier')
                        : l10n.t('new_supplier'),
                    style: AppTextStyles.h6.copyWith(color: fg),
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
            const Divider(height: 1),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.destructiveLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.destructive),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppTextField(
                      label: '${l10n.t("label_name")} *',
                      hint: l10n.t('supplier_name_placeholder'),
                      controller: _nameCtrl,
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.t('label_phone'),
                      hint: '+966 5x xxx xxxx',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.t('label_email'),
                      hint: 'email@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.t('label_address'),
                      hint: l10n.t('address_placeholder'),
                      controller: _addressCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.t('label_tax_number'),
                      hint: l10n.t('tax_no_placeholder'),
                      controller: _taxNoCtrl,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.t('label_opening_balance'),
                      hint: '0.00',
                      controller: _balanceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.t('label_notes'),
                      hint: l10n.t('notes_placeholder'),
                      controller: _notesCtrl,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: Text(l10n.t('is_active'),
                              style: AppTextStyles.labelMd.copyWith(
                                  color: fg)),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (v) =>
                              setState(() => _isActive = v),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outline(
                            label: l10n.cancel,
                            onPressed: () =>
                                Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton.primary(
                            label: isEditing
                                ? l10n.saveChanges
                                : l10n.t('create_supplier'),
                            isLoading: _submitting,
                            onPressed: _submitting ? null : _submit,
                          ),
                        ),
                      ],
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
