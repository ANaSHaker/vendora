import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/device_session_entity.dart';
import '../repositories/devices_repository.dart';

class GetDeviceSessionsUseCase {
  final DevicesRepository _repo;
  const GetDeviceSessionsUseCase(this._repo);
  Future<Either<Failure, List<DeviceSessionEntity>>> call() =>
      _repo.getSessions();
}

class LogoutDeviceUseCase {
  final DevicesRepository _repo;
  const LogoutDeviceUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.logoutDevice(id);
}

class LogoutAllDevicesUseCase {
  final DevicesRepository _repo;
  const LogoutAllDevicesUseCase(this._repo);
  Future<Either<Failure, void>> call() => _repo.logoutAllDevices();
}

class BlockDeviceUseCase {
  final DevicesRepository _repo;
  const BlockDeviceUseCase(this._repo);
  Future<Either<Failure, void>> call(String id) => _repo.blockDevice(id);
}
