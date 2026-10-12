import '../../domain/entities/reservation_entity.dart';

class ReservationModel extends ReservationEntity {
  const ReservationModel({
    required super.id,
    required super.reference,
    required super.customerName,
    super.customerPhone,
    super.customerEmail,
    required super.partySize,
    super.tableId,
    super.tableName,
    super.branchId,
    super.branchName,
    required super.reservationDate,
    super.timeFrom,
    super.timeTo,
    required super.status,
    super.notes,
    super.source,
    required super.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final customerJson = json['customer'] as Map<String, dynamic>?;
    final tableJson = json['table'] as Map<String, dynamic>?;
    final branchJson = json['branch'] as Map<String, dynamic>?;

    final rawDate = json['reservation_date'] as String? ??
        json['date'] as String? ??
        json['reserved_at'] as String? ??
        '';
    final reservationDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    final rawCreatedAt = json['created_at'] as String? ?? '';
    final createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();

    return ReservationModel(
      id: json['id']?.toString() ?? '',
      reference: json['reference'] as String? ??
          json['ref'] as String? ??
          '#${json['id']}',
      customerName: json['customer_name'] as String? ??
          customerJson?['name'] as String? ??
          json['name'] as String? ??
          '',
      customerPhone: json['customer_phone'] as String? ??
          customerJson?['phone'] as String? ??
          json['phone'] as String?,
      customerEmail: json['customer_email'] as String? ??
          customerJson?['email'] as String? ??
          json['email'] as String?,
      partySize: (json['guests_count'] as num?)?.toInt() ??
          (json['party_size'] as num?)?.toInt() ??
          (json['guests'] as num?)?.toInt() ??
          (json['pax'] as num?)?.toInt() ??
          1,
      tableId: json['table_id']?.toString() ?? tableJson?['id']?.toString(),
      tableName: json['table_name'] as String? ?? tableJson?['name'] as String?,
      branchId: json['branch_id']?.toString() ?? branchJson?['id']?.toString(),
      branchName: json['branch_name'] as String? ?? branchJson?['name'] as String?,
      reservationDate: reservationDate,
      timeFrom: json['reservation_time'] as String? ??
          json['time_from'] as String? ??
          json['start_time'] as String? ??
          json['from'] as String?,
      timeTo: json['time_to'] as String? ??
          json['end_time'] as String? ??
          json['to'] as String?,
      status: json['status'] as String? ?? 'pending',
      notes: json['special_request'] as String? ??
          json['notes'] as String? ??
          json['note'] as String? ??
          json['special_requests'] as String?,
      source: json['source'] as String? ??
          json['booking_source'] as String? ??
          json['channel'] as String?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'customer_name': customerName,
        'customer_phone': customerPhone,
        'customer_email': customerEmail,
        'party_size': partySize,
        'table_id': tableId,
        'branch_id': branchId,
        'reservation_date': reservationDate.toIso8601String().split('T').first,
        'time_from': timeFrom,
        'time_to': timeTo,
        'status': status,
        'notes': notes,
      };
}

// ─── Day Schedule Model ───────────────────────────────────────────────────────

class DayScheduleModel extends DayScheduleEntity {
  const DayScheduleModel({
    required super.day,
    required super.isOpen,
    required super.openTime,
    required super.closeTime,
    required super.maxGuests,
  });

  factory DayScheduleModel.fromJson(String day, Map<String, dynamic> json) {
    bool parseBool(dynamic v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v == 'true';
      return fallback;
    }

    return DayScheduleModel(
      day: day,
      isOpen: parseBool(json['is_open'] ?? json['open'] ?? json['enabled'], fallback: true),
      // API uses opening_time / closing_time
      openTime: json['opening_time'] as String? ??
          json['open_time'] as String? ??
          json['start_time'] as String? ??
          '09:00',
      closeTime: json['closing_time'] as String? ??
          json['close_time'] as String? ??
          json['end_time'] as String? ??
          '22:00',
      maxGuests: (json['max_guests_per_slot'] as num?)?.toInt() ??
          (json['max_guests'] as num?)?.toInt() ??
          (json['capacity'] as num?)?.toInt() ??
          20,
    );
  }

  // Parse from the API list format [{day_name, day_of_week, is_open, opening_time, …}, …]
  static List<DayScheduleModel> fromApiList(List<dynamic> list) {
    const dayNames = [
      'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
    ];
    return list.map((item) {
      final json = item as Map<String, dynamic>;
      final day = json['day_name'] as String? ??
          dayNames[(json['day_of_week'] as num?)?.toInt() ?? 0];
      return DayScheduleModel.fromJson(day, json);
    }).toList();
  }

  Map<String, dynamic> toJson() => {
        'is_open': isOpen,
        'opening_time': openTime,
        'closing_time': closeTime,
        'max_guests_per_slot': maxGuests,
      };
}

// ─── Exception Model ──────────────────────────────────────────────────────────

class ReservationExceptionModel extends ReservationExceptionEntity {
  const ReservationExceptionModel({
    required super.id,
    required super.date,
    required super.isClosed,
    super.openTime,
    super.closeTime,
    super.reason,
  });

  factory ReservationExceptionModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v == 'true';
      return fallback;
    }

    final rawDate = json['date'] as String? ??
        json['exception_date'] as String? ?? '';
    return ReservationExceptionModel(
      id: json['id']?.toString() ?? '',
      date: DateTime.tryParse(rawDate) ?? DateTime.now(),
      isClosed: parseBool(json['is_closed'] ?? json['closed'], fallback: true),
      openTime: json['opening_time'] as String? ?? json['open_time'] as String?,
      closeTime: json['closing_time'] as String? ?? json['close_time'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
        'is_closed': isClosed,
        if (openTime != null) 'opening_time': openTime,
        if (closeTime != null) 'closing_time': closeTime,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
      };
}

// ─── Settings Model ───────────────────────────────────────────────────────────

const List<String> _kDays = [
  'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'
];

class ReservationSettingsModel extends ReservationSettingsEntity {
  const ReservationSettingsModel({
    required super.isEnabled,
    required super.autoConfirm,
    required super.allowCancellation,
    required super.requirePhone,
    required super.requireEmail,
    super.slotDuration,
    super.bufferTime,
    super.minAdvanceHours,
    super.maxAdvanceDays,
    super.weeklySchedule,
    super.exceptions,
  });

  factory ReservationSettingsModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v == 'true';
      return fallback;
    }

    // API returns: {general: {...}, time_slots: {...}, schedule: [...]}
    final general   = json['general']    as Map<String, dynamic>? ?? json;
    final timeSlots = json['time_slots'] as Map<String, dynamic>? ?? json;

    // Schedule: API returns a list [{day_name, is_open, opening_time, closing_time, …}]
    List<DayScheduleEntity>? schedule;
    final scheduleRaw = json['schedule'];
    if (scheduleRaw is List && scheduleRaw.isNotEmpty) {
      schedule = DayScheduleModel.fromApiList(scheduleRaw);
    } else if (scheduleRaw is Map<String, dynamic>) {
      schedule = _kDays.map((day) {
        final dayData = scheduleRaw[day] as Map<String, dynamic>?;
        if (dayData != null) return DayScheduleModel.fromJson(day, dayData);
        return DayScheduleEntity(
          day: day,
          isOpen: day != 'friday',
          openTime: '09:00',
          closeTime: '22:00',
          maxGuests: 20,
        );
      }).toList();
    }

    return ReservationSettingsModel(
      isEnabled: parseBool(
        general['reservations_enabled'] ?? general['is_enabled'] ?? general['enabled'],
        fallback: true,
      ),
      autoConfirm: parseBool(general['auto_confirm'] ?? general['auto_confirmation']),
      allowCancellation: parseBool(
        general['allow_cancellation'] ?? general['cancellation_allowed'],
        fallback: true,
      ),
      requirePhone: parseBool(
        general['require_phone'] ?? general['phone_required'],
        fallback: true,
      ),
      requireEmail: parseBool(general['require_email'] ?? general['email_required']),
      // time_slots uses: slot_interval, preparation_buffer, lead_time_hours, max_future_days
      slotDuration: (timeSlots['slot_interval'] as num?)?.toInt() ??
          (timeSlots['slot_duration'] as num?)?.toInt() ??
          30,
      bufferTime: (timeSlots['preparation_buffer'] as num?)?.toInt() ??
          (timeSlots['buffer_time'] as num?)?.toInt() ??
          0,
      minAdvanceHours: (timeSlots['lead_time_hours'] as num?)?.toInt() ??
          (timeSlots['min_advance_hours'] as num?)?.toInt() ??
          1,
      maxAdvanceDays: (timeSlots['max_future_days'] as num?)?.toInt() ??
          (timeSlots['max_advance_days'] as num?)?.toInt() ??
          30,
      weeklySchedule: schedule,
      exceptions: _parseExceptions(json['exceptions']),
    );
  }

