import '../../domain/entities/public_booking_entities.dart';

class VendorBookingInfoModel extends VendorBookingInfoEntity {
  const VendorBookingInfoModel({
    required super.name,
    required super.displayName,
    super.logoUrl,
    required super.primaryColor,
    required super.secondaryColor,
    required super.slug,
    required super.reservationsEnabled,
    required super.autoConfirm,
    required super.requirePhone,
    required super.requireEmail,
    required super.slotInterval,
    required super.leadTimeHours,
    required super.maxFutureDays,
  });

  factory VendorBookingInfoModel.fromJson(Map<String, dynamic> json) {
    final vendor   = json['vendor']   as Map<String, dynamic>? ?? {};
    final settings = json['settings'] as Map<String, dynamic>? ?? {};
    return VendorBookingInfoModel(
      name:                vendor['name']         as String? ?? '',
      displayName:         vendor['display_name'] as String? ?? vendor['name'] as String? ?? '',
      logoUrl:             vendor['logo_url']     as String?,
      primaryColor:        vendor['primary_color']   as String? ?? '#0C2461',
      secondaryColor:      vendor['secondary_color'] as String? ?? '#1E4BB5',
      slug:                vendor['slug']         as String? ?? '',
      reservationsEnabled: settings['reservations_enabled'] as bool? ?? false,
      autoConfirm:         settings['auto_confirm']         as bool? ?? false,
      requirePhone:        settings['require_phone']        as bool? ?? true,
      requireEmail:        settings['require_email']        as bool? ?? false,
      slotInterval:        settings['slot_interval']        as int?  ?? 30,
      leadTimeHours:       settings['lead_time_hours']      as int?  ?? 1,
      maxFutureDays:       settings['max_future_days']      as int?  ?? 90,
    );
  }
}

class BookingSlotModel extends BookingSlotEntity {
  const BookingSlotModel({
    required super.time,
    required super.timeFormatted,
    required super.available,
    super.guestsRemaining,
  });

  factory BookingSlotModel.fromJson(Map<String, dynamic> json) {
    return BookingSlotModel(
      time:           json['time']           as String? ?? '',
      timeFormatted:  json['time_formatted'] as String? ?? json['time'] as String? ?? '',
      available:      json['available']      as bool?   ?? false,
      guestsRemaining: json['guests_remaining'] as int?,
    );
  }
}

class ConfirmedBookingModel extends ConfirmedBookingEntity {
  const ConfirmedBookingModel({
    required super.reference,
    required super.reservationDate,
    required super.reservationTime,
    required super.guestsCount,
    required super.autoConfirmed,
  });

  factory ConfirmedBookingModel.fromJson(Map<String, dynamic> json, {required int guestsCount}) {
    return ConfirmedBookingModel(
      reference:       json['reference']        as String? ?? '',
      reservationDate: json['reservation_date'] as String? ?? '',
      reservationTime: json['reservation_time'] as String? ?? '',
      guestsCount:     guestsCount,
      autoConfirmed:   json['auto_confirmed']   as bool? ?? false,
    );
  }
}
