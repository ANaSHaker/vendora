import 'package:equatable/equatable.dart';

class AdminSubscriptionEntity extends Equatable {
  final String id;
  final String vendorId;
  final String vendorName;
  final String? vendorSlug;
  final String planId;
  final String planName;
  final double planPrice;
  final int? planMaxProducts;
  final int? planMaxUsers;
  final int? planMaxBranches;
  final String status; // active, trial, past_due, cancelled, suspended, expired
  final String startsAt;
  final String? expiresAt;
  final String? notes;
  final String createdAt;

  const AdminSubscriptionEntity({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    this.vendorSlug,
    required this.planId,
    required this.planName,
    required this.planPrice,
    this.planMaxProducts,
    this.planMaxUsers,
    this.planMaxBranches,
    required this.status,
    required this.startsAt,
    this.expiresAt,
    this.notes,
    required this.createdAt,
  });

  bool get isActive => status == 'active' || status == 'trial';

  bool get isExpired {
    if (expiresAt == null) return false;
    final dt = DateTime.tryParse(expiresAt!);
    return dt != null && dt.isBefore(DateTime.now());
  }

  @override
  List<Object?> get props => [
        id, vendorId, vendorName, vendorSlug,
        planId, planName, planPrice,
        planMaxProducts, planMaxUsers, planMaxBranches,
        status, startsAt, expiresAt, notes, createdAt,
      ];
}
