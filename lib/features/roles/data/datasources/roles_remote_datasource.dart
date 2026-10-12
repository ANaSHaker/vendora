import '../../../../core/api/api_client.dart';
import '../models/role_model.dart';
import '../../domain/entities/role_entity.dart';

abstract class RolesRemoteDataSource {
  Future<List<RoleModel>> getRoles({String? search});
  Future<RoleModel> createRole(RoleFormData data);
  Future<RoleModel> updateRole(String id, RoleFormData data);
  Future<void> deleteRole(String id);
  Future<RoleModel> cloneRole(String id);
  Future<List<PermissionModuleModel>> getPermissions();
}

class RolesRemoteDataSourceImpl implements RolesRemoteDataSource {
  final ApiClient _client;
  const RolesRemoteDataSourceImpl(this._client);

  @override
  Future<List<RoleModel>> getRoles({String? search}) async {
    final params = <String, dynamic>{
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get<Map<String, dynamic>>(
      '/api/roles',
      queryParameters: params,
    );
    final body = res.data ?? {};
    final list = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(RoleModel.fromJson).toList();
  }

  @override
  Future<RoleModel> createRole(RoleFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/roles',
      data: data.toJson(),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return RoleModel.fromJson(json);
  }

  @override
  Future<RoleModel> updateRole(String id, RoleFormData data) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/api/roles/$id',
      data: data.toJson(),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return RoleModel.fromJson(json);
  }

  @override
  Future<void> deleteRole(String id) async {
    await _client.delete<void>('/api/roles/$id');
  }

  @override
  Future<RoleModel> cloneRole(String id) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/roles/$id/clone',
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return RoleModel.fromJson(json);
  }

  @override
  Future<List<PermissionModuleModel>> getPermissions() async {
    final res = await _client.get<Map<String, dynamic>>('/api/permissions');
    final body = res.data ?? {};
    final data = body['data'] as Map<String, dynamic>? ?? {};
    final modules = (data['modules'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return modules.map(PermissionModuleModel.fromJson).toList();
  }
}
