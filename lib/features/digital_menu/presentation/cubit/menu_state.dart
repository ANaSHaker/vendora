import 'package:equatable/equatable.dart';
import '../../domain/entities/menu_entities.dart';

abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {
  const MenuInitial();
}

class MenuLoading extends MenuState {
  const MenuLoading();
}

class MenuLoaded extends MenuState {
  final MenuSettings settings;
  final List<MenuProductConfig> products;
  final bool isSaving;
  final bool isSaved;
  final String? error;
  final bool isUploadingLogo;

  const MenuLoaded({
    required this.settings,
    required this.products,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
    this.isUploadingLogo = false,
  });

  MenuLoaded copyWith({
    MenuSettings? settings,
    List<MenuProductConfig>? products,
    bool? isSaving,
    bool? isSaved,
    String? error,
    bool? isUploadingLogo,
    bool clearError = false,
    bool clearSaved = false,
  }) {
    return MenuLoaded(
      settings: settings ?? this.settings,
      products: products ?? this.products,
      isSaving: isSaving ?? this.isSaving,
      isSaved: clearSaved ? false : (isSaved ?? this.isSaved),
      error: clearError ? null : (error ?? this.error),
      isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
    );
  }

  @override
  List<Object?> get props =>
      [settings, products, isSaving, isSaved, error, isUploadingLogo];
}

class MenuError extends MenuState {
  final String message;
  const MenuError(this.message);
  @override
  List<Object?> get props => [message];
}
