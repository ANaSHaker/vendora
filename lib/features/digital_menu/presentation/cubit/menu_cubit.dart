import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../features/products/domain/usecases/products_usecases.dart';
import '../../data/models/menu_models.dart';
import '../../domain/entities/menu_entities.dart';
import '../../domain/usecases/menu_usecases.dart';
import 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  final GetMenuSettingsUseCase _getSettings;
  final GetMenuProductConfigsUseCase _getProductConfigs;
  final SaveMenuSettingsUseCase _saveSettings;
  final SaveMenuProductConfigsUseCase _saveProductConfigs;
  final UploadMenuLogoUseCase _uploadLogo;
  final GetProductsUseCase _getProducts;
  final SecureStorage _secureStorage;

  MenuCubit({
    required GetMenuSettingsUseCase getSettings,
    required GetMenuProductConfigsUseCase getProductConfigs,
    required SaveMenuSettingsUseCase saveSettings,
    required SaveMenuProductConfigsUseCase saveProductConfigs,
    required UploadMenuLogoUseCase uploadLogo,
    required GetProductsUseCase getProducts,
    required SecureStorage secureStorage,
  })  : _getSettings = getSettings,
        _getProductConfigs = getProductConfigs,
        _saveSettings = saveSettings,
        _saveProductConfigs = saveProductConfigs,
        _uploadLogo = uploadLogo,
        _getProducts = getProducts,
        _secureStorage = secureStorage,
        super(const MenuInitial());

  Future<void> load() async {
    emit(const MenuLoading());

    final vendorId = await _secureStorage.getUserId();
    if (vendorId == null) {
      emit(const MenuError('User not found — please log in again'));
      return;
    }

    final settingsResult = await _getSettings(vendorId);
    final configsResult = await _getProductConfigs(vendorId);
    final productsResult = await _getProducts(perPage: 500);

    final settings = settingsResult.fold<MenuSettings>(
      (_) => MenuSettingsModel.defaultFor(vendorId),
      (s) => s ?? MenuSettingsModel.defaultFor(vendorId),
    );

    final firestoreConfigs = configsResult.fold<List<MenuProductConfig>>(
      (_) => [],
      (c) => c,
    );

    final backendProducts = productsResult.fold(
      (_) => <dynamic>[],
      (r) => r.data,
    );

    final configMap = {for (final c in firestoreConfigs) c.productId: c};
    final merged = <MenuProductConfig>[];

    for (var i = 0; i < backendProducts.length; i++) {
      final product = backendProducts[i];
      if (configMap.containsKey(product.id)) {
        merged.add(configMap[product.id]!.copyWith(
          productName: product.name,
          productImage: product.imageUrl,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
          originalPrice: product.price,
        ));
      } else {
        merged.add(MenuProductConfigModel.fromProduct(product, i));
      }
    }

    emit(MenuLoaded(settings: settings, products: merged));
  }

  void updateSettings(MenuSettings Function(MenuSettings) updater) {
    final s = state;
    if (s is! MenuLoaded) return;
    emit(s.copyWith(settings: updater(s.settings), clearSaved: true));
  }

  void toggleProduct(String productId) {
    final s = state;
    if (s is! MenuLoaded) return;
    final updated = s.products.map((p) {
      return p.productId == productId ? p.copyWith(isVisible: !p.isVisible) : p;
    }).toList();
    emit(s.copyWith(products: updated, clearSaved: true));
  }

  void updateMenuPrice(String productId, double? price) {
    final s = state;
    if (s is! MenuLoaded) return;
    final updated = s.products.map((p) {
      if (p.productId != productId) return p;
      return p.copyWith(menuPrice: price, clearMenuPrice: price == null);
    }).toList();
    emit(s.copyWith(products: updated, clearSaved: true));
  }

  Future<void> save() async {
    final s = state;
    if (s is! MenuLoaded) return;

    emit(s.copyWith(isSaving: true, clearError: true));

    final settingsRes = await _saveSettings(s.settings);
    if (settingsRes.isLeft()) {
      emit(s.copyWith(
        isSaving: false,
        error: settingsRes.fold((l) => l.message, (_) => ''),
      ));
      return;
    }

    final productsRes = await _saveProductConfigs(s.settings.vendorId, s.products);
    if (productsRes.isLeft()) {
      emit(s.copyWith(
        isSaving: false,
        error: productsRes.fold((l) => l.message, (_) => ''),
      ));
      return;
    }

    emit(s.copyWith(isSaving: false, isSaved: true, clearError: true));

    await Future.delayed(const Duration(seconds: 3));
    if (state is MenuLoaded) {
      emit((state as MenuLoaded).copyWith(clearSaved: true));
    }
  }

  Future<void> uploadLogo(Uint8List bytes, String ext) async {
    final s = state;
    if (s is! MenuLoaded) return;

    emit(s.copyWith(isUploadingLogo: true));

    final result = await _uploadLogo(s.settings.vendorId, bytes.toList(), ext);

    result.fold(
      (failure) => emit(s.copyWith(isUploadingLogo: false, error: failure.message)),
      (url) => emit(s.copyWith(
        settings: s.settings.copyWith(logoUrl: url),
        isUploadingLogo: false,
      )),
    );
  }

  void removeLogo() {
    final s = state;
    if (s is! MenuLoaded) return;
    emit(s.copyWith(settings: s.settings.copyWith(clearLogo: true), clearSaved: true));
  }
}
