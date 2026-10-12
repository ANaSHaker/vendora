import 'package:equatable/equatable.dart';
import '../../domain/entities/admin_analytics_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';

sealed class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminAnalyticsEntity analytics;
  final List<AdminVendorEntity> recentVendors;
  final int totalVendors;
  final int accountActive;
  const AdminDashboardLoaded(
    this.analytics, {
    this.recentVendors = const [],
    this.totalVendors = 0,
    this.accountActive = 0,
  });
  @override
  List<Object?> get props => [analytics, recentVendors, totalVendors, accountActive];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError(this.message);
  @override
  List<Object?> get props => [message];
}
