import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../models/activity_log_model.dart';

abstract class ActivityLogRemoteDataSource {
  Future<PaginatedResponse<ActivityLogEntryModel>> getActivityLog(
    ActivityLogFilters filters,
  );

  Future<List<ActivityLogUserModel>> getUsers();
}

class ActivityLogRemoteDataSourceImpl implements ActivityLogRemoteDataSource {
  final ApiClient _client;

  const ActivityLogRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<ActivityLogEntryModel>> getActivityLog(
    ActivityLogFilters filters,
  ) async {
    final params = <String, dynamic>{
      'page': filters.page,
      'per_page': filters.perPage,
      if (filters.userId != null && filters.userId!.isNotEmpty)
        'user_id': filters.userId,
      if (filters.action != null && filters.action!.isNotEmpty)
        'action': filters.action,
      if (filters.dateFrom != null && filters.dateFrom!.isNotEmpty)
        'date_from': filters.dateFrom,
      if (filters.dateTo != null && filters.dateTo!.isNotEmpty)
        'date_to': filters.dateTo,
    };

    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.activityLog,
      queryParameters: params,
    );

    return PaginatedResponse.fromJson(
      res.data!,
      ActivityLogEntryModel.fromJson,
    );
  }

  @override
  Future<List<ActivityLogUserModel>> getUsers() async {
    final res = await _client
        .get<Map<String, dynamic>>(ApiEndpoints.activityLogUsers);
    final body = res.data!;
    final rawData = body['data'] as List<dynamic>? ?? [];
    return rawData
        .map((e) =>
            ActivityLogUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
