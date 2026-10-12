import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final String? categoryId;
  final String? categoryName;
  final int stock;
  final bool isActive;
  final bool isOnline;
  final bool isPublished;
  final bool isFeatured;
  final String? imageUrl;
  final String? description;
  final String? unit;
  final bool trackStock;
  final bool hasOptions;

  const ProductEntity({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.categoryId,
    this.categoryName,
    this.stock = 0,
    this.isActive = true,
    this.isOnline = false,
    this.isPublished = false,
    this.isFeatured = false,
    this.imageUrl,
    this.description,
    this.unit,
    this.trackStock = false,
    this.hasOptions = false,
  });

  @override
  List<Object?> get props => [
        id, name, sku, barcode, price, categoryId, categoryName,
        stock, isActive, isOnline, isPublished, isFeatured, imageUrl,
        description, unit, trackStock, hasOptions,
      ];
}

class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? parentId;
  final String? parentName;
  final int productCount;
  final int sortOrder;
  final bool isActive;
  final List<CategoryEntity> children;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
    this.productCount = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.children = const [],
  });

  @override
  List<Object?> get props =>
      [id, name, parentId, parentName, productCount, sortOrder, isActive];
}

class CategoryFormData extends Equatable {
  final String name;
  final String? parentId;
  final int sortOrder;
  final bool isActive;

  const CategoryFormData({
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, parentId, sortOrder, isActive];
}

class ProductFormData extends Equatable {
  final String name;
  final String? sku;
  final String? barcode;
  final double price;
  final String? categoryId;
  final String? description;
  final bool isOnline;
  final bool isPublished;
  final bool isFeatured;
  final String? unit;
  final bool trackStock;
  final List<int>? imageBytes;

  const ProductFormData({
    required this.name,
    this.sku,
    this.barcode,
    required this.price,
    this.categoryId,
    this.description,
    this.isOnline = false,
    this.isPublished = false,
    this.isFeatured = false,
    this.unit,
    this.trackStock = false,
    this.imageBytes,
  });

  @override
  List<Object?> get props => [
        name, sku, barcode, price, categoryId,
        description, isOnline, isPublished, isFeatured, unit, trackStock,
      ];
}
