import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';

enum SnackbarType { success, error, warning, info }

abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final config = _SnackbarConfig.from(type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        margin: const EdgeInsets.all(AppSpacing.base),
        content: _SnackbarContent(
          message: message,
          config: config,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message);
}

class _SnackbarConfig {
  final Color bg;
  final Color fg;
  final Color border;
  final IconData icon;

  const _SnackbarConfig({
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
  });

  factory _SnackbarConfig.from(SnackbarType type) => switch (type) {
        SnackbarType.success => const _SnackbarConfig(
            bg: AppColors.successLight,
            fg: AppColors.successForeground,
            border: AppColors.success,
            icon: Icons.check_circle_rounded,
          ),
        SnackbarType.error => const _SnackbarConfig(
            bg: AppColors.destructiveLight,
            fg: AppColors.destructive,
            border: AppColors.destructive,
            icon: Icons.error_rounded,
          ),
        SnackbarType.warning => const _SnackbarConfig(
            bg: AppColors.warningLight,
            fg: AppColors.warningForeground,
            border: AppColors.warning,
            icon: Icons.warning_rounded,
          ),
        SnackbarType.info => const _SnackbarConfig(
            bg: AppColors.infoLight,
            fg: AppColors.infoForeground,
            border: AppColors.info,
            icon: Icons.info_rounded,
          ),
      };
}

class _SnackbarContent extends StatelessWidget {
  final String message;
  final _SnackbarConfig config;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SnackbarContent({
    required this.message,
    required this.config,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: config.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(config.icon, size: AppSizes.iconLg, color: config.fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.labelMd.copyWith(color: config.fg),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: AppSpacing.md),
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.labelMd.copyWith(
                  color: config.fg,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(
                Icons.close_rounded,
                size: AppSizes.iconMd,
                color: config.fg.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
