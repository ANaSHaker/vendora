import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/badges/status_badge.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/buttons/app_icon_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/app_snackbar.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../../../../design_system/widgets/inputs/app_search_field.dart';
import '../../../../../design_system/widgets/inputs/app_select_field.dart';
import '../../../../../design_system/widgets/tables/app_pagination.dart';
import '../../../domain/entities/order_entity.dart';
import '../../cubit/orders_cubit.dart';
import '../../cubit/orders_state.dart';
import 'widgets/order_refund_modal.dart';
import 'widgets/order_settings_dialog.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
Color _surfaceOf(bool isDark) =>
    isDark ? AppColors.darkSurface : AppColors.surface;
Color _borderOf(bool isDark) =>
    isDark ? AppColors.darkBorder : AppColors.border;
Color _fgOf(bool isDark) =>
    isDark ? AppColors.darkForeground : AppColors.foreground;
Color _mutedOf(bool isDark) =>
    isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;

class DesktopOrdersPage extends StatelessWidget {
  const DesktopOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrdersCubit(
        getOrders: getIt(),
        getOrderById: getIt(),
        updateStatus: getIt(),
        updateFulfillmentStatus: getIt(),
        refundOrder: getIt(),
        downloadInvoice: getIt(),
        getNetRevenue: getIt(),
      )..load(),
      child: const _OrdersContent(),
    );
  }
}

class _OrdersContent extends StatelessWidget {
  const _OrdersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        final cubit = context.read<OrdersCubit>();
        final filters = switch (state) {
          OrdersLoaded(:final filters) => filters,
          OrdersLoading(:final filters) => filters,
          OrdersError(:final filters) => filters,
          _ => const OrdersFilters(),
        };
        final selectedOrder =
            state is OrdersLoaded ? state.selectedOrder : null;

        return ColoredBox(
          color: AppColors.background,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OrdersHeader(filters: filters, cubit: cubit),
                    if (state case OrdersLoaded(stats: final s?))
                      _OrdersStatsBar(stats: s),
                    _StoreTrackingCard(),
                    _ChannelTabs(filters: filters, cubit: cubit),
                    _OrdersFilterBar(filters: filters, cubit: cubit),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.desktopContentPadding,
                        ),
                        child: _buildBody(context, state, cubit),
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedOrder != null)
                _OrderDetailPanel(
                  order: selectedOrder,
                  isLoading:
                      state is OrdersLoaded && state.isDetailLoading,
                  cubit: cubit,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    OrdersState state,
    OrdersCubit cubit,
  ) {
    return switch (state) {
      OrdersInitial() || OrdersLoading() => const ShimmerTableRows(),
      OrdersError(:final message, :final filters) => AppErrorWidget(
          message: message,
          onRetry: () => cubit.load(filters: filters),
        ),
      OrdersLoaded(:final orders, :final filters)
          when orders.isEmpty =>
        AppEmptyState(
          icon: const Icon(Icons.receipt_long_outlined, size: 40),
          message: filters.hasActiveFilters || filters.channel != null
              ? AppLocalizations.of(context).noOrdersFound
              : AppLocalizations.of(context).noOrdersYet,
          subtitle: !filters.hasActiveFilters && filters.channel == null
              ? AppLocalizations.of(context).ordersWillAppearHere
              : null,
        ),
      OrdersLoaded(:final orders, :final meta) => Column(
          children: [
            Expanded(child: _OrdersTable(orders: orders, cubit: cubit)),
            const SizedBox(height: AppSpacing.md),
            AppPagination(meta: meta, onPageChanged: cubit.goToPage),
            const SizedBox(height: AppSizes.desktopContentPadding),
          ],
        ),
    };
  }
}

// ─── Stats Bar ────────────────────────────────────────────────────────────────

