import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../../../design_system/widgets/inputs/app_date_range_picker.dart';
import '../../domain/entities/reservation_entity.dart';

class ReservationsFilters extends Equatable {
  final int page;
  final String search;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? branchId;
  final DateRangePreset preset;

  const ReservationsFilters({
    this.page = 1,
    this.search = '',
    this.status,
    this.dateFrom,
    this.dateTo,
    this.branchId,
    this.preset = DateRangePreset.thisMonth,
  });

  ReservationsFilters copyWith({
    int? page,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? branchId,
    DateRangePreset? preset,
    bool clearStatus = false,
    bool clearBranch = false,
    bool clearDates = false,
  }) {
    return ReservationsFilters(
      page: page ?? this.page,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      branchId: clearBranch ? null : (branchId ?? this.branchId),
      preset: preset ?? this.preset,
    );
  }

  @override
  List<Object?> get props =>
      [page, search, status, dateFrom, dateTo, branchId, preset];
}

// ─── Reservations List States ─────────────────────────────────────────────────

sealed class ReservationsState extends Equatable {
  const ReservationsState();
}

class ReservationsInitial extends ReservationsState {
  const ReservationsInitial();

  @override
  List<Object?> get props => [];
}

class ReservationsLoading extends ReservationsState {
  final ReservationsFilters filters;
  const ReservationsLoading({required this.filters});

  @override
  List<Object?> get props => [filters];
}

class ReservationsLoaded extends ReservationsState {
  final List<ReservationEntity> reservations;
  final PaginationMeta meta;
  final ReservationsFilters filters;

  const ReservationsLoaded({
    required this.reservations,
    required this.meta,
    required this.filters,
  });

  ReservationsLoaded copyWith({
    List<ReservationEntity>? reservations,
    PaginationMeta? meta,
    ReservationsFilters? filters,
  }) {
    return ReservationsLoaded(
      reservations: reservations ?? this.reservations,
      meta: meta ?? this.meta,
      filters: filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props => [reservations, meta, filters];
}

class ReservationsError extends ReservationsState {
  final String message;
  final ReservationsFilters filters;

  const ReservationsError({required this.message, required this.filters});

  @override
  List<Object?> get props => [message, filters];
}

// ─── Settings States ──────────────────────────────────────────────────────────

sealed class ReservationSettingsState extends Equatable {
  const ReservationSettingsState();
}

class ReservationSettingsInitial extends ReservationSettingsState {
  const ReservationSettingsInitial();

  @override
  List<Object?> get props => [];
}

class ReservationSettingsLoading extends ReservationSettingsState {
  const ReservationSettingsLoading();

  @override
  List<Object?> get props => [];
}

class ReservationSettingsLoaded extends ReservationSettingsState {
  final ReservationSettingsEntity settings;
  final bool isSaving;
  final String? saveError;
  final bool saveSuccess;

  const ReservationSettingsLoaded({
    required this.settings,
    this.isSaving = false,
    this.saveError,
    this.saveSuccess = false,
  });

  ReservationSettingsLoaded copyWith({
    ReservationSettingsEntity? settings,
    bool? isSaving,
    String? saveError,
    bool? saveSuccess,
    bool clearError = false,
  }) {
    return ReservationSettingsLoaded(
      settings: settings ?? this.settings,
      isSaving: isSaving ?? this.isSaving,
      saveError: clearError ? null : (saveError ?? this.saveError),
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }

  @override
  List<Object?> get props => [settings, isSaving, saveError, saveSuccess];
}

class ReservationSettingsError extends ReservationSettingsState {
  final String message;
  const ReservationSettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}
