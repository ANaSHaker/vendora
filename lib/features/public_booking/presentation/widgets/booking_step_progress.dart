import 'package:flutter/material.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../cubit/public_booking_state.dart';

class BookingStepProgress extends StatelessWidget {
  final BookingStep current;
  final Color primaryColor;

  const BookingStepProgress({
    super.key,
    required this.current,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      BookingStep.guests,
      BookingStep.dateTime,
      BookingStep.customerInfo,
      BookingStep.success,
    ];
    final idx    = steps.indexOf(current).clamp(0, 3);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactive = isDark ? AppColors.darkBorder : AppColors.border;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final done    = i < idx;
        final active  = i == idx;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              width: active ? 26 : 22,
              height: active ? 26 : 22,
              decoration: BoxDecoration(
                color: (done || active) ? primaryColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (done || active) ? primaryColor : inactive,
                  width: active ? 2 : 1.5,
                ),
                boxShadow: active
                    ? [BoxShadow(color: primaryColor.withValues(alpha: 0.28), blurRadius: 8)]
                    : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active
                              ? Colors.white
                              : (isDark
                                  ? AppColors.darkMutedForeground
                                  : AppColors.mutedForeground),
                        ),
                      ),
              ),
            ),
            if (i < 3)
              AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                width: 28,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i < idx ? primaryColor : inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      }),
    );
  }
}
