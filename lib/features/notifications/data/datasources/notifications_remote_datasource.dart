import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  final ApiClient _client;
  const NotificationsRemoteDataSourceImpl(this._client);

  @override
  Future<List<NotificationModel>> getNotifications({
    bool unreadOnly = false,
  }) async {
    final params = <String, dynamic>{
      'per_page': 50,
      if (unreadOnly) 'filter': 'unread',
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.notifications,
      queryParameters: params,
    );
    final body = res.data ?? {};
    final list = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(NotificationModel.fromJson).toList();
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final res = await _client
          .get<Map<String, dynamic>>(ApiEndpoints.unreadCount);
      final body = res.data ?? {};
      return (body['count'] as int?) ??
          (body['unread_count'] as int?) ??
          (body['data'] as int?) ??
          0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    await _client.post<void>(ApiEndpoints.readNotification(id));
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.post<void>(ApiEndpoints.readAllNotifications);
  }
}
