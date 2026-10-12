import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../domain/entities/public_booking_entities.dart';
import 'booking_inline_calendar.dart';
import 'booking_time_slot_grid.dart';

class BookingStep2DateTime extends StatelessWidget {
  final String selectedDate;
  final String selectedTime;
  final List<String> closedDates;
  final List<BookingSlotEntity> slots;
  final bool slotsLoading;
  final int maxFutureDays;
  final Map<String, String> errors;
  final void Function(String date) onDateChange;
  final void Function(String time) onTimeChange;
  final void Function(int year, int month) onMonthChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Color primaryColor;

  const BookingStep2DateTime({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.closedDates,
    required this.slots,
    required this.slotsLoading,
    required this.maxFutureDays,
    required this.errors,
    required this.onDateChange,
    required this.onTimeChange,
    required this.onMonthChanged,
    required this.onBack,
    required this.onNext,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final locale = Localizations.localeOf(context).languageCode;
    final isRtl  = l10n.isAr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.t('pbStep2Title'),
          textAlign: TextAlign.center,
          style: AppTextStyles.h4.copyWith(color: fg, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.t('pbStep2Subtitle'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.lg),

        BookingInlineCalendar(
          selected: selectedDate,
          onSelect: onDateChange,
          closedDates: closedDates,
          maxFutureDays: maxFutureDays,
          primaryColor: primaryColor,
          onMonthChanged: onMonthChanged,
        ),

        if (errors['date'] != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.t(errors['date']!),
              style: AppTextStyles.labelSm.copyWith(color: AppColors.destructive)),
          ),

        if (selectedDate.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 16, color: muted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.t('pbAvailableTimes').replaceAll(
                  '{date}',
                  DateFormat('EEE, MMM d', locale).format(DateTime.parse('${selectedDate}T00:00:00')),
                ),
                style: AppTextStyles.bodySm.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          BookingTimeSlotGrid(
            slots: slots,
            selected: selectedTime,
            onSelect: onTimeChange,
            loading: slotsLoading,
            primaryColor: primaryColor,
          ),
          if (errors['time'] != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(l10n.t(errors['time']!),
                style: AppTextStyles.labelSm.copyWith(color: AppColors.destructive)),
            ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _BackBtn(onTap: onBack, border: border, muted: muted, isRtl: isRtl),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PrimaryBtn(label: l10n.t('pbStep2Continue'), onTap: onNext, primaryColor: primaryColor, isRtl: isRtl),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  final Color border;
  final Color muted;
  final bool isRtl;
  const _BackBtn({required this.onTap, required this.border, required this.muted, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(borderRadius: AppRadius.brLg, border: Border.all(color: border)),
        child: Row(
          children: [
            Icon(isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(AppLocalizations.of(context).t('pbBack'),
              style: AppTextStyles.bodySm.copyWith(color: muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isRtl;
  const _PrimaryBtn({required this.label, required this.onTap, required this.primaryColor, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: AppRadius.brLg,
          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha:0.35), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            Icon(isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