class _OrdersStatsBar extends StatelessWidget {
  final OrdersStats stats;
  const _OrdersStatsBar({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs     = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.desktopContentPadding,
        0,
        AppSizes.desktopContentPadding,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          // Revenue
          _StatCard(
            label:     l10n.netRevenue,
            value:     stats.netRevenue != null
                           ? AppFormatters.currency(stats.netRevenue!)
                           : '—',
            icon:      Icons.trending_up_rounded,
            accentColor: AppColors.success,
            isDark:    isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Total orders
          _StatCard(
            label:     l10n.totalOrders,
            value:     AppFormatters.number(stats.totalOrders.toDouble()),
            icon:      Icons.receipt_long_rounded,
            accentColor: cs.primary,
            isDark:    isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Pending
          _StatCard(
            label:     l10n.statusPending,
            value:     AppFormatters.number(stats.pendingOrders.toDouble()),
            icon:      Icons.hourglass_empty_rounded,
            accentColor: AppColors.statusPending,
            isDark:    isDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Online
          _StatCard(
            label:     l10n.channelOnline,
            value:     AppFormatters.number(stats.onlineOrders.toDouble()),
            icon:      Icons.language_rounded,
            accentColor: AppColors.info,
            isDark:    isDark,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = _surfaceOf(isDark);
    final border  = _borderOf(isDark);
    final fg      = _fgOf(isDark);
    final muted   = _mutedOf(isDark);

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: AppRadius.brLg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colored top accent bar
            Container(height: 3, color: accentColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon pill
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.brMd,
                    ),
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Number + label
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: AppTextStyles.h5.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: AppTextStyles.bodyXs.copyWith(color: muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _OrdersHeader extends StatelessWidget {
  final OrdersFilters filters;
  final OrdersCubit cubit;

  const _OrdersHeader({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<OrdersCubit>().state;
    final total = state is OrdersLoaded ? state.meta.total : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.desktopContentPadding,
        AppSizes.desktopContentPadding,
        AppSizes.desktopContentPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.orders, style: AppTextStyles.h4.copyWith(color: fg)),
              if (total != null)
                Text(
                  '${AppFormatters.number(total.toDouble())} ${l10n.results}',
                  style: AppTextStyles.bodySm.copyWith(color: muted),
                ),
            ],
          ),
          const Spacer(),
          AppButton.outline(
            label: l10n.orderSettings,
            leading: const Icon(Icons.settings_outlined, size: 16),
            onPressed: () => OrderSettingsDialog.show(context),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppDateRangePicker(
            startDate: filters.dateFrom,
            endDate: filters.dateTo,
            activePreset: switch (filters.datePreset) {
              'today'     => DateRangePreset.today,
              'thisWeek'  => DateRangePreset.thisWeek,
              'custom'    => DateRangePreset.custom,
              _           => DateRangePreset.thisMonth,
            },
            onPresetChanged: (preset) {
              if (preset != DateRangePreset.custom) {
                cubit.applyDatePreset(switch (preset) {
                  DateRangePreset.today     => 'today',
                  DateRangePreset.thisWeek  => 'thisWeek',
                  DateRangePreset.thisMonth => 'thisMonth',
                  _                         => 'thisMonth',
                });
              }
            },
            onCustomRange: cubit.setDateRange,
          ),
        ],
      ),
    );
  }
}

// ─── Store Tracking Card ──────────────────────────────────────────────────────

class _StoreTrackingCard extends StatelessWidget {
  const _StoreTrackingCard();

  String _trackingUrl(String slug) {
    if (kIsWeb) return '${Uri.base.origin}/#/track/$slug';
    return '/track/$slug';
  }

  @override
  Widget build(BuildContext context) {
    final slug = getIt<LocalStorage>().trackingSlug;
    if (slug == null || slug.isEmpty) return const SizedBox.shrink();

    final url = _trackingUrl(slug);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.desktopContentPadding,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: AppRadius.brMd,
          color: _surfaceOf(isDark),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trackingLink,
                    style: AppTextStyles.labelXs.copyWith(color: muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    style: AppTextStyles.bodySm.copyWith(
                      color: fg,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Copy
            _TrackingAction(
              icon: Icons.copy_rounded,
              label: l10n.copyLink,
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                AppSnackbar.success(context, l10n.linkCopied);
              },
            ),
            const SizedBox(width: AppSpacing.xs),
            // QR
            _TrackingAction(
              icon: Icons.qr_code_rounded,
              label: 'QR كود',
              onTap: () => _showQr(context, url, isDark, border, fg),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Open
            _TrackingAction(
              icon: Icons.open_in_new_rounded,
              label: l10n.trackingLink,
              color: cs.primary,
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQr(
      BuildContext context, String url, bool isDark, Color border, Color fg) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                url,
                style: TextStyle(
                  fontSize: 11,
                  color: fg,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _TrackingAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = _mutedOf(isDark);
    final c = color ?? muted;

    return Tooltip(
      message: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(fontSize: 9, color: c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Channel Tabs ─────────────────────────────────────────────────────────────

class _ChannelTabs extends StatelessWidget {
  final OrdersFilters filters;
  final OrdersCubit cubit;

  const _ChannelTabs({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = _borderOf(isDark);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.desktopContentPadding,
        0,
        AppSizes.desktopContentPadding,
        0,
      ),
      child: Row(
        children: [
          _ChannelTab(
            label: l10n.allChannels,
            isActive: filters.channel == null,
            onTap: () => cubit.filterByChannel(null),
            isDark: isDark,
          ),
          _ChannelTab(
            label: l10n.channelPos,
            isActive: filters.channel == 'pos',
            onTap: () => cubit.filterByChannel('pos'),
            icon: Icons.point_of_sale_rounded,
            isDark: isDark,
          ),
          _ChannelTab(
            label: l10n.channelOnline,
            isActive: filters.channel == 'online',
            onTap: () => cubit.filterByChannel('online'),
            icon: Icons.language_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ChannelTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isDark;

  const _ChannelTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = _mutedOf(isDark);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? cs.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? cs.primary : muted,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: isActive ? cs.primary : muted,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _OrdersFilterBar extends StatelessWidget {
  final OrdersFilters filters;
  final OrdersCubit cubit;

  const _OrdersFilterBar({required this.filters, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = _borderOf(isDark);
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.desktopContentPadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 300,
                child: AppSearchField(
                  hint: l10n.searchOrders,
                  onChanged: cubit.search,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusFilterRow(
                selected: filters.status,
                onSelect: cubit.filterByStatus,
                l10n: l10n,
                isDark: isDark,
              ),
              const Spacer(),
              if (filters.hasActiveFilters)
                GestureDetector(
                  onTap: () => cubit.load(),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      l10n.reset,
                      style: AppTextStyles.bodySm.copyWith(
                        color: cs.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          _FulfillmentFilterRow(
            selected: filters.fulfillmentStatus,
            onSelect: cubit.filterByFulfillmentStatus,
            l10n: l10n,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final AppLocalizations l10n;
  final bool isDark;

  const _StatusFilterRow({
    required this.selected,
    required this.onSelect,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('paid', l10n.statusPaid),
      ('pending', l10n.statusPending),
      ('refunded', l10n.statusRefunded),
      ('partially_refunded', l10n.statusPartiallyRefunded),
      ('void', l10n.statusVoid),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: statuses.map((s) {
        final isActive = selected == s.$1;
        return _StatusChip(
          label: s.$2,
          isActive: isActive,
          onTap: () => onSelect(isActive ? null : s.$1),
          status: s.$1,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _FulfillmentFilterRow extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;
  final AppLocalizations l10n;
  final bool isDark;

  const _FulfillmentFilterRow({
    required this.selected,
    required this.onSelect,
    required this.l10n,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      ('preparing', l10n.fulfillPreparing),
      ('ready', l10n.fulfillReady),
      ('completed', l10n.fulfillCompleted),
      ('cancelled', l10n.fulfillCancelled),
    ];

    final muted = _mutedOf(isDark);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${l10n.fulfillmentStatus}:',
          style: AppTextStyles.labelXs.copyWith(color: muted),
        ),
        const SizedBox(width: AppSpacing.xs),
        ...statuses.map((s) {
          final isActive = selected == s.$1;
          return _StatusChip(
            label: s.$2,
            isActive: isActive,
            onTap: () => onSelect(isActive ? null : s.$1),
            status: s.$1,
            isDark: isDark,
          );
        }),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final String status;
  final bool isDark;

  const _StatusChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (color, bg) = _statusColors(status);
    final border = _borderOf(isDark);

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? bg : Colors.transparent,
            border: Border.all(color: isActive ? color : border),
            borderRadius: AppRadius.brFull,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelXs.copyWith(
              color: isActive ? color : _mutedOf(isDark),
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String s) => switch (s) {
        'paid' => (AppColors.statusPaid, AppColors.statusPaidBg),
        'refunded' => (AppColors.statusRefunded, AppColors.statusRefundedBg),
        'partially_refunded' =>
          (AppColors.statusPartialRefund, AppColors.statusPartialRefundBg),
        'cancelled' => (AppColors.statusCancelled, AppColors.statusCancelledBg),
        'pending' => (AppColors.statusPending, AppColors.statusPendingBg),
        'preparing' => (AppColors.statusPending, AppColors.statusPendingBg),
        'ready' => (AppColors.statusApproved, AppColors.statusApprovedBg),
        'completed' => (AppColors.statusCompleted, AppColors.statusCompletedBg),
        _ => (AppColors.statusDraft, AppColors.statusDraftBg),
      };
}

// ─── Table ────────────────────────────────────────────────────────────────────

const List<int> _flexes = [2, 2, 2, 2, 2, 2, 1];

class _OrdersTable extends StatelessWidget {
  final List<OrderEntity> orders;
  final OrdersCubit cubit;

  const _OrdersTable({required this.orders, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _surfaceOf(isDark);
    final border = _borderOf(isDark);
    final headerBg = isDark ? AppColors.darkMuted : AppColors.primaryMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border),
        borderRadius: AppRadius.brLg,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.brLg,
        child: Column(
          children: [
            _TableHeader(isDark: isDark, headerBg: headerBg),
            Divider(height: 1, color: border),
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: border),
                itemBuilder: (ctx, i) => _OrderRow(
                  order: orders[i],
                  isDark: isDark,
                  onTap: () => cubit.selectOrder(orders[i].id),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final bool isDark;
  final Color headerBg;

  const _TableHeader({required this.isDark, required this.headerBg});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 44,
      color: headerBg,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: _flexes[0],
            child: Text(l10n.reference, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[1],
            child: Text(l10n.customer, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[2],
            child:
                Text(l10n.dateCreated, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[3],
            child: Text(l10n.orderStatus, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[4],
            child: Text(
                l10n.fulfillmentStatus, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[5],
            child: Text(l10n.paymentMethod, style: AppTextStyles.tableHeader),
          ),
          Expanded(
            flex: _flexes[6],
            child: Text(
              l10n.total,
              style: AppTextStyles.tableHeader,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final VoidCallback onTap;

  const _OrderRow({
    required this.order,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final muted = _mutedOf(isDark);
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final cs = Theme.of(context).colorScheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // Reference + channel badge
              Expanded(
                flex: _flexes[0],
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.reference,
                        style: AppTextStyles.labelSm.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _ChannelBadge(channel: order.channel),
                  ],
                ),
              ),
              // Customer
              Expanded(
                flex: _flexes[1],
                child: Text(
                  order.customerName ?? l10n.noCustomer,
                  style: AppTextStyles.tableCell,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Date
              Expanded(
                flex: _flexes[2],
                child: Text(
                  dateFmt.format(order.createdAt.toLocal()),
                  style: AppTextStyles.tableCell.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Order status
              Expanded(
                flex: _flexes[3],
                child: _StatusBadgeWidget(status: order.status, l10n: l10n),
              ),
              // Fulfillment status
              Expanded(
                flex: _flexes[4],
                child: order.fulfillmentStatus != null
                    ? _FulfillmentBadge(
                        status: order.fulfillmentStatus!, l10n: l10n)
                    : Text('—',
                        style:
                            AppTextStyles.tableCell.copyWith(color: muted)),
              ),
              // Payment method
              Expanded(
                flex: _flexes[5],
                child: Text(
                  _paymentLabel(order.paymentMethod, l10n),
                  style: AppTextStyles.tableCell,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Total
              Expanded(
                flex: _flexes[6],
                child: Text(
                  AppFormatters.currency(order.total),
                  style: AppTextStyles.numeric,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 40,
                child: AppIconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  onPressed: onTap,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _paymentLabel(String method, AppLocalizations l10n) =>
      switch (method) {
        'cash' => l10n.cash,
        'card' => l10n.card,
        'bank_transfer' => l10n.bankTransfer,
        _ => method,
      };
}

class _ChannelBadge extends StatelessWidget {
  final String channel;
  const _ChannelBadge({required this.channel});

  @override
  Widget build(BuildContext context) {
    final isOnline = channel == 'online';
    final color = isOnline ? AppColors.info : AppColors.mutedForeground;
    final bg = isOnline
        ? AppColors.info.withValues(alpha: 0.1)
        : AppColors.muted;
    final icon =
        isOnline ? Icons.language_rounded : Icons.point_of_sale_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 2),
          Text(
            isOnline
                ? AppLocalizations.of(context).channelOnline
                : AppLocalizations.of(context).channelPos,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadgeWidget extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const _StatusBadgeWidget({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'paid' => (AppColors.statusPaid, AppColors.statusPaidBg, l10n.statusPaid),
      'refunded' => (
          AppColors.statusRefunded,
          AppColors.statusRefundedBg,
          l10n.statusRefunded
        ),
      'partially_refunded' => (
          AppColors.statusPartialRefund,
          AppColors.statusPartialRefundBg,
          l10n.statusPartiallyRefunded
        ),
      'void' => (AppColors.statusDraft, AppColors.statusDraftBg, l10n.statusVoid),
      'cancelled' => (
          AppColors.statusCancelled,
          AppColors.statusCancelledBg,
          l10n.statusCancelled
        ),
      'pending' => (
          AppColors.statusPending,
          AppColors.statusPendingBg,
          l10n.statusPending
        ),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg, status),
    };
    return StatusBadge.custom(label: label, color: color, bgColor: bg);
  }
}

class _FulfillmentBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;

  const _FulfillmentBadge({required this.status, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'preparing' => (
          AppColors.statusPending,
          AppColors.statusPendingBg,
          l10n.fulfillPreparing
        ),
      'ready' => (
          AppColors.statusApproved,
          AppColors.statusApprovedBg,
          l10n.fulfillReady
        ),
      'completed' => (
          AppColors.statusCompleted,
          AppColors.statusCompletedBg,
          l10n.fulfillCompleted
        ),
      'cancelled' => (
          AppColors.statusCancelled,
          AppColors.statusCancelledBg,
          l10n.fulfillCancelled
        ),
      _ => (AppColors.statusDraft, AppColors.statusDraftBg, status),
    };
    return StatusBadge.custom(label: label, color: color, bgColor: bg);
  }
}

// ─── Detail Panel ─────────────────────────────────────────────────────────────

class _OrderDetailPanel extends StatelessWidget {
  final OrderEntity order;
  final bool isLoading;
  final OrdersCubit cubit;

  const _OrderDetailPanel({
    required this.order,
    required this.isLoading,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = _surfaceOf(isDark);
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: 400,
      decoration: BoxDecoration(
        color: surface,
        border: Border(left: BorderSide(color: border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Container(
            height: AppSizes.topbarHeight,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
            ),
            child: Row(
              children: [
                _ChannelBadge(channel: order.channel),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  order.reference,
                  style: AppTextStyles.labelMd.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _StatusBadgeWidget(status: order.status, l10n: l10n),
                const SizedBox(width: AppSpacing.sm),
                AppIconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: cubit.closeDetail,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.sm,
                ),
              ],
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date + actions row
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14, color: muted),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM yyyy, HH:mm')
                              .format(order.createdAt.toLocal()),
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Order status changer
                    _OrderStatusChanger(
                      order: order,
                      cubit: cubit,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Fulfillment Status Section
                    _FulfillmentSection(
                      order: order,
                      cubit: cubit,
                      isDark: isDark,
                      l10n: l10n,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Info rows
                    _DetailSection(
                      children: [
                        _InfoRow(
                          label: l10n.customer,
                          value: order.displayCustomerName ?? l10n.noCustomer,
                          isDark: isDark,
                        ),
                        if (order.customerPhone != null)
                          _InfoRow(
                            label: l10n.phone,
                            value: order.customerPhone!,
                            isDark: isDark,
                          ),
                        _InfoRow(
                          label: l10n.branch,
                          value: order.branchName,
                          isDark: isDark,
                        ),
                        if (order.cashierName != null)
                          _InfoRow(
                            label: l10n.cashier,
                            value: order.cashierName!,
                            isDark: isDark,
                          ),
                        _InfoRow(
                          label: l10n.paymentMethod,
                          value: _paymentLabel(order.paymentMethod, l10n),
                          isDark: isDark,
                        ),
                        if (order.paidAt != null)
                          _InfoRow(
                            label: l10n.paidAt,
                            value: DateFormat('dd MMM yyyy, HH:mm')
                                .format(order.paidAt!.toLocal()),
                            isDark: isDark,
                          ),
                        if (order.note != null && order.note!.isNotEmpty)
                          _InfoRow(
                            label: l10n.note,
                            value: order.note!,
                            isDark: isDark,
                          ),
                      ],
                    ),
                    // Guest checkout info
                    if (order.isGuestCheckout) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _GuestCheckoutSection(
                          order: order, isDark: isDark, l10n: l10n),
                    ],
                    // Split payments
                    if (order.payments.length > 1) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SplitPaymentsSection(
                          order: order, isDark: isDark, l10n: l10n, fg: fg),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Order items
                    Text(
                      l10n.orderItems,
                      style: AppTextStyles.labelMd.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailSection(
                      children: [
                        for (final item in order.items)
                          _OrderItemRow(item: item, isDark: isDark),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Totals
                    _DetailSection(
                      children: [
                        _TotalRow(
                          label: l10n.subtotal,
                          value: AppFormatters.currency(order.subtotal),
                          isDark: isDark,
                        ),
                        if (order.discountAmount > 0)
                          _TotalRow(
                            label: l10n.discount,
                            value:
                                '-${AppFormatters.currency(order.discountAmount)}',
                            valueColor: AppColors.success,
                            isDark: isDark,
                          ),
                        _TotalRow(
                          label: l10n.tax,
                          value: AppFormatters.currency(order.taxAmount),
                          isDark: isDark,
                          labelColor: muted,
                        ),
                        const Divider(height: 16),
                        _TotalRow(
                          label: l10n.total,
                          value: AppFormatters.currency(order.total),
                          isDark: isDark,
                          isBold: true,
                        ),
                      ],
                    ),

                    // Refund history
                    if (order.refunds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _RefundHistorySection(
                          order: order, isDark: isDark, l10n: l10n, fg: fg),
                    ],

                    // Tracking link (shown when store has a tracking slug)
                    Builder(builder: (ctx) {
                      final slug = getIt<LocalStorage>().trackingSlug;
                      if (slug == null || slug.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          const SizedBox(height: AppSpacing.lg),
                          _TrackingLinkSection(
                            orderRef: order.reference,
                            slug: slug,
                            isDark: isDark,
                            l10n: l10n,
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: AppSpacing.xl),

                    // Actions
                    Column(
                      children: [
                        AppButton.outline(
                          label: l10n.printInvoice,
                          leading:
                              const Icon(Icons.print_outlined, size: 16),
                          fullWidth: true,
                          onPressed: () => _printInvoice(context, l10n),
                        ),
                        if (!order.isTerminalStatus &&
                            order.status != 'cancelled') ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppButton.outline(
                            label: l10n.orderRefund,
                            leading: const Icon(Icons.undo_rounded, size: 16),
                            fullWidth: true,
                            onPressed: () => _refund(context, l10n),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _refund(BuildContext context, AppLocalizations l10n) async {
    final ok = await OrderRefundModal.show(context, order: order, cubit: cubit);
    if (!context.mounted || !ok) return;
    AppSnackbar.success(context, l10n.refundSuccess);
    cubit.closeDetail();
  }

  Future<void> _printInvoice(
      BuildContext context, AppLocalizations l10n) async {
    final bytes = await cubit.getInvoiceBytes(order.id);
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      AppSnackbar.error(context, l10n.invoiceError);
      return;
    }
    await Printing.layoutPdf(
      onLayout: (_) async => Uint8List.fromList(bytes),
      name: 'invoice-${order.reference}',
    );
  }

  String _paymentLabel(String method, AppLocalizations l10n) =>
      switch (method) {
        'cash' => l10n.cash,
        'card' => l10n.card,
        'bank_transfer' => l10n.bankTransfer,
        _ => method,
      };
}

// ─── Fulfillment Section ──────────────────────────────────────────────────────

class _FulfillmentSection extends StatelessWidget {
  final OrderEntity order;
  final OrdersCubit cubit;
  final bool isDark;
  final AppLocalizations l10n;

  const _FulfillmentSection({
    required this.order,
    required this.cubit,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;

    final steps = [
      ('preparing', l10n.fulfillPreparing, Icons.inventory_2_outlined),
      ('ready', l10n.fulfillReady, Icons.check_circle_outline_rounded),
      ('completed', l10n.fulfillCompleted, Icons.local_shipping_outlined),
    ];

    final currentIdx = steps.indexWhere(
      (s) => s.$1 == order.fulfillmentStatus,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.fulfillmentStatus,
                style: AppTextStyles.labelSm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (order.fulfillmentStatus != null &&
                  order.fulfillmentStatus != 'cancelled')
                _FulfillmentStepButtons(
                  order: order,
                  cubit: cubit,
                  l10n: l10n,
                  cs: cs,
                ),
            ],
          ),
          if (order.fulfillmentStatus == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                l10n.noFulfillmentStatus,
                style: AppTextStyles.bodyXs.copyWith(color: muted),
              ),
            )
          else ...[
            const SizedBox(height: AppSpacing.sm),
            // Progress steps
            Row(
              children: List.generate(steps.length * 2 - 1, (i) {
                if (i.isOdd) {
                  final stepIdx = i ~/ 2;
                  final isDone = stepIdx < currentIdx;
                  return Expanded(
                    child: Container(
                      height: 2,
                      color: isDone ? cs.primary : border,
                    ),
                  );
                }
                final stepIdx = i ~/ 2;
                final isDone = stepIdx <= currentIdx;
                final isCurrent = stepIdx == currentIdx;
                final (_, label, icon) = steps[stepIdx];
                return Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? cs.primary
                            : _surfaceOf(isDark),
                        border: Border.all(
                          color: isCurrent ? cs.primary : border,
                          width: isCurrent ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: isDone ? Colors.white : muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isCurrent ? cs.primary : muted,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _FulfillmentStepButtons extends StatefulWidget {
  final OrderEntity order;
  final OrdersCubit cubit;
  final AppLocalizations l10n;
  final ColorScheme cs;

  const _FulfillmentStepButtons({
    required this.order,
    required this.cubit,
    required this.l10n,
    required this.cs,
  });

  @override
  State<_FulfillmentStepButtons> createState() => _FulfillmentStepButtonsState();
}

class _FulfillmentStepButtonsState extends State<_FulfillmentStepButtons> {
  bool _loading = false;

  static const _steps = ['preparing', 'ready', 'completed'];

  int get _idx => _steps.indexOf(widget.order.fulfillmentStatus ?? '');
  String? get _prev => _idx > 0 ? _steps[_idx - 1] : null;
  String? get _next => (_idx >= 0 && _idx < _steps.length - 1) ? _steps[_idx + 1] : null;

  String _label(String s) => switch (s) {
    'preparing' => widget.l10n.fulfillPreparing,
    'ready'     => widget.l10n.fulfillReady,
    'completed' => widget.l10n.fulfillCompleted,
    _           => s,
  };

  Future<void> _update(String status) async {
    if (_loading) return;
    setState(() => _loading = true);
    final err = await widget.cubit.updateFulfillmentStatus(widget.order.id, status);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) AppSnackbar.error(context, err);
  }

  Widget _btn(String target, {required bool isNext}) {
    return GestureDetector(
      onTap: _loading ? null : () => _update(target),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isNext ? widget.cs.primary.withValues(alpha: 0.1) : Colors.transparent,
            border: isNext ? null : Border.all(color: widget.cs.primary.withValues(alpha: 0.3)),
            borderRadius: AppRadius.brSm,
          ),
          child: _loading
              ? SizedBox(
                  width: 12, height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: widget.cs.primary),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: isNext
                      ? [
                          Text(_label(target), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.cs.primary)),
                          const SizedBox(width: 3),
                          Icon(Icons.arrow_forward_rounded, size: 11, color: widget.cs.primary),
                        ]
                      : [
                          Icon(Icons.arrow_back_rounded, size: 11, color: widget.cs.primary),
                          const SizedBox(width: 3),
                          Text(_label(target), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.cs.primary)),
                        ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prev = _prev;
    final next = _next;
    if (prev == null && next == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (prev != null) _btn(prev, isNext: false),
        if (prev != null && next != null) const SizedBox(width: 6),
        if (next != null) _btn(next, isNext: true),
      ],
    );
  }
}

// ─── Tracking Link Section ────────────────────────────────────────────────────

class _TrackingLinkSection extends StatelessWidget {
  final String orderRef;
  final String slug;
  final bool isDark;
  final AppLocalizations l10n;

  const _TrackingLinkSection({
    required this.orderRef,
    required this.slug,
    required this.isDark,
    required this.l10n,
  });

  String get _trackingUrl {
    final encoded = Uri.encodeComponent(orderRef);
    if (kIsWeb) return '${Uri.base.origin}/#/track/$slug?ref=$encoded';
    return '/track/$slug?ref=$encoded';
  }

  @override
  Widget build(BuildContext context) {
    final border = _borderOf(isDark);
    final fg = _fgOf(isDark);
    final muted = _mutedOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final surface = _surfaceOf(isDark);
    final url = _trackingUrl;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
        borderRadius: AppRadius.brLg,
        color: cs.primary.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Icon(Icons.qr_code_rounded,
                      size: 16, color: cs.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trackingLink,
                        style: AppTextStyles.labelSm.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.shareWithCustomer,
                        style: AppTextStyles.bodyXs.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // QR Code
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: border),
              ),
              child: QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // URL row with copy
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: surface,
                border: Border.all(color: border),
                borderRadius: AppRadius.brSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: AppTextStyles.bodyXs.copyWith(
                        color: fg,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: url));
                        AppSnackbar.success(context, l10n.linkCopied);
                      },
                      child: Icon(Icons.copy_rounded,
                          size: 14, color: cs.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ─── Order Status Changer ─────────────────────────────────────────────────────

class _OrderStatusChanger extends StatefulWidget {
  final OrderEntity order;
  final OrdersCubit cubit;
  final bool isDark;
  final AppLocalizations l10n;

  const _OrderStatusChanger({
    required this.order,
    required this.cubit,
    required this.isDark,
    required this.l10n,
  });

  @override
  State<_OrderStatusChanger> createState() => _OrderStatusChangerState();
}

class _OrderStatusChangerState extends State<_OrderStatusChanger> {
  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.order.status;
  }

  @override
  void didUpdateWidget(_OrderStatusChanger old) {
    super.didUpdateWidget(old);
    if (old.order.status != widget.order.status) {
      _selected = widget.order.status;
    }
  }

  Future<void> _onChange(String newStatus) async {
    if (newStatus == _selected || _saving) return;
    setState(() {
      _selected = newStatus;
      _saving = true;
    });
    final err =
        await widget.cubit.updateOrderStatus(widget.order.id, newStatus);
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      AppSnackbar.success(context, widget.l10n.success);
    } else {
      setState(() => _selected = widget.order.status);
      AppSnackbar.error(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = _borderOf(widget.isDark);
    final fg = _fgOf(widget.isDark);
    final muted = _mutedOf(widget.isDark);

    final isTerminal = widget.order.isTerminalStatus;
    final options = [
      AppSelectOption(value: 'paid', label: widget.l10n.statusPaid),
      AppSelectOption(value: 'pending', label: widget.l10n.statusPending),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: AppRadius.brMd,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded,
                  size: 14, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                widget.l10n.changeOrderStatus,
                style: AppTextStyles.labelSm.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_saving)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (isTerminal)
                _StatusBadgeWidget(status: widget.order.status, l10n: widget.l10n)
              else
                Text(
                  widget.l10n.updateStatus,
                  style: AppTextStyles.bodyXs.copyWith(color: muted),
                ),
            ],
          ),
          if (!isTerminal) ...[
            const SizedBox(height: AppSpacing.sm),
            AppSelectField<String>(
              value: _selected,
              options: options,
              onChanged: _saving ? null : (v) { if (v != null) _onChange(v); },
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Detail Section ───────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final List<Widget> children;
  const _DetailSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkMuted : AppColors.muted;
    final border = _borderOf(isDark);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted = _mutedOf(isDark);
    final fg = _fgOf(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: muted)),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.labelSm.copyWith(color: fg),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItemEntity item;
  final bool isDark;

  const _OrderItemRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = _mutedOf(isDark);
    final fg = _fgOf(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.labelSm.copyWith(color: fg),
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.sku != null)
                  Text(
                    item.sku!,
                    style: AppTextStyles.bodyXs.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '×${item.quantity}  ${AppFormatters.currency(item.lineTotal)}',
                style: AppTextStyles.tableCell.copyWith(color: fg),
              ),
              if (item.discountAmount > 0)
                Text(
                  '-${AppFormatters.currency(item.discountAmount)}',
                  style: AppTextStyles.bodyXs.copyWith(
                      color: AppColors.success),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Guest Checkout Section ───────────────────────────────────────────────────

class _GuestCheckoutSection extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final AppLocalizations l10n;

  const _GuestCheckoutSection({
    required this.order,
    required this.isDark,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fgOf(isDark);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              l10n.guestCheckout,
              style: AppTextStyles.labelMd.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailSection(
          children: [
            if (order.guestName != null)
              _InfoRow(label: l10n.fullName, value: order.guestName!, isDark: isDark),
            if (order.guestPhone != null)
              _InfoRow(label: l10n.phone, value: order.guestPhone!, isDark: isDark),
            if (order.guestEmail != null)
              _InfoRow(label: l10n.email, value: order.guestEmail!, isDark: isDark),
            if (order.shippingAddress != null)
              _InfoRow(
                  label: l10n.shippingAddress,
                  value: order.shippingAddress!,
                  isDark: isDark),
          ],
        ),
      ],
    );
  }
}

// ─── Split Payments Section ───────────────────────────────────────────────────

class _SplitPaymentsSection extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;

  const _SplitPaymentsSection({
    required this.order,
    required this.isDark,
    required this.l10n,
    required this.fg,
  });

  String _methodLabel(String method) => switch (method) {
        'cash' => l10n.cash,
        'card' => l10n.card,
        'bank_transfer' => l10n.bankTransfer,
        'voucher' => l10n.voucher,
        _ => method,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_outlined, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              l10n.splitPayments,
              style: AppTextStyles.labelMd.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailSection(
          children: order.payments
              .map((p) => _InfoRow(
                    label: _methodLabel(p.method),
                    value: AppFormatters.currency(p.amount),
                    isDark: isDark,
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ─── Refund History Section ───────────────────────────────────────────────────

class _RefundHistorySection extends StatelessWidget {
  final OrderEntity order;
  final bool isDark;
  final AppLocalizations l10n;
  final Color fg;

  const _RefundHistorySection({
    required this.order,
    required this.isDark,
    required this.l10n,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final muted = _mutedOf(isDark);
    final border = _borderOf(isDark);
    final cs = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.undo_rounded, size: 14, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              l10n.refundHistory,
              style: AppTextStyles.labelMd.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: AppRadius.brMd,
          ),
          child: Column(
            children: order.refunds.asMap().entries.map((entry) {
              final i = entry.key;
              final r = entry.value;
              return Column(
                children: [
                  if (i > 0) Divider(height: 1, color: border),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppFormatters.currency(r.total),
                              style: AppTextStyles.labelSm.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            _StatusBadgeWidget(status: r.status, l10n: l10n),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.reason,
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (r.cashierName != null)
                              Text(
                                r.cashierName!,
                                style:
                                    AppTextStyles.bodyXs.copyWith(color: muted),
                              ),
                            Text(
                              dateFmt.format(r.createdAt.toLocal()),
                              style:
                                  AppTextStyles.bodyXs.copyWith(color: muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  final bool isBold;
  final bool isDark;

  const _TotalRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.isBold = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = _fgOf(isDark);
    final textStyle = isBold
        ? AppTextStyles.labelMd.copyWith(
            color: labelColor ?? fg,
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.bodySm.copyWith(color: labelColor ?? fg);
    final valueStyle = isBold
        ? AppTextStyles.numericLg.copyWith(
            color: valueColor ?? fg,
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.numeric.copyWith(color: valueColor ?? fg);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
