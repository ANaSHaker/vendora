import '../../domain/entities/device_session_entity.dart';

class DeviceSessionModel extends DeviceSessionEntity {
  const DeviceSessionModel({
    required super.id,
    required super.device,
    required super.userAgent,
    required super.userName,
    required super.userEmail,
    required super.location,
    required super.ipAddress,
    required super.lastLoginAt,
    required super.isActive,
    required super.isCurrent,
    required super.isBlocked,
    required super.isExpired,
  });

  factory DeviceSessionModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? {};

    final city = json['city'] as String? ?? '';
    final country = json['country'] as String? ?? '';
    final locationParts = [city, country].where((s) => s.isNotEmpty).toList();
    final location = locationParts.isNotEmpty
        ? locationParts.join(', ')
        : json['location'] as String? ?? '';

    return DeviceSessionModel(
      id: json['id']?.toString() ?? '',
      device: json['device'] as String? ?? json['device_name'] as String? ?? '',
      userAgent: json['user_agent'] as String? ?? '',
      userName: user['name'] as String? ?? json['user_name'] as String? ?? '',
      userEmail: user['email'] as String? ?? json['user_email'] as String? ?? '',
      location: location,
      ipAddress: json['ip_address'] as String? ?? json['ip'] as String? ?? '',
      lastLoginAt: json['last_login_at'] as String? ??
          json['last_active_at'] as String? ??
          json['created_at'] as String? ??
          '',
      isActive: json['is_active'] as bool? ?? true,
      isCurrent: json['is_current_device'] as bool? ??
          json['is_current'] as bool? ??
          json['current_device'] as bool? ??
          false,
      isBlocked: json['is_blocked'] as bool? ?? false,
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }
}
