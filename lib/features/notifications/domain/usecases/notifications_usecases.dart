import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  final NotificationsRepository _repo;
  const GetNotificationsUseCase(this._repo);
  Future<Either<Failure, List<NotificationEntity>>> call({
    bool unreadOnly = false,
  }) =>
      _repo.getNotifications(unreadOnly: unreadOnly);
}

class GetUnreadCountUseCase {
  final NotificationsRepository _repo;
  const GetUnreadCountUseCase(this._repo);
  Future<Either<Failure, int>> call() => _repo.getUnreadCount();
}

class MarkNotificationReadUseCase {
  final NotificationsRepository _repo;
  const MarkNotificationReadUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.markAsRead(id);
}

class MarkAllNotificationsReadUseCase {
  final NotificationsRepository _repo;
  const MarkAllNotificationsReadUseCase(this._repo);
  Future<Either<Failure, void>> call() => _repo.markAllAsRead();
}
