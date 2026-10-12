import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../../theme/app_durations.dart';

class AppSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double? width;

  const AppSearchField({
    super.key,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.controller,
    this.focusNode,
    this.width,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late final TextEditingController _ctrl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    _ctrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _ctrl.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    widget.onChanged?.call(_ctrl.text);
  }

  void _clear() {
    _ctrl.clear();
    widget.onClear?.call();
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Widget field = TextField(
      controller: _ctrl,
      focusNode: widget.focusNode,
      style: AppTextStyles.bodySm.copyWith(
        color: isDark ? AppColors.darkForeground : AppColors.foreground,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.bodySm.copyWith(
          color: isDark
              ? AppColors.darkSubtleForeground
              : AppColors.subtleForeground,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: AppSizes.iconMd,
          color: isDark
              ? AppColors.darkMutedForeground
              : AppColors.mutedForeground,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        suffixIcon: AnimatedSwitcher(
          duration: AppDurations.fast,
          child: _hasText
              ? GestureDetector(
                  onTap: _clear,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: AppSizes.iconSm,
                        color: isDark
                            ? AppColors.darkMutedForeground
                            : AppColors.mutedForeground,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 32),
        filled: true,
        fillColor: isDark ? AppColors.darkMuted : AppColors.muted,
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        isDense: true,
      ),
    );

    if (widget.width != null) {
      return SizedBox(width: widget.width, child: field);
    }
    return field;
  }
}
