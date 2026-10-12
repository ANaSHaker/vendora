import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';

class BookingStep1Guests extends StatelessWidget {
  final int count;
  final void Function(int) onChange;
  final void Function() onNext;
  final Color primaryColor;

  const BookingStep1Guests({
    super.key,
    required this.count,
    required this.onChange,
    required this.onNext,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder  : AppColors.border;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.t('pbStep1Title'),
          textAlign: TextAlign.center,
          style: AppTextStyles.h4.copyWith(color: fg, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.t('pbStep1Subtitle'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.xl),

        // Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleBtn(
              icon: Icons.remove_rounded,
              onTap: count > 1 ? () => onChange(count - 1) : null,
              primaryColor: primaryColor,
              border: border,
              bg: bg,
              fg: fg,
            ),
            const SizedBox(width: AppSpacing.xl),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$count',
                key: ValueKey(count),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            _CircleBtn(
              icon: Icons.add_rounded,
              onTap: count < 50 ? () => onChange(count + 1) : null,
              primaryColor: primaryColor,
              border: border,
              bg: bg,
              fg: fg,
              filled: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          count == 1 ? l10n.t('pbGuestSingle') : l10n.t('pbGuestsLabel'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: muted),
        ),

        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
        const SizedBox(height: AppSpacing.md),

        // Quick presets
        Text(l10n.t('pbQuickSelect'),
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 2.6,
          children: [1, 2, 3, 4, 5, 6, 7, 8].map((n) {
            final isActive = count == n;
            return GestureDetector(
              onTap: () => onChange(n),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isActive ? primaryColor : bg,
                  borderRadius: AppRadius.brLg,
                  border: Border.all(
                    color: isActive ? primaryColor : border,
                  ),
                  boxShadow: isActive
                      ? [BoxShadow(color: primaryColor.withValues(alpha: 0.25), blurRadius: 6)]
                      : null,
                ),
                child: Center(
                  child: Text('$n',
                    style: AppTextStyles.bodySm.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : muted,
                    )),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: AppSpacing.xl),
        _PrimaryBtn(
          label: l10n.t('pbStep1Continue'),
          onTap: onNext,
          primaryColor: primaryColor,
        ),
      ],
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color primaryColor;
  final Color border;
  final Color bg;
  final Color fg;
  final bool filled;

  const _CircleBtn({
    required this.icon, required this.onTap,
    required this.primaryColor, required this.border,
    required this.bg, required this.fg,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44, height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? (disabled ? primaryColor.withValues(alpha: 0.35) : primaryColor) : bg,
          border: Border.all(color: filled ? Colors.transparent : border, width: 1.5),
          boxShadow: filled && !disabled
              ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 10)]
              : null,
        ),
        child: Icon(icon, size: 20,
          color: filled ? Colors.white : (disabled ? fg.withValues(alpha: 0.3) : fg)),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color primaryColor;

  const _PrimaryBtn({required this.label, required this.onTap, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isRtl = AppLocalizations.of(context).isAr;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: AppRadius.brXl,
          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: AppTextStyles.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            const SizedBox(width: AppSpacing.xs),
            Icon(isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
