import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/store_settings_model.dart';

abstract class StoreSettingsRemoteDataSource {
  Future<StoreSettingsModel> getStoreSettings();
  Future<StoreSettingsModel> updateStoreSettings(Map<String, dynamic> data);
}

class StoreSettingsRemoteDataSourceImpl
    implements StoreSettingsRemoteDataSource {
  final ApiClient _client;
  const StoreSettingsRemoteDataSourceImpl(this._client);

  @override
  Future<StoreSettingsModel> getStoreSettings() async {
    final response =
        await _client.get(ApiEndpoints.storeSettings);
    return StoreSettingsModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  @override
  Future<StoreSettingsModel> updateStoreSettings(
      Map<String, dynamic> data) async {
    final response =
        await _client.put(ApiEndpoints.storeSettings, data: data);
    return StoreSettingsModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
