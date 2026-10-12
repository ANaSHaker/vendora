import 'package:equatable/equatable.dart';
import '../../domain/entities/public_booking_entities.dart';

enum BookingStep { guests, dateTime, customerInfo, success }

abstract class PublicBookingState extends Equatable {
  const PublicBookingState();
  @override
  List<Object?> get props => [];
}

class PublicBookingInitial extends PublicBookingState {
  const PublicBookingInitial();
}

class PublicBookingLoading extends PublicBookingState {
  const PublicBookingLoading();
}

class PublicBookingError extends PublicBookingState {
  final String message;
  const PublicBookingError(this.message);
  @override
  List<Object?> get props => [message];
}

class PublicBookingLoaded extends PublicBookingState {
  final VendorBookingInfoEntity vendorInfo;
  final BookingStep step;

  // Step 1
  final int guestsCount;

  // Step 2
  final String selectedDate;
  final String selectedTime;
  final List<String> closedDates;
  final bool closedDatesLoading;
  final List<BookingSlotEntity> slots;
  final bool slotsLoading;

  // Step 3
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String specialRequest;
  final bool submitting;
  final Map<String, String> fieldErrors;
  final String? globalError;

  // Success
  final ConfirmedBookingEntity? confirmed;

  const PublicBookingLoaded({
    required this.vendorInfo,
    this.step = BookingStep.guests,
    this.guestsCount = 2,
    this.selectedDate = '',
    this.selectedTime = '',
    this.closedDates = const [],
    this.closedDatesLoading = false,
    this.slots = const [],
    this.slotsLoading = false,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.specialRequest = '',
    this.submitting = false,
    this.fieldErrors = const {},
    this.globalError,
    this.confirmed,
  });

  PublicBookingLoaded copyWith({
    VendorBookingInfoEntity? vendorInfo,
    BookingStep? step,
    int? guestsCount,
    String? selectedDate,
    String? selectedTime,
    List<String>? closedDates,
    bool? closedDatesLoading,
    List<BookingSlotEntity>? slots,
    bool? slotsLoading,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? specialRequest,
    bool? submitting,
    Map<String, String>? fieldErrors,
    String? globalError,
    bool clearGlobalError = false,
    ConfirmedBookingEntity? confirmed,
  }) =>
      PublicBookingLoaded(
        vendorInfo:          vendorInfo          ?? this.vendorInfo,
        step:                step                ?? this.step,
        guestsCount:         guestsCount         ?? this.guestsCount,
        selectedDate:        selectedDate        ?? this.selectedDate,
        selectedTime:        selectedTime        ?? this.selectedTime,
        closedDates:         closedDates         ?? this.closedDates,
        closedDatesLoading:  closedDatesLoading  ?? this.closedDatesLoading,
        slots:               slots               ?? this.slots,
        slotsLoading:        slotsLoading        ?? this.slotsLoading,
        customerName:        customerName        ?? this.customerName,
        customerPhone:       customerPhone       ?? this.customerPhone,
        customerEmail:       customerEmail       ?? this.customerEmail,
        specialRequest:      specialRequest      ?? this.specialRequest,
        submitting:          submitting          ?? this.submitting,
        fieldErrors:         fieldErrors         ?? this.fieldErrors,
        globalError:         clearGlobalError ? null : (globalError ?? this.globalError),
        confirmed:           confirmed           ?? this.confirmed,
      );

  @override
  List<Object?> get props => [
        vendorInfo, step, guestsCount, selectedDate, selectedTime,
        closedDates, closedDatesLoading, slots, slotsLoading,
        customerName, customerPhone, customerEmail, specialRequest,
        submitting, fieldErrors, globalError, confirmed,
      ];
}
