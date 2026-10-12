import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/theme/app_border_radius.dart';

class AdminLogsPage extends StatelessWidget {
  const AdminLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AdminPlaceholder(
      icon: Icons.history_rounded,
      title: l10n.t('systemLogs'),
      subtitle: l10n.t('logsPageSubtitle'),
    );
  }
}

class AdminSystemSettingsPage extends StatelessWidget {
  const AdminSystemSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _AdminPlaceholder(
      icon: Icons.settings_rounded,
      title: l10n.t('systemSettings'),
      subtitle: l10n.t('settingsPageSubtitle'),
    );
  }
}

class _AdminPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdminPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.h4.copyWith(color: fg)),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle,
                  style: AppTextStyles.bodySm.copyWith(color: muted)),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppRadius.brLg,
                border: Border.all(color: border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.brLg,
                    ),
                    child: Icon(icon,
                        size: 26, color: AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    l10n.t('comingSoon'),
                    style: AppTextStyles.labelLg.copyWith(color: fg),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.t('comingSoonDesc'),
                    style: AppTextStyles.bodySm.copyWith(color: muted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
