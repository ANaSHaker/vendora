import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/public_booking_entities.dart';
import '../../domain/repositories/public_booking_repository.dart';
import '../datasources/public_booking_remote_datasource.dart';

class PublicBookingRepositoryImpl implements PublicBookingRepository {
  final PublicBookingRemoteDataSource _ds;
  const PublicBookingRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, VendorBookingInfoEntity>> getVendorInfo(String slug) async {
    try {
      return Right(await _ds.getVendorInfo(slug));
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getClosedDates(
    String slug, {
    required int year,
    required int month,
  }) async {
    try {
      return Right(await _ds.getClosedDates(slug, year: year, month: month));
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, List<BookingSlotEntity>>> getSlots(
    String slug, {
    required String date,
    required int guests,
  }) async {
    try {
      return Right(await _ds.getSlots(slug, date: date, guests: guests));
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  @override
  Future<Either<Failure, ConfirmedBookingEntity>> createBooking(
    String slug, {
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required int guestsCount,
    required String reservationDate,
    required String reservationTime,
    String? specialRequest,
  }) async {
    try {
      return Right(await _ds.createBooking(
        slug,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        guestsCount: guestsCount,
        reservationDate: reservationDate,
        reservationTime: reservationTime,
        specialRequest: specialRequest,
      ));
    } catch (e) {
      return Left(_mapError(e));
    }
  }

  Failure _mapError(Object e) {
    if (e is ServerFailure) return e;
    return ServerFailure(e.toString());
  }
}
