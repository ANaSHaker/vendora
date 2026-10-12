import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_plan_entity.dart';
import '../../domain/entities/vendor_create_meta_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_vendors_state.dart';

class AdminVendorsCubit extends Cubit<AdminVendorsState> {
  final GetAdminVendorsUseCase _getVendors;
  final GetAdminPlansUseCase _getPlans;
  final GetVendorCreateMetaUseCase _getCreateMeta;
  final ToggleAdminVendorStatusUseCase _toggleStatus;
  final CreateAdminVendorUseCase _createVendor;
  final UpdateAdminVendorUseCase _updateVendor;
  final GetAdminVendorDetailsUseCase _getVendorDetails;
  final AssignVendorSubscriptionUseCase _assignSubscription;

  List<AdminPlanEntity> _cachedPlans = const [];
  VendorCreateMetaEntity? _cachedMeta;

  AdminVendorsCubit({
    required GetAdminVendorsUseCase getVendors,
    required GetAdminPlansUseCase getPlans,
    required GetVendorCreateMetaUseCase getCreateMeta,
    required ToggleAdminVendorStatusUseCase toggleStatus,
    required CreateAdminVendorUseCase createVendor,
    required UpdateAdminVendorUseCase updateVendor,
    required GetAdminVendorDetailsUseCase getVendorDetails,
    required AssignVendorSubscriptionUseCase assignSubscription,
  })  : _getVendors = getVendors,
        _getPlans = getPlans,
        _getCreateMeta = getCreateMeta,
        _toggleStatus = toggleStatus,
        _createVendor = createVendor,
        _updateVendor = updateVendor,
        _getVendorDetails = getVendorDetails,
        _assignSubscription = assignSubscription,
        super(const AdminVendorsInitial());

  Future<void> load({
    String? search,
    String? status,
    String? planId,
    String? subscriptionStatus,
    String? accountStatus,
    int page = 1,
  }) async {
    emit(const AdminVendorsLoading());

    // Load meta (plans + modules + statuses + currencies + features) once
    if (_cachedMeta == null) {
      final metaResult = await _getCreateMeta();
      metaResult.fold((_) {}, (m) {
        _cachedMeta = m;
        if (m.plans.isNotEmpty) _cachedPlans = m.plans;
      });
    }
    // Fallback: load plans separately if meta failed
    if (_cachedPlans.isEmpty) {
      final plansResult = await _getPlans();
      plansResult.fold((_) {}, (p) => _cachedPlans = p);
    }

    final result = await _getVendors(
      search: search,
      status: status,
      planId: planId,
      subscriptionStatus: subscriptionStatus,
      accountStatus: accountStatus,
      page: page,
    );
    result.fold(
      (failure) => emit(AdminVendorsError(failure.message)),
      (paginated) => emit(AdminVendorsLoaded(
        vendors: paginated.data,
        meta: paginated.meta,
        summary: paginated.summary ?? const {},
        plans: _cachedPlans,
        createMeta: _cachedMeta,
        search: search ?? '',
        statusFilter: status,
        planFilter: planId,
        subscriptionStatusFilter: subscriptionStatus,
        accountStatusFilter: accountStatus,
        page: page,
      )),
    );
  }

  Future<void> search(String query) async {
    final current = state;
    if (current is AdminVendorsLoaded) {
      await load(
        search: query,
        status: current.statusFilter,
        planId: current.planFilter,
        subscriptionStatus: current.subscriptionStatusFilter,
        accountStatus: current.accountStatusFilter,
        page: 1,
      );
    } else {
      await load(search: query, page: 1);
    }
  }

  Future<void> filterByStatus(String? status) async {
    final current = state;
    if (current is! AdminVendorsLoaded) return load(status: status, page: 1);
    await load(
      search: current.search,
      status: status,
      planId: current.planFilter,
      subscriptionStatus: current.subscriptionStatusFilter,
      accountStatus: current.accountStatusFilter,
      page: 1,
    );
  }

  Future<void> filterByPlan(String? planId) async {
    final current = state;
    if (current is! AdminVendorsLoaded) return load(planId: planId, page: 1);
    await load(
      search: current.search,
      status: current.statusFilter,
      planId: planId,
      subscriptionStatus: current.subscriptionStatusFilter,
      accountStatus: current.accountStatusFilter,
      page: 1,
    );
  }

