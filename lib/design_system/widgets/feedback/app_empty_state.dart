import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class AppEmptyState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final Widget? icon;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.message,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final subtle = isDark
        ? AppColors.darkSubtleForeground
        : AppColors.subtleForeground;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.md)),
          ),
          child: Center(
            child: icon ??
                Icon(
                  Icons.inbox_outlined,
                  size: AppSizes.iconXl,
                  color: subtle,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          message,
          style: AppTextStyles.h6.copyWith(color: fg),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: AppTextStyles.bodySm.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: AppSpacing.base),
          action!,
        ],
      ],
    );
  }
}
