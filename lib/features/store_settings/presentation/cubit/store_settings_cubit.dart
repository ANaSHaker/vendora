import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/store_settings_usecases.dart';
import 'store_settings_state.dart';

class StoreSettingsCubit extends Cubit<StoreSettingsState> {
  final GetStoreSettingsUseCase _get;
  final UpdateStoreSettingsUseCase _update;

  StoreSettingsCubit({
    required GetStoreSettingsUseCase getStoreSettings,
    required UpdateStoreSettingsUseCase updateStoreSettings,
  })  : _get = getStoreSettings,
        _update = updateStoreSettings,
        super(const StoreSettingsInitial());

  Future<void> load() async {
    emit(const StoreSettingsLoading());
    final result = await _get();
    if (isClosed) return;
    result.fold(
      (failure) => emit(StoreSettingsError(failure.message)),
      (settings) => emit(StoreSettingsLoaded(settings: settings)),
    );
  }

  Future<bool> save(Map<String, dynamic> data) async {
    final s = state;
    if (s is! StoreSettingsLoaded) return false;
    if (s.isSaving) return false;

    emit(s.copyWith(isSaving: true, saveSuccess: false));
    final result = await _update(data);
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(s.copyWith(isSaving: false));
        return false;
      },
      (updated) {
        emit(StoreSettingsLoaded(
          settings: updated,
          isSaving: false,
          saveSuccess: true,
        ));
        return true;
      },
    );
  }
}
