import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/device_session_model.dart';

abstract class DevicesRemoteDataSource {
  Future<List<DeviceSessionModel>> getSessions();
  Future<void> logoutDevice(String id);
  Future<void> logoutAllDevices();
  Future<void> blockDevice(String id);
}

class DevicesRemoteDataSourceImpl implements DevicesRemoteDataSource {
  final ApiClient _client;
  const DevicesRemoteDataSourceImpl(this._client);

  @override
  Future<List<DeviceSessionModel>> getSessions() async {
    final res = await _client.get<Map<String, dynamic>>(ApiEndpoints.devices);
    final body = res.data ?? {};
    final list = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(DeviceSessionModel.fromJson).toList();
  }

  @override
  Future<void> logoutDevice(String id) async {
    await _client.post<void>(ApiEndpoints.logoutDevice(id));
  }

  @override
  Future<void> logoutAllDevices() async {
    await _client.post<void>(ApiEndpoints.logoutAllDevices);
  }

  @override
  Future<void> blockDevice(String id) async {
    await _client.post<void>(ApiEndpoints.blockDevice(id));
  }
}