  Future<void> filterBySubscriptionStatus(String? status) async {
    final current = state;
    if (current is! AdminVendorsLoaded) {
      return load(subscriptionStatus: status, page: 1);
    }
    await load(
      search: current.search,
      status: current.statusFilter,
      planId: current.planFilter,
      subscriptionStatus: status,
      accountStatus: current.accountStatusFilter,
      page: 1,
    );
  }

  Future<void> filterByAccountStatus(String? status) async {
    final current = state;
    if (current is! AdminVendorsLoaded) {
      return load(accountStatus: status, page: 1);
    }
    await load(
      search: current.search,
      status: current.statusFilter,
      planId: current.planFilter,
      subscriptionStatus: current.subscriptionStatusFilter,
      accountStatus: status,
      page: 1,
    );
  }

  Future<void> changePage(int page) async {
    final current = state;
    if (current is! AdminVendorsLoaded) return;
    await load(
      search: current.search,
      status: current.statusFilter,
      planId: current.planFilter,
      subscriptionStatus: current.subscriptionStatusFilter,
      accountStatus: current.accountStatusFilter,
      page: page,
    );
  }

  Future<void> selectVendor(String id) async {
    final current = state;
    if (current is! AdminVendorsLoaded) return;
    // Pre-fill with the list entry while details load.
    final listVendor = current.vendors.where((v) => v.id == id).toList();
    emit(current.copyWith(
      selectedVendorId: id,
      detailVendor: listVendor.isNotEmpty ? listVendor.first : null,
      isLoadingDetail: true,
    ));
    final result = await _getVendorDetails(id);
    final s = state;
    if (s is! AdminVendorsLoaded || s.selectedVendorId != id) return;
    result.fold(
      (_) => emit(s.copyWith(isLoadingDetail: false)),
      (vendor) =>
          emit(s.copyWith(detailVendor: vendor, isLoadingDetail: false)),
    );
  }

  void clearSelectedVendor() {
    final current = state;
    if (current is! AdminVendorsLoaded) return;
    emit(current.copyWith(
      clearSelectedVendor: true,
      clearDetailVendor: true,
      isLoadingDetail: false,
    ));
  }

  Future<bool> assignSubscription(
      String vendorId, Map<String, dynamic> data) async {
    final result = await _assignSubscription(vendorId, data);
    return result.fold(
      (_) => false,
      (_) {
        // Refresh the detail panel to reflect the new subscription.
        final current = state;
        if (current is AdminVendorsLoaded &&
            current.selectedVendorId == vendorId) {
          selectVendor(vendorId);
        }
        return true;
      },
    );
  }

  Future<bool> toggleStatus(String id) async {
    final current = state;
    if (current is! AdminVendorsLoaded) return false;
    emit(current.copyWith(togglingIds: {...current.togglingIds, id}));
    final result = await _toggleStatus(id);
    return result.fold(
      (failure) {
        final s = state;
        if (s is AdminVendorsLoaded) {
          final updated = Set<String>.from(s.togglingIds)..remove(id);
          emit(s.copyWith(togglingIds: updated));
        }
        return false;
      },
      (updated) {
        final s = state;
        if (s is AdminVendorsLoaded) {
          final updatedIds = Set<String>.from(s.togglingIds)..remove(id);
          final vendors = s.vendors.map((v) => v.id == id ? updated : v).toList();
          emit(s.copyWith(vendors: vendors, togglingIds: updatedIds));
        }
        return true;
      },
    );
  }

  Future<bool> createVendor(Map<String, dynamic> data) async {
    final result = await _createVendor(data);
    return result.fold(
      (_) => false,
      (_) {
        final current = state;
        if (current is AdminVendorsLoaded) {
          load(
            search: current.search,
            status: current.statusFilter,
            planId: current.planFilter,
            subscriptionStatus: current.subscriptionStatusFilter,
            accountStatus: current.accountStatusFilter,
            page: current.page,
          );
        }
        return true;
      },
    );
  }

  Future<bool> updateVendor(String id, Map<String, dynamic> data) async {
    final result = await _updateVendor(id, data);
    return result.fold(
      (_) => false,
      (updated) {
        final current = state;
        if (current is AdminVendorsLoaded) {
          final vendors = current.vendors.map((v) => v.id == id ? updated : v).toList();
          emit(current.copyWith(vendors: vendors));
        }
        return true;
      },
    );
  }
}
