import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/branch_model.dart';
import '../../domain/entities/branch_entity.dart';

abstract class BranchesRemoteDataSource {
  Future<List<BranchModel>> getBranches({String? search});
  Future<BranchModel> createBranch(BranchFormData data);
  Future<BranchModel> updateBranch(String id, BranchFormData data);
  Future<void> deleteBranch(String id);
}

class BranchesRemoteDataSourceImpl implements BranchesRemoteDataSource {
  final ApiClient _client;
  const BranchesRemoteDataSourceImpl(this._client);

  @override
  Future<List<BranchModel>> getBranches({String? search}) async {
    final params = <String, dynamic>{
      'per_page': 200,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.branches,
      queryParameters: params,
    );
    final body = res.data ?? {};
    final list = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return list.map(BranchModel.fromJson).toList();
  }

  @override
  Future<BranchModel> createBranch(BranchFormData data) async {
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.branches,
      data: data.toJson(),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return BranchModel.fromJson(json);
  }

  @override
  Future<BranchModel> updateBranch(String id, BranchFormData data) async {
    final res = await _client.put<Map<String, dynamic>>(
      ApiEndpoints.branchById(id),
      data: data.toJson(),
    );
    final body = res.data ?? {};
    final json = body.containsKey('data') && body['data'] is Map
        ? body['data'] as Map<String, dynamic>
        : body;
    return BranchModel.fromJson(json);
  }

  @override
  Future<void> deleteBranch(String id) async {
    await _client.delete<void>(ApiEndpoints.branchById(id));
  }
}
