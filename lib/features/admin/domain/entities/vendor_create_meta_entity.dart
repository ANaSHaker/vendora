import 'package:equatable/equatable.dart';
import 'admin_plan_entity.dart';

class VendorPermissionEntity extends Equatable {
  final String key;
  final String label;
  final String description;

  const VendorPermissionEntity({
    required this.key,
    required this.label,
    required this.description,
  });

  @override
  List<Object?> get props => [key, label, description];
}

class VendorModuleEntity extends Equatable {
  final String key;
  final String label;
  final String description;
  final List<VendorPermissionEntity> permissions;

  const VendorModuleEntity({
    required this.key,
    required this.label,
    required this.description,
    required this.permissions,
  });

  @override
  List<Object?> get props => [key, label, description, permissions];
}

class VendorFeatureOptionEntity extends Equatable {
  final String id;
  final String key;
  final String name;

  const VendorFeatureOptionEntity({
    required this.id,
    required this.key,
    required this.name,
  });

  @override
  List<Object?> get props => [id, key, name];
}

class VendorCreateMetaEntity extends Equatable {
  final List<AdminPlanEntity> plans;
  final List<VendorModuleEntity> modules;
  final List<String> statuses;
  final List<String> currencies;
  final List<VendorFeatureOptionEntity> features;

  const VendorCreateMetaEntity({
    required this.plans,
    required this.modules,
    required this.statuses,
    required this.currencies,
    required this.features,
  });

  @override
  List<Object?> get props => [plans, modules, statuses, currencies, features];
}
