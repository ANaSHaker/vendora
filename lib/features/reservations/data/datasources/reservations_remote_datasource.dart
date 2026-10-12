import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/reservation_entity.dart';
import '../models/reservation_model.dart';

abstract class ReservationsRemoteDataSource {
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

class ReservationsRemoteDataSourceImpl
    implements ReservationsRemoteDataSource {
  final ApiClient _client;
  static final _dateFmt = DateFormat('yyyy-MM-dd', 'en_US');

  const ReservationsRemoteDataSourceImpl(this._client);

  @override
  Future<PaginatedResponse<ReservationEntity>> getReservations({
    required int page,
    int perPage = 20,
    String? search,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? branchId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
      if (dateFrom != null) 'date_from': _dateFmt.format(dateFrom),
      if (dateTo != null) 'date_to': _dateFmt.format(dateTo),
      if (branchId != null) 'branch_id': branchId,
    };

    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.reservations,
      queryParameters: params,
    );

    return PaginatedResponse.fromJson(
      response.data!,
      ReservationModel.fromJson,
    );
  }

  @override
  Future<ReservationEntity> getReservationById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.reservationById(id),
    );
    final body = response.data!;
    final data = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return ReservationModel.fromJson(data);
  }

  @override
  Future<ReservationEntity> createReservation(
      Map<String, dynamic> data) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.reservations,
      data: data,
    );
    final body = response.data!;
    final item = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return ReservationModel.fromJson(item);
  }

  @override
  Future<void> updateReservationStatus(String id, String status) async {
    await _client.patch<dynamic>(
      ApiEndpoints.reservationStatus(id),
      data: {'status': status},
    );
  }

  @override
  Future<void> deleteReservation(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.reservationById(id));
  }

  @override
  Future<ReservationSettingsEntity> getSettings() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.reservationSettings,
    );
    final body = response.data!;
    final data = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return ReservationSettingsModel.fromJson(data);
  }

  @override
  Future<ReservationExceptionEntity> createException(
      Map<String, dynamic> data) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.reservationExceptions,
      data: data,
    );
    final body = response.data!;
    final item = body.containsKey('data')
        ? body['data'] as Map<String, dynamic>
        : body;
    return ReservationExceptionModel.fromJson(item);
  }

  @override
  Future<void> deleteException(String id) async {
    await _client.delete<dynamic>(ApiEndpoints.reservationExceptionById(id));
  }

  @override
  Future<void> saveSettings(ReservationSettingsEntity settings) async {
    final model = settings is ReservationSettingsModel
        ? settings
        : ReservationSettingsModel(
            isEnabled: settings.isEnabled,
            autoConfirm: settings.autoConfirm,
            allowCancellation: settings.allowCancellation,
            requirePhone: settings.requirePhone,
            requireEmail: settings.requireEmail,
            slotDuration: settings.slotDuration,
            bufferTime: settings.bufferTime,
            minAdvanceHours: settings.minAdvanceHours,
            maxAdvanceDays: settings.maxAdvanceDays,
            weeklySchedule: settings.weeklySchedule,
          );
    // API uses 3 separate endpoints per tab
    await Future.wait([
      _client.put<dynamic>(
        ApiEndpoints.reservationSettingsGeneral,
        data: model.toJsonGeneral(),
      ),
      _client.put<dynamic>(
        ApiEndpoints.reservationSettingsSlots,
        data: model.toJsonSlots(),
      ),
      _client.put<dynamic>(
        ApiEndpoints.reservationSettingsSchedule,
        data: model.toJsonSchedule(),
      ),
    ]);
  }
}
