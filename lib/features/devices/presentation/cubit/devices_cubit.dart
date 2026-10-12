import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/devices_usecases.dart';
import 'devices_state.dart';

class DevicesCubit extends Cubit<DevicesState> {
  final GetDeviceSessionsUseCase _getSessions;
  final LogoutDeviceUseCase _logoutDevice;
  final LogoutAllDevicesUseCase _logoutAll;
  final BlockDeviceUseCase _blockDevice;

  DevicesCubit({
    required GetDeviceSessionsUseCase getSessions,
    required LogoutDeviceUseCase logoutDevice,
    required LogoutAllDevicesUseCase logoutAll,
    required BlockDeviceUseCase blockDevice,
  })  : _getSessions = getSessions,
        _logoutDevice = logoutDevice,
        _logoutAll = logoutAll,
        _blockDevice = blockDevice,
        super(const DevicesInitial());

  Future<void> load() async {
    emit(const DevicesLoading());
    final result = await _getSessions();
    result.fold(
      (f) => emit(DevicesError(f.message)),
      (sessions) => emit(DevicesLoaded(sessions)),
    );
  }

  Future<bool> logoutDevice(String id) async {
    final result = await _logoutDevice(id);
    return result.fold(
      (_) => false,
      (_) {
        load();
        return true;
      },
    );
  }

  Future<bool> logoutAll() async {
    final result = await _logoutAll();
    return result.fold(
      (_) => false,
      (_) {
        load();
        return true;
      },
    );
  }

  Future<bool> blockDevice(String id) async {
    final result = await _blockDevice(id);
    return result.fold(
      (_) => false,
      (_) {
        load();
        return true;
      },
    );
  }
}
