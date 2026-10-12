import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notifications_usecases.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  final GetNotificationsUseCase _get;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAll;

  NotificationsFilter _filter = NotificationsFilter.all;

  NotificationsCubit({
    required GetNotificationsUseCase get,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAll,
  })  : _get = get,
        _markRead = markRead,
        _markAll = markAll,
        super(const NotificationsInitial());

  Future<void> load() async {
    emit(const NotificationsLoading());
    final result =
        await _get(unreadOnly: _filter == NotificationsFilter.unread);
    result.fold(
      (f) => emit(NotificationsError(f.message)),
      (list) => emit(NotificationsLoaded(notifications: list, filter: _filter)),
    );
  }

  Future<void> setFilter(NotificationsFilter filter) async {
    _filter = filter;
    await load();
  }

  Future<void> markAsRead(String id) async {
    if (state is! NotificationsLoaded) return;
    final prev = state as NotificationsLoaded;
    // Optimistic update
    final updated = prev.notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    final filtered = _filter == NotificationsFilter.unread
        ? updated.where((n) => !n.isRead).toList()
        : updated;
    emit(NotificationsLoaded(notifications: filtered, filter: _filter));
    // Persist – revert on failure
    final result = await _markRead(id);
    result.fold(
      (_) => emit(prev), // revert if API failed
      (_) {},
    );
  }

  Future<void> markAllAsRead() async {
    if (state is! NotificationsLoaded) return;
    final prev = state as NotificationsLoaded;
    // Optimistic update
    final updated = prev.notifications.map((n) => n.copyWith(isRead: true)).toList();
    final filtered =
        _filter == NotificationsFilter.unread ? <NotificationEntity>[] : updated;
    emit(NotificationsLoaded(notifications: filtered, filter: _filter));
    // Persist – revert on failure
    final result = await _markAll();
    result.fold(
      (_) => emit(prev), // revert if API failed
      (_) {},
    );
  }

  void refresh() => load();
}
