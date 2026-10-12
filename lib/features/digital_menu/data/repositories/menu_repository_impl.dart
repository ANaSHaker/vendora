import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/menu_entities.dart';
import '../../domain/repositories/menu_repository.dart';
import '../datasources/menu_firestore_datasource.dart';
import '../models/menu_models.dart';

class MenuRepositoryImpl implements MenuRepository {
  final MenuFirestoreDataSource _ds;
  const MenuRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, MenuSettings?>> getSettings(String vendorId) async {
    try {
      return Right(await _ds.getSettings(vendorId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MenuProductConfig>>> getProductConfigs(String vendorId) async {
    try {
      return Right(await _ds.getProductConfigs(vendorId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(MenuSettings settings) async {
    try {
      await _ds.saveSettings(MenuSettingsModel(
        vendorId: settings.vendorId,
        slug: settings.slug,
        menuName: settings.menuName,
        logoUrl: settings.logoUrl,
        primaryColor: settings.primaryColor,
        backgroundColor: settings.backgroundColor,
        textColor: settings.textColor,
        themeId: settings.themeId,
        phones: settings.phones,
        address: settings.address,
        description: settings.description,
        instagramUrl: settings.instagramUrl,
        whatsappNumber: settings.whatsappNumber,
        showPrices: settings.showPrices,
        currency: settings.currency,
        isActive: settings.isActive,
      ));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveProductConfigs(
    String vendorId,
    List<MenuProductConfig> configs,
  ) async {
    try {
      await _ds.saveProductConfigs(
        vendorId,
        configs.map(MenuProductConfigModel.fromConfig).toList(),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MenuSettings?>> getPublicMenuBySlug(String slug) async {
    try {
      return Right(await _ds.getMenuBySlug(slug));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MenuProductConfig>>> getPublicMenuProducts(String slug) async {
    try {
      return Right(await _ds.getMenuProductsBySlug(slug));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadLogo(
    String vendorId,
    List<int> bytes,
    String ext,
  ) async {
    try {
      final url = await _ds.uploadLogo(vendorId, Uint8List.fromList(bytes), ext);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
