import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/admin_plan_entity.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/entities/vendor_create_meta_entity.dart';

sealed class AdminVendorsState extends Equatable {
  const AdminVendorsState();
  @override
  List<Object?> get props => [];
}

class AdminVendorsInitial extends AdminVendorsState {
  const AdminVendorsInitial();
}

class AdminVendorsLoading extends AdminVendorsState {
  const AdminVendorsLoading();
}

class AdminVendorsLoaded extends AdminVendorsState {
  final List<AdminVendorEntity> vendors;
  final PaginationMeta meta;
  final Map<String, dynamic> summary;
  final List<AdminPlanEntity> plans;
  final VendorCreateMetaEntity? createMeta;
  final String search;
  final String? statusFilter;
  final String? planFilter;
  final String? subscriptionStatusFilter;
  final String? accountStatusFilter;
  final int page;
  final Set<String> togglingIds;
  final String? selectedVendorId;
  final AdminVendorEntity? detailVendor;
  final bool isLoadingDetail;

  const AdminVendorsLoaded({
    required this.vendors,
    required this.meta,
    this.summary = const {},
    this.plans = const [],
    this.createMeta,
    this.search = '',
    this.statusFilter,
    this.planFilter,
    this.subscriptionStatusFilter,
    this.accountStatusFilter,
    this.page = 1,
    this.togglingIds = const {},
    this.selectedVendorId,
    this.detailVendor,
    this.isLoadingDetail = false,
  });

  AdminVendorsLoaded copyWith({
    List<AdminVendorEntity>? vendors,
    PaginationMeta? meta,
    Map<String, dynamic>? summary,
    List<AdminPlanEntity>? plans,
    VendorCreateMetaEntity? createMeta,
    String? search,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? planFilter,
    bool clearPlanFilter = false,
    String? subscriptionStatusFilter,
    bool clearSubscriptionStatusFilter = false,
    String? accountStatusFilter,
    bool clearAccountStatusFilter = false,
    int? page,
    Set<String>? togglingIds,
    String? selectedVendorId,
    bool clearSelectedVendor = false,
    AdminVendorEntity? detailVendor,
    bool clearDetailVendor = false,
    bool? isLoadingDetail,
  }) {
    return AdminVendorsLoaded(
      vendors: vendors ?? this.vendors,
      meta: meta ?? this.meta,
      summary: summary ?? this.summary,
      plans: plans ?? this.plans,
      createMeta: createMeta ?? this.createMeta,
      search: search ?? this.search,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      planFilter: clearPlanFilter ? null : (planFilter ?? this.planFilter),
      subscriptionStatusFilter: clearSubscriptionStatusFilter
          ? null
          : (subscriptionStatusFilter ?? this.subscriptionStatusFilter),
      accountStatusFilter: clearAccountStatusFilter
          ? null
          : (accountStatusFilter ?? this.accountStatusFilter),
      page: page ?? this.page,
      togglingIds: togglingIds ?? this.togglingIds,
      selectedVendorId:
          clearSelectedVendor ? null : (selectedVendorId ?? this.selectedVendorId),
      detailVendor:
          clearDetailVendor ? null : (detailVendor ?? this.detailVendor),
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    );
  }

  @override
  List<Object?> get props => [
        vendors, meta, summary, plans, createMeta, search, statusFilter, planFilter,
        subscriptionStatusFilter, accountStatusFilter, page, togglingIds,
        selectedVendorId, detailVendor, isLoadingDetail,
      ];
}

class AdminVendorsError extends AdminVendorsState {
  final String message;
  const AdminVendorsError(this.message);
  @override
  List<Object?> get props => [message];
}
