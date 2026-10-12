import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/sf_entities.dart';

abstract class StorefrontRepository {
  Future<Either<Failure, (SfVendorInfo, List<SfHomepageSection>)>> getStorefront(String slug);
  Future<Either<Failure, List<SfCategory>>>   getCategories(String slug);
  Future<Either<Failure, List<SfProduct>>>    getProducts(String slug, {String? search, String? categoryId, int page});
  Future<Either<Failure, SfProduct>>          getProduct(String slug, String productId);
  Future<Either<Failure, SfOrderResult>>      placeOrder(String slug, Map<String, dynamic> payload);
  Future<Either<Failure, SfOrderStatus>>      getOrderStatus(String slug, String reference);
  Future<Either<Failure, void>>               placeReservation(String slug, Map<String, dynamic> payload);

  // Dashboard: vendor storefront settings (authenticated)
  Future<Either<Failure, SfVendorInfo>>       getStorefrontSettings();
  Future<Either<Failure, void>>               updateStorefrontSettings(Map<String, dynamic> payload);
}
