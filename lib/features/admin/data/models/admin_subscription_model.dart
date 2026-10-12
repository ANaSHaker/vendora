import '../../domain/entities/admin_subscription_entity.dart';

class AdminSubscriptionModel extends AdminSubscriptionEntity {
  const AdminSubscriptionModel({
    required super.id,
    required super.vendorId,
    required super.vendorName,
    super.vendorSlug,
    required super.planId,
    required super.planName,
    required super.planPrice,
    super.planMaxProducts,
    super.planMaxUsers,
    super.planMaxBranches,
    required super.status,
    required super.startsAt,
    super.expiresAt,
    super.notes,
    required super.createdAt,
  });

  factory AdminSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>?;
    final plan = json['plan'] as Map<String, dynamic>?;

    return AdminSubscriptionModel(
      id: json['id'].toString(),
      vendorId: vendor?['id']?.toString() ?? json['vendor_id']?.toString() ?? '',
      vendorName: vendor?['name'] as String? ?? json['vendor_name'] as String? ?? '',
      vendorSlug: vendor?['slug'] as String? ?? json['vendor_slug'] as String?,
      planId: plan?['id']?.toString() ?? json['plan_id']?.toString() ?? '',
      planName: plan?['name'] as String? ?? json['plan_name'] as String? ?? '',
      planPrice: (plan?['price'] as num?)?.toDouble() ?? (json['plan_price'] as num?)?.toDouble() ?? 0,
      planMaxProducts: (plan?['max_products'] as num?)?.toInt(),
      planMaxUsers: (plan?['max_users'] as num?)?.toInt(),
      planMaxBranches: (plan?['max_branches'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'active',
      startsAt: json['starts_at'] as String? ?? json['started_at'] as String? ?? json['created_at'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? json['ends_at'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
