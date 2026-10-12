import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../buttons/app_button.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;
  final double? height;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.onRetry,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return SizedBox(
      height: height ?? 200,
      child: ClipRect(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.destructiveLight,
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppSpacing.md)),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: AppSizes.iconXl,
                      color: AppColors.destructive,
                    ),
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
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.base),
                AppButton.outline(
                  label: 'Try Again',
                  onPressed: onRetry,
                  size: AppButtonSize.sm,
                  leading: const Icon(Icons.refresh_rounded),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
