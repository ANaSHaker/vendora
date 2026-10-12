import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

// Always uses dark color palette regardless of system theme
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthCubit>().adminLogin(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    const bg = AppColors.darkBackground;
    const cardBg = AppColors.darkSurface;
    const borderColor = AppColors.darkBorder;
    const fg = AppColors.darkForeground;
    const muted = AppColors.darkMutedForeground;
    const inputBg = AppColors.darkBackground;
    const mutedBg = AppColors.darkMuted;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shield icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: mutedBg,
                    borderRadius: AppRadius.brLg,
                    border: Border.all(color: borderColor),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    size: AppSizes.iconXl,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Admin Panel',
                  style: AppTextStyles.h4,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Restricted access. Sign in to continue.',
                  style: AppTextStyles.bodySm,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl2),

                // Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppRadius.brXl2,
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error banner
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          if (state is! AuthError) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.base,
                            ),
                            child: _AdminErrorBanner(message: state.message),
                          );
                        },
                      ),

                      // Email
                      const _AdminFieldLabel(label: 'Email address'),
                      const SizedBox(height: AppSpacing.xs),
                      _AdminTextField(
                        controller: _emailController,
                        hint: 'admin@saas.com',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        inputBg: inputBg,
                        borderColor: borderColor,
                        fg: fg,
                        muted: muted,
                      ),
                      const SizedBox(height: AppSpacing.base),

                      // Password
                      const _AdminFieldLabel(label: 'Password'),
                      const SizedBox(height: AppSpacing.xs),
                      _AdminTextField(
                        controller: _passwordController,
                        hint: '••••••••',
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        inputBg: inputBg,
                        borderColor: borderColor,
                        fg: fg,
                        muted: muted,
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: AppSizes.iconMd,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Submit
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return SizedBox(
                            height: AppSizes.buttonHeightLg,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                disabledBackgroundColor:
                                    AppColors.primary.withValues(alpha: 0.5),
                                elevation: 0,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.brMd,
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign in to Admin',
                                      style: AppTextStyles.buttonMd,
                                    ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),
                const Text(
                  'Vendora Admin — Authorized Access Only',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

class _AdminFieldLabel extends StatelessWidget {
  final String label;

  const _AdminFieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelSm.copyWith(
        color: AppColors.darkMutedForeground,
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;
  final Color inputBg;
  final Color borderColor;
  final Color fg;
  final Color muted;

  const _AdminTextField({
    required this.controller,
    required this.hint,
    required this.inputBg,
    required this.borderColor,
    required this.fg,
    required this.muted,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: AppTextStyles.bodySm.copyWith(color: fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySm.copyWith(color: muted),
        suffixIcon: suffix != null
            ? Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: suffix,
              )
            : null,
        suffixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: AppSizes.inputHeightLg),
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
      ),
    );
  }
}

class _AdminErrorBanner extends StatelessWidget {
  final String message;

  const _AdminErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.12),
        borderRadius: AppRadius.brMd,
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: AppSizes.iconMd,
            color: AppColors.destructive,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