  static List<ReservationExceptionEntity>? _parseExceptions(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    return raw
        .map((e) => ReservationExceptionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJsonGeneral() => {
        'reservations_enabled': isEnabled,
        'auto_confirm': autoConfirm,
        'allow_cancellation': allowCancellation,
        'require_phone': requirePhone,
        'require_email': requireEmail,
      };

  Map<String, dynamic> toJsonSlots() => {
        'slot_interval': slotDuration,
        'preparation_buffer': bufferTime,
        'lead_time_hours': minAdvanceHours,
        'max_future_days': maxAdvanceDays,
      };

  Map<String, dynamic> toJsonSchedule() {
    const dayOrder = {
      'sunday': 0, 'monday': 1, 'tuesday': 2, 'wednesday': 3,
      'thursday': 4, 'friday': 5, 'saturday': 6,
    };
    final list = weeklySchedule.map((day) {
      final json = day is DayScheduleModel
          ? day.toJson()
          : {
              'is_open': day.isOpen,
              'opening_time': day.openTime,
              'closing_time': day.closeTime,
              'max_guests_per_slot': day.maxGuests,
            };
      return {
        'day_name': day.day,
        'day_of_week': dayOrder[day.day] ?? 0,
        ...json,
      };
    }).toList();
    return {'schedule': list};
  }
}
