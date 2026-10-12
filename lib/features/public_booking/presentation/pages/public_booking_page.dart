import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../cubit/public_booking_cubit.dart';
import '../cubit/public_booking_state.dart';
import '../widgets/booking_step_progress.dart';
import '../widgets/booking_step1_guests.dart';
import '../widgets/booking_step2_datetime.dart';
import '../widgets/booking_step3_form.dart';
import '../widgets/booking_success_screen.dart';

class PublicBookingPage extends StatelessWidget {
  final String slug;
  const PublicBookingPage({super.key, required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PublicBookingCubit(
        getInfo:       getIt(),
        getClosedDates: getIt(),
        getSlots:      getIt(),
        createBooking: getIt(),
      )..load(slug),
      child: _BookingView(slug: slug),
    );
  }
}

class _BookingView extends StatelessWidget {
  final String slug;
  const _BookingView({required this.slug});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicBookingCubit, PublicBookingState>(
      builder: (context, state) {
        if (state is PublicBookingLoading || state is PublicBookingInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PublicBookingError) {
          return _ErrorScreen(message: state.message);
        }

        if (state is PublicBookingLoaded) {
          final info    = state.vendorInfo;
          final primary = _parseColor(info.primaryColor);

          if (!info.reservationsEnabled) {
            return _UnavailableScreen(name: info.displayName, primaryColor: primary);
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Ambient background
                _AmbientBackground(primaryColor: primary, secondaryColor: _parseColor(info.secondaryColor)),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl3),
                    child: Column(
                      children: [
                        _HeroSection(info: info, primaryColor: primary),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              child: _BookingCard(slug: slug, state: state, primaryColor: primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ── Ambient gradient background ──────────────────────────────────────────────

class _AmbientBackground extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;
  const _AmbientBackground({required this.primaryColor, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseBg = isDark ? AppColors.darkBackground : AppColors.background;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(primaryColor, baseBg, 0.88)!,
            baseBg,
            Color.lerp(secondaryColor, baseBg, 0.90)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final dynamic info;
  final Color primaryColor;
  const _HeroSection({required this.info, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Logo or icon fallback
          if (info.logoUrl != null && (info.logoUrl as String).isNotEmpty)
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                borderRadius: AppRadius.brXl,
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 16, offset: const Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: CachedNetworkImage(
                imageUrl: info.logoUrl as String,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => _FallbackLogo(primaryColor: primaryColor),
              ),
            )
          else
            _FallbackLogo(primaryColor: primaryColor),

          const SizedBox(height: AppSpacing.md),
          Text(l10n.t('pbHeroTitle'),
            style: AppTextStyles.h2.copyWith(color: fg, fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.t('pbHeroAt').replaceAll('{name}', info.displayName as String),
            style: AppTextStyles.bodySm.copyWith(color: muted)),
        ],
      ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  final Color primaryColor;
  const _FallbackLogo({required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        borderRadius: AppRadius.brXl,
        color: primaryColor.withValues(alpha:0.12),
        border: Border.all(color: primaryColor.withValues(alpha:0.3)),
      ),
      child: Icon(Icons.event_seat_rounded, size: 32, color: primaryColor),
    );
  }
}

// ── Main booking card ─────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final String slug;
  final PublicBookingLoaded state;
  final Color primaryColor;

  const _BookingCard({required this.slug, required this.state, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder  : AppColors.border;
    final cubit  = context.read<PublicBookingCubit>();

    return Container(
      decoration: BoxDecoration(
        color: bg.withValues(alpha:0.95),
        borderRadius: AppRadius.brXl3,
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha:0.08), blurRadius: 32, offset: const Offset(0, 8)),
          BoxShadow(color: primaryColor.withValues(alpha:0.04), blurRadius: 60, spreadRadius: 4),
        ],
      ),
      child: Column(
        children: [
          // Step progress (hide on success)
          if (state.step != BookingStep.success)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: BookingStepProgress(current: state.step, primaryColor: primaryColor),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: _stepContent(context, cubit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent(BuildContext ctx, PublicBookingCubit cubit) {
    switch (state.step) {
      case BookingStep.guests:
        return KeyedSubtree(
          key: const ValueKey('step1'),
          child: BookingStep1Guests(
            count: state.guestsCount,
            onChange: cubit.setGuests,
            onNext: () => cubit.goNext(slug),
            primaryColor: primaryColor,
          ),
        );
      case BookingStep.dateTime:
        return KeyedSubtree(
          key: const ValueKey('step2'),
          child: BookingStep2DateTime(
            selectedDate: state.selectedDate,
            selectedTime: state.selectedTime,
            closedDates: state.closedDates,
            slots: state.slots,
            slotsLoading: state.slotsLoading,
            maxFutureDays: state.vendorInfo.maxFutureDays,
            errors: state.fieldErrors,
            onDateChange: (d) => cubit.setDate(slug, d),
            onTimeChange: cubit.setTime,
            onMonthChanged: (y, m) => cubit.loadClosedDatesForMonth(slug, y, m),
            onBack: cubit.goBack,
            onNext: () => cubit.goNext(slug),
            primaryColor: primaryColor,
          ),
        );
      case BookingStep.customerInfo:
        return KeyedSubtree(
          key: const ValueKey('step3'),
          child: BookingStep3Form(
            selectedDate: state.selectedDate,
            selectedTime: state.selectedTime,
            guestsCount: state.guestsCount,
            requireEmail: state.vendorInfo.requireEmail,
            customerName: state.customerName,
            customerPhone: state.customerPhone,
            customerEmail: state.customerEmail,
            specialRequest: state.specialRequest,
            errors: state.fieldErrors,
            globalError: state.globalError,
            submitting: state.submitting,
            onNameChange: cubit.setCustomerName,
            onPhoneChange: cubit.setCustomerPhone,
            onEmailChange: cubit.setCustomerEmail,
            onRequestChange: cubit.setSpecialRequest,
            onBack: cubit.goBack,
            onSubmit: () => cubit.goNext(slug),
            primaryColor: primaryColor,
          ),
        );
      case BookingStep.success:
        return KeyedSubtree(
          key: const ValueKey('success'),
          child: BookingSuccessScreen(
            confirmed: state.confirmed!,
            vendorName: state.vendorInfo.displayName,
            onBookAnother: cubit.resetAll,
            primaryColor: primaryColor,
          ),
        );
    }
  }
}

// ── Unavailable screen ────────────────────────────────────────────────────────

class _UnavailableScreen extends StatelessWidget {
  final String name;
  final Color primaryColor;
  const _UnavailableScreen({required this.name, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final l10n  = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg    = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkMuted : AppColors.muted,
              ),
              child: Icon(Icons.event_busy_rounded, size: 32, color: muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.t('pbUnavailableTitle').replaceAll('{name}', name),
              textAlign: TextAlign.center,
              style: AppTextStyles.h5.copyWith(color: fg, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.t('pbUnavailableBody'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}

// ── Error screen ──────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;
  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off_rounded, size: 48, color: muted.withValues(alpha:0.5)),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.t('pbNotFoundTitle'),
              style: AppTextStyles.h5.copyWith(color: fg, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.t('pbNotFoundBody'),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}
