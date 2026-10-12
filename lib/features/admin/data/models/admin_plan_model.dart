import '../../domain/entities/admin_plan_entity.dart';

class AdminPlanModel extends AdminPlanEntity {
  const AdminPlanModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.price,
    required super.isActive,
    super.description,
    super.maxProducts,
    super.maxUsers,
    super.maxBranches,
  });

  factory AdminPlanModel.fromJson(Map<String, dynamic> json) {
    return AdminPlanModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? (json['monthly_price'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] as bool? ?? (json['status'] == 'active'),
      description: json['description'] as String?,
      maxProducts: (json['max_products'] as num?)?.toInt(),
      maxUsers: (json['max_users'] as num?)?.toInt(),
      maxBranches: (json['max_branches'] as num?)?.toInt(),
    );
  }
}
