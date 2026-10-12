import '../../domain/entities/notification_entity.dart';

enum NotificationsFilter { all, unread }

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  final NotificationsFilter filter;
  const NotificationsLoaded({
    required this.notifications,
    required this.filter,
  });
}

class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
}
