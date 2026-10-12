import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sf_entities.dart';
import '../../domain/repositories/storefront_repository.dart';
import '../datasources/sf_remote_datasource.dart';
import '../models/sf_models.dart';

class StorefrontRepositoryImpl implements StorefrontRepository {
  final SfRemoteDataSource _ds;
  StorefrontRepositoryImpl(this._ds);

  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, (SfVendorInfo, List<SfHomepageSection>)>> getStorefront(
    String slug,
  ) => _wrap(() async {
    final body = await _ds.getStorefront(slug);
    final vendorJson   = body['data'] as Map<String, dynamic>? ?? body;
    final vendor       = SfVendorInfoModel.fromJson(vendorJson);

    final layoutJson   = body['layout'] as List<dynamic>?;
    final sections     = (layoutJson ?? [])
        .map((s) => SfHomepageSectionModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return (vendor as SfVendorInfo, sections as List<SfHomepageSection>);
  });

  @override
  Future<Either<Failure, List<SfCategory>>> getCategories(String slug) =>
      _wrap(() async {
        final list = await _ds.getCategories(slug);
        return list.map(SfCategoryModel.fromJson).toList();
      });

  @override
  Future<Either<Failure, List<SfProduct>>> getProducts(
    String slug, {String? search, String? categoryId, int page = 1}
  ) => _wrap(() async {
    final list = await _ds.getProducts(
      slug, search: search, categoryId: categoryId, page: page,
    );
    return list.map(SfProductModel.fromJson).toList();
  });

  @override
  Future<Either<Failure, SfProduct>> getProduct(String slug, String productId) =>
      _wrap(() async {
        final json = await _ds.getProduct(slug, productId);
        return SfProductModel.fromJson(json);
      });

  @override
  Future<Either<Failure, SfOrderResult>> placeOrder(
    String slug, Map<String, dynamic> payload,
  ) => _wrap(() async {
    final json = await _ds.placeOrder(slug, payload);
    return SfOrderResultModel.fromJson(json);
  });

  @override
  Future<Either<Failure, SfOrderStatus>> getOrderStatus(
    String slug, String reference,
  ) => _wrap(() async {
    final json = await _ds.getOrderStatus(slug, reference);
    return SfOrderStatusModel.fromJson(json);
  });

  @override
  Future<Either<Failure, void>> placeReservation(
    String slug, Map<String, dynamic> payload,
  ) => _wrap(() => _ds.placeReservation(slug, payload));

  @override
  Future<Either<Failure, SfVendorInfo>> getStorefrontSettings() =>
      _wrap(() async {
        final json = await _ds.getStorefrontSettings();
        return SfVendorInfoModel.fromJson(json);
      });

  @override
  Future<Either<Failure, void>> updateStorefrontSettings(Map<String, dynamic> payload) =>
      _wrap(() => _ds.updateStorefrontSettings(payload));
}
