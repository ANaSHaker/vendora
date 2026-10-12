import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/store_settings_entity.dart';
import '../repositories/store_settings_repository.dart';

class GetStoreSettingsUseCase {
  final StoreSettingsRepository _repo;
  const GetStoreSettingsUseCase(this._repo);

  Future<Either<Failure, StoreSettingsEntity>> call() =>
      _repo.getStoreSettings();
}

class UpdateStoreSettingsUseCase {
  final StoreSettingsRepository _repo;
  const UpdateStoreSettingsUseCase(this._repo);

  Future<Either<Failure, StoreSettingsEntity>> call(
          Map<String, dynamic> data) =>
      _repo.updateStoreSettings(data);
}
