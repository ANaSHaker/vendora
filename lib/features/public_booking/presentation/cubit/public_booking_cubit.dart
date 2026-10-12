import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/public_booking_usecases.dart';
import 'public_booking_state.dart';

class PublicBookingCubit extends Cubit<PublicBookingState> {
  final GetPublicBookingInfoUseCase _getInfo;
  final GetBookingClosedDatesUseCase _getClosedDates;
  final GetBookingSlotsUseCase _getSlots;
  final CreateBookingUseCase _createBooking;

  PublicBookingCubit({
    required GetPublicBookingInfoUseCase getInfo,
    required GetBookingClosedDatesUseCase getClosedDates,
    required GetBookingSlotsUseCase getSlots,
    required CreateBookingUseCase createBooking,
  })  : _getInfo = getInfo,
        _getClosedDates = getClosedDates,
        _getSlots = getSlots,
        _createBooking = createBooking,
        super(const PublicBookingInitial());

  Future<void> load(String slug) async {
    emit(const PublicBookingLoading());
    final result = await _getInfo(slug);
    result.fold(
      (f) => emit(PublicBookingError(f.message)),
      (info) => emit(PublicBookingLoaded(vendorInfo: info)),
    );
  }

  void setGuests(int count) {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;
    emit(s.copyWith(guestsCount: count.clamp(1, 50)));
  }

  void goNext(String slug) {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;

    if (s.step == BookingStep.guests) {
      emit(s.copyWith(step: BookingStep.dateTime, fieldErrors: {}));
      _loadClosedDates(slug, s.selectedDate);
    } else if (s.step == BookingStep.dateTime) {
      final errs = <String, String>{};
      if (s.selectedDate.isEmpty) errs['date'] = 'selectDate';
      if (s.selectedTime.isEmpty) errs['time'] = 'selectTime';
      if (errs.isNotEmpty) { emit(s.copyWith(fieldErrors: errs)); return; }
      emit(s.copyWith(step: BookingStep.customerInfo, fieldErrors: {}));
    } else if (s.step == BookingStep.customerInfo) {
      _submit(slug);
    }
  }

  void goBack() {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;
    if (s.step == BookingStep.dateTime) {
      emit(s.copyWith(step: BookingStep.guests, fieldErrors: {}));
    } else if (s.step == BookingStep.customerInfo) {
      emit(s.copyWith(step: BookingStep.dateTime, fieldErrors: {}));
    }
  }

  void setDate(String slug, String date) {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;
    emit(s.copyWith(selectedDate: date, selectedTime: '', slots: [], slotsLoading: true, fieldErrors: {}));
    _loadSlots(slug, date, s.guestsCount);
  }

  void setTime(String time) {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;
    emit(s.copyWith(selectedTime: time, fieldErrors: {}));
  }

  void setCustomerName(String v) {
    if (state is! PublicBookingLoaded) return;
    emit((state as PublicBookingLoaded).copyWith(customerName: v));
  }

  void setCustomerPhone(String v) {
    if (state is! PublicBookingLoaded) return;
    emit((state as PublicBookingLoaded).copyWith(customerPhone: v));
  }

  void setCustomerEmail(String v) {
    if (state is! PublicBookingLoaded) return;
    emit((state as PublicBookingLoaded).copyWith(customerEmail: v));
  }

  void setSpecialRequest(String v) {
    if (state is! PublicBookingLoaded) return;
    emit((state as PublicBookingLoaded).copyWith(specialRequest: v));
  }

  void loadClosedDatesForMonth(String slug, int year, int month) {
    _loadClosedDatesForMonth(slug, year, month);
  }

  void resetAll() {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;
    emit(PublicBookingLoaded(vendorInfo: s.vendorInfo));
  }

  Future<void> _loadClosedDates(String slug, String currentDate) async {
    final now = DateTime.now();
    final year = currentDate.isNotEmpty
        ? int.tryParse(currentDate.split('-')[0]) ?? now.year
        : now.year;
    final month = currentDate.isNotEmpty
        ? int.tryParse(currentDate.split('-')[1]) ?? now.month
        : now.month;
    _loadClosedDatesForMonth(slug, year, month);
  }

  Future<void> _loadClosedDatesForMonth(String slug, int year, int month) async {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;
    emit(s.copyWith(closedDatesLoading: true));
    final result = await _getClosedDates(slug, year: year, month: month);
    if (isClosed) return;
    if (state is! PublicBookingLoaded) return;
    result.fold(
      (_) => emit((state as PublicBookingLoaded).copyWith(closedDatesLoading: false)),
      (dates) => emit((state as PublicBookingLoaded).copyWith(
        closedDates: dates,
        closedDatesLoading: false,
      )),
    );
  }

  Future<void> _loadSlots(String slug, String date, int guests) async {
    final result = await _getSlots(slug, date: date, guests: guests);
    if (isClosed) return;
    if (state is! PublicBookingLoaded) return;
    result.fold(
      (_) => emit((state as PublicBookingLoaded).copyWith(slots: [], slotsLoading: false)),
      (slots) => emit((state as PublicBookingLoaded).copyWith(slots: slots, slotsLoading: false)),
    );
  }

  Future<void> _submit(String slug) async {
    if (state is! PublicBookingLoaded) return;
    final s = state as PublicBookingLoaded;

    final errs = <String, String>{};
    if (s.customerName.trim().isEmpty) errs['name'] = 'nameRequired';
    if (s.customerPhone.trim().isEmpty) errs['phone'] = 'phoneRequired';
    if (s.vendorInfo.requireEmail && s.customerEmail.trim().isEmpty) errs['email'] = 'emailRequired';
    if (errs.isNotEmpty) { emit(s.copyWith(fieldErrors: errs)); return; }

    emit(s.copyWith(submitting: true, fieldErrors: {}, clearGlobalError: true));

    final result = await _createBooking(
      slug,
      customerName:    s.customerName.trim(),
      customerPhone:   s.customerPhone.trim(),
      customerEmail:   s.customerEmail.trim().isNotEmpty ? s.customerEmail.trim() : null,
      guestsCount:     s.guestsCount,
      reservationDate: s.selectedDate,
      reservationTime: s.selectedTime,
      specialRequest:  s.specialRequest.trim().isNotEmpty ? s.specialRequest.trim() : null,
    );

    if (isClosed) return;
    if (state is! PublicBookingLoaded) return;
    result.fold(
      (f) => emit((state as PublicBookingLoaded).copyWith(
        submitting: false,
        globalError: f.message,
      )),
      (confirmed) => emit((state as PublicBookingLoaded).copyWith(
        submitting: false,
        step: BookingStep.success,
        confirmed: confirmed,
      )),
    );
  }
}
