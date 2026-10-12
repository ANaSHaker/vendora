import 'package:equatable/equatable.dart';

class VendorBookingInfoEntity extends Equatable {
  final String name;
  final String displayName;
  final String? logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String slug;
  final bool reservationsEnabled;
  final bool autoConfirm;
  final bool requirePhone;
  final bool requireEmail;
  final int slotInterval;
  final int leadTimeHours;
  final int maxFutureDays;

  const VendorBookingInfoEntity({
    required this.name,
    required this.displayName,
    this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.slug,
    required this.reservationsEnabled,
    required this.autoConfirm,
    required this.requirePhone,
    required this.requireEmail,
    required this.slotInterval,
    required this.leadTimeHours,
    required this.maxFutureDays,
  });

  @override
  List<Object?> get props => [
        name, displayName, logoUrl, primaryColor, secondaryColor, slug,
        reservationsEnabled, autoConfirm, requirePhone, requireEmail,
        slotInterval, leadTimeHours, maxFutureDays,
      ];
}

class BookingSlotEntity extends Equatable {
  final String time;
  final String timeFormatted;
  final bool available;
  final int? guestsRemaining;

  const BookingSlotEntity({
    required this.time,
    required this.timeFormatted,
    required this.available,
    this.guestsRemaining,
  });

  @override
  List<Object?> get props => [time, timeFormatted, available, guestsRemaining];
}

class ConfirmedBookingEntity extends Equatable {
  final String reference;
  final String reservationDate;
  final String reservationTime;
  final int guestsCount;
  final bool autoConfirmed;

  const ConfirmedBookingEntity({
    required this.reference,
    required this.reservationDate,
    required this.reservationTime,
    required this.guestsCount,
    required this.autoConfirmed,
  });

  @override
  List<Object?> get props => [reference, reservationDate, reservationTime, guestsCount, autoConfirmed];
}
