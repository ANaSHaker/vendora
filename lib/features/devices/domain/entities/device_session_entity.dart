class DeviceSessionEntity {
  final String id;
  final String device;
  final String userAgent;
  final String userName;
  final String userEmail;
  final String location;
  final String ipAddress;
  final String lastLoginAt;
  final bool isActive;
  final bool isCurrent;
  final bool isBlocked;
  final bool isExpired;

  const DeviceSessionEntity({
    required this.id,
    required this.device,
    required this.userAgent,
    required this.userName,
    required this.userEmail,
    required this.location,
    required this.ipAddress,
    required this.lastLoginAt,
    required this.isActive,
    required this.isCurrent,
    required this.isBlocked,
    required this.isExpired,
  });
}
