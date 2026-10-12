import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../domain/entities/product_entities.dart';

class CategoryFormDialog extends StatefulWidget {
  final CategoryEntity? editing;
  final List<CategoryEntity> allCategories;
  final Future<bool> Function(CategoryFormData data) onSubmit;

  const CategoryFormDialog({
    super.key,
    this.editing,
    required this.allCategories,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    CategoryEntity? editing,
    required List<CategoryEntity> allCategories,
    required Future<bool> Function(CategoryFormData data) onSubmit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryFormDialog(
        editing: editing,
        allCategories: allCategories,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _sortCtrl;
  String? _parentId;
  bool _isActive = true;
  bool _submitting = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _sortCtrl = TextEditingController(text: '${e?.sortOrder ?? 0}');
    _parentId = e?.parentId;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  // Returns true if [candidate] is a descendant of [ancestorId]
  bool _isDescendant(CategoryEntity candidate, String ancestorId) {
    if (candidate.parentId == null) return false;
    if (candidate.parentId == ancestorId) return true;
    final parent = widget.allCategories.where((c) => c.id == candidate.parentId).firstOrNull;
    return parent != null && _isDescendant(parent, ancestorId);
  }

  List<CategoryEntity> get _parentOptions {
    final editId = widget.editing?.id;
    return widget.allCategories.where((c) {
      if (c.id == editId) return false;                      // exclude self
      if (editId != null && _isDescendant(c, editId)) return false; // exclude descendants
      return true;
    }).toList();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppLocalizations.of(context).categoryName);
      return;
    }
    setState(() {
      _submitting = true;
      _nameError = null;
    });
    final data = CategoryFormData(
      name: name,
      parentId: _parentId,
      sortOrder: int.tryParse(_sortCtrl.text.trim()) ?? 0,
      isActive: _isActive,
    );
    final ok = await widget.onSubmit(data);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _submitting = false;
        _nameError = AppLocalizations.of(context).categoryDeleteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final isEditing = widget.editing != null;

    return Dialog(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SizedBox(
        width: 440,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: AppRadius.brMd,
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? l10n.editCategory : l10n.addCategory,
                          style: AppTextStyles.h5.copyWith(color: fg),
                        ),
                        if (isEditing)
                          Text(
                            widget.editing!.name,
                            style: AppTextStyles.bodyXs.copyWith(color: muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 18, color: muted),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Divider(height: 1, color: border),
              const SizedBox(height: AppSpacing.lg),

              // ── Category Name ─────────────────────────────────────────────
              AppTextField(
                controller: _nameCtrl,
                label: l10n.categoryName,
                hint: l10n.categoryNameHint,
                errorText: _nameError,
                autofocus: true,
                onChanged: (_) => setState(() => _nameError = null),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Parent Category ───────────────────────────────────────────
              AppSelectField<String>(
                label: l10n.parentCategory,
                hint: l10n.noParent,
                value: _parentId,
                options: _parentOptions
                    .map((c) => AppSelectOption(value: c.id, label: c.name))
                    .toList(),
                onChanged: (v) => setState(() => _parentId = v),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Sort Order ────────────────────────────────────────────────
              AppTextField(
                controller: _sortCtrl,
                label: l10n.sortOrder,
                hint: '0',
                helperText: l10n.sortOrderHint,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Active Toggle ─────────────────────────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkMuted : AppColors.muted,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: border),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 2,
                  ),
                  title: Text(
                    l10n.activeLabel,
                    style: AppTextStyles.labelSm.copyWith(color: fg),
                  ),
                  subtitle: Text(
                    l10n.activeHint,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
                  value: _isActive,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              Divider(height: 1, color: border),
              const SizedBox(height: AppSpacing.md),

              // ── Actions ───────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton.outline(
                    label: l10n.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.primary(
                    label: isEditing ? l10n.saveChanges : l10n.createCategory,
                    isLoading: _submitting,
                    onPressed: _submitting ? null : _submit,
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
