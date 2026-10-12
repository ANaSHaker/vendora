import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/public_booking_models.dart';

abstract class PublicBookingRemoteDataSource {
  Future<VendorBookingInfoModel> getVendorInfo(String slug);
  Future<List<String>> getClosedDates(String slug, {required int year, required int month});
  Future<List<BookingSlotModel>> getSlots(String slug, {required String date, required int guests});
  Future<ConfirmedBookingModel> createBooking(
    String slug, {
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required int guestsCount,
    required String reservationDate,
    required String reservationTime,
    String? specialRequest,
  });
}

class PublicBookingRemoteDataSourceImpl implements PublicBookingRemoteDataSource {
  final ApiClient _client;
  const PublicBookingRemoteDataSourceImpl(this._client);

  @override
  Future<VendorBookingInfoModel> getVendorInfo(String slug) async {
    final res = await _client.get<Map<String, dynamic>>(ApiEndpoints.bookingInfo(slug));
    final data = (res.data?['data'] ?? res.data) as Map<String, dynamic>;
    return VendorBookingInfoModel.fromJson(data);
  }

  @override
  Future<List<String>> getClosedDates(
    String slug, {
    required int year,
    required int month,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.bookingClosedDates(slug),
      queryParameters: {'year': year, 'month': month},
    );
    final data = (res.data?['data'] ?? res.data) as Map<String, dynamic>? ?? {};
    final list = data['closed_dates'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  @override
  Future<List<BookingSlotModel>> getSlots(
    String slug, {
    required String date,
    required int guests,
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.bookingSlots(slug),
      queryParameters: {'date': date, 'guests': guests},
    );
    final data = (res.data?['data'] ?? res.data) as Map<String, dynamic>? ?? {};
    final list = data['slots'] as List<dynamic>? ?? [];
    return list
        .map((e) => BookingSlotModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConfirmedBookingModel> createBooking(
    String slug, {
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required int guestsCount,
    required String reservationDate,
    required String reservationTime,
    String? specialRequest,
  }) async {
    final body = <String, dynamic>{
      'customer_name':    customerName,
      'customer_phone':   customerPhone,
      'guests_count':     guestsCount,
      'reservation_date': reservationDate,
      'reservation_time': reservationTime,
      if (customerEmail != null && customerEmail.isNotEmpty) 'customer_email': customerEmail,
      if (specialRequest != null && specialRequest.isNotEmpty) 'special_request': specialRequest,
    };
    final res = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.createBooking(slug),
      data: body,
    );
    final data = (res.data?['data'] ?? res.data) as Map<String, dynamic>;
    return ConfirmedBookingModel.fromJson(data, guestsCount: guestsCount);
  }
}
