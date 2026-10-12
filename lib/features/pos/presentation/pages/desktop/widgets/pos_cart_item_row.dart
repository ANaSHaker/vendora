import 'package:flutter/material.dart';
import '../../../../../../core/utils/formatters.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../presentation/cubit/cart_state.dart';

class PosCartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantityChanged;

  const PosCartItemRow({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Remove button
          _SmallIconButton(
            icon: Icons.close,
            color: AppColors.destructive,
            onTap: onRemove,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.sku.isNotEmpty)
                  Text(
                    item.sku,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                if (item.lineDiscount > 0)
                  Text(
                    '-${AppFormatters.currency(item.lineDiscount)} / unit',
                    style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Quantity stepper
          _QuantityStepper(
            quantity: item.quantity,
            onDecrement: () => onQuantityChanged(item.quantity - 1),
            onIncrement: () => onQuantityChanged(item.quantity + 1),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Line total
          SizedBox(
            width: 72,
            child: Text(
              AppFormatters.currency(item.total),
              style: AppTextStyles.numeric.copyWith(
                color: AppColors.foreground,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final double quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallIconButton(
            icon: Icons.remove,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              quantity % 1 == 0
                  ? quantity.toInt().toString()
                  : quantity.toStringAsFixed(1),
              style: AppTextStyles.labelSm,
            ),
          ),
          _SmallIconButton(
            icon: Icons.add,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _SmallIconButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.px4),
        child: Icon(
          icon,
          size: 16,
          color: color ?? AppColors.mutedForeground,
        ),
      ),
    );
  }
}
