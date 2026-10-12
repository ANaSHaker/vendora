import '../../../../core/api/api_response.dart';
import '../../domain/entities/reservation_entity.dart';
import '../../domain/repositories/reservations_repository.dart';
import '../datasources/reservations_remote_datasource.dart';

class ReservationsRepositoryImpl implements ReservationsRepository {
  final ReservationsRemoteDataSource _ds;
  const ReservationsRepositoryImpl(this._ds);

  @override
  Future<PaginatedResponse<ReservationEntity>> getReservations({
    required int page,
    int perPage = 20,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? branchId,
  }) =>
      _ds.getReservations(
        page: page,
        perPage: perPage,
        search: search,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
      );

  @override
  Future<ReservationEntity> getReservationById(String id) =>
      _ds.getReservationById(id);

  @override
  Future<ReservationEntity> createReservation(Map<String, dynamic> data) =>
      _ds.createReservation(data);

  @override
  Future<void> updateReservationStatus(String id, String status) =>
      _ds.updateReservationStatus(id, status);

  @override
  Future<void> deleteReservation(String id) => _ds.deleteReservation(id);

  @override
  Future<ReservationSettingsEntity> getSettings() => _ds.getSettings();

  @override
  Future<void> saveSettings(ReservationSettingsEntity settings) =>
      _ds.saveSettings(settings);

  @override
  Future<ReservationExceptionEntity> createException(
          Map<String, dynamic> data) =>
      _ds.createException(data);

  @override
  Future<void> deleteException(String id) => _ds.deleteException(id);
}
