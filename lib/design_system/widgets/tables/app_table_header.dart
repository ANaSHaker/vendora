import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../inputs/app_search_field.dart';
import '../buttons/app_button.dart';

class AppTableHeader extends StatelessWidget {
  final String? searchHint;
  final ValueChanged<String>? onSearch;
  final TextEditingController? searchController;
  final List<Widget> actions;
  final List<Widget> filters;
  final Widget? leading;

  const AppTableHeader({
    super.key,
    this.searchHint,
    this.onSearch,
    this.searchController,
    this.actions = const [],
    this.filters = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            if (searchHint != null)
              AppSearchField(
                hint: searchHint!,
                onChanged: onSearch,
                controller: searchController,
                width: 260,
              ),
            const Spacer(),
            ...actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: a,
              ),
            ),
          ],
        ),
        if (filters.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: filters,
          ),
        ],
      ],
    );
  }
}

class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onTap,
      variant: isActive ? AppButtonVariant.primary : AppButtonVariant.outline,
      size: AppButtonSize.sm,
    );
  }
}
