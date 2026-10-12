import '../../domain/entities/admin_vendor_entity.dart';

class AdminVendorSubscriptionModel extends AdminVendorSubscriptionEntity {
  const AdminVendorSubscriptionModel({
    required super.id,
    required super.planId,
    required super.planName,
    required super.status,
    required super.startedAt,
    super.endsAt,
    super.trialEndsAt,
    super.amount,
  });

  factory AdminVendorSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>?;
    return AdminVendorSubscriptionModel(
      id: json['id']?.toString() ?? '',
      planId: plan?['id']?.toString() ?? json['plan_id']?.toString() ?? '',
      planName: plan?['name'] as String? ?? json['plan_name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      startedAt: json['started_at'] as String? ??
          json['starts_at'] as String? ??
          json['created_at'] as String? ??
          '',
      endsAt: json['ends_at'] as String?,
      trialEndsAt: json['trial_ends_at'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble(),
    );
  }
}

class AdminVendorModel extends AdminVendorEntity {
  const AdminVendorModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.status,
    super.planName,
    super.planId,
    required super.createdAt,
    super.subscriptionEndsAt,
    super.ordersCount,
    super.productsCount,
    super.currencyCode,
    super.slug,
    super.usersCount,
    super.branchesCount,
    super.maxBranches,
    super.maxUsers,
    super.maxProducts,
    super.billingEmail,
    super.notes,
    super.assignedFeatureKeys,
    super.timezone,
    super.country,
    super.totalRevenue,
    super.billingCollected,
    super.subscriptionDisplayStatus,
    super.subscriptionStatus,
    super.planExpiresAt,
    super.trialEndsAt,
    super.subscriptionDisplayExpiringSoon,
    super.currentSubscription,
  });

  factory AdminVendorModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>?;
    final sub = json['subscription'] as Map<String, dynamic>?;
    final financials = json['financials'] as Map<String, dynamic>?;
    final subDisplay = json['subscription_display'] as Map<String, dynamic>?;

    List<String> parseFeatureKeys() {
      final raw = json['assigned_features'] ?? json['feature_keys'];
      if (raw is List) {
        return raw
            .map((e) {
              if (e is Map) {
                return (e['key'] ?? e['name'] ?? e['slug'] ?? '').toString();
              }
              return e.toString();
            })
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (raw is Map) {
        return raw.keys.map((e) => e.toString()).toList();
      }
      return const [];
    }

    AdminVendorSubscriptionModel? parseSubscription() {
      final rawSub = json['current_subscription'] ?? json['subscription'];
      if (rawSub is Map<String, dynamic>) {
        return AdminVendorSubscriptionModel.fromJson(rawSub);
      }
      return null;
    }

    return AdminVendorModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'active',
      planName: plan?['name'] as String? ?? json['plan_name'] as String?,
      planId: plan?['id']?.toString() ?? json['plan_id']?.toString(),
      createdAt: json['created_at'] as String? ?? '',
      subscriptionEndsAt: sub?['ends_at'] as String? ??
          json['subscription_ends_at'] as String?,
      ordersCount: (json['orders_count'] as num?)?.toInt(),
      productsCount: (json['products_count'] as num?)?.toInt(),
      currencyCode: json['currency'] as String?,
      slug: json['slug'] as String?,
      usersCount: (json['users_count'] as num?)?.toInt(),
      branchesCount: (json['branches_count'] as num?)?.toInt(),
      maxBranches: (plan?['max_branches'] as num?)?.toInt() ??
          (json['max_branches'] as num?)?.toInt(),
      maxUsers: (plan?['max_users'] as num?)?.toInt() ??
          (json['max_users'] as num?)?.toInt(),
      maxProducts: (plan?['max_products'] as num?)?.toInt() ??
          (json['max_products'] as num?)?.toInt(),
      billingEmail: json['billing_email'] as String?,
      notes: json['notes'] as String?,
      assignedFeatureKeys: parseFeatureKeys(),
      timezone: json['timezone'] as String?,
      country: json['country'] as String?,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ??
          (json['orders_total'] as num?)?.toDouble() ??
          (financials?['sales_net'] as num?)?.toDouble(),
      billingCollected: (financials?['billing_collected'] as num?)?.toDouble(),
      subscriptionDisplayStatus:
          subDisplay?['status'] as String? ?? json['subscription_status'] as String?,
      subscriptionStatus: json['subscription_status'] as String?,
      planExpiresAt: json['plan_expires_at'] as String?,
      trialEndsAt: json['trial_ends_at'] as String?,
      subscriptionDisplayExpiringSoon:
          (subDisplay?['expiring_soon'] as bool?) ?? false,
      currentSubscription: parseSubscription(),
    );
  }
}
