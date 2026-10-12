import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../../../core/utils/formatters.dart';

enum DateRangePreset { today, thisWeek, thisMonth, custom }

class AppDateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final DateRangePreset activePreset;
  final ValueChanged<DateRangePreset>? onPresetChanged;
  final Function(DateTime start, DateTime end)? onCustomRange;

  const AppDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    this.activePreset = DateRangePreset.thisMonth,
    this.onPresetChanged,
    this.onCustomRange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PresetChip(
          label: l10n.today,
          isActive: activePreset == DateRangePreset.today,
          isDark: isDark,
          onTap: () => onPresetChanged?.call(DateRangePreset.today),
        ),
        const SizedBox(width: AppSpacing.xs),
        _PresetChip(
          label: l10n.thisWeek,
          isActive: activePreset == DateRangePreset.thisWeek,
          isDark: isDark,
          onTap: () => onPresetChanged?.call(DateRangePreset.thisWeek),
        ),
        const SizedBox(width: AppSpacing.xs),
        _PresetChip(
          label: l10n.thisMonth,
          isActive: activePreset == DateRangePreset.thisMonth,
          isDark: isDark,
          onTap: () => onPresetChanged?.call(DateRangePreset.thisMonth),
        ),
        const SizedBox(width: AppSpacing.xs),
        _CustomRangeButton(
          startDate: startDate,
          endDate: endDate,
          isActive: activePreset == DateRangePreset.custom,
          isDark: isDark,
          onTap: () => _pickCustomRange(context),
        ),
      ],
    );
  }

  Future<void> _pickCustomRange(BuildContext context) async {
    final primary = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: primary,
              ),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      onCustomRange?.call(result.start, result.end);
      onPresetChanged?.call(DateRangePreset.custom);
    }
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isActive
        ? cs.primary
        : (isDark ? AppColors.darkMuted : AppColors.muted);
    final fg = isActive
        ? AppColors.white
        : (isDark ? AppColors.darkForeground : AppColors.foreground);
    final borderColor = isActive
        ? cs.primary
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: AppSizes.inputHeightMd,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: borderColor),
          ),
          child: Center(
            child: Text(label, style: AppTextStyles.labelMd.copyWith(color: fg)),
          ),
        ),
      ),
    );
  }
}

class _CustomRangeButton extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isDark;
  final VoidCallback onTap;

  const _CustomRangeButton({
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final bg = isActive
        ? cs.primary
        : (isDark ? AppColors.darkMuted : AppColors.muted);
    final fg = isActive
        ? AppColors.white
        : (isDark ? AppColors.darkForeground : AppColors.foreground);
    final borderColor = isActive
        ? cs.primary
        : (isDark ? AppColors.darkBorder : AppColors.border);

    final label = isActive && startDate != null && endDate != null
        ? '${AppFormatters.dateShort(startDate!)} – ${AppFormatters.dateShort(endDate!)}'
        : l10n.customRange;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: AppSizes.inputHeightMd,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: AppSizes.iconSm,
                color: fg,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTextStyles.labelMd.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

