import '../../domain/entities/vendor_create_meta_entity.dart';
import 'admin_plan_model.dart';

class VendorPermissionModel extends VendorPermissionEntity {
  const VendorPermissionModel({
    required super.key,
    required super.label,
    required super.description,
  });

  factory VendorPermissionModel.fromJson(Map<String, dynamic> json) {
    return VendorPermissionModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class VendorModuleModel extends VendorModuleEntity {
  const VendorModuleModel({
    required super.key,
    required super.label,
    required super.description,
    required super.permissions,
  });

  factory VendorModuleModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'] as List<dynamic>? ?? [];
    return VendorModuleModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      permissions: rawPerms
          .map((e) => VendorPermissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VendorFeatureOptionModel extends VendorFeatureOptionEntity {
  const VendorFeatureOptionModel({
    required super.id,
    required super.key,
    required super.name,
  });

  factory VendorFeatureOptionModel.fromJson(Map<String, dynamic> json) {
    return VendorFeatureOptionModel(
      id: json['id']?.toString() ?? '',
      key: json['key'] as String? ?? '',
      name: json['name'] as String? ?? json['label'] as String? ?? '',
    );
  }
}

class VendorCreateMetaModel extends VendorCreateMetaEntity {
  const VendorCreateMetaModel({
    required super.plans,
    required super.modules,
    required super.statuses,
    required super.currencies,
    required super.features,
  });

  factory VendorCreateMetaModel.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'] as List<dynamic>? ?? [];
    final rawModules = json['modules'] as List<dynamic>? ?? [];
    final rawStatuses = json['statuses'] as List<dynamic>? ?? [];
    final rawCurrencies = json['currencies'] as List<dynamic>? ?? [];
    final rawFeatures = json['features'] as List<dynamic>? ?? [];

    return VendorCreateMetaModel(
      plans: rawPlans
          .map((e) => AdminPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      modules: rawModules
          .map((e) => VendorModuleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      statuses: rawStatuses.map((e) => e.toString()).toList(),
      currencies: rawCurrencies.map((e) => e.toString()).toList(),
      features: rawFeatures
          .map((e) => VendorFeatureOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
