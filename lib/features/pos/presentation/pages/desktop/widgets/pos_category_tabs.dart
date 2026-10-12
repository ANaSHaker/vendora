import 'package:flutter/material.dart';
import '../../../../../../core/l10n/app_localizations.dart';
import '../../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../../design_system/theme/app_colors.dart';
import '../../../../../../design_system/theme/app_spacing.dart';
import '../../../../../../design_system/theme/app_text_styles.dart';
import '../../../../domain/entities/pos_entities.dart';

class PosCategoryTabs extends StatelessWidget {
  final List<PosCategoryEntity> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  const PosCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Tab(
            label: AppLocalizations.of(context).all,
            isActive: selectedCategoryId == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (c) => _Tab(
              label: c.name,
              isActive: selectedCategoryId == c.id,
              onTap: () => onSelect(c.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          borderRadius: AppRadius.brFull,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: isActive ? AppColors.white : AppColors.foreground,
          ),
        ),
      ),
    );
  }
}
