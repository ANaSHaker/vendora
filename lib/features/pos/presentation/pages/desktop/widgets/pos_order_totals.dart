import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../presentation/cubit/cart_state.dart';

class PosOrderTotals extends StatelessWidget {
  final CartState cart;
  final VoidCallback onAddDiscount;
  final VoidCallback onClearDiscount;

  const PosOrderTotals({
    super.key,
    required this.cart,
    required this.onAddDiscount,
    required this.onClearDiscount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        _TotalRow(
          label: l10n.subtotal,
          value: AppFormatters.currency(cart.subtotal),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (cart.discount != null) ...[
          _TotalRow(
            label: _discountLabel(cart.discount!, l10n),
            value: '-${AppFormatters.currency(cart.discountAmount)}',
            valueColor: AppColors.success,
            action: GestureDetector(
              onTap: onClearDiscount,
              child: Text(
                l10n.remove,
                style: AppTextStyles.bodyXs.copyWith(
                  color: AppColors.destructive,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ] else ...[
          GestureDetector(
            onTap: onAddDiscount,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.4),
                  ),
                  borderRadius: AppRadius.brMd,
                  color: cs.primary.withValues(alpha: 0.06),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.discount_outlined,
                        size: 12, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      l10n.addDiscount,
                      style: AppTextStyles.labelXs.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        _TotalRow(
          label: l10n.taxWithRate,
          value: AppFormatters.currency(cart.taxAmount),
          labelColor: AppColors.mutedForeground,
        ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.sm),
        _TotalRow(
          label: l10n.total,
          value: AppFormatters.currency(cart.total),
          isTotal: true,
        ),
      ],
    );
  }

  String _discountLabel(CartDiscount discount, AppLocalizations l10n) {
    return discount.type == DiscountType.percent
        ? '${l10n.discount} (${AppFormatters.percent(discount.value)})'
        : l10n.discountFlat;
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  final bool isTotal;
  final Widget? action;

  const _TotalRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.isTotal = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = isTotal
        ? AppTextStyles.labelLg.copyWith(color: AppColors.foreground)
        : AppTextStyles.bodySm.copyWith(
            color: labelColor ?? AppColors.foreground,
          );
    final valueStyle = isTotal
        ? AppTextStyles.numericXl.copyWith(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.numeric.copyWith(
            color: valueColor ?? AppColors.foreground,
          );
    return Row(
      children: [
        Text(label, style: labelStyle),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.xs),
          action!,
        ],
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}
