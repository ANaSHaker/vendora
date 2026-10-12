import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../buttons/app_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final double? width;
  final bool showDividers;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.width,
    this.showDividers = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
    double? width,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => AppDialog(
        title: title,
        subtitle: subtitle,
        actions: actions,
        width: width,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width ?? 520,
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: AppRadius.brXl,
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.base,
                AppSpacing.base,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.h5.copyWith(color: fg),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySm.copyWith(color: muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _CloseButton(isDark: isDark, borderColor: borderColor),
                ],
              ),
            ),

            if (showDividers) Divider(color: borderColor, height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: child,
              ),
            ),

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              if (showDividers) Divider(color: borderColor, height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: EdgeInsets.only(
                            left: e.key > 0 ? AppSpacing.sm : 0,
                          ),
                          child: e.value,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final bool isDark;
  final Color borderColor;

  const _CloseButton({required this.isDark, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: borderColor),
          ),
          child: Icon(Icons.close_rounded, size: AppSizes.iconMd, color: muted),
        ),
      ),
    );
  }
}

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.isDestructive = false,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool isDestructive = false,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDestructive: isDestructive,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    final l10n = AppLocalizations.of(context);
    return AppDialog(
      title: title,
      actions: [
        AppButton.outline(
          label: l10n.cancel,
          onPressed: () => Navigator.of(context).pop(false),
          size: AppButtonSize.sm,
        ),
        AppButton(
          label: confirmLabel,
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          variant: isDestructive
              ? AppButtonVariant.destructive
              : AppButtonVariant.primary,
          size: AppButtonSize.sm,
        ),
      ],
      child: Text(
        message,
        style: AppTextStyles.bodySm.copyWith(color: muted),
      ),
    );
  }
}
