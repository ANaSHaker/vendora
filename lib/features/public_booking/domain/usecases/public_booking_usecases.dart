import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/public_booking_entities.dart';
import '../repositories/public_booking_repository.dart';

class GetPublicBookingInfoUseCase {
  final PublicBookingRepository _repo;
  const GetPublicBookingInfoUseCase(this._repo);

  Future<Either<Failure, VendorBookingInfoEntity>> call(String slug) =>
      _repo.getVendorInfo(slug);
}

class GetBookingClosedDatesUseCase {
  final PublicBookingRepository _repo;
  const GetBookingClosedDatesUseCase(this._repo);

  Future<Either<Failure, List<String>>> call(
    String slug, {
    required int year,
    required int month,
  }) =>
      _repo.getClosedDates(slug, year: year, month: month);
}

class GetBookingSlotsUseCase {
  final PublicBookingRepository _repo;
  const GetBookingSlotsUseCase(this._repo);

  Future<Either<Failure, List<BookingSlotEntity>>> call(
    String slug, {
    required String date,
    required int guests,
  }) =>
      _repo.getSlots(slug, date: date, guests: guests);
}

class CreateBookingUseCase {
  final PublicBookingRepository _repo;
  const CreateBookingUseCase(this._repo);

  Future<Either<Failure, ConfirmedBookingEntity>> call(
    String slug, {
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required int guestsCount,
    required String reservationDate,
    required String reservationTime,
    String? specialRequest,
  }) =>
      _repo.createBooking(
        slug,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        guestsCount: guestsCount,
        reservationDate: reservationDate,
        reservationTime: reservationTime,
        specialRequest: specialRequest,
      );
}
