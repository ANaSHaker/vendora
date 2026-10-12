import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/public_booking_entities.dart';

abstract class PublicBookingRepository {
  Future<Either<Failure, VendorBookingInfoEntity>> getVendorInfo(String slug);

  Future<Either<Failure, List<String>>> getClosedDates(
    String slug, {
    required int year,
    required int month,
  });

  Future<Either<Failure, List<BookingSlotEntity>>> getSlots(
    String slug, {
    required String date,
    required int guests,
  });

  Future<Either<Failure, ConfirmedBookingEntity>> createBooking(
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
