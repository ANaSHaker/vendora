import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/dashboard_models.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardDataModel> getDashboard({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  });
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final ApiClient _client;
  static final _dateFmt = DateFormat('yyyy-MM-dd', 'en_US');

  const DashboardRemoteDataSourceImpl(this._client);

  @override
  Future<DashboardDataModel> getDashboard({
    required DateTime dateFrom,
    required DateTime dateTo,
    String? branchId,
  }) async {
    final params = <String, dynamic>{
      'date_from': _dateFmt.format(dateFrom),
      'date_to': _dateFmt.format(dateTo),
      if (branchId != null) 'branch_id': branchId,
    };

    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.dashboard,
      queryParameters: params,
    );

    final body = response.data!;
    final unwrapped =
        body.containsKey('data') && body['data'] is Map<String, dynamic>
            ? body['data'] as Map<String, dynamic>
            : body;

    return DashboardDataModel.fromJson(unwrapped);
  }
}
