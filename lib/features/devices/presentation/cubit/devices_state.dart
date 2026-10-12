import '../../domain/entities/device_session_entity.dart';

sealed class DevicesState {
  const DevicesState();
}

class DevicesInitial extends DevicesState {
  const DevicesInitial();
}

class DevicesLoading extends DevicesState {
  const DevicesLoading();
}

class DevicesLoaded extends DevicesState {
  final List<DeviceSessionEntity> sessions;
  const DevicesLoaded(this.sessions);
}

class DevicesError extends DevicesState {
  final String message;
  const DevicesError(this.message);
}
