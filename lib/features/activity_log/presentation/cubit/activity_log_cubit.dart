import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/activity_log_entity.dart';
import '../../domain/usecases/activity_log_usecases.dart';
import 'activity_log_state.dart';

class ActivityLogCubit extends Cubit<ActivityLogState> {
  final GetActivityLogUseCase _getActivityLog;
  final GetActivityLogUsersUseCase _getUsers;

  ActivityLogCubit({
    required GetActivityLogUseCase getActivityLog,
    required GetActivityLogUsersUseCase getUsers,
  })  : _getActivityLog = getActivityLog,
        _getUsers = getUsers,
        super(const ActivityLogInitial());

  /// Load entries (and users if not yet loaded) for the given [filters].
  Future<void> load({ActivityLogFilters? filters}) async {
    final currentFilters = filters ??
        (state is ActivityLogLoaded
            ? (state as ActivityLogLoaded).filters
            : const ActivityLogFilters());

    // Preserve users across reloads so the dropdown stays populated.
    final previousUsers = state is ActivityLogLoaded
        ? (state as ActivityLogLoaded).users
        : <ActivityLogUser>[];

    emit(const ActivityLogLoading());

    final entriesResult = await _getActivityLog(currentFilters);
    if (isClosed) return;

    await entriesResult.fold(
      (failure) async => emit(ActivityLogError(failure.message)),
      (paginated) async {
        // Only fetch users on first load or when list is empty.
        List<ActivityLogUser> users = previousUsers;
        if (users.isEmpty) {
          final usersResult = await _getUsers();
          if (isClosed) return;
          usersResult.fold(
            (_) {},
            (u) => users = u,
          );
        }

        if (!isClosed) {
          emit(ActivityLogLoaded(
            entries: paginated.data,
            meta: paginated.meta,
            filters: currentFilters,
            users: users,
          ));
        }
      },
    );
  }

  /// Apply a new set of filters and reload from page 1.
  Future<void> applyFilters(ActivityLogFilters filters) async {
    final resetFilters = ActivityLogFilters(
      userId: filters.userId,
      action: filters.action,
      dateFrom: filters.dateFrom,
      dateTo: filters.dateTo,
      page: 1,
      perPage: filters.perPage,
    );
    await load(filters: resetFilters);
  }

  /// Navigate to a specific page while keeping current filters.
  Future<void> goToPage(int page) async {
    final s = state;
    if (s is! ActivityLogLoaded) return;

    final newFilters = ActivityLogFilters(
      userId: s.filters.userId,
      action: s.filters.action,
      dateFrom: s.filters.dateFrom,
      dateTo: s.filters.dateTo,
      page: page,
      perPage: s.filters.perPage,
    );

    final result = await _getActivityLog(newFilters);
    if (isClosed) return;

    result.fold(
      (failure) => emit(ActivityLogError(failure.message)),
      (paginated) => emit(s.copyWith(
        entries: paginated.data,
        meta: paginated.meta,
        filters: newFilters,
      )),
    );
  }

  /// Reload with the same filters.
  Future<void> refresh() async {
    final s = state;
    if (s is ActivityLogLoaded) {
      await load(filters: s.filters);
    } else {
      await load();
    }
  }

  /// Update only the user filter and reload.
  void updateUserFilter(String? userId) {
    final s = state;
    if (s is! ActivityLogLoaded) return;
    load(
      filters: ActivityLogFilters(
        userId: userId,
        action: s.filters.action,
        dateFrom: s.filters.dateFrom,
        dateTo: s.filters.dateTo,
        page: 1,
        perPage: s.filters.perPage,
      ),
    );
  }

  /// Update only the action filter and reload.
  void updateActionFilter(String? action) {
    final s = state;
    if (s is! ActivityLogLoaded) return;
    load(
      filters: ActivityLogFilters(
        userId: s.filters.userId,
        action: action,
        dateFrom: s.filters.dateFrom,
        dateTo: s.filters.dateTo,
        page: 1,
        perPage: s.filters.perPage,
      ),
    );
  }

  /// Update the date range and reload.
  void updateDateRange(String? dateFrom, String? dateTo) {
    final s = state;
    if (s is! ActivityLogLoaded) return;
    load(
      filters: ActivityLogFilters(
        userId: s.filters.userId,
        action: s.filters.action,
        dateFrom: dateFrom,
        dateTo: dateTo,
        page: 1,
        perPage: s.filters.perPage,
      ),
    );
  }

  /// Remove all active filters.
  void clearFilters() {
    final s = state;
    if (s is! ActivityLogLoaded) return;
    load(filters: ActivityLogFilters(perPage: s.filters.perPage));
  }
}
