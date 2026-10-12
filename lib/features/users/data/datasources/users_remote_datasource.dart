import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';
import '../../domain/entities/user_entity.dart';

abstract class UsersRemoteDataSource {
  Future<List<UserModel>> getUsers({String? search, int page = 1});
  Future<UserModel> getUserById(String id);
  Future<UserModel> createUser(UserFormData data);
  Future<UserModel> updateUser(String id, UserFormData data);
  Future<void> deleteUser(String id);
}

class UsersRemoteDataSourceImpl implements UsersRemoteDataSource {
  final ApiClient _client;
  const UsersRemoteDataSourceImpl(this._client);

  @override
  Future<List<UserModel>> getUsers({String? search, int page = 1}) async {
    final params = <String, dynamic>{
      'per_page': 20,
      'page': page,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.users,
      queryParameters: params,
    );
    final body = res.data ?? {};
    final list = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(UserModel.fromJson).toList();
  }

  @override
  Future<UserModel> getUserById(String id) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.userById(id),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return UserModel.fromJson(json);
  }

  @override
  Future<UserModel> createUser(UserFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.users,
      data: data.toJson(),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return UserModel.fromJson(json);
  }

  @override
  Future<UserModel> updateUser(String id, UserFormData data) async {
    final res = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.userById(id),
      data: data.toJson(),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return UserModel.fromJson(json);
  }

  @override
  Future<void> deleteUser(String id) async {
    await _client.delete<void>(ApiEndpoints.userById(id));
  }
}
