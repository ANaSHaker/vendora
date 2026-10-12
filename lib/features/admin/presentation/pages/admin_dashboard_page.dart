import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_border_radius.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_text_styles.dart';
import '../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../domain/entities/admin_analytics_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardCubit(
        getAnalytics: getIt<GetAdminAnalyticsUseCase>(),
        getVendors: getIt<GetAdminVendorsUseCase>(),
      )..load(),
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PageHeader(l10n: l10n, isDark: isDark),
                const SizedBox(height: AppSpacing.xl),
                if (state is AdminDashboardLoading)
                  const ShimmerStatCards(count: 4)
                else if (state is AdminDashboardError)
                  AppErrorWidget(
                    message: state.message,
                    onRetry: () =>
                        context.read<AdminDashboardCubit>().load(),
                  )
                else if (state is AdminDashboardLoaded) ...[
                  _AnalyticsGrid(
                    analytics: state.analytics,
                    totalVendors: state.totalVendors,
                    accountActive: state.accountActive,
                    isDark: isDark,
                    borderColor: borderColor,
                    l10n: l10n,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _VendorPanelsRow(
                    analytics: state.analytics,
                    recentVendors: state.recentVendors,
                    isDark: isDark,
                    borderColor: borderColor,
                    l10n: l10n,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final bool isDark;

  const _PageHeader({required this.l10n, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('adminDashboard'),
          style: AppTextStyles.h4.copyWith(color: fg),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.t('adminDashboardSubtitle'),
          style: AppTextStyles.bodySm.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final AdminAnalyticsEntity analytics;
  final int totalVendors;
  final int accountActive;
  final bool isDark;
  final Color borderColor;
  final AppLocalizations l10n;

  const _AnalyticsGrid({
    required this.analytics,
    required this.totalVendors,
    required this.accountActive,
    required this.isDark,
    required this.borderColor,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData(
        icon: Icons.store_rounded,
        label: l10n.t('totalVendors'),
        value: totalVendors.toString(),
        color: AppColors.primary,
      ),
      _StatData(
        icon: Icons.check_circle_rounded,
        label: l10n.t('activeAccounts'),
        value: accountActive.toString(),
        color: AppColors.statusPaid,
      ),
      _StatData(
        icon: Icons.shopping_bag_rounded,
        label: l10n.t('totalOrders'),
        value: analytics.totalOrders.toString(),
        color: AppColors.warning,
      ),
      _StatData(
        icon: Icons.attach_money_rounded,
        label: l10n.t('totalRevenue'),
        value: AppFormatters.currency(analytics.totalRevenue),
        color: AppColors.primary,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
                ? 2
                : 2;
        return GridView.count(
          crossAxisCount: crossCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.2,
          children: cards
              .map((d) => _StatCard(
                    data: d,
                    isDark: isDark,
                    borderColor: borderColor,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  final bool isDark;
  final Color borderColor;

  const _StatCard({
    required this.data,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(data.icon, size: 20, color: data.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.label,
                  style: AppTextStyles.labelSm.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  data.value,
                  style: AppTextStyles.h5.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorPanelsRow extends StatelessWidget {
  final AdminAnalyticsEntity analytics;
  final List<AdminVendorEntity> recentVendors;
  final bool isDark;
  final Color borderColor;
  final AppLocalizations l10n;

  const _VendorPanelsRow({
    required this.analytics,
    required this.recentVendors,
    required this.isDark,
    required this.borderColor,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final topByRevenue = [...analytics.topVendors]
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        final recent = _VendorPanel(
          title: l10n.t('recentVendors'),
          isDark: isDark,
          borderColor: borderColor,
          l10n: l10n,
          actionLabel: l10n.t('viewAll'),
          onAction: () => context.go('/admin/vendors'),
          children: recentVendors.take(5).map(
            (v) => _RecentVendorTile(
              isDark: isDark,
              name: v.name,
              slug: v.slug ?? v.email,
              planName: v.planName,
            ),
          ).toList(),
        );
        final top = _VendorPanel(
          title: l10n.t('topVendorsByRevenue'),
          isDark: isDark,
          borderColor: borderColor,
          l10n: l10n,
          actionLabel: l10n.t('analytics'),
          onAction: () => context.go('/admin/analytics'),
          children: topByRevenue.take(5).toList().asMap().entries.map(
            (e) => _TopVendorTile(
              isDark: isDark,
              rank: e.key + 1,
              name: e.value.name,
              revenue: AppFormatters.currency(e.value.totalRevenue),
              ordersCount: e.value.ordersCount,
              l10n: l10n,
            ),
          ).toList(),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: recent),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: top),
            ],
          );
        }
        return Column(
          children: [
            recent,
            const SizedBox(height: AppSpacing.lg),
            top,
          ],
        );
      },
    );
  }
}

class _VendorPanel extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color borderColor;
  final AppLocalizations l10n;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _VendorPanel({
    required this.title,
    required this.isDark,
    required this.borderColor,
    required this.l10n,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.white;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLg.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null)
                GestureDetector(
                  onTap: onAction,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: AppTextStyles.labelSm.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: cs.primary),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                l10n.t('noVendors'),
                style: AppTextStyles.bodySm.copyWith(color: muted),
              ),
            )
          else
            ...children,
        ],
      ),
    );
  }
}

// Recent vendor tile: name + slug + plan badge
class _RecentVendorTile extends StatelessWidget {
  final bool isDark;
  final String name;
  final String slug;
  final String? planName;

  const _RecentVendorTile({
    required this.isDark,
    required this.name,
    required this.slug,
    this.planName,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMd.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (slug.isNotEmpty)
                  Text(
                    slug,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (planName != null && planName!.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.brSm,
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                planName!,
                style: AppTextStyles.caption.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Top vendor tile: rank badge + name + revenue prominent + orders count
class _TopVendorTile extends StatelessWidget {
  final bool isDark;
  final int rank;
  final String name;
  final String revenue;
  final int ordersCount;
  final AppLocalizations l10n;

  const _TopVendorTile({
    required this.isDark,
    required this.rank,
    required this.name,
    required this.revenue,
    required this.ordersCount,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.brSm,
            ),
            child: Text(
              '#$rank',
              style: AppTextStyles.caption.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.labelMd.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                revenue,
                style: AppTextStyles.numeric.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$ordersCount ${l10n.t('orders')}',
                style: AppTextStyles.caption.copyWith(color: muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
