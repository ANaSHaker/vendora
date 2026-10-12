import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/menu_entities.dart';

abstract class MenuRepository {
  Future<Either<Failure, MenuSettings?>> getSettings(String vendorId);
  Future<Either<Failure, List<MenuProductConfig>>> getProductConfigs(String vendorId);
  Future<Either<Failure, void>> saveSettings(MenuSettings settings);
  Future<Either<Failure, void>> saveProductConfigs(String vendorId, List<MenuProductConfig> configs);
  Future<Either<Failure, MenuSettings?>> getPublicMenuBySlug(String slug);
  Future<Either<Failure, List<MenuProductConfig>>> getPublicMenuProducts(String slug);
  Future<Either<Failure, String>> uploadLogo(String vendorId, List<int> bytes, String ext);
}
