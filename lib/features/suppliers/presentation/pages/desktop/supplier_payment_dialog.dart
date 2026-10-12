import 'package:flutter/material.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../domain/entities/supplier_entities.dart';
import '../../../domain/usecases/ledger_usecases.dart';

Future<void> showSupplierPaymentDialog(
  BuildContext context, {
  required SupplierEntity supplier,
  required AppLocalizations l10n,
  VoidCallback? onSuccess,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => SupplierPaymentDialog(
      supplier: supplier,
      l10n: l10n,
      onSuccess: onSuccess,
    ),
  );
}

class SupplierPaymentDialog extends StatefulWidget {
  final SupplierEntity supplier;
  final AppLocalizations l10n;
  final VoidCallback? onSuccess;

  const SupplierPaymentDialog({
    super.key,
    required this.supplier,
    required this.l10n,
    this.onSuccess,
  });

  @override
  State<SupplierPaymentDialog> createState() => _SupplierPaymentDialogState();
}

class _SupplierPaymentDialogState extends State<SupplierPaymentDialog> {
  final _amountCtrl    = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _notesCtrl     = TextEditingController();
  final _dateCtrl      = TextEditingController();
  String _method = 'cash';
  bool _submitting = false;
  String? _error;

  static const _methods = ['cash', 'bank', 'card', 'cheque', 'other'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _methodLabel(String m) {
    final l10n = widget.l10n;
    return switch (m) {
      'cash'   => l10n.supplierPaymentMethodCash,
      'bank'   => l10n.supplierPaymentMethodBank,
      'card'   => l10n.supplierPaymentMethodCard,
      'cheque' => l10n.supplierPaymentMethodCheque,
      _        => l10n.supplierPaymentMethodOther,
    };
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = l10n.supplierPaymentAmountRequired);
      return;
    }
    final amount = double.tryParse(raw) ?? 0;
    if (amount <= 0) {
      setState(() => _error = l10n.supplierPaymentAmountInvalid);
      return;
    }
    setState(() { _submitting = true; _error = null; });

    final data = <String, dynamic>{
      'amount': amount,
      'payment_method': _method,
      if (_referenceCtrl.text.trim().isNotEmpty)
        'reference': _referenceCtrl.text.trim(),
      if (_notesCtrl.text.trim().isNotEmpty)
        'notes': _notesCtrl.text.trim(),
      if (_dateCtrl.text.trim().isNotEmpty)
        'paid_at': _dateCtrl.text.trim(),
    };

    final result =
        await getIt<RecordSupplierPaymentUseCase>()(widget.supplier.id, data);
    if (!mounted) return;

    result.fold(
      (f) => setState(() { _submitting = false; _error = f.message; }),
      (_) {
        Navigator.of(context).pop();
        AppSnackbar.success(context, l10n.supplierPaymentSuccess);
        widget.onSuccess?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.supplierPaymentTitle,
                            style: AppTextStyles.h5),
                        Text(
                          widget.supplier.name,
                          style:
                              AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
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
                                size: 14, color: AppColors.destructive),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(_error!,
                                  style: AppTextStyles.bodySm.copyWith(
                                      color: AppColors.destructive)),
                            ),
                          ],
                        ),
                      ),
                    // Amount
                    AppTextField(
                      label: '${l10n.supplierPaymentAmount} *',
                      hint: l10n.t('supplierPaymentAmountHint'),
                      controller: _amountCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Payment Method dropdown
                    DropdownButtonFormField<String>(
                      value: _method.isEmpty ? null : _method,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.supplierPaymentMethod,
                        labelStyle: AppTextStyles.labelMd,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                      items: _methods
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(_methodLabel(m),
                                    style: AppTextStyles.bodySm),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _method = v ?? 'cash'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Reference + Date picker
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: l10n.supplierPaymentReference,
                            hint: l10n.t('supplierPaymentReferenceHint'),
                            controller: _referenceCtrl,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: now,
                                firstDate:
                                    DateTime(now.year - 5),
                                lastDate:
                                    DateTime(now.year + 1),
                              );
                              if (picked != null) {
                                _dateCtrl.text =
                                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                              }
                            },
                            child: AbsorbPointer(
                              child: AppTextField(
                                label: l10n.supplierPaymentDate,
                                hint: 'YYYY-MM-DD',
                                controller: _dateCtrl,
                                suffix: const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Notes
                    AppTextField(
                      label: l10n.supplierPaymentNotes,
                      hint: '',
                      controller: _notesCtrl,
                      maxLines: 2,
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
                    label: l10n.supplierPaymentSubmit,
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
