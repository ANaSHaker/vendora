import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/usecases/reservations_usecases.dart';
import 'reservations_state.dart';

class ReservationsCubit extends Cubit<ReservationsState> {
  final GetReservationsUseCase _getReservations;
  final UpdateReservationStatusUseCase _updateStatus;
  final DeleteReservationUseCase _deleteReservation;

  Timer? _searchDebounce;

  ReservationsCubit({
    required GetReservationsUseCase getReservations,
    required UpdateReservationStatusUseCase updateStatus,
    required DeleteReservationUseCase deleteReservation,
  })  : _getReservations = getReservations,
        _updateStatus = updateStatus,
        _deleteReservation = deleteReservation,
        super(const ReservationsInitial());

  Future<void> load({ReservationsFilters? filters}) async {
    final f = filters ?? const ReservationsFilters();
    emit(ReservationsLoading(filters: f));
    try {
      final result = await _getReservations(
        page: f.page,
        search: f.search.isEmpty ? null : f.search,
        status: f.status,
        dateFrom: f.dateFrom,
        dateTo: f.dateTo,
        branchId: f.branchId,
      );
      emit(ReservationsLoaded(
        reservations: result.data,
        meta: result.meta,
        filters: f,
      ));
    } catch (e) {
      emit(ReservationsError(message: _errorMessage(e), filters: f));
    }
  }

  void refresh() {
    load(filters: _currentFilters.copyWith(page: 1));
  }

  void search(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      load(filters: _currentFilters.copyWith(search: query, page: 1));
    });
  }

  void filterByStatus(String? status) {
    load(
      filters: status == null
          ? _currentFilters.copyWith(page: 1, clearStatus: true)
          : _currentFilters.copyWith(status: status, page: 1),
    );
  }

  void changePreset(DateRangePreset preset) {
    if (preset == DateRangePreset.custom) return;
    final now = DateTime.now();
    final (from, to) = switch (preset) {
      DateRangePreset.today => (
          DateTime(now.year, now.month, now.day),
          DateTime(now.year, now.month, now.day, 23, 59, 59),
        ),
      DateRangePreset.thisWeek => (
          now.subtract(const Duration(days: 7)),
          now,
        ),
      DateRangePreset.thisMonth => (
          now.subtract(const Duration(days: 30)),
          now,
        ),
      DateRangePreset.custom => (null as DateTime?, null as DateTime?),
    };
    load(
      filters: _currentFilters.copyWith(
        preset: preset,
        dateFrom: from,
        dateTo: to,
        page: 1,
      ),
    );
  }

  void setCustomRange(DateTime from, DateTime to) {
    load(
      filters: _currentFilters.copyWith(
        preset: DateRangePreset.custom,
        dateFrom: from,
        dateTo: to,
        page: 1,
      ),
    );
  }

  void filterByBranch(String? branchId) {
    load(
      filters: branchId == null
          ? _currentFilters.copyWith(page: 1, clearBranch: true)
          : _currentFilters.copyWith(branchId: branchId, page: 1),
    );
  }

  void loadPage(int page) {
    load(filters: _currentFilters.copyWith(page: page));
  }

  /// Optimistically updates status in list then reloads.
  Future<String?> updateStatus(String id, String status) async {
    if (state is ReservationsLoaded) {
      final loaded = state as ReservationsLoaded;
      final updated = loaded.reservations.map((r) {
        if (r.id == id) {
          return ReservationEntity(
            id: r.id,
            reference: r.reference,
            customerName: r.customerName,
            customerPhone: r.customerPhone,
            customerEmail: r.customerEmail,
            partySize: r.partySize,
            tableId: r.tableId,
            tableName: r.tableName,
            branchId: r.branchId,
            branchName: r.branchName,
            reservationDate: r.reservationDate,
            timeFrom: r.timeFrom,
            timeTo: r.timeTo,
            status: status,
            notes: r.notes,
            source: r.source,
            createdAt: r.createdAt,
          );
        }
        return r;
      }).toList();
      emit(loaded.copyWith(reservations: updated));
    }
    try {
      await _updateStatus(id, status);
      refresh();
      return null;
    } catch (e) {
      debugPrint('[ReservationsCubit] updateStatus error: $e');
      refresh();
      return _errorMessage(e);
    }
  }

  Future<String?> deleteReservation(String id) async {
    try {
      await _deleteReservation(id);
      refresh();
      return null;
    } catch (e) {
      debugPrint('[ReservationsCubit] deleteReservation error: $e');
      return _errorMessage(e);
    }
  }

  ReservationsFilters get _currentFilters => switch (state) {
        ReservationsLoaded(:final filters) => filters,
        ReservationsLoading(:final filters) => filters,
        ReservationsError(:final filters) => filters,
        _ => const ReservationsFilters(),
      };

  static String _errorMessage(Object e) {
    if (e is DioException) {
      final inner = e.error;
      if (inner is ServerException) return inner.message;
      if (inner is ValidationException) {
        final first = inner.errors?.values.firstOrNull?.firstOrNull;
        return first ?? inner.message;
      }
      if (inner is NetworkException) return inner.message;
      if (inner is ForbiddenException) return 'Permission denied';
      if (inner is UnauthorizedException) return 'Unauthorized';
      if (inner is SubscriptionException) return 'Subscription required';
      final body = e.response?.data;
      if (body is Map) {
        return body['message'] as String? ?? e.message ?? 'Server error';
      }
      return e.message ?? 'Server error';
    }
    if (e is ServerException) return e.message;
    if (e is ValidationException) return e.message;
    if (e is NetworkException) return e.message;
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return e.toString();
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}

