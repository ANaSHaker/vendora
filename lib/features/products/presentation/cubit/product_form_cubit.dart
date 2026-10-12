import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_entities.dart';
import '../../domain/usecases/products_usecases.dart';
import 'product_form_state.dart';

class ProductFormCubit extends Cubit<ProductFormState> {
  final CreateProductUseCase _create;
  final UpdateProductUseCase _update;

  final String? editingId;

  ProductFormCubit({
    required CreateProductUseCase create,
    required UpdateProductUseCase update,
    ProductEntity? editing,
  })  : _create = create,
        _update = update,
        editingId = editing?.id,
        super(editing != null
            ? ProductFormState.fromEntity(editing)
            : const ProductFormState());

  bool get isEditing => editingId != null;

  void setName(String v) => emit(state.copyWith(name: v, errors: {}));
  void setSku(String v) => emit(state.copyWith(sku: v));
  void setBarcode(String v) => emit(state.copyWith(barcode: v));
  void setPrice(String v) => emit(state.copyWith(price: v, errors: {}));
  void setCategory(String? v) => emit(state.copyWith(categoryId: () => v));
  void setDescription(String v) => emit(state.copyWith(description: v));
  void setIsOnline(bool v) => emit(state.copyWith(isOnline: v));
  void setIsPublished(bool v) => emit(state.copyWith(isPublished: v));
  void setIsFeatured(bool v) => emit(state.copyWith(isFeatured: v));
  void setUnit(String v) => emit(state.copyWith(unit: v));
  void setTrackStock(bool v) => emit(state.copyWith(trackStock: v));
  void setImageBytes(List<int>? v) => emit(state.copyWith(imageBytes: () => v));
  void clearImage() => emit(state.copyWith(imageBytes: () => null, existingImageUrl: () => null));

  Future<bool> submit() async {
    if (!_validate()) return false;

    emit(state.copyWith(
      status: ProductFormStatus.submitting,
      serverError: () => null,
    ));

    final data = state.toFormData();
    final result = isEditing
        ? await _update(editingId!, data)
        : await _create(data);

    if (isClosed) return false;
    return result.fold(
      (failure) {
        final errors = <String, String>{};
        if (failure is ValidationFailure) {
          errors.addAll(failure.errors?.map(
                (k, v) => MapEntry(k, (v as List).first.toString()),
              ) ??
              {});
        }
        emit(state.copyWith(
          status: ProductFormStatus.error,
          errors: errors,
          serverError: () => failure.message,
        ));
        return false;
      },
      (_) {
        emit(state.copyWith(status: ProductFormStatus.success));
        return true;
      },
    );
  }

  bool _validate() {
    final errors = <String, String>{};
    if (state.name.trim().isEmpty) {
      errors['name'] = 'Product name is required';
    }
    final price = double.tryParse(state.price);
    if (price == null || price < 0) {
      errors['price'] = 'Enter a valid price';
    }
    if (errors.isNotEmpty) {
      emit(state.copyWith(errors: errors));
      return false;
    }
    return true;
  }
}
