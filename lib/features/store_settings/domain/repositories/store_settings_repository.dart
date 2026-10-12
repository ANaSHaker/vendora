import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store_settings_entity.dart';

abstract class StoreSettingsRepository {
  Future<Either<Failure, StoreSettingsEntity>> getStoreSettings();
  Future<Either<Failure, StoreSettingsEntity>> updateStoreSettings(
      Map<String, dynamic> data);
}
