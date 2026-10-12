import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../domain/entities/public_booking_entities.dart';

class BookingTimeSlotGrid extends StatelessWidget {
  final List<BookingSlotEntity> slots;
  final String selected;
  final void Function(String time) onSelect;
  final bool loading;
  final Color primaryColor;

  const BookingTimeSlotGrid({
    super.key,
    required this.slots,
    required this.selected,
    required this.onSelect,
    required this.loading,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n   = AppLocalizations.of(context);
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;

    if (loading) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkMuted : AppColors.muted,
            borderRadius: AppRadius.brLg,
          ),
        ),
      );
    }

    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        decoration: BoxDecoration(
          color: bg, borderRadius: AppRadius.brXl, border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Icon(Icons.access_time_rounded, size: 36, color: muted.withValues(alpha:0.5)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.t('pbNoSlots'), style: AppTextStyles.bodySm.copyWith(color: muted)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.t('pbNoSlotsHint'), style: AppTextStyles.labelSm.copyWith(color: muted.withValues(alpha:0.7))),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4,
      ),
      itemCount: slots.length,
      itemBuilder: (_, i) {
        final slot       = slots[i];
        final isSelected = selected == slot.time;
        final available  = slot.available;

        Color bgColor;
        Color textColor;
        Color borderColor;

        if (isSelected) {
          bgColor     = primaryColor;
          textColor   = Colors.white;
          borderColor = primaryColor;
        } else if (available) {
          bgColor     = bg;
          textColor   = fg;
          borderColor = border;
        } else {
          bgColor     = isDark ? AppColors.darkMuted : AppColors.muted;
          textColor   = muted.withValues(alpha:0.4);
          borderColor = border.withValues(alpha:0.3);
        }

        return GestureDetector(
          onTap: available ? () => onSelect(slot.time) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.brLg,
              border: Border.all(color: borderColor),
              boxShadow: isSelected
                  ? [BoxShadow(color: primaryColor.withValues(alpha:0.3), blurRadius: 8, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slot.timeFormatted,
                  style: AppTextStyles.bodySm.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    decoration: available ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (!available)
                  Text(
                    l10n.t('pbSlotFull'),
                    style: AppTextStyles.labelSm.copyWith(color: textColor, fontSize: 9),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
