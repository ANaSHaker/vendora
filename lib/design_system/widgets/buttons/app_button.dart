import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_border_radius.dart';
import '../../theme/app_durations.dart';

enum AppButtonVariant { primary, secondary, destructive, outline, ghost }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.outline;

  const AppButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.leading,
    this.trailing,
    this.isLoading = false,
    this.fullWidth = false,
  }) : variant = AppButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onPressed == null || isLoading;

    final height = switch (size) {
      AppButtonSize.sm => AppSizes.buttonHeightSm,
      AppButtonSize.md => AppSizes.buttonHeightMd,
      AppButtonSize.lg => AppSizes.buttonHeightLg,
    };

    final hPad = switch (size) {
      AppButtonSize.sm => AppSpacing.md,
      AppButtonSize.md => AppSpacing.base,
      AppButtonSize.lg => AppSpacing.xl,
    };

    final textStyle = switch (size) {
      AppButtonSize.sm => AppTextStyles.buttonSm,
      AppButtonSize.md => AppTextStyles.buttonMd,
      AppButtonSize.lg => AppTextStyles.buttonLg,
    };

    final iconSize = switch (size) {
      AppButtonSize.sm => AppSizes.iconSm,
      AppButtonSize.md => AppSizes.iconMd,
      AppButtonSize.lg => AppSizes.iconLg,
    };

    final bg = _bgColor(isDark, disabled);
    final fg = _fgColor(isDark, disabled);
    final border = _borderColor(isDark, disabled);

    Widget child = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: isLoading
          ? SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: fg,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(size: iconSize, color: fg),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.xs + AppSpacing.px2),
                ],
                Text(label, style: textStyle.copyWith(color: fg)),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs + AppSpacing.px2),
                  IconTheme(
                    data: IconThemeData(size: iconSize, color: fg),
                    child: trailing!,
                  ),
                ],
              ],
            ),
    );

    child = AnimatedContainer(
      duration: AppDurations.fast,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brMd,
        border: border != null ? Border.all(color: border) : null,
      ),
      child: Center(child: child),
    );

    if (fullWidth) child = SizedBox(width: double.infinity, child: child);

    return GestureDetector(
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
  }

  Color _bgColor(bool isDark, bool disabled) => switch (variant) {
        AppButtonVariant.primary     => AppColors.primary,
        AppButtonVariant.secondary   =>
          isDark ? AppColors.darkMuted : AppColors.muted,
        AppButtonVariant.destructive => AppColors.destructive,
        AppButtonVariant.outline     => AppColors.transparent,
        AppButtonVariant.ghost       => AppColors.transparent,
      };

  Color _fgColor(bool isDark, bool disabled) => switch (variant) {
        AppButtonVariant.primary     => AppColors.white,
        AppButtonVariant.secondary   =>
          isDark ? AppColors.darkForeground : AppColors.foreground,
        AppButtonVariant.destructive => AppColors.white,
        AppButtonVariant.outline     =>
          isDark ? AppColors.darkForeground : AppColors.foreground,
        AppButtonVariant.ghost       =>
          isDark ? AppColors.darkForeground : AppColors.foreground,
      };

  Color? _borderColor(bool isDark, bool disabled) => switch (variant) {
        AppButtonVariant.outline =>
          isDark ? AppColors.darkBorder : AppColors.border,
        _ => null,
      };
}
