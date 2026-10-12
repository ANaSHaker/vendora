import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/cubit/locale_cubit.dart';
import '../../core/cubit/theme_cubit.dart';
import '../../core/l10n/app_localizations.dart';
import '../../design_system/theme/app_border_radius.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_text_styles.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../../features/settings/presentation/widgets/theme_picker_dialog.dart';

// Re-uses the same language list defined in desktop_topbar; duplicated here
// to avoid cross-layout imports.
class _LangOption {
  final String code;
  final String flag;
  final String Function(AppLocalizations) name;
  const _LangOption(this.code, this.flag, this.name);
}

const List<_LangOption> _kLangs = [
  _LangOption('ar', '🇸🇦', _nameAr),
  _LangOption('en', '🇺🇸', _nameEn),
  _LangOption('fr', '🇫🇷', _nameFr),
  _LangOption('it', '🇮🇹', _nameIt),
  _LangOption('de', '🇩🇪', _nameDe),
];

String _nameAr(AppLocalizations l) => l.arabic;
String _nameEn(AppLocalizations l) => l.english;
String _nameFr(AppLocalizations l) => l.french;
String _nameIt(AppLocalizations l) => l.italian;
String _nameDe(AppLocalizations l) => l.german;

_LangOption _langFor(String code) =>
    _kLangs.firstWhere((l) => l.code == code, orElse: () => _kLangs.first);

// ─── Admin Topbar ─────────────────────────────────────────────────────────────

class AdminTopbar extends StatelessWidget {
  const AdminTopbar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final muted = cs.onSurfaceVariant;
    final l10n = AppLocalizations.of(context);

    return Container(
      height: AppSizes.topbarHeight,
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: AppSizes.iconSm, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.t('adminLabel'),
            style: AppTextStyles.overline.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          _ThemeToggleButton(isDark: isDark, muted: muted),
          const SizedBox(width: AppSpacing.xs),
          _PaletteButton(muted: muted),
          const SizedBox(width: AppSpacing.xs),
          _LanguageSwitcherButton(isDark: isDark, muted: muted, borderColor: borderColor),
          const SizedBox(width: AppSpacing.sm),
          _AdminUserMenu(isDark: isDark),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isDark;
  final Color muted;
  const _ThemeToggleButton({required this.isDark, required this.muted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<ThemeCubit>().toggle(),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: AppSizes.iconMd,
          color: muted,
        ),
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  final Color muted;
  const _PaletteButton({required this.muted});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ThemePickerDialog.show(context),
      borderRadius: AppRadius.brMd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(Icons.palette_outlined, size: AppSizes.iconMd, color: muted),
      ),
    );
  }
}

class _LanguageSwitcherButton extends StatelessWidget {
  final bool isDark;
  final Color muted;
  final Color borderColor;

  const _LanguageSwitcherButton({
    required this.isDark,
    required this.muted,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) {
        final current = _langFor(locale.languageCode);

        return PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: BorderSide(color: borderColor),
          ),
          elevation: 8,
          offset: const Offset(0, 4),
          constraints: const BoxConstraints(minWidth: 200),
          onSelected: (code) =>
              context.read<LocaleCubit>().setLocale(Locale(code)),
          itemBuilder: (ctx) {
            final primary = Theme.of(ctx).colorScheme.primary;
            final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
            return _kLangs.map((lang) {
              final isSelected = locale.languageCode == lang.code;
              return PopupMenuItem<String>(
                value: lang.code,
                child: Row(
                  children: [
                    Text(lang.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        lang.name(l10n),
                        style: AppTextStyles.labelSm.copyWith(
                          color: fg,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded, size: 16, color: primary),
                  ],
                ),
              );
            }).toList();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(current.flag, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  current.code.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: muted),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminUserMenu extends StatelessWidget {
  final bool isDark;
  const _AdminUserMenu({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final name = user?.name ?? '';
        final email = user?.email ?? '';
        final initial = user?.initials ?? 'A';

        return PopupMenuButton<String>(
          position: PopupMenuPosition.under,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: BorderSide(color: borderColor),
          ),
          elevation: 8,
          offset: const Offset(0, 4),
          constraints: const BoxConstraints(minWidth: 224),
          onSelected: (value) {
            if (value == 'signout') context.read<AuthCubit>().adminLogout();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.labelSm.copyWith(
                        color: fg, fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.px2),
                    Text(
                      email,
                      style: AppTextStyles.caption.copyWith(color: muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuDivider(height: 1, color: borderColor),
            PopupMenuItem<String>(
              value: 'signout',
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, size: AppSizes.iconSm, color: AppColors.destructive),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.signOut,
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.destructive),
                  ),
                ],
              ),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AdminAvatar(initial: initial, primary: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  name,
                  style: AppTextStyles.labelSm.copyWith(color: fg, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.keyboard_arrow_down_rounded, size: AppSizes.iconMd, color: muted),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  final String initial;
  final Color primary;
  const _AdminAvatar({required this.initial, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
