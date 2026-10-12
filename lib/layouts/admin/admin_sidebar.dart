import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../design_system/theme/app_border_radius.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_text_styles.dart';
import '../nav_items.dart';

class AdminSidebar extends StatefulWidget {
  const AdminSidebar({super.key});

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  final _filterController = TextEditingController();
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _filterController.addListener(() {
      setState(() => _filter = _filterController.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  List<NavSection> get _visibleSections {
    if (_filter.isEmpty) return kAdminNavSections;
    return kAdminNavSections
        .map((section) => NavSection(
              title: section.title,
              l10nKey: section.l10nKey,
              items: section.items
                  .where((item) =>
                      item.label.toLowerCase().contains(_filter))
                  .toList(),
            ))
        .where((section) => section.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSidebarBg : AppColors.sidebarBg;
    final borderColor = isDark ? AppColors.darkSidebarBorder : AppColors.sidebarBorder;
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: AppSizes.sidebarWidth,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _AdminSidebarHeader(isDark: isDark, borderColor: borderColor),
          _AdminFilterInput(
            controller: _filterController,
            isDark: isDark,
            borderColor: borderColor,
          ),
          Expanded(
            child: _AdminNavList(
              sections: _visibleSections,
              currentPath: currentPath,
              isDark: isDark,
              filter: _filter,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _AdminSidebarHeader extends StatelessWidget {
  final bool isDark;
  final Color borderColor;

  const _AdminSidebarHeader({
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: AppSizes.topbarHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.brSm,
            ),
            padding: const EdgeInsets.all(2),
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppLocalizations.of(context).adminPanel,
            style: AppTextStyles.labelMd.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Filter input ─────────────────────────────────────────────────────────────

class _AdminFilterInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final Color borderColor;

  const _AdminFilterInput({
    required this.controller,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkBackground : AppColors.background;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.labelSm.copyWith(color: fg),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).filter,
          hintStyle: AppTextStyles.labelSm.copyWith(color: muted),
          prefixIcon: Icon(Icons.search_rounded, size: AppSizes.iconMd, color: muted),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: AppSizes.inputHeightSm,
          ),
          filled: true,
          fillColor: bg,
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
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Nav list ─────────────────────────────────────────────────────────────────

class _AdminNavList extends StatelessWidget {
  final List<NavSection> sections;
  final String currentPath;
  final bool isDark;
  final String filter;

  const _AdminNavList({
    required this.sections,
    required this.currentPath,
    required this.isDark,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    if (sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No matches',
            style: AppTextStyles.bodySm.copyWith(color: muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: sections.asMap().entries.map((entry) {
          return _AdminNavSection(
            section: entry.value,
            currentPath: currentPath,
            isDark: isDark,
            addTopPadding: entry.key > 0,
          );
        }).toList(),
      ),
    );
  }
}

class _AdminNavSection extends StatelessWidget {
  final NavSection section;
  final String currentPath;
  final bool isDark;
  final bool addTopPadding;

  const _AdminNavSection({
    required this.section,
    required this.currentPath,
    required this.isDark,
    required this.addTopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Padding(
      padding: EdgeInsets.only(top: addTopPadding ? AppSpacing.lg : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                bottom: AppSpacing.xs,
              ),
              child: Text(
                (section.l10nKey != null
                    ? l10n.t(section.l10nKey!)
                    : section.title!)
                    .toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ).copyWith(color: muted),
              ),
            ),
          ...section.items.asMap().entries.map((e) {
            final isLast = e.key == section.items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.px2),
              child: _AdminNavItem(
                item: e.value,
                currentPath: currentPath,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AdminNavItem extends StatelessWidget {
  final NavItem item;
  final String currentPath;
  final bool isDark;

  const _AdminNavItem({
    required this.item,
    required this.currentPath,
    required this.isDark,
  });

  bool get _isActive {
    if (item.exactPath) return currentPath == item.path;
    return currentPath == item.path ||
        currentPath.startsWith('${item.path}/');
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive;
    final fg = isActive
        ? AppColors.white
        : isDark
            ? AppColors.darkMutedForeground
            : AppColors.mutedForeground;
    final hoverColor = isActive
        ? AppColors.white.withValues(alpha: 0.1)
        : isDark
            ? AppColors.darkSidebarHoverItem
            : AppColors.sidebarHoverItem;

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Material(
      color: isActive ? cs.primary : Colors.transparent,
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: () => context.goNamed(item.routeName),
        borderRadius: AppRadius.brMd,
        hoverColor: hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(item.icon, size: AppSizes.iconMd, color: fg),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.t(item.l10nKey),
                  style: AppTextStyles.labelSm.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
