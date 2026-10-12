import '../../domain/entities/activity_log_entity.dart';

class ActivityLogEntryModel extends ActivityLogEntry {
  const ActivityLogEntryModel({
    required super.id,
    required super.action,
    super.entity,
    super.entityId,
    super.causer,
    super.ip,
    required super.createdAt,
  });

  factory ActivityLogEntryModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>?;

    return ActivityLogEntryModel(
      id: json['id']?.toString() ?? '',
      action: json['action'] as String? ?? '',
      entity: json['entity'] as String?,
      entityId: json['entity_id']?.toString(),
      causer: userJson != null ? ActivityLogCauserModel.fromJson(userJson) : null,
      ip: json['ip_address'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class ActivityLogCauserModel extends ActivityLogCauser {
  const ActivityLogCauserModel({required super.name, super.email});

  factory ActivityLogCauserModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogCauserModel(
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
}

class ActivityLogUserModel extends ActivityLogUser {
  const ActivityLogUserModel({
    required super.id,
    required super.name,
    super.email,
  });

  factory ActivityLogUserModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String?,
    );
  }
}
