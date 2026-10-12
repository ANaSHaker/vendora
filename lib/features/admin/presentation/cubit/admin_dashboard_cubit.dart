import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/admin_vendor_entity.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final GetAdminAnalyticsUseCase _getAnalytics;
  final GetAdminVendorsUseCase _getVendors;

  AdminDashboardCubit({
    required GetAdminAnalyticsUseCase getAnalytics,
    required GetAdminVendorsUseCase getVendors,
  })  : _getAnalytics = getAnalytics,
        _getVendors = getVendors,
        super(const AdminDashboardInitial());

  Future<void> load() async {
    emit(const AdminDashboardLoading());
    final analyticsFuture = _getAnalytics();
    final vendorsFuture = _getVendors(accountStatus: 'all', perPage: 5);
    final analyticsResult = await analyticsFuture;
    final vendorsResult = await vendorsFuture;

    analyticsResult.fold(
      (failure) => emit(AdminDashboardError(failure.message)),
      (analytics) {
        final recentVendors = vendorsResult.fold(
          (_) => <AdminVendorEntity>[],
          (page) => page.data,
        );
        final summary = vendorsResult.fold(
          (_) => <String, dynamic>{},
          (page) => page.summary ?? <String, dynamic>{},
        );
        emit(AdminDashboardLoaded(
          analytics,
          recentVendors: recentVendors,
          totalVendors: (summary['total'] as num?)?.toInt() ?? 0,
          accountActive: (summary['account_active'] as num?)?.toInt() ?? 0,
        ));
      },
    );
  }
}
