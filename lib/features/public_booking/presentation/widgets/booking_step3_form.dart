import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';

class BookingStep3Form extends StatelessWidget {
  final String selectedDate;
  final String selectedTime;
  final int guestsCount;
  final bool requireEmail;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String specialRequest;
  final Map<String, String> errors;
  final String? globalError;
  final bool submitting;
  final void Function(String) onNameChange;
  final void Function(String) onPhoneChange;
  final void Function(String) onEmailChange;
  final void Function(String) onRequestChange;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final Color primaryColor;

  const BookingStep3Form({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.guestsCount,
    required this.requireEmail,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.specialRequest,
    required this.errors,
    this.globalError,
    required this.submitting,
    required this.onNameChange,
    required this.onPhoneChange,
    required this.onEmailChange,
    required this.onRequestChange,
    required this.onBack,
    required this.onSubmit,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg     = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted  = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final bg     = isDark ? AppColors.darkBackground : AppColors.background;
    final locale = Localizations.localeOf(context).languageCode;
    final isRtl  = l10n.isAr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.t('pbStep3Title'),
          textAlign: TextAlign.center,
          style: AppTextStyles.h4.copyWith(color: fg, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text(l10n.t('pbStep3Subtitle'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.lg),

        // Summary pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.06),
            borderRadius: AppRadius.brXl,
            border: Border.all(color: border),
          ),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.center,
            children: [
              _SummaryChip(
                icon: Icons.calendar_today_rounded,
                label: DateFormat('EEE, MMM d', locale).format(DateTime.parse('${selectedDate}T00:00:00')),
                color: muted,
              ),
              Text('·', style: TextStyle(color: muted)),
              _SummaryChip(icon: Icons.access_time_rounded, label: selectedTime, color: muted),
              Text('·', style: TextStyle(color: muted)),
              _SummaryChip(
                icon: Icons.people_rounded,
                label: guestsCount == 1
                    ? l10n.t('pbGuestSingleLine')
                    : l10n.t('pbGuestPluralLine').replaceAll('{count}', '$guestsCount'),
                color: muted,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _FormField(
          label: l10n.t('pbFieldName'),
          required: true,
          error: errors['name'] != null ? l10n.t(errors['name']!) : null,
          child: _FieldInput(
            icon: Icons.person_outline_rounded,
            value: customerName,
            onChange: onNameChange,
            placeholder: l10n.t('pbFieldNameHint'),
            hasError: errors.containsKey('name'),
            primaryColor: primaryColor,
            bg: bg, border: border, fg: fg, muted: muted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _FormField(
          label: l10n.t('pbFieldPhone'),
          required: true,
          error: errors['phone'] != null ? l10n.t(errors['phone']!) : null,
          child: _FieldInput(
            icon: Icons.phone_outlined,
            value: customerPhone,
            onChange: onPhoneChange,
            placeholder: l10n.t('pbFieldPhoneHint'),
            inputType: TextInputType.phone,
            hasError: errors.containsKey('phone'),
            primaryColor: primaryColor,
            bg: bg, border: border, fg: fg, muted: muted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _FormField(
          label: l10n.t('pbFieldEmail'),
          required: requireEmail,
          error: errors['email'] != null ? l10n.t(errors['email']!) : null,
          child: _FieldInput(
            icon: Icons.mail_outline_rounded,
            value: customerEmail,
            onChange: onEmailChange,
            placeholder: l10n.t('pbFieldEmailHint'),
            inputType: TextInputType.emailAddress,
            hasError: errors.containsKey('email'),
            primaryColor: primaryColor,
            bg: bg, border: border, fg: fg, muted: muted,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _FormField(
          label: l10n.t('pbFieldRequest'),
          child: _TextAreaInput(
            icon: Icons.chat_bubble_outline_rounded,
            value: specialRequest,
            onChange: onRequestChange,
            placeholder: l10n.t('pbFieldRequestHint'),
            primaryColor: primaryColor,
            bg: bg, border: border, fg: fg, muted: muted,
          ),
        ),

        if (globalError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.destructive.withValues(alpha: 0.08),
              borderRadius: AppRadius.brLg,
              border: Border.all(color: AppColors.destructive.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.destructive),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(globalError!,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.destructive)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _BackBtn(onTap: submitting ? null : onBack, border: border, muted: muted, isRtl: isRtl),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _SubmitBtn(
                label: l10n.t('pbSubmit'),
                loadingLabel: l10n.t('pbSubmitting'),
                loading: submitting,
                onTap: onSubmit,
                primaryColor: primaryColor,
                isRtl: isRtl,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.t('pbFooterHint'),
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSm.copyWith(color: muted)),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SummaryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSm.copyWith(color: color)),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final String? error;
  final Widget child;
  const _FormField({required this.label, this.required = false, this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
              style: AppTextStyles.labelSm.copyWith(color: muted, fontWeight: FontWeight.w700)),
            if (required) ...[
              const SizedBox(width: 2),
              const Text('*', style: TextStyle(color: AppColors.destructive, fontSize: 12)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        child,
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 12, color: AppColors.destructive),
                const SizedBox(width: 4),
                Text(error!, style: AppTextStyles.labelSm.copyWith(color: AppColors.destructive)),
              ],
            ),
          ),
      ],
    );
  }
}

class _FieldInput extends StatelessWidget {
  final IconData icon;
  final String value;
  final void Function(String) onChange;
  final String placeholder;
  final TextInputType inputType;
  final bool hasError;
  final Color primaryColor;
  final Color bg, border, fg, muted;

  const _FieldInput({
    required this.icon, required this.value, required this.onChange,
    required this.placeholder, this.inputType = TextInputType.text,
    required this.hasError, required this.primaryColor,
    required this.bg, required this.border, required this.fg, required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChange,
      keyboardType: inputType,
      style: AppTextStyles.bodySm.copyWith(color: fg),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
        prefixIcon: Icon(icon, size: 18, color: muted),
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        border: OutlineInputBorder(borderRadius: AppRadius.brLg, borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: hasError ? AppColors.destructive : border)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: hasError ? AppColors.destructive : primaryColor, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.brLg, borderSide: const BorderSide(color: AppColors.destructive)),
      ),
    );
  }
}

class _TextAreaInput extends StatelessWidget {
  final IconData icon;
  final String value;
  final void Function(String) onChange;
  final String placeholder;
  final Color primaryColor;
  final Color bg, border, fg, muted;

  const _TextAreaInput({
    required this.icon, required this.value, required this.onChange,
    required this.placeholder, required this.primaryColor,
    required this.bg, required this.border, required this.fg, required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChange,
      maxLines: 3,
      maxLength: 500,
      style: AppTextStyles.bodySm.copyWith(color: fg),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 44),
          child: Icon(icon, size: 18, color: muted),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        filled: true,
        fillColor: bg,
        counterStyle: AppTextStyles.labelSm.copyWith(color: muted),
        border: OutlineInputBorder(borderRadius: AppRadius.brLg, borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brLg, borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brLg, borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback? onTap;
  final Color border, muted;
  final bool isRtl;
  const _BackBtn({required this.onTap, required this.border, required this.muted, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
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
      ),
    );
  }
}

class _SubmitBtn extends StatelessWidget {
  final String label, loadingLabel;
  final bool loading;
  final VoidCallback onTap;
  final Color primaryColor;
  final bool isRtl;

  const _SubmitBtn({
    required this.label, required this.loadingLabel, required this.loading,
    required this.onTap, required this.primaryColor, required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: loading ? primaryColor.withValues(alpha: 0.6) : primaryColor,
          borderRadius: AppRadius.brLg,
          boxShadow: loading ? null : [BoxShadow(color: primaryColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: loading
              ? [
                  const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(loadingLabel, style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                ]
              : [
                  Text(label, style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Icon(isRtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                ],
        ),
      ),
    );
  }
}
