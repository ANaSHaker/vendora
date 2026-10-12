import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/device_session_entity.dart';

abstract class DevicesRepository {
  Future<Either<Failure, List<DeviceSessionEntity>>> getSessions();
  Future<Either<Failure, void>> logoutDevice(String id);
  Future<Either<Failure, void>> logoutAllDevices();
  Future<Either<Failure, void>> blockDevice(String id);
}
