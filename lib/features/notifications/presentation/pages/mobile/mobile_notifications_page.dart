import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../design_system/theme/app_border_radius.dart';
import '../../../../../design_system/theme/app_colors.dart';
import '../../../../../design_system/theme/app_spacing.dart';
import '../../../../../design_system/theme/app_text_styles.dart';
import '../../../../../design_system/widgets/feedback/app_empty_state.dart';
import '../../../../../design_system/widgets/feedback/app_error_widget.dart';
import '../../../../../design_system/widgets/feedback/shimmer_loader.dart';
import '../../../domain/entities/notification_entity.dart';
import '../../../domain/usecases/notifications_usecases.dart';
import '../../cubit/notifications_cubit.dart';
import '../../cubit/notifications_state.dart';
import '../../cubit/unread_count_cubit.dart';
import '../desktop/desktop_notifications_page.dart'
    show NotificationTypeIcon, NotificationFilterChip;

class MobileNotificationsPage extends StatelessWidget {
  const MobileNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(
        get: getIt<GetNotificationsUseCase>(),
        markRead: getIt<MarkNotificationReadUseCase>(),
        markAll: getIt<MarkAllNotificationsReadUseCase>(),
      )..load(),
      child: const _MobileContent(),
    );
  }
}

class _MobileContent extends StatelessWidget {
  const _MobileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final filter = state is NotificationsLoaded
            ? state.filter
            : NotificationsFilter.all;
        final hasUnread = state is NotificationsLoaded &&
            state.notifications.any((n) => !n.isRead);

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
          appBar: AppBar(
            backgroundColor:
                isDark ? AppColors.darkSurface : AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title:
                Text(l10n.notifications, style: AppTextStyles.h6),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                color:
                    isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            actions: [
              if (hasUnread)
                IconButton(
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                  tooltip: l10n.t('markAllRead'),
                  onPressed: () {
                    cubit.markAllAsRead();
                    context.read<UnreadCountCubit>().reset();
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    NotificationFilterChip(
                      label: l10n.all,
                      active: filter == NotificationsFilter.all,
                      onTap: () =>
                          cubit.setFilter(NotificationsFilter.all),
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
              // List
              Expanded(
                child: switch (state) {
                  NotificationsInitial() ||
                  NotificationsLoading() =>
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: 5,
                      itemBuilder: (_, __) => const Padding(
                        padding:
                            EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ShimmerBox(height: 80),
                      ),
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
                    ),
                  NotificationsLoaded(:final notifications) =>
                    ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, i) =>
                          _MobileNotificationCard(
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
            ],
          ),
        );
      },
    );
  }
}

class _MobileNotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final AppLocalizations l10n;
  final VoidCallback onMarkRead;

  const _MobileNotificationCard({
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

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return l10n.t('justNow');
      if (diff.inMinutes < 60) return '${diff.inMinutes} ${l10n.t("minutesAgo")}';
      if (diff.inHours < 24) return '${diff.inHours} ${l10n.t("hoursAgo")}';
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

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final fg = isDark ? AppColors.darkForeground : AppColors.foreground;
    final muted =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final primary = Theme.of(context).colorScheme.primary;
    final unreadBg = primary.withValues(alpha: 0.04);

    return GestureDetector(
      onTap: notification.isRead ? null : onMarkRead,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead ? surface : unreadBg,
          border: Border.all(
            color: notification.isRead
                ? border
                : primary.withValues(alpha: 0.2),
          ),
          borderRadius: AppRadius.brMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationTypeIcon(
                type: notification.type, primary: primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!notification.isRead)
                        Container(
                          width: 6,
                          height: 6,
                          margin:
                              const EdgeInsetsDirectional.only(end: 6),
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _localizedTitle(),
                          style: AppTextStyles.labelSm.copyWith(
                            color: fg,
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
                      style: AppTextStyles.bodyXs.copyWith(color: muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _fmtDate(notification.createdAt),
                    style: AppTextStyles.bodyXs
                        .copyWith(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Icon(
                Icons.radio_button_unchecked_rounded,
                size: 16,
                color: primary.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }
}
