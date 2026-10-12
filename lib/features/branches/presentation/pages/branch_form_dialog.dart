import 'package:flutter/material.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../design_system/widgets/dialogs/app_dialog.dart';
import '../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/branch_entity.dart';
import '../cubit/branches_cubit.dart';

Future<void> showBranchForm(
  BuildContext context,
  BranchesCubit cubit,
  AppLocalizations l10n, {
  BranchManagementEntity? editing,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BranchFormDialog(
      editing: editing,
      l10n: l10n,
      onSave: (data) async {
        final ok = editing != null
            ? await cubit.updateBranch(editing.id, data)
            : await cubit.createBranch(data);
        if (ok && context.mounted) {
          AppSnackbar.success(
            context,
            editing != null
                ? l10n.t('branchUpdated')
                : l10n.t('branchCreated'),
          );
        }
        return ok;
      },
    ),
  );
}

Future<void> confirmDeleteBranch(
  BuildContext context,
  BranchManagementEntity branch,
  BranchesCubit cubit,
  AppLocalizations l10n,
) async {
  final confirmed = await ConfirmDialog.show(
    context: context,
    title: l10n.t('deleteBranchTitle'),
    message: l10n.t('deleteBranchMsg').replaceAll('{name}', branch.name),
    confirmLabel: l10n.delete,
    isDestructive: true,
    onConfirm: () {},
  );
  if (confirmed != true || !context.mounted) return;
  final ok = await cubit.deleteBranch(branch.id);
  if (context.mounted) {
    ok
        ? AppSnackbar.success(context, l10n.t('branchDeleted'))
        : AppSnackbar.error(context, l10n.t('actionFailed'));
  }
}

// ── Branch Form Dialog ────────────────────────────────────────────────────────

class BranchFormDialog extends StatefulWidget {
  final BranchManagementEntity? editing;
  final AppLocalizations l10n;
  final Future<bool> Function(BranchFormData) onSave;

  const BranchFormDialog({
    super.key,
    this.editing,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<BranchFormDialog> createState() => _BranchFormDialogState();
}

class _BranchFormDialogState extends State<BranchFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late bool _isActive;
  late bool _isDefault;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _addressCtrl = TextEditingController(text: e?.address ?? '');
    _isActive = e?.isActive ?? true;
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.t('nameRequired'));
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final data = BranchFormData(
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      isActive: _isActive,
      isDefault: _isDefault,
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
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.md, 0),
              child: Row(
                children: [
                  Text(
                    isEditing
                        ? l10n.t('editBranch')
                        : l10n.t('addBranch'),
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
            Padding(
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
                  AppTextField(
                    label: '${l10n.t("labelBranchName")} *',
                    hint: l10n.t('branchNamePlaceholder'),
                    controller: _nameCtrl,
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: l10n.t('labelBranchAddress'),
                    hint: l10n.t('branchAddressPlaceholder'),
                    controller: _addressCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FormToggle(
                    label: l10n.t('isActive'),
                    hint: l10n.t('branchActiveHint'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _FormToggle(
                    label: l10n.t('branchDefault'),
                    hint: l10n.t('branchDefaultHint'),
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
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
                        : l10n.t('createBranch'),
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

class _FormToggle extends StatelessWidget {
  final String label;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _FormToggle({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelMd),
              Text(
                hint,
                style: AppTextStyles.bodyXs
                    .copyWith(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ],
    );
  }
}
