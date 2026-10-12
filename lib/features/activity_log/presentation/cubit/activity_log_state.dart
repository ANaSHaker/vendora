import 'package:equatable/equatable.dart';
import '../../../../core/api/api_response.dart';
import '../../domain/entities/activity_log_entity.dart';

sealed class ActivityLogState extends Equatable {
  const ActivityLogState();

  @override
  List<Object?> get props => [];
}

class ActivityLogInitial extends ActivityLogState {
  const ActivityLogInitial();
}

class ActivityLogLoading extends ActivityLogState {
  const ActivityLogLoading();
}

class ActivityLogLoaded extends ActivityLogState {
  final List<ActivityLogEntry> entries;
  final PaginationMeta meta;
  final ActivityLogFilters filters;
  final List<ActivityLogUser> users;

  const ActivityLogLoaded({
    required this.entries,
    required this.meta,
    required this.filters,
    this.users = const [],
  });

  ActivityLogLoaded copyWith({
    List<ActivityLogEntry>? entries,
    PaginationMeta? meta,
    ActivityLogFilters? filters,
    List<ActivityLogUser>? users,
  }) {
    return ActivityLogLoaded(
      entries: entries ?? this.entries,
      meta: meta ?? this.meta,
      filters: filters ?? this.filters,
      users: users ?? this.users,
    );
  }

  @override
  List<Object?> get props => [entries, meta, filters, users];
}

class ActivityLogError extends ActivityLogState {
  final String message;

  const ActivityLogError(this.message);

  @override
  List<Object?> get props => [message];
}
