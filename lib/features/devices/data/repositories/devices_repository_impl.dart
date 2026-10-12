import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/device_session_entity.dart';
import '../../domain/repositories/devices_repository.dart';
import '../datasources/devices_remote_datasource.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  final DevicesRemoteDataSource _ds;
  const DevicesRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<DeviceSessionEntity>>> getSessions() async {
    try {
      return Right(await _ds.getSessions());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logoutDevice(String id) async {
    try {
      await _ds.logoutDevice(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logoutAllDevices() async {
    try {
      await _ds.logoutAllDevices();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> blockDevice(String id) async {
    try {
      await _ds.blockDevice(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
