import 'package:equatable/equatable.dart';

class ActivityLogEntry extends Equatable {
  final String id;
  final String action;
  final String? entity;
  final String? entityId;
  final ActivityLogCauser? causer;
  final String? ip;
  final String createdAt;

  const ActivityLogEntry({
    required this.id,
    required this.action,
    this.entity,
    this.entityId,
    this.causer,
    this.ip,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, action, entity, entityId, causer, ip, createdAt];
}

class ActivityLogCauser extends Equatable {
  final String name;
  final String? email;

  const ActivityLogCauser({required this.name, this.email});

  @override
  List<Object?> get props => [name, email];
}

class ActivityLogUser extends Equatable {
  final String id;
  final String name;
  final String? email;

  const ActivityLogUser({
    required this.id,
    required this.name,
    this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}

class ActivityLogFilters extends Equatable {
  final String? userId;
  final String? action;
  final String? dateFrom;
  final String? dateTo;
  final int page;
  final int perPage;

  const ActivityLogFilters({
    this.userId,
    this.action,
    this.dateFrom,
    this.dateTo,
    this.page = 1,
    this.perPage = 20,
  });

  ActivityLogFilters copyWith({
    String? Function()? userId,
    String? Function()? action,
    String? Function()? dateFrom,
    String? Function()? dateTo,
    int? page,
    int? perPage,
  }) {
    return ActivityLogFilters(
      userId: userId != null ? userId() : this.userId,
      action: action != null ? action() : this.action,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
    );
  }

  @override
  List<Object?> get props => [userId, action, dateFrom, dateTo, page, perPage];
}
