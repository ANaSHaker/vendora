import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../domain/entities/public_booking_entities.dart';

class BookingSuccessScreen extends StatefulWidget {
  final ConfirmedBookingEntity confirmed;
  final String vendorName;
  final VoidCallback onBookAnother;
  final Color primaryColor;

  const BookingSuccessScreen({
    super.key,
    required this.confirmed,
    required this.vendorName,
    required this.onBookAnother,
    required this.primaryColor,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.elasticOut));
    _fade  = CurvedAnimation(parent: _ctrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final locale = Localizations.localeOf(context).languageCode;
    final isRtl  = l10n.isAr;
    final primary = widget.primaryColor;
    final c       = widget.confirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        // Success icon
        Center(
          child: ScaleTransition(
            scale: _scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.12),
                  ),
                ),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [AppColors.success.withValues(alpha: 0.25), AppColors.success.withValues(alpha: 0.1)],
                    ),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Icon(Icons.check_rounded, size: 40, color: AppColors.success),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              Text(
                c.autoConfirmed ? l10n.t('pbSuccessConfirmedTitle') : l10n.t('pbSuccessRequestTitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.h4.copyWith(color: fg, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                c.autoConfirmed
                    ? l10n.t('pbSuccessConfirmedBody').replaceAll('{name}', widget.vendorName)
                    : l10n.t('pbSuccessPendingBody').replaceAll('{name}', widget.vendorName),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Reference card
        FadeTransition(
          opacity: _fade,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.brXl,
              border: Border.all(color: border),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary.withValues(alpha: 0.18), primary.withValues(alpha: 0.05)],
                    ),
                    border: Border(bottom: BorderSide(color: border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.t('pbBookingReference'),
                        style: AppTextStyles.labelSm.copyWith(color: muted, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                      const SizedBox(height: AppSpacing.xs),
                      SelectableText(
                        c.reference,
                        style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w900, color: fg,
                          letterSpacing: 3, fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: cardBg,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('EEEE, MMMM d, yyyy', locale)
                            .format(DateTime.parse('${c.reservationDate}T00:00:00')),
                        color: primary, fg: fg,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(icon: Icons.access_time_rounded, label: c.reservationTime, color: primary, fg: fg),
                      const SizedBox(height: AppSpacing.sm),
                      _DetailRow(
                        icon: Icons.people_rounded,
                        label: c.guestsCount == 1
                            ? l10n.t('pbGuestSingleLine').replaceAll('{count}', '${c.guestsCount}')
                            : l10n.t('pbGuestPluralLine').replaceAll('{count}', '${c.guestsCount}'),
                        color: primary, fg: fg,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        FadeTransition(
          opacity: _fade,
          child: Text(l10n.t('pbSuccessHint'),
            textAlign: TextAlign.center,
            style: AppTextStyles.labelSm.copyWith(color: muted)),
        ),
        const SizedBox(height: AppSpacing.xl),

        FadeTransition(
          opacity: _fade,
          child: GestureDetector(
            onTap: widget.onBookAnother,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: AppRadius.brXl,
                boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.t('pbBookAnother'),
                    style: AppTextStyles.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, fg;
  const _DetailRow({required this.icon, required this.label, required this.color, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTextStyles.bodySm.copyWith(color: fg))),
      ],
    );
  }
}
