import 'package:equatable/equatable.dart';
import '../../domain/entities/product_entities.dart';

enum ProductFormStatus { idle, submitting, success, error }

class ProductFormState extends Equatable {
  final ProductFormStatus status;
  final String name;
  final String sku;
  final String barcode;
  final String price;
  final String? categoryId;
  final String description;
  final bool isOnline;
  final bool isPublished;
  final bool isFeatured;
  final String unit;
  final bool trackStock;
  final List<int>? imageBytes;
  final String? existingImageUrl;
  final Map<String, String> errors;
  final String? serverError;

  const ProductFormState({
    this.status = ProductFormStatus.idle,
    this.name = '',
    this.sku = '',
    this.barcode = '',
    this.price = '',
    this.categoryId,
    this.description = '',
    this.isOnline = false,
    this.isPublished = false,
    this.isFeatured = false,
    this.unit = '',
    this.trackStock = false,
    this.imageBytes,
    this.existingImageUrl,
    this.errors = const {},
    this.serverError,
  });

  factory ProductFormState.fromEntity(ProductEntity product) {
    return ProductFormState(
      name: product.name,
      sku: product.sku ?? '',
      barcode: product.barcode ?? '',
      price: product.price.toStringAsFixed(2),
      categoryId: product.categoryId,
      description: product.description ?? '',
      isOnline: product.isOnline,
      isPublished: product.isPublished,
      isFeatured: product.isFeatured,
      unit: product.unit ?? '',
      trackStock: product.trackStock,
      existingImageUrl: product.imageUrl,
    );
  }

  bool get isEditing => false;

  bool get isValid {
    if (name.trim().isEmpty) return false;
    final p = double.tryParse(price);
    return p != null && p >= 0;
  }

  ProductFormData toFormData() => ProductFormData(
        name: name.trim(),
        sku: sku.trim().isEmpty ? null : sku.trim(),
        barcode: barcode.trim().isEmpty ? null : barcode.trim(),
        price: double.tryParse(price) ?? 0,
        categoryId: categoryId,
        description: description.trim().isEmpty ? null : description.trim(),
        isOnline: isOnline,
        isPublished: isPublished,
        isFeatured: isFeatured,
        unit: unit.trim().isEmpty ? null : unit.trim(),
        trackStock: trackStock,
        imageBytes: imageBytes,
      );

  ProductFormState copyWith({
    ProductFormStatus? status,
    String? name,
    String? sku,
    String? barcode,
    String? price,
    String? Function()? categoryId,
    String? description,
    bool? isOnline,
    bool? isPublished,
    bool? isFeatured,
    String? unit,
    bool? trackStock,
    List<int>? Function()? imageBytes,
    String? Function()? existingImageUrl,
    Map<String, String>? errors,
    String? Function()? serverError,
  }) {
    return ProductFormState(
      status: status ?? this.status,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      description: description ?? this.description,
      isOnline: isOnline ?? this.isOnline,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      unit: unit ?? this.unit,
      trackStock: trackStock ?? this.trackStock,
      imageBytes: imageBytes != null ? imageBytes() : this.imageBytes,
      existingImageUrl: existingImageUrl != null ? existingImageUrl() : this.existingImageUrl,
      errors: errors ?? this.errors,
      serverError: serverError != null ? serverError() : this.serverError,
    );
  }

  @override
  List<Object?> get props => [
        status, name, sku, barcode, price, categoryId, description,
        isOnline, isPublished, isFeatured, unit, trackStock,
        errors, serverError,
      ];
}
