import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';

class AppSelectOption<T> {
  final T value;
  final String label;
  final Widget? icon;

  const AppSelectOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

class AppSelectField<T> extends StatelessWidget {
  final String? label;
  final String hint;
  final T? value;
  final List<AppSelectOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final bool enabled;

  const AppSelectField({
    super.key,
    this.label,
    this.hint = 'Select...',
    required this.value,
    required this.options,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fillColor = isDark ? AppColors.darkMuted : AppColors.muted;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkSubtleForeground
        : AppColors.subtleForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMd.copyWith(color: fg),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        DropdownButtonFormField<T>(
          value: value,
          onChanged: enabled ? onChanged : null,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: AppSizes.iconMd,
            color: muted,
          ),
          style: AppTextStyles.bodySm.copyWith(color: fg),
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
            errorText: errorText,
            errorStyle: AppTextStyles.bodyXs.copyWith(
              color: AppColors.destructive,
            ),
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.brMd,
              borderSide: BorderSide(color: AppColors.destructive),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            isDense: true,
          ),
          items: options
              .map(
                (opt) => DropdownMenuItem<T>(
                  value: opt.value,
                  child: Row(
                    children: [
                      if (opt.icon != null) ...[
                        IconTheme(
                          data: IconThemeData(size: AppSizes.iconSm, color: fg),
                          child: opt.icon!,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        opt.label,
                        style: AppTextStyles.bodySm.copyWith(color: fg),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
