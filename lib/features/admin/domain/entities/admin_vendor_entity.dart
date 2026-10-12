import 'package:equatable/equatable.dart';

class AdminVendorEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String status; // active, suspended, inactive
  final String? planName;
  final String? planId;
  final String createdAt;
  final String? subscriptionEndsAt;
  final int? ordersCount;
  final int? productsCount;
  final String? currencyCode;
  final String? slug;
  final int? usersCount;
  final int? branchesCount;
  final int? maxBranches;
  final int? maxUsers;
  final int? maxProducts;
  final String? billingEmail;
  final String? notes;
  final List<String> assignedFeatureKeys;
  final String? timezone;
  final String? country;
  final double? totalRevenue;
  final double? billingCollected;
  final String? subscriptionDisplayStatus;
  final String? subscriptionStatus; // raw stored: active|trial|past_due|cancelled|suspended
  final String? planExpiresAt;
  final String? trialEndsAt;
  final bool subscriptionDisplayExpiringSoon;
  final AdminVendorSubscriptionEntity? currentSubscription;

  const AdminVendorEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.status,
    this.planName,
    this.planId,
    required this.createdAt,
    this.subscriptionEndsAt,
    this.ordersCount,
    this.productsCount,
    this.currencyCode,
    this.slug,
    this.usersCount,
    this.branchesCount,
    this.maxBranches,
    this.maxUsers,
    this.maxProducts,
    this.billingEmail,
    this.notes,
    this.assignedFeatureKeys = const [],
    this.timezone,
    this.country,
    this.totalRevenue,
    this.billingCollected,
    this.subscriptionDisplayStatus,
    this.subscriptionStatus,
    this.planExpiresAt,
    this.trialEndsAt,
    this.subscriptionDisplayExpiringSoon = false,
    this.currentSubscription,
  });

  bool get isActive => status == 'active';

  @override
  List<Object?> get props => [
        id, name, email, phone, status, planName, planId,
        createdAt, subscriptionEndsAt, ordersCount, productsCount, currencyCode,
        slug, usersCount, branchesCount, maxBranches, maxUsers, maxProducts,
        billingEmail, notes, assignedFeatureKeys, timezone, country,
        totalRevenue, billingCollected, subscriptionDisplayStatus,
        subscriptionStatus, planExpiresAt, trialEndsAt,
        subscriptionDisplayExpiringSoon, currentSubscription,
      ];
}

class AdminVendorSubscriptionEntity extends Equatable {
  final String id;
  final String planId;
  final String planName;
  final String status; // active, expired, trial, canceled, cancelled
  final String startedAt;
  final String? endsAt;
  final String? trialEndsAt;
  final double? amount;

  const AdminVendorSubscriptionEntity({
    required this.id,
    required this.planId,
    required this.planName,
    required this.status,
    required this.startedAt,
    this.endsAt,
    this.trialEndsAt,
    this.amount,
  });

  bool get isActive => status == 'active' || status == 'trial';

  @override
  List<Object?> get props => [
        id, planId, planName, status, startedAt, endsAt, trialEndsAt, amount,
      ];
}
