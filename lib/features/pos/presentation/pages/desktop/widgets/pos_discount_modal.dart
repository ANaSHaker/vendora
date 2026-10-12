import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../../design_system/widgets/inputs/app_text_field.dart';
import '../../../../presentation/cubit/cart_state.dart';

class PosDiscountModal extends StatefulWidget {
  final CartDiscount? current;

  const PosDiscountModal({super.key, this.current});

  static Future<CartDiscount?> show(
    BuildContext context, {
    CartDiscount? current,
  }) {
    return showDialog<CartDiscount>(
      context: context,
      builder: (_) => PosDiscountModal(current: current),
    );
  }

  @override
  State<PosDiscountModal> createState() => _PosDiscountModalState();
}

class _PosDiscountModalState extends State<PosDiscountModal> {
  late DiscountType _type;
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _type = widget.current?.type ?? DiscountType.percent;
    _ctrl = TextEditingController(
      text: widget.current != null
          ? widget.current!.value.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _apply(AppLocalizations l10n) {
    final raw = double.tryParse(_ctrl.text.trim());
    if (raw == null || raw <= 0) {
      setState(() => _error = l10n.enterValidAmount);
      return;
    }
    if (_type == DiscountType.percent && raw > 100) {
      setState(() => _error = l10n.percentCannotExceed100);
      return;
    }
    Navigator.of(context).pop(CartDiscount(type: _type, value: raw));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.orderDiscount, style: AppTextStyles.h5),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _TypeChip(
                      label: l10n.percentLabel,
                      isActive: _type == DiscountType.percent,
                      onTap: () => setState(() {
                        _type = DiscountType.percent;
                        _error = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TypeChip(
                      label: l10n.fixedAmount,
                      isActive: _type == DiscountType.flat,
                      onTap: () => setState(() {
                        _type = DiscountType.flat;
                        _error = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _ctrl,
                label: _type == DiscountType.percent ? l10n.percentLabel : l10n.amountLabel,
                hint: _type == DiscountType.percent ? 'e.g. 10' : 'e.g. 50.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                errorText: _error,
                autofocus: true,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      label: l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton.primary(
                      label: l10n.apply,
                      onPressed: () => _apply(l10n),
                    ),
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

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : surfaceColor,
          border: Border.all(
            color: isActive ? cs.primary : AppColors.border,
          ),
          borderRadius: AppRadius.brSm,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? AppColors.white : AppColors.foreground,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
