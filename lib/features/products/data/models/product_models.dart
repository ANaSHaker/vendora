import '../../domain/entities/product_entities.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.sku,
    super.barcode,
    required super.price,
    super.categoryId,
    super.categoryName,
    super.stock,
    super.isActive,
    super.isOnline,
    super.isPublished,
    super.isFeatured,
    super.imageUrl,
    super.description,
    super.unit,
    super.trackStock,
    super.hasOptions,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final rawPrice = json['price'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '0') ?? 0.0;

    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      price: price,
      categoryId: category?['id'] as String? ?? json['category_id'] as String?,
      categoryName: category?['name'] as String?,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isOnline: json['is_online'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      imageUrl: json['image_url'] as String?
          ?? json['image'] as String?
          ?? json['thumbnail'] as String?
          ?? json['photo'] as String?,
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      trackStock: json['track_stock'] as bool? ?? false,
      hasOptions: json['has_options'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson(ProductFormData data) => {
        'name': data.name,
        if (data.sku != null && data.sku!.isNotEmpty) 'sku': data.sku,
        if (data.barcode != null && data.barcode!.isNotEmpty)
          'barcode': data.barcode,
        'price': data.price,
        if (data.categoryId != null) 'category_id': data.categoryId,
        if (data.description != null && data.description!.isNotEmpty)
          'description': data.description,
        'is_online': data.isOnline,
        'is_published': data.isPublished,
        'is_featured': data.isFeatured,
        if (data.unit != null && data.unit!.isNotEmpty) 'unit': data.unit,
        'track_stock': data.trackStock,
      };
}

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    super.parentId,
    super.parentName,
    super.productCount,
    super.sortOrder,
    super.isActive,
    super.children,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final parent = json['parent'] as Map<String, dynamic>?;
    final rawChildren = json['children'] as List<dynamic>? ?? [];
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      parentId: parent?['id']?.toString() ?? json['parent_id']?.toString(),
      parentName: parent?['name'] as String?,
      productCount: (json['products_count'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      children: rawChildren
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson(CategoryFormData data) => {
        'name': data.name,
        'parent_id': data.parentId,
        'sort_order': data.sortOrder,
        'is_active': data.isActive,
      };
}
