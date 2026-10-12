import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sf_entities.dart';
import '../repositories/storefront_repository.dart';

class GetStorefrontUseCase {
  final StorefrontRepository repo;
  GetStorefrontUseCase(this.repo);
  Future<Either<Failure, (SfVendorInfo, List<SfHomepageSection>)>> call(String slug) =>
      repo.getStorefront(slug);
}

class GetSfCategoriesUseCase {
  final StorefrontRepository repo;
  GetSfCategoriesUseCase(this.repo);
  Future<Either<Failure, List<SfCategory>>> call(String slug) =>
      repo.getCategories(slug);
}

class GetSfProductsUseCase {
  final StorefrontRepository repo;
  GetSfProductsUseCase(this.repo);
  Future<Either<Failure, List<SfProduct>>> call(
    String slug, {String? search, String? categoryId, int page = 1}
  ) => repo.getProducts(slug, search: search, categoryId: categoryId, page: page);
}

class GetSfProductUseCase {
  final StorefrontRepository repo;
  GetSfProductUseCase(this.repo);
  Future<Either<Failure, SfProduct>> call(String slug, String productId) =>
      repo.getProduct(slug, productId);
}

class PlaceSfOrderUseCase {
  final StorefrontRepository repo;
  PlaceSfOrderUseCase(this.repo);
  Future<Either<Failure, SfOrderResult>> call(String slug, Map<String, dynamic> payload) =>
      repo.placeOrder(slug, payload);
}

class GetSfOrderStatusUseCase {
  final StorefrontRepository repo;
  GetSfOrderStatusUseCase(this.repo);
  Future<Either<Failure, SfOrderStatus>> call(String slug, String reference) =>
      repo.getOrderStatus(slug, reference);
}

class PlaceSfReservationUseCase {
  final StorefrontRepository repo;
  PlaceSfReservationUseCase(this.repo);
  Future<Either<Failure, void>> call(String slug, Map<String, dynamic> payload) =>
      repo.placeReservation(slug, payload);
}

class GetStorefrontSettingsUseCase {
  final StorefrontRepository repo;
  GetStorefrontSettingsUseCase(this.repo);
  Future<Either<Failure, SfVendorInfo>> call() => repo.getStorefrontSettings();
}

class UpdateStorefrontSettingsUseCase {
  final StorefrontRepository repo;
  UpdateStorefrontSettingsUseCase(this.repo);
  Future<Either<Failure, void>> call(Map<String, dynamic> payload) =>
      repo.updateStorefrontSettings(payload);
}
