import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_subscriptions_state.dart';

class AdminSubscriptionsCubit extends Cubit<AdminSubscriptionsState> {
  final GetAdminSubscriptionsUseCase _getSubscriptions;
  final AssignVendorSubscriptionUseCase _assignSubscription;
  final UpdateAdminSubscriptionUseCase _updateSubscription;

  AdminSubscriptionsCubit({
    required GetAdminSubscriptionsUseCase getSubscriptions,
    required AssignVendorSubscriptionUseCase assignSubscription,
    required UpdateAdminSubscriptionUseCase updateSubscription,
  })  : _getSubscriptions = getSubscriptions,
        _assignSubscription = assignSubscription,
        _updateSubscription = updateSubscription,
        super(const AdminSubscriptionsInitial());

  Future<void> load({String? status, String? vendorId, int page = 1}) async {
    emit(const AdminSubscriptionsLoading());
    final result = await _getSubscriptions(
        page: page, status: status, vendorId: vendorId);
    result.fold(
      (failure) => emit(AdminSubscriptionsError(failure.message)),
      (paginated) => emit(AdminSubscriptionsLoaded(
        subscriptions: paginated.data,
        meta: paginated.meta,
        page: page,
        statusFilter: status,
        vendorFilter: vendorId,
      )),
    );
  }

  Future<void> filterByStatus(String? status) async {
    final s = state;
    final vendorId = s is AdminSubscriptionsLoaded ? s.vendorFilter : null;
    await load(status: status, vendorId: vendorId, page: 1);
  }

  Future<void> changePage(int page) async {
    final s = state;
    if (s is! AdminSubscriptionsLoaded) return;
    await load(status: s.statusFilter, vendorId: s.vendorFilter, page: page);
  }

  Future<bool> createSubscription(String vendorId, Map<String, dynamic> data) async {
    final result = await _assignSubscription(vendorId, data);
    return result.fold((_) => false, (_) {
      final s = state;
      if (s is AdminSubscriptionsLoaded) {
        load(status: s.statusFilter, vendorId: s.vendorFilter, page: 1);
      }
      return true;
    });
  }

  Future<bool> updateSubscription(String id, Map<String, dynamic> data) async {
    final result = await _updateSubscription(id, data);
    return result.fold((_) => false, (_) {
      final s = state;
      if (s is AdminSubscriptionsLoaded) {
        load(status: s.statusFilter, vendorId: s.vendorFilter, page: s.page);
      }
      return true;
    });
  }
}
