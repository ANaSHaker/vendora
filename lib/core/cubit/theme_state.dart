part of 'theme_cubit.dart';

class ThemeState extends Equatable {
  final ThemeMode mode;
  final AppColorPreset preset;
  final String posDefaultStatus;

  const ThemeState({
    this.mode = ThemeMode.light,
    this.preset = AppColorPreset.navy,
    this.posDefaultStatus = 'completed',
  });

  Color get primaryColor => preset.primary;

  ThemeState copyWith({
    ThemeMode? mode,
    AppColorPreset? preset,
    String? posDefaultStatus,
  }) =>
      ThemeState(
        mode: mode ?? this.mode,
        preset: preset ?? this.preset,
        posDefaultStatus: posDefaultStatus ?? this.posDefaultStatus,
      );

  @override
  List<Object> get props => [mode, preset, posDefaultStatus];
}
