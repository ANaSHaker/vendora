import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../design_system/theme/app_border_radius.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_durations.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_text_styles.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/cubit/auth_state.dart';
import '../nav_items.dart';
import 'desktop_sidebar_cubit.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DesktopSidebarCubit, bool>(
      builder: (context, collapsed) => _SidebarContent(collapsed: collapsed),
    );
  }
}

// ─── Content ─────────────────────────────────────────────────────────────────

class _SidebarContent extends StatelessWidget {
  final bool collapsed;
  const _SidebarContent({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSidebarBg : AppColors.sidebarBg;
    final borderColor = isDark ? AppColors.darkSidebarBorder : AppColors.sidebarBorder;
    final width = collapsed ? AppSizes.sidebarCollapsedWidth : AppSizes.sidebarWidth;

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: Curves.easeInOut,
      width: width,
      decoration: BoxDecoration(
        color: bg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          _SidebarHeader(isDark: isDark, borderColor: borderColor, collapsed: collapsed),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.md,
              ),
              child: _SidebarNav(collapsed: collapsed, isDark: isDark),
            ),
          ),
          _SidebarFooter(isDark: isDark, borderColor: borderColor, collapsed: collapsed),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final bool collapsed;

  const _SidebarHeader({
    required this.isDark,
    required this.borderColor,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Container(
        height: AppSizes.topbarHeight,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor)),
        ),
        child: Center(child: _CollapseButton(isDark: isDark, collapsed: collapsed)),
      );
    }

    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;

    return Container(
      height: AppSizes.topbarHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
          Expanded(
            child: Text(
              'Vendora',
              style: AppTextStyles.labelMd.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          _CollapseButton(isDark: isDark, collapsed: collapsed),
        ],
      ),
    );
  }
}

class _CollapseButton extends StatelessWidget {
  final bool isDark;
  final bool collapsed;

  const _CollapseButton({required this.isDark, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return InkWell(
      onTap: () => context.read<DesktopSidebarCubit>().toggle(),
      borderRadius: AppRadius.brSm,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(
          collapsed
              ? Icons.keyboard_double_arrow_right_rounded
              : Icons.keyboard_double_arrow_left_rounded,
          size: AppSizes.iconMd,
          color: muted,
        ),
      ),
    );
  }
}

// ─── Navigation ──────────────────────────────────────────────────────────────

class _SidebarNav extends StatelessWidget {
  final bool collapsed;
  final bool isDark;

  const _SidebarNav({required this.collapsed, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kAppNavSections.asMap().entries.map((entry) {
        return _NavSectionWidget(
          section: entry.value,
          currentPath: currentPath,
          collapsed: collapsed,
          isDark: isDark,
          addTopPadding: entry.key > 0,
        );
      }).toList(),
    );
  }
}

class _NavSectionWidget extends StatelessWidget {
  final NavSection section;
  final String currentPath;
  final bool collapsed;
  final bool isDark;
  final bool addTopPadding;

  const _NavSectionWidget({
    required this.section,
    required this.currentPath,
    required this.collapsed,
    required this.isDark,
    required this.addTopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final dividerColor = isDark ? AppColors.darkSidebarBorder : AppColors.sidebarBorder;

    return Padding(
      padding: EdgeInsets.only(top: addTopPadding ? AppSpacing.base : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (section.title != null) ...[
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.px10,
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
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Divider(color: dividerColor, height: 1),
              ),
          ],
          ...section.items.asMap().entries.map((e) {
            final isLast = e.key == section.items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.px2),
              child: _NavItemWidget(
                item: e.value,
                currentPath: currentPath,
                collapsed: collapsed,
                isDark: isDark,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final String currentPath;
  final bool collapsed;
  final bool isDark;

  const _NavItemWidget({
    required this.item,
    required this.currentPath,
    required this.collapsed,
    required this.isDark,
  });

  bool get _isActive {
    if (item.exactPath) return currentPath == item.path;
    return currentPath == item.path ||
        currentPath.startsWith('${item.path}/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final localizedLabel = l10n.t(item.l10nKey);
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

    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? AppSpacing.sm : AppSpacing.px10,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(item.icon, size: AppSizes.iconMd, color: fg),
          if (!collapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                localizedLabel,
                style: AppTextStyles.labelSm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: collapsed ? localizedLabel : '',
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 600),
      child: Material(
        color: isActive ? cs.primary : Colors.transparent,
        borderRadius: AppRadius.brMd,
        child: InkWell(
          onTap: () => context.goNamed(item.routeName),
          borderRadius: AppRadius.brMd,
          hoverColor: hoverColor,
          child: content,
        ),
      ),
    );
  }
}

// ─── Footer ──────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final bool collapsed;

  const _SidebarFooter({
    required this.isDark,
    required this.borderColor,
    required this.collapsed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthAuthenticated ? authState.user : null;
        final initial = user?.initials ?? 'U';
        final name = user?.name ?? '';

        if (collapsed) {
          return Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(child: _UserAvatar(initial: initial)),
          );
        }

        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted = isDark
            ? AppColors.darkMutedForeground
            : AppColors.mutedForeground;

        return Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: borderColor)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _UserAvatar(initial: initial),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.labelSm.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => context.read<AuthCubit>().logout(),
                        child: Text(
                          AppLocalizations.of(context).signOut,
                          style: AppTextStyles.caption.copyWith(color: muted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String initial;
  const _UserAvatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
