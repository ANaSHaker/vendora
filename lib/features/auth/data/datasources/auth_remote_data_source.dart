import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<UserModel> adminLogin({required String email, required String password});
  Future<void> adminLogout();
  Future<UserModel> adminGetCurrentUser();
  Future<Map<String, dynamic>> fetchStoreSettings();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _client;
  final SecureStorage _storage;

  const AuthRemoteDataSourceImpl(this._client, this._storage);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    await _storage.saveToken(data['token'] as String);
    final deviceToken = data['device_token'] as String?;
    if (deviceToken != null) await _storage.saveDeviceToken(deviceToken);
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveUserId(user.id);
    return user;
  }

  @override
  Future<void> logout() async {
    try {
      await _client.post<void>(ApiEndpoints.logout);
    } on DioException {
      // Swallow API error — local storage is always cleared below
    }
    await _storage.clearAll();
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>(ApiEndpoints.me);
    final data = response.data!;
    final userJson = data.containsKey('user')
        ? data['user'] as Map<String, dynamic>
        : data;
    return UserModel.fromJson(userJson);
  }

  @override
  Future<UserModel> adminLogin({
    required String email,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.adminLogin,
      data: {'email': email, 'password': password},
    );
    final data = response.data!;

    // Backend may return token as 'token' or 'access_token'
    final token = data['token'] as String? ??
        data['access_token'] as String?;
    if (token == null) throw Exception('No token in admin login response');
    await _storage.saveToken(token);

    // Backend may return admin user as 'user', 'admin', or at root level
    final userJson = data['user'] as Map<String, dynamic>? ??
        data['admin'] as Map<String, dynamic>? ??
        data;
    final user = UserModel.fromJson(userJson, isAdmin: true);
    await _storage.saveUserId(user.id);
    return user;
  }

  @override
  Future<void> adminLogout() async {
    try {
      await _client.post<void>(ApiEndpoints.adminLogout);
    } on DioException {
      // Swallow API error — local storage is always cleared below
    }
    await _storage.clearAll();
  }

  @override
  Future<UserModel> adminGetCurrentUser() async {
    final response = await _client.get<Map<String, dynamic>>(ApiEndpoints.adminMe);
    final data = response.data!;
    final userJson = data['user'] as Map<String, dynamic>? ??
        data['admin'] as Map<String, dynamic>? ??
        data;
    return UserModel.fromJson(userJson, isAdmin: true);
  }

  @override
  Future<Map<String, dynamic>> fetchStoreSettings() async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.storeSettings,
      );
      final body = response.data ?? {};
      final data = body.containsKey('data') && body['data'] is Map<String, dynamic>
          ? body['data'] as Map<String, dynamic>
          : body;
      return data;
    } catch (_) {
      return {};
    }
  }
}
