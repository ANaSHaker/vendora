import '../../../../core/api/api_response.dart';
import '../entities/reservation_entity.dart';

abstract class ReservationsRepository {
  Future<PaginatedResponse<ReservationEntity>> getReservations({
    required int page,
    int perPage,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? branchId,
  });

  Future<ReservationEntity> getReservationById(String id);

  Future<ReservationEntity> createReservation(Map<String, dynamic> data);

  Future<void> updateReservationStatus(String id, String status);

  Future<void> deleteReservation(String id);

  Future<ReservationSettingsEntity> getSettings();

  Future<void> saveSettings(ReservationSettingsEntity settings);

  Future<ReservationExceptionEntity> createException(Map<String, dynamic> data);

  Future<void> deleteException(String id);
}
