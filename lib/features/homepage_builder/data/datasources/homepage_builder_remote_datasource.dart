import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/homepage_builder_models.dart';
import '../../domain/entities/homepage_builder_entities.dart';

abstract class HomepageBuilderRemoteDataSource {
  Future<List<HomepageSectionModel>> getLayout();
  Future<void> saveLayout(List<HomepageSection> sections);
}

class HomepageBuilderRemoteDataSourceImpl
    implements HomepageBuilderRemoteDataSource {
  final ApiClient _client;
  const HomepageBuilderRemoteDataSourceImpl(this._client);

  @override
  Future<List<HomepageSectionModel>> getLayout() async {
    final response =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.vendorPageHome);
    final body = response.data ?? {};
    final data = body['data'] ?? body;
    final raw  = (data is Map<String, dynamic> ? data['layout_json'] : null) ?? [];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(HomepageSectionModel.fromJson)
        .toList();
  }

  @override
  Future<void> saveLayout(List<HomepageSection> sections) async {
    await _client.put<dynamic>(
      ApiEndpoints.vendorPageHome,
      data: {'sections': sections.map((s) => s.toJson()).toList()},
    );
  }
}
