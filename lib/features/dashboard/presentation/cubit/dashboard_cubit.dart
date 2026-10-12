import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_usecase.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final GetDashboardUseCase _getDashboard;

  DashboardCubit(this._getDashboard) : super(const DashboardInitial());

  Future<void> load({DashboardFilters? filters}) async {
    final f = filters ??
        const DashboardFilters(period: DashboardPeriodFilter.month);
    emit(DashboardLoading(filters: f));
    final result = await _getDashboard(
      GetDashboardParams(
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
        branchId: f.branchId,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(DashboardError(message: failure.message, filters: f)),
      (data) => emit(DashboardLoaded(data: data, filters: f)),
    );
  }

  Future<void> changePeriod(DashboardPeriodFilter period) async {
    await load(filters: _currentFilters.copyWith(period: period));
  }

  Future<void> changeCustomPeriod(DateTime from, DateTime to) async {
    await load(
      filters: DashboardFilters(
        period: DashboardPeriodFilter.custom,
        branchId: _currentFilters.branchId,
        customFrom: from,
        customTo: to,
      ),
    );
  }

  Future<void> refresh() async => load(filters: _currentFilters);

  DashboardFilters get _currentFilters {
    final s = state;
    if (s is DashboardLoading) return s.filters;
    if (s is DashboardLoaded) return s.filters;
    if (s is DashboardError) return s.filters;
    return const DashboardFilters(period: DashboardPeriodFilter.month);
  }
}
