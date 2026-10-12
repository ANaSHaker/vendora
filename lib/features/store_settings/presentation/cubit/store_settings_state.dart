import 'package:equatable/equatable.dart';
import '../../domain/entities/store_settings_entity.dart';

abstract class StoreSettingsState extends Equatable {
  const StoreSettingsState();

  @override
  List<Object?> get props => [];
}

class StoreSettingsInitial extends StoreSettingsState {
  const StoreSettingsInitial();
}

class StoreSettingsLoading extends StoreSettingsState {
  const StoreSettingsLoading();
}

class StoreSettingsLoaded extends StoreSettingsState {
  final StoreSettingsEntity settings;
  final bool isSaving;
  final bool saveSuccess;

  const StoreSettingsLoaded({
    required this.settings,
    this.isSaving = false,
    this.saveSuccess = false,
  });

  StoreSettingsLoaded copyWith({
    StoreSettingsEntity? settings,
    bool? isSaving,
    bool? saveSuccess,
  }) =>
      StoreSettingsLoaded(
        settings: settings ?? this.settings,
        isSaving: isSaving ?? this.isSaving,
        saveSuccess: saveSuccess ?? this.saveSuccess,
      );

  @override
  List<Object?> get props => [settings, isSaving, saveSuccess];
}

class StoreSettingsError extends StoreSettingsState {
  final String message;
  const StoreSettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
