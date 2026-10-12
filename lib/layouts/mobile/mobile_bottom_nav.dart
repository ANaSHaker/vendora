import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/router/route_names.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_border_radius.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_text_styles.dart';

const _kNavItems = [
  _MobileNavItemData(
    routeName: RouteNames.dashboard,
    path: '/dashboard',
    l10nKey: 'dashboard',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  _MobileNavItemData(
    routeName: RouteNames.orders,
    path: '/orders',
    l10nKey: 'orders',
    icon: Icons.receipt_long_outlined,
    activeIcon: Icons.receipt_long_rounded,
  ),
  _MobileNavItemData(
    routeName: RouteNames.products,
    path: '/products',
    l10nKey: 'products',
    icon: Icons.inventory_2_outlined,
    activeIcon: Icons.inventory_2_rounded,
  ),
  _MobileNavItemData(
    routeName: RouteNames.customers,
    path: '/customers',
    l10nKey: 'customers',
    icon: Icons.people_outline_rounded,
    activeIcon: Icons.people_rounded,
  ),
  _MobileNavItemData(
    routeName: RouteNames.notifications,
    path: '/notifications',
    l10nKey: 'notifications',
    icon: Icons.menu_rounded,
    activeIcon: Icons.menu_rounded,
  ),
];

class _MobileNavItemData {
  final String routeName;
  final String path;
  final String l10nKey;
  final IconData icon;
  final IconData activeIcon;

  const _MobileNavItemData({
    required this.routeName,
    required this.path,
    required this.l10nKey,
    required this.icon,
    required this.activeIcon,
  });
}

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndex(currentPath);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.mobileBottomNavHeight,
          child: Row(
            children: _kNavItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isActive = idx == selectedIndex;
              return Expanded(
                child: _BottomNavItem(
                  item: item,
                  isActive: isActive,
                  isDark: isDark,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  int _selectedIndex(String path) {
    for (var i = 0; i < _kNavItems.length; i++) {
      final item = _kNavItems[i];
      if (path == item.path || path.startsWith('${item.path}/')) return i;
    }
    return 0;
  }
}

class _BottomNavItem extends StatelessWidget {
  final _MobileNavItemData item;
  final bool isActive;
  final bool isDark;

  const _BottomNavItem({
    required this.item,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final activeColor = cs.primary;
    final inactiveColor =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final indicatorColor = cs.primary.withValues(alpha: 0.12);

    return InkWell(
      onTap: () => context.goNamed(item.routeName),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isActive ? indicatorColor : Colors.transparent,
              borderRadius: AppRadius.brFull,
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              size: AppSizes.iconLg,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
          const SizedBox(height: AppSpacing.px2),
          Text(
            l10n.t(item.l10nKey),
            style: AppTextStyles.caption.copyWith(
              color: isActive ? activeColor : inactiveColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
