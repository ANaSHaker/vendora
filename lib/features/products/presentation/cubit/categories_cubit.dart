import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/file_saver.dart';
import '../../domain/entities/product_entities.dart';
import '../../domain/usecases/products_usecases.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  final GetCategoriesUseCase _getCategories;
  final CreateCategoryUseCase _createCategory;
  final UpdateCategoryUseCase _updateCategory;
  final DeleteCategoryUseCase _deleteCategory;
  final ExportCategoriesUseCase _exportCategories;
  final ImportCategoriesUseCase _importCategories;

  CategoriesCubit({
    required GetCategoriesUseCase getCategories,
    required CreateCategoryUseCase createCategory,
    required UpdateCategoryUseCase updateCategory,
    required DeleteCategoryUseCase deleteCategory,
    required ExportCategoriesUseCase exportCategories,
    required ImportCategoriesUseCase importCategories,
  })  : _getCategories = getCategories,
        _createCategory = createCategory,
        _updateCategory = updateCategory,
        _deleteCategory = deleteCategory,
        _exportCategories = exportCategories,
        _importCategories = importCategories,
        super(const CategoriesInitial());

  Future<void> load() async {
    emit(const CategoriesLoading());
    final result = await _getCategories();
    if (isClosed) return;
    result.fold(
      (f) => emit(CategoriesError(f.message)),
      (cats) => emit(CategoriesLoaded(cats)),
    );
  }

  Future<bool> createCategory(CategoryFormData data) async {
    final result = await _createCategory(data);
    if (isClosed) return false;
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> updateCategory(String id, CategoryFormData data) async {
    final result = await _updateCategory(id, data);
    if (isClosed) return false;
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<bool> deleteCategory(String id) async {
    final result = await _deleteCategory(id);
    if (isClosed) return false;
    return result.fold((_) => false, (_) {
      load();
      return true;
    });
  }

  Future<String?> exportFile({bool template = false}) async {
    final result = await _exportCategories(template: template);
    return result.fold(
      (_) => null,
      (bytes) => saveExportFile(
        bytes,
        template ? 'categories-template.xlsx' : 'categories-export.xlsx',
      ),
    );
  }

  Future<Map<String, dynamic>?> importFile(
    List<int> bytes,
    String filename, {
    String duplicateMode = 'skip',
  }) async {
    final result = await _importCategories(bytes, filename,
        duplicateMode: duplicateMode);
    return result.fold((_) => null, (data) {
      load();
      return data;
    });
  }
}
