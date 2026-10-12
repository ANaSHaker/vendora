import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ── Vendor / Config ───────────────────────────────────────────────────────────

class SfVendorInfo extends Equatable {
  final String   slug;
  final String   name;
  final String?  displayName;
  final String?  logoUrl;
  final String   currency;
  final String   storeTheme;
  final bool     darkMode;
  final Color?   primaryOverride;
  final bool     isActive;
  final bool     reservationsEnabled;

  final String?  aboutTitle;
  final String?  aboutContent;
  final String?  contactPhone;
  final String?  contactEmail;
  final String?  contactAddress;
  final String?  instagramUrl;
  final String?  twitterUrl;
  final String?  facebookUrl;

  const SfVendorInfo({
    required this.slug,
    required this.name,
    this.displayName,
    this.logoUrl,
    required this.currency,
    required this.storeTheme,
    required this.darkMode,
    this.primaryOverride,
    this.isActive = false,
    this.reservationsEnabled = false,
    this.aboutTitle,
    this.aboutContent,
    this.contactPhone,
    this.contactEmail,
    this.contactAddress,
    this.instagramUrl,
    this.twitterUrl,
    this.facebookUrl,
  });

  String get displayTitle => displayName ?? name;

  @override
  List<Object?> get props => [slug, storeTheme, darkMode, primaryOverride, isActive, reservationsEnabled];
}

class SfHomepageSection extends Equatable {
  final String               id;
  final String               type;
  final Map<String, dynamic> settings;

  const SfHomepageSection({
    required this.id,
    required this.type,
    required this.settings,
  });

  @override
  List<Object?> get props => [id, type];
}

// ── Product / Category ────────────────────────────────────────────────────────

class SfCategory extends Equatable {
  final String  id;
  final String  name;
  final String? imageUrl;
  final int     productCount;

  const SfCategory({
    required this.id,
    required this.name,
    this.imageUrl,
    this.productCount = 0,
  });

  @override
  List<Object?> get props => [id];
}

class SfProductImage extends Equatable {
  final String  id;
  final String  url;
  final String? alt;

  const SfProductImage({required this.id, required this.url, this.alt});

  @override
  List<Object?> get props => [id];
}

class SfProduct extends Equatable {
  final String            id;
  final String            name;
  final String?           description;
  final double            price;
  final double?           oldPrice;
  final String?           image;
  final List<SfProductImage> images;
  final String?           unit;
  final SfCategory?       category;
  final bool              isFeatured;
  final int               stock;

  const SfProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.oldPrice,
    this.image,
    this.images = const [],
    this.unit,
    this.category,
    this.isFeatured = false,
    this.stock = 0,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;
  double get discountPercent =>
      hasDiscount ? ((oldPrice! - price) / oldPrice! * 100) : 0;

  String? get primaryImage => image ?? (images.isNotEmpty ? images.first.url : null);

  @override
  List<Object?> get props => [id];
}

// ── Cart ──────────────────────────────────────────────────────────────────────

class SfCartItem extends Equatable {
  final SfProduct product;
  final int       quantity;

  const SfCartItem({required this.product, required this.quantity});

  double get total => product.price * quantity;

  SfCartItem copyWith({int? quantity}) =>
      SfCartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [product.id, quantity];
}

// ── Order ─────────────────────────────────────────────────────────────────────

class SfOrderResult extends Equatable {
  final String  reference;
  final String  trackingToken;
  final double  total;
  final String  status;

  const SfOrderResult({
    required this.reference,
    required this.trackingToken,
    required this.total,
    required this.status,
  });

  @override
  List<Object?> get props => [reference];
}

class SfOrderStatus extends Equatable {
  final String  reference;
  final String  status;
  final double  total;
  final String  customerName;
  final String? deliveryAddress;
  final DateTime createdAt;
  final List<SfOrderStatusItem> items;

  const SfOrderStatus({
    required this.reference,
    required this.status,
    required this.total,
    required this.customerName,
    this.deliveryAddress,
    required this.createdAt,
    required this.items,
  });

  @override
  List<Object?> get props => [reference];
}

class SfOrderStatusItem extends Equatable {
  final String name;
  final int    quantity;
  final double price;

  const SfOrderStatusItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  @override
  List<Object?> get props => [name, quantity];
}