// ─── Settings Cubit ───────────────────────────────────────────────────────────

class ReservationSettingsCubit extends Cubit<ReservationSettingsState> {
  final GetReservationSettingsUseCase _getSettings;
  final SaveReservationSettingsUseCase _saveSettings;
  final CreateReservationExceptionUseCase _createException;
  final DeleteReservationExceptionUseCase _deleteException;

  ReservationSettingsCubit({
    required GetReservationSettingsUseCase getSettings,
    required SaveReservationSettingsUseCase saveSettings,
    required CreateReservationExceptionUseCase createException,
    required DeleteReservationExceptionUseCase deleteException,
  })  : _getSettings = getSettings,
        _saveSettings = saveSettings,
        _createException = createException,
        _deleteException = deleteException,
        super(const ReservationSettingsInitial());

  Future<void> load() async {
    if (isClosed) return;
    emit(const ReservationSettingsLoading());
    try {
      final settings = await _getSettings();
      if (isClosed) return;
      emit(ReservationSettingsLoaded(settings: settings));
    } catch (e) {
      if (isClosed) return;
      emit(ReservationSettingsError(message: e.toString()));
    }
  }

  void toggleEnabled() => _update((s) => s.copyWith(isEnabled: !s.isEnabled));
  void toggleAutoConfirm() => _update((s) => s.copyWith(autoConfirm: !s.autoConfirm));
  void toggleAllowCancellation() => _update((s) => s.copyWith(allowCancellation: !s.allowCancellation));
  void toggleRequirePhone() => _update((s) => s.copyWith(requirePhone: !s.requirePhone));
  void toggleRequireEmail() => _update((s) => s.copyWith(requireEmail: !s.requireEmail));

  void setSlotDuration(int minutes) => _update((s) => s.copyWith(slotDuration: minutes));
  void setBufferTime(int minutes) => _update((s) => s.copyWith(bufferTime: minutes));
  void setMinAdvanceHours(int hours) => _update((s) => s.copyWith(minAdvanceHours: hours));
  void setMaxAdvanceDays(int days) => _update((s) => s.copyWith(maxAdvanceDays: days));

  void updateDaySchedule(DayScheduleEntity updated) {
    if (state is! ReservationSettingsLoaded) return;
    final loaded = state as ReservationSettingsLoaded;
    final schedule = List<DayScheduleEntity>.from(loaded.settings.weeklySchedule);
    final dayIdx = schedule.indexWhere((d) => d.day == updated.day);
    if (dayIdx >= 0) {
      schedule[dayIdx] = updated;
    } else {
      schedule.add(updated);
    }
    _update((s) => s.copyWith(weeklySchedule: schedule));
  }

  void _update(ReservationSettingsEntity Function(ReservationSettingsEntity) fn) {
    if (state is! ReservationSettingsLoaded) return;
    final loaded = state as ReservationSettingsLoaded;
    emit(loaded.copyWith(settings: fn(loaded.settings)));
  }

  Future<void> save() async {
    if (state is! ReservationSettingsLoaded) return;
    final loaded = state as ReservationSettingsLoaded;
    if (loaded.isSaving) return;
    if (isClosed) return;
    emit(loaded.copyWith(isSaving: true, clearError: true, saveSuccess: false));
    try {
      await _saveSettings(loaded.settings);
      if (isClosed) return;
      emit(loaded.copyWith(isSaving: false, saveSuccess: true));
      await load();
    } catch (e) {
      if (isClosed) return;
      emit(loaded.copyWith(
        isSaving: false,
        saveError: ReservationsCubit._errorMessage(e),
        saveSuccess: false,
      ));
    }
  }

  Future<String?> createException(Map<String, dynamic> data) async {
    try {
      final entity = await _createException(data);
      if (state is! ReservationSettingsLoaded) return null;
      final loaded = state as ReservationSettingsLoaded;
      final updated = [
        ...loaded.settings.exceptions,
        entity,
      ];
      _update((s) => s.copyWith(exceptions: updated));
      return null;
    } catch (e) {
      return ReservationsCubit._errorMessage(e);
    }
  }

  Future<String?> deleteException(String id) async {
    try {
      await _deleteException(id);
      if (state is! ReservationSettingsLoaded) return null;
      _update((s) => s.copyWith(
            exceptions: s.exceptions.where((e) => e.id != id).toList(),
          ));
      return null;
    } catch (e) {
      return ReservationsCubit._errorMessage(e);
    }
  }
}
