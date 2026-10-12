import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../design_system/theme/app_color_presets.dart';
import '../storage/local_storage.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  final LocalStorage _storage;

  ThemeCubit(this._storage)
      : super(ThemeState(
          mode: _storage.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
          preset: AppColorPreset.fromKey(_storage.colorPreset),
          posDefaultStatus: _storage.posDefaultStatus,
        ));

  void setMode(ThemeMode mode) {
    _storage.saveThemeMode(mode == ThemeMode.dark ? 'dark' : 'light');
    emit(state.copyWith(mode: mode));
  }

  void toggle() =>
      setMode(state.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);

  void setPreset(AppColorPreset preset) {
    _storage.saveColorPreset(preset.name);
    emit(state.copyWith(preset: preset));
  }

  void setPosDefaultStatus(String status) {
    _storage.savePosDefaultStatus(status);
    emit(state.copyWith(posDefaultStatus: status));
  }

  /// Applies and persists all settings at once (used by ThemePickerDialog).
  void applySettings(ThemeState settings) {
    _storage.saveThemeMode(settings.mode == ThemeMode.dark ? 'dark' : 'light');
    _storage.saveColorPreset(settings.preset.name);
    _storage.savePosDefaultStatus(settings.posDefaultStatus);
    emit(settings);
  }
}
