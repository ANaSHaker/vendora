import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.label, this.onTap});
}

class AppBreadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const AppBreadcrumb({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        final item = e.value;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: item.onTap,
              child: MouseRegion(
                cursor: item.onTap != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
                child: Text(
                  item.label,
                  style: AppTextStyles.labelMd.copyWith(
                    color: isLast ? fg : muted,
                    fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                size: AppSizes.iconMd,
                color: muted,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        );
      }).toList(),
    );
  }
}
