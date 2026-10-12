import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/menu_entities.dart';
import '../repositories/menu_repository.dart';

class GetMenuSettingsUseCase {
  final MenuRepository _repo;
  const GetMenuSettingsUseCase(this._repo);
  Future<Either<Failure, MenuSettings?>> call(String vendorId) => _repo.getSettings(vendorId);
}

class GetMenuProductConfigsUseCase {
  final MenuRepository _repo;
  const GetMenuProductConfigsUseCase(this._repo);
  Future<Either<Failure, List<MenuProductConfig>>> call(String vendorId) =>
      _repo.getProductConfigs(vendorId);
}

class SaveMenuSettingsUseCase {
  final MenuRepository _repo;
  const SaveMenuSettingsUseCase(this._repo);
  Future<Either<Failure, void>> call(MenuSettings settings) => _repo.saveSettings(settings);
}

class SaveMenuProductConfigsUseCase {
  final MenuRepository _repo;
  const SaveMenuProductConfigsUseCase(this._repo);
  Future<Either<Failure, void>> call(String vendorId, List<MenuProductConfig> configs) =>
      _repo.saveProductConfigs(vendorId, configs);
}

class GetPublicMenuBySlugUseCase {
  final MenuRepository _repo;
  const GetPublicMenuBySlugUseCase(this._repo);
  Future<Either<Failure, MenuSettings?>> call(String slug) => _repo.getPublicMenuBySlug(slug);
}

class GetPublicMenuProductsUseCase {
  final MenuRepository _repo;
  const GetPublicMenuProductsUseCase(this._repo);
  Future<Either<Failure, List<MenuProductConfig>>> call(String slug) =>
      _repo.getPublicMenuProducts(slug);
}

class UploadMenuLogoUseCase {
  final MenuRepository _repo;
  const UploadMenuLogoUseCase(this._repo);
  Future<Either<Failure, String>> call(String vendorId, List<int> bytes, String ext) =>
      _repo.uploadLogo(vendorId, bytes, ext);
}
