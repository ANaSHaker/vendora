import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_border_radius.dart';
import '../../theme/app_spacing.dart';

class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isDestructive;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.destructive : AppColors.primary;

    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: onPressed == null
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              borderRadius: AppRadius.brSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(size: AppSizes.iconSm, color: color),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppTextStyles.labelMd.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
