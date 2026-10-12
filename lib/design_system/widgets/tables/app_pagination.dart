import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_border_radius.dart';
import '../../../core/api/api_response.dart';
import '../../../core/l10n/app_localizations.dart';

class AppPagination extends StatelessWidget {
  final PaginationMeta meta;
  final ValueChanged<int> onPageChanged;

  const AppPagination({
    super.key,
    required this.meta,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final start = ((meta.currentPage - 1) * meta.perPage) + 1;
    final end = (meta.currentPage * meta.perPage).clamp(0, meta.total);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppLocalizations.of(context).showingPagination(start, end, meta.total),
          style: AppTextStyles.labelSm.copyWith(color: muted),
        ),
        Row(
          children: [
            _PageButton(
              icon: Icons.chevron_left_rounded,
              enabled: meta.currentPage > 1,
              isDark: isDark,
              borderColor: borderColor,
              onTap: () => onPageChanged(meta.currentPage - 1),
            ),
            const SizedBox(width: AppSpacing.xs),
            ..._buildPageNumbers(isDark, borderColor),
            const SizedBox(width: AppSpacing.xs),
            _PageButton(
              icon: Icons.chevron_right_rounded,
              enabled: meta.hasMore,
              isDark: isDark,
              borderColor: borderColor,
              onTap: () => onPageChanged(meta.currentPage + 1),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPageNumbers(bool isDark, Color borderColor) {
    final pages = <int>[];
    final current = meta.currentPage;
    final last = meta.lastPage;

    if (last <= 7) {
      pages.addAll(List.generate(last, (i) => i + 1));
    } else {
      pages.add(1);
      if (current > 3) pages.add(-1);
      for (var i = (current - 1).clamp(2, last - 1);
          i <= (current + 1).clamp(2, last - 1);
          i++) {
        pages.add(i);
      }
      if (current < last - 2) pages.add(-1);
      pages.add(last);
    }

    return pages.map((p) {
      if (p == -1) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Text('…'),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: _PageNumber(
          number: p,
          isActive: p == meta.currentPage,
          isDark: isDark,
          borderColor: borderColor,
          onTap: () {},
        ),
      );
    }).toList();
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: Container(
            width: AppSizes.buttonHeightSm,
            height: AppSizes.buttonHeightSm,
            decoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, size: AppSizes.iconMd, color: fg),
          ),
        ),
      ),
    );
  }
}

class _PageNumber extends StatelessWidget {
  final int number;
  final bool isActive;
  final bool isDark;
  final Color borderColor;
  final VoidCallback onTap;

  const _PageNumber({
    required this.number,
    required this.isActive,
    required this.isDark,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? AppColors.primary : AppColors.transparent;
    final fg = isActive
        ? AppColors.white
        : (isDark ? AppColors.darkForeground : AppColors.foreground);
    final border = isActive ? AppColors.primary : borderColor;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: AppSizes.buttonHeightSm,
          height: AppSizes.buttonHeightSm,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.labelSm.copyWith(color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
