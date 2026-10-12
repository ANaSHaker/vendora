import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/homepage_builder_entities.dart';

abstract class HomepageBuilderRepository {
  Future<Either<Failure, List<HomepageSection>>> getLayout();
  Future<Either<Failure, void>> saveLayout(List<HomepageSection> sections);
}
