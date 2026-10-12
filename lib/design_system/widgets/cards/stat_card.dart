import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final String? trend;
  final bool? isTrendPositive;
  final String? subLabel;
  final Color? iconBgColor;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.isTrendPositive,
    this.subLabel,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMd.copyWith(color: muted),
              ),
              if (icon != null)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBgColor ??
                        (isDark
                            ? AppColors.darkMuted
                            : AppColors.primaryBg),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(
                        size: AppSizes.iconMd,
                        color: iconColor ?? Theme.of(context).colorScheme.primary,
                      ),
                      child: icon!,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.numericXl.copyWith(color: fg)),
          if (trend != null || subLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (trend != null) ...[
                  Icon(
                    isTrendPositive == true
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: AppSizes.iconSm,
                    color: isTrendPositive == true
                        ? AppColors.success
                        : AppColors.destructive,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trend!,
                    style: AppTextStyles.labelSm.copyWith(
                      color: isTrendPositive == true
                          ? AppColors.success
                          : AppColors.destructive,
                    ),
                  ),
                  if (subLabel != null)
                    const SizedBox(width: AppSpacing.xs),
                ],
                if (subLabel != null)
                  Text(
                    subLabel!,
                    style: AppTextStyles.labelSm.copyWith(color: muted),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
