import 'package:equatable/equatable.dart';

class ReservationSummaryEntity extends Equatable {
  final int total;
  final int noShow;
  final int confirmedToday;
  final int pendingToday;
  final int upcoming;

  const ReservationSummaryEntity({
    required this.total,
    required this.noShow,
    required this.confirmedToday,
    required this.pendingToday,
    required this.upcoming,
  });

  @override
  List<Object?> get props => [total, noShow, confirmedToday, pendingToday, upcoming];
}

class ReservationEntity extends Equatable {
  final String id;
  final String reference;
  final String customerName;
  final String? customerPhone;
  final String? customerEmail;
  final int partySize;
  final String? tableId;
  final String? tableName;
  final String? branchId;
  final String? branchName;
  final DateTime reservationDate;
  final String? timeFrom;
  final String? timeTo;
  final String status;
  final String? notes;
  final String? source;
  final DateTime createdAt;

  const ReservationEntity({
    required this.id,
    required this.reference,
    required this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.partySize,
    this.tableId,
    this.tableName,
    this.branchId,
    this.branchName,
    required this.reservationDate,
    this.timeFrom,
    this.timeTo,
    required this.status,
    this.notes,
    this.source,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        customerName,
        customerPhone,
        customerEmail,
        partySize,
        tableId,
        tableName,
        branchId,
        branchName,
        reservationDate,
        timeFrom,
        timeTo,
        status,
        notes,
        source,
        createdAt,
      ];
}

// ─── Day Schedule ─────────────────────────────────────────────────────────────

class DayScheduleEntity extends Equatable {
  final String day; // sunday, monday, …, saturday
  final bool isOpen;
  final String openTime;  // "09:00"
  final String closeTime; // "22:00"
  final int maxGuests;

  const DayScheduleEntity({
    required this.day,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    required this.maxGuests,
  });

  DayScheduleEntity copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
    int? maxGuests,
  }) =>
      DayScheduleEntity(
        day: day,
        isOpen: isOpen ?? this.isOpen,
        openTime: openTime ?? this.openTime,
        closeTime: closeTime ?? this.closeTime,
        maxGuests: maxGuests ?? this.maxGuests,
      );

  @override
  List<Object?> get props => [day, isOpen, openTime, closeTime, maxGuests];
}

// ─── Reservation Exception ───────────────────────────────────────────────────

class ReservationExceptionEntity extends Equatable {
  final String id;
  final DateTime date;
  final bool isClosed;
  final String? openTime;
  final String? closeTime;
  final String? reason;

  const ReservationExceptionEntity({
    required this.id,
    required this.date,
    required this.isClosed,
    this.openTime,
    this.closeTime,
    this.reason,
  });

  @override
  List<Object?> get props => [id, date, isClosed, openTime, closeTime, reason];
}

// ─── Reservation Settings ─────────────────────────────────────────────────────

class ReservationSettingsEntity extends Equatable {
  // General
  final bool isEnabled;
  final bool autoConfirm;
  final bool allowCancellation;
  final bool requirePhone;
  final bool requireEmail;

  // Periods
  final int slotDuration;    // minutes: 15, 30, or 60
  final int bufferTime;      // minutes between slots
  final int minAdvanceHours; // minimum hours before booking
  final int maxAdvanceDays;  // maximum days ahead for booking

  // Availability (Sun=0 … Sat=6)
  final List<DayScheduleEntity> weeklySchedule;
  final List<ReservationExceptionEntity> exceptions;

  const ReservationSettingsEntity({
    required this.isEnabled,
    required this.autoConfirm,
    required this.allowCancellation,
    required this.requirePhone,
    required this.requireEmail,
    this.slotDuration = 30,
    this.bufferTime = 0,
    this.minAdvanceHours = 1,
    this.maxAdvanceDays = 30,
    List<DayScheduleEntity>? weeklySchedule,
    List<ReservationExceptionEntity>? exceptions,
  })  : weeklySchedule = weeklySchedule ?? _defaultSchedule,
        exceptions = exceptions ?? const [];

  static const List<DayScheduleEntity> _defaultSchedule = [
    DayScheduleEntity(day: 'sunday',    isOpen: true,  openTime: '09:00', closeTime: '22:00', maxGuests: 20),
    DayScheduleEntity(day: 'monday',    isOpen: true,  openTime: '09:00', closeTime: '22:00', maxGuests: 20),
    DayScheduleEntity(day: 'tuesday',   isOpen: true,  openTime: '09:00', closeTime: '22:00', maxGuests: 20),
    DayScheduleEntity(day: 'wednesday', isOpen: true,  openTime: '09:00', closeTime: '22:00', maxGuests: 20),
    DayScheduleEntity(day: 'thursday',  isOpen: true,  openTime: '09:00', closeTime: '22:00', maxGuests: 20),
    DayScheduleEntity(day: 'friday',    isOpen: false, openTime: '09:00', closeTime: '22:00', maxGuests: 20),
    DayScheduleEntity(day: 'saturday',  isOpen: true,  openTime: '09:00', closeTime: '22:00', maxGuests: 20),
  ];

  ReservationSettingsEntity copyWith({
    bool? isEnabled,
    bool? autoConfirm,
    bool? allowCancellation,
    bool? requirePhone,
    bool? requireEmail,
    int? slotDuration,
    int? bufferTime,
    int? minAdvanceHours,
    int? maxAdvanceDays,
    List<DayScheduleEntity>? weeklySchedule,
    List<ReservationExceptionEntity>? exceptions,
  }) =>
      ReservationSettingsEntity(
        isEnabled: isEnabled ?? this.isEnabled,
        autoConfirm: autoConfirm ?? this.autoConfirm,
        allowCancellation: allowCancellation ?? this.allowCancellation,
        requirePhone: requirePhone ?? this.requirePhone,
        requireEmail: requireEmail ?? this.requireEmail,
        slotDuration: slotDuration ?? this.slotDuration,
        bufferTime: bufferTime ?? this.bufferTime,
        minAdvanceHours: minAdvanceHours ?? this.minAdvanceHours,
        maxAdvanceDays: maxAdvanceDays ?? this.maxAdvanceDays,
        weeklySchedule: weeklySchedule ?? this.weeklySchedule,
        exceptions: exceptions ?? this.exceptions,
      );

  @override
  List<Object?> get props => [
        isEnabled,
        autoConfirm,
        allowCancellation,
        requirePhone,
        requireEmail,
        slotDuration,
        bufferTime,
        minAdvanceHours,
        maxAdvanceDays,
        weeklySchedule,
        exceptions,
      ];
}
