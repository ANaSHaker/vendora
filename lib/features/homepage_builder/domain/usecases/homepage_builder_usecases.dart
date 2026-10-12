import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/homepage_builder_entities.dart';
import '../repositories/homepage_builder_repository.dart';

class GetHomepageLayoutUseCase {
  final HomepageBuilderRepository _repo;
  const GetHomepageLayoutUseCase(this._repo);
  Future<Either<Failure, List<HomepageSection>>> call() => _repo.getLayout();
}

class SaveHomepageLayoutUseCase {
  final HomepageBuilderRepository _repo;
  const SaveHomepageLayoutUseCase(this._repo);
  Future<Either<Failure, void>> call(List<HomepageSection> sections) =>
      _repo.saveLayout(sections);
}
