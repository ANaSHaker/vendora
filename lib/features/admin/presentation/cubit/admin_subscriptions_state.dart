import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/admin_subscription_entity.dart';

sealed class AdminSubscriptionsState extends Equatable {
  const AdminSubscriptionsState();
  @override
  List<Object?> get props => [];
}

class AdminSubscriptionsInitial extends AdminSubscriptionsState {
  const AdminSubscriptionsInitial();
}

class AdminSubscriptionsLoading extends AdminSubscriptionsState {
  const AdminSubscriptionsLoading();
}

class AdminSubscriptionsLoaded extends AdminSubscriptionsState {
  final List<AdminSubscriptionEntity> subscriptions;
  final PaginationMeta meta;
  final int page;
  final String? statusFilter;
  final String? vendorFilter;
  final bool saveSuccess;

  const AdminSubscriptionsLoaded({
    required this.subscriptions,
    required this.meta,
    this.page = 1,
    this.statusFilter,
    this.vendorFilter,
    this.saveSuccess = false,
  });

  AdminSubscriptionsLoaded copyWith({
    List<AdminSubscriptionEntity>? subscriptions,
    PaginationMeta? meta,
    int? page,
    String? statusFilter,
    String? vendorFilter,
    bool clearStatusFilter = false,
    bool clearVendorFilter = false,
    bool? saveSuccess,
  }) {
    return AdminSubscriptionsLoaded(
      subscriptions: subscriptions ?? this.subscriptions,
      meta: meta ?? this.meta,
      page: page ?? this.page,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      vendorFilter: clearVendorFilter ? null : (vendorFilter ?? this.vendorFilter),
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }

  @override
  List<Object?> get props => [subscriptions, meta, page, statusFilter, vendorFilter, saveSuccess];
}

class AdminSubscriptionsError extends AdminSubscriptionsState {
  final String message;
  const AdminSubscriptionsError(this.message);
  @override
  List<Object?> get props => [message];
}
