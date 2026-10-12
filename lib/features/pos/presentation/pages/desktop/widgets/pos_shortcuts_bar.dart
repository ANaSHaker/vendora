import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';

/// A compact always-visible bar at the bottom of the products panel
/// showing all available keyboard shortcuts.
class PosShortcutsBar extends StatelessWidget {
  const PosShortcutsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkMuted : const Color(0xFFF9FAFB);
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    final shortcuts = [
      ('//', l10n.search),
      ('Enter', l10n.charge),
      ('D', l10n.discount),
      ('Ctrl+Z', l10n.undo),
      ('F1-F5', l10n.categories),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: shortcuts
              .map((s) => _ShortcutChip(keyLabel: s.$1, label: s.$2))
              .toList(),
        ),
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final String keyLabel;
  final String label;

  const _ShortcutChip({required this.keyLabel, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyBg = isDark ? AppColors.darkSurface : Colors.white;
    final keyBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark ? AppColors.darkForeground : AppColors.foreground;
    final mutedColor = isDark
        ? AppColors.darkMutedForeground
        : AppColors.mutedForeground;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: keyBg,
            border: Border.all(color: keyBorder),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            keyLabel,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: textColor,
              fontFamily: AppTextStyles.numeric.fontFamily,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: mutedColor,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
