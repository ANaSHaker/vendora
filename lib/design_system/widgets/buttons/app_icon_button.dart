import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../../theme/app_durations.dart';
import 'app_button.dart';

class AppIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final String? tooltip;
  final bool isLoading;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.outline,
    this.size = AppButtonSize.md,
    this.tooltip,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onPressed == null || isLoading;

    final boxSize = switch (size) {
      AppButtonSize.sm => AppSizes.buttonHeightSm,
      AppButtonSize.md => AppSizes.buttonHeightMd,
      AppButtonSize.lg => AppSizes.buttonHeightLg,
    };

    final iconSize = switch (size) {
      AppButtonSize.sm => AppSizes.iconSm,
      AppButtonSize.md => AppSizes.iconMd,
      AppButtonSize.lg => AppSizes.iconLg,
    };

    final bg = switch (variant) {
      AppButtonVariant.primary     => AppColors.primary,
      AppButtonVariant.secondary   =>
        isDark ? AppColors.darkMuted : AppColors.muted,
      AppButtonVariant.destructive => AppColors.destructive,
      AppButtonVariant.outline     => AppColors.transparent,
      AppButtonVariant.ghost       => AppColors.transparent,
    };

    final fg = switch (variant) {
      AppButtonVariant.primary     => AppColors.white,
      AppButtonVariant.secondary   =>
        isDark ? AppColors.darkForeground : AppColors.foreground,
      AppButtonVariant.destructive => AppColors.white,
      AppButtonVariant.outline     =>
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
      AppButtonVariant.ghost       =>
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
    };

    final borderColor = variant == AppButtonVariant.outline
        ? (isDark ? AppColors.darkBorder : AppColors.border)
        : null;

    Widget child = AnimatedContainer(
      duration: AppDurations.fast,
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: fg),
              )
            : IconTheme(
                data: IconThemeData(size: iconSize, color: fg),
                child: icon,
              ),
      ),
    );

    child = GestureDetector(
      onTap: disabled ? null : onPressed,
      child: MouseRegion(
        cursor: disabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        child: Opacity(
          opacity: disabled && !isLoading ? 0.5 : 1.0,
          child: child,
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}
