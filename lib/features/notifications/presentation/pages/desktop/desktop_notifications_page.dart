import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/buttons/app_button.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/usecases/notifications_usecases.dart';
import '../../cubit/notifications_cubit.dart';
import '../../cubit/notifications_state.dart';
import '../../cubit/unread_count_cubit.dart';

class DesktopNotificationsPage extends StatelessWidget {
  const DesktopNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(
        get: getIt<GetNotificationsUseCase>(),
        markRead: getIt<MarkNotificationReadUseCase>(),
        markAll: getIt<MarkAllNotificationsReadUseCase>(),
      )..load(),
      child: const _NotificationsContent(),
    );
  }
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = isDark ? AppColors.darkBackground : AppColors.background;
        final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
        final muted =
            isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
        final filter = state is NotificationsLoaded ? state.filter : NotificationsFilter.all;
        final unread = state is NotificationsLoaded
            ? state.notifications.where((n) => !n.isRead).length
            : 0;

        return ColoredBox(
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSizes.desktopContentPadding,
                  AppSpacing.md,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notifications,
                          style: AppTextStyles.h4.copyWith(color: fg),
                        ),
                        Text(
                          unread > 0
                              ? l10n.t("notificationsUnreadCount").replaceAll("{count}", "$unread")
                              : l10n.t('notificationsAllRead'),
                          style: AppTextStyles.bodySm.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (state is NotificationsLoaded &&
                        state.notifications.any((n) => !n.isRead))
                      AppButton.outline(
                        label: l10n.t('markAllRead'),
                        size: AppButtonSize.sm,
                        leading: const Icon(Icons.done_all_rounded, size: 14),
                        onPressed: () {
                          cubit.markAllAsRead();
                          context
                              .read<UnreadCountCubit>()
                              .reset();
                        },
                      ),
                  ],
                ),
              ),

              // ── Filter tabs ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.desktopContentPadding,
                ),
                child: Row(
                  children: [
                    NotificationFilterChip(
                      label: l10n.all,
                      active: filter == NotificationsFilter.all,
                      onTap: () => cubit.setFilter(NotificationsFilter.all),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    NotificationFilterChip(
                      label: l10n.t('unread'),
                      active: filter == NotificationsFilter.unread,
                      onTap: () =>
                          cubit.setFilter(NotificationsFilter.unread),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── List ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.desktopContentPadding,
                  ),
                  child: switch (state) {
                    NotificationsInitial() ||
                    NotificationsLoading() =>
                      ListView.separated(
                        itemCount: 6,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, __) =>
                            const ShimmerBox(height: 80),
                      ),
                    NotificationsError(:final message) => AppErrorWidget(
                        message: message,
                        onRetry: cubit.refresh,
                      ),
                    NotificationsLoaded(:final notifications)
                        when notifications.isEmpty =>
                      AppEmptyState(
                        icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 40),
                        message: l10n.t('noNotifications'),
                        subtitle: l10n.t('noNotificationsSubtitle'),
                      ),
                    NotificationsLoaded(:final notifications) =>
                      ListView.separated(
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, i) => _NotificationTile(
                          notification: notifications[i],
                          isDark: isDark,
                          l10n: l10n,
                          onMarkRead: () {
                            cubit.markAsRead(notifications[i].id);
                            if (!notifications[i].isRead) {
                              context
                                  .read<UnreadCountCubit>()
                                  .decrement();
                            }
                          },
                        ),
                      ),
                  },
                ),
              ),
              const SizedBox(height: AppSizes.desktopContentPadding),
            ],
          ),
        );
      },
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class NotificationFilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const NotificationFilterChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: active
              ? primary
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: AppRadius.brMd,
          border: Border.all(
            color: active
                ? primary
                : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSm.copyWith(
            color: active
                ? Colors.white
                : (isDark
                    ? AppColors.darkMutedForeground
                    : AppColors.mutedForeground),
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onMarkRead;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.l10n,
    required this.onMarkRead,
  });

  String _localizedTitle() {
    final key = switch (notification.type) {
      'order_created'                          => 'notifNewOrder',
      'order_status_updated' || 'order_ready'  => 'notifOrderStatus',
      'payment'                                => 'notifPayment',
      'low_stock'                              => 'notifLowStock',
      'refund_completed'                       => 'notifRefund',
      'subscription_expiring' ||
      'subscription_expired'  ||
      'employee_created'      ||
      'system'                                 => 'notifSystem',
      _                                        => null,
    };
    if (key == null) return notification.title;
    final translated = l10n.t(key);
    return translated == key ? notification.title : translated;
  }

  String _localizedBody() {
    final d = notification.data;
    final ref = d['reference'] as String? ??
        d['order_reference'] as String? ?? '';
    final name = d['name'] as String? ??
        d['product_name'] as String? ?? '';

    if (ref.isEmpty && name.isEmpty) return notification.body;

    final tmpl = switch (notification.type) {
      'order_created'                         => l10n.t('notifNewOrderBody'),
      'order_status_updated' || 'order_ready' => l10n.t('notifOrderStatusBody'),
      'payment'                               => l10n.t('notifPaymentBody'),
      'low_stock'                             => l10n.t('notifLowStockBody'),
      'refund_completed'                      => l10n.t('notifRefundBody'),
      _                                       => notification.body,
    };
    return tmpl.replaceAll('{ref}', ref).replaceAll('{name}', name);
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;

    final unreadBg = isDark
        ? primary.withValues(alpha: 0.06)
        : primary.withValues(alpha: 0.03);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        // Read → plain surface, normal border. Unread → tinted bg + primary border
        color: notification.isRead ? surface : unreadBg,
        border: Border.all(
          color: notification.isRead ? border : primary.withValues(alpha: 0.25),
        ),
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type icon (muted for read, colored for unread) ──
          NotificationTypeIcon(
            type: notification.type,
            primary: notification.isRead ? muted : primary,
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Content ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Unread dot
                    if (!notification.isRead)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        _localizedTitle(),
                        style: AppTextStyles.labelSm.copyWith(
                          color: notification.isRead ? muted : fg,
                          fontWeight: notification.isRead
                              ? FontWeight.w400
                              : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (notification.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _localizedBody(),
                    style: AppTextStyles.bodyXs.copyWith(
                      color: notification.isRead
                          ? muted.withValues(alpha: 0.6)
                          : muted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _fmtDate(notification.createdAt, l10n),
                  style: AppTextStyles.bodyXs.copyWith(
                    color: muted.withValues(
                        alpha: notification.isRead ? 0.5 : 1.0),
                  ),
                ),
              ],
            ),
          ),

          // ── Mark read button (only for unread) ──
          if (!notification.isRead)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
              child: Tooltip(
                message: l10n.t('markRead'),
                child: InkWell(
                  onTap: onMarkRead,
                  borderRadius: AppRadius.brFull,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 18,
                      color: primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmtDate(String iso, AppLocalizations l10n) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return l10n.t('justNow');
      if (diff.inMinutes < 60) return '${diff.inMinutes} ${l10n.t("minutesAgo")}';
      if (diff.inHours < 24) return '${diff.inHours} ${l10n.t("hoursAgo")}';
      if (diff.inDays < 7) return '${diff.inDays} ${l10n.t("daysAgo")}';

      final d = dt.day;
      final mo = dt.month;
      final y = dt.year;
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final mi = dt.minute.toString().padLeft(2, '0');
      final amPm = dt.hour < 12 ? 'ص' : 'م';
      return '$d/$mo/$y · $h:$mi $amPm';
    } catch (_) {
      return iso;
    }
  }
}

