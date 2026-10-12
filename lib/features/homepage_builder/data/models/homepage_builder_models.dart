import '../../domain/entities/homepage_builder_entities.dart';

class HomepageSectionModel extends HomepageSection {
  const HomepageSectionModel({
    required super.id,
    required super.type,
    required super.settings,
  });

  factory HomepageSectionModel.fromJson(Map<String, dynamic> json) {
    final type = SectionTypeExt.fromKey(json['type'] as String? ?? '');
    final raw  = json['settings'];
    final settings = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return HomepageSectionModel(
      id:       json['id'] as String? ?? '',
      type:     type,
      settings: Map<String, dynamic>.from(settings),
    );
  }
}
