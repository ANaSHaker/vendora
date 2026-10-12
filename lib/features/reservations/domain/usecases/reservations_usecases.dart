import '../../../../core/api/api_response.dart';
import '../entities/reservation_entity.dart';
import '../repositories/reservations_repository.dart';

class GetReservationsUseCase {
  final ReservationsRepository _repo;
  const GetReservationsUseCase(this._repo);

  Future<PaginatedResponse<ReservationEntity>> call({
    required int page,
    int perPage = 20,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? branchId,
  }) =>
      _repo.getReservations(
        page: page,
        perPage: perPage,
        search: search,
        status: status,
        dateFrom: dateFrom,
        dateTo: dateTo,
        branchId: branchId,
      );
}

class GetReservationByIdUseCase {
  final ReservationsRepository _repo;
  const GetReservationByIdUseCase(this._repo);

  Future<ReservationEntity> call(String id) => _repo.getReservationById(id);
}

class CreateReservationUseCase {
  final ReservationsRepository _repo;
  const CreateReservationUseCase(this._repo);

  Future<ReservationEntity> call(Map<String, dynamic> data) =>
      _repo.createReservation(data);
}

class UpdateReservationStatusUseCase {
  final ReservationsRepository _repo;
  const UpdateReservationStatusUseCase(this._repo);

  Future<void> call(String id, String status) =>
      _repo.updateReservationStatus(id, status);
}

class DeleteReservationUseCase {
  final ReservationsRepository _repo;
  const DeleteReservationUseCase(this._repo);

  Future<void> call(String id) => _repo.deleteReservation(id);
}

class GetReservationSettingsUseCase {
  final ReservationsRepository _repo;
  const GetReservationSettingsUseCase(this._repo);

  Future<ReservationSettingsEntity> call() => _repo.getSettings();
}

class SaveReservationSettingsUseCase {
  final ReservationsRepository _repo;
  const SaveReservationSettingsUseCase(this._repo);

  Future<void> call(ReservationSettingsEntity settings) =>
      _repo.saveSettings(settings);
}

class CreateReservationExceptionUseCase {
  final ReservationsRepository _repo;
  const CreateReservationExceptionUseCase(this._repo);

  Future<ReservationExceptionEntity> call(Map<String, dynamic> data) =>
      _repo.createException(data);
}

class DeleteReservationExceptionUseCase {
  final ReservationsRepository _repo;
  const DeleteReservationExceptionUseCase(this._repo);

  Future<void> call(String id) => _repo.deleteException(id);
}