// ── Notification Icon ─────────────────────────────────────────────────────────

class NotificationTypeIcon extends StatelessWidget {
  final String type;
  final Color primary;

  const NotificationTypeIcon({
    super.key,
    required this.type,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, bg) = _iconFor(type, primary);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: primary),
    );
  }

  (IconData, Color) _iconFor(String type, Color primary) {
    return switch (type) {
      'order_created' || 'order_status_updated' || 'order_ready' => (
          Icons.receipt_long_outlined,
          primary.withValues(alpha: 0.12)
        ),
      'payment' => (
          Icons.payments_outlined,
          AppColors.successForeground.withValues(alpha: 0.12)
        ),
      'low_stock' => (
          Icons.inventory_2_outlined,
          const Color(0xFFF59E0B).withValues(alpha: 0.12)
        ),
      'refund_completed' => (
          Icons.keyboard_return_rounded,
          AppColors.destructive.withValues(alpha: 0.12)
        ),
      'subscription_expiring' || 'subscription_expired' ||
      'employee_created'      || 'system' => (
          Icons.settings_outlined,
          AppColors.mutedForeground.withValues(alpha: 0.12)
        ),
      _ => (
          Icons.notifications_none_rounded,
          primary.withValues(alpha: 0.12)
        ),
    };
  }
}
