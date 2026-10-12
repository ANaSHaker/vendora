import '../../../../features/products/domain/entities/product_entities.dart';
import '../../domain/entities/menu_entities.dart';

class MenuSettingsModel extends MenuSettings {
  const MenuSettingsModel({
    required super.vendorId,
    required super.slug,
    required super.menuName,
    super.logoUrl,
    super.primaryColor,
    super.backgroundColor,
    super.textColor,
    super.themeId,
    super.phones,
    super.address,
    super.description,
    super.instagramUrl,
    super.whatsappNumber,
    super.facebookUrl,
    super.snapchatUrl,
    super.websiteUrl,
    super.showPrices,
    super.currency,
    super.isActive,
  });

  factory MenuSettingsModel.fromFirestore(Map<String, dynamic> data, String vendorId) {
    return MenuSettingsModel(
      vendorId: vendorId,
      slug: data['slug'] as String? ?? vendorId,
      menuName: data['menuName'] as String? ?? '',
      logoUrl: data['logoUrl'] as String?,
      primaryColor: data['primaryColor'] as String? ?? '#0C2461',
      backgroundColor: data['backgroundColor'] as String? ?? '#FFFFFF',
      textColor: data['textColor'] as String? ?? '#1A1A1A',
      themeId: (data['themeId'] as int?) ?? 1,
      phones: List<String>.from(data['phones'] as List? ?? []),
      address: data['address'] as String?,
      description: data['description'] as String?,
      instagramUrl: data['instagramUrl'] as String?,
      whatsappNumber: data['whatsappNumber'] as String?,
      facebookUrl: data['facebookUrl'] as String?,
      snapchatUrl: data['snapchatUrl'] as String?,
      websiteUrl: data['websiteUrl'] as String?,
      showPrices: data['showPrices'] as bool? ?? true,
      currency: data['currency'] as String? ?? 'EGP',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'slug': slug,
        'menuName': menuName,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'primaryColor': primaryColor,
        'backgroundColor': backgroundColor,
        'textColor': textColor,
        'themeId': themeId,
        'phones': phones,
        if (address != null) 'address': address,
        if (description != null) 'description': description,
        if (instagramUrl != null) 'instagramUrl': instagramUrl,
        if (whatsappNumber != null) 'whatsappNumber': whatsappNumber,
        if (facebookUrl != null) 'facebookUrl': facebookUrl,
        if (snapchatUrl != null) 'snapchatUrl': snapchatUrl,
        if (websiteUrl != null) 'websiteUrl': websiteUrl,
        'showPrices': showPrices,
        'currency': currency,
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  static MenuSettingsModel defaultFor(String vendorId) {
    final slug = vendorId.length > 12 ? vendorId.substring(0, 12) : vendorId;
    return MenuSettingsModel(
      vendorId: vendorId,
      slug: slug.toLowerCase(),
      menuName: '',
      primaryColor: '#0C2461',
      backgroundColor: '#FFFFFF',
      textColor: '#1A1A1A',
      themeId: 1,
      phones: const [],
      showPrices: true,
      currency: 'EGP',
      isActive: true,
    );
  }

  MenuSettingsModel withSettings(MenuSettings s) => MenuSettingsModel(
        vendorId: s.vendorId,
        slug: s.slug,
        menuName: s.menuName,
        logoUrl: s.logoUrl,
        primaryColor: s.primaryColor,
        backgroundColor: s.backgroundColor,
        textColor: s.textColor,
        themeId: s.themeId,
        phones: s.phones,
        address: s.address,
        description: s.description,
        instagramUrl: s.instagramUrl,
        whatsappNumber: s.whatsappNumber,
        facebookUrl: s.facebookUrl,
        snapchatUrl: s.snapchatUrl,
        websiteUrl: s.websiteUrl,
        showPrices: s.showPrices,
        currency: s.currency,
        isActive: s.isActive,
      );
}

class MenuProductConfigModel extends MenuProductConfig {
  const MenuProductConfigModel({
    required super.productId,
    required super.productName,
    super.productImage,
    super.categoryId,
    super.categoryName,
    required super.originalPrice,
    super.menuPrice,
    super.isVisible,
    super.displayOrder,
  });

  factory MenuProductConfigModel.fromFirestore(String productId, Map<String, dynamic> data) {
    return MenuProductConfigModel(
      productId: productId,
      productName: data['productName'] as String? ?? '',
      productImage: data['productImage'] as String?,
      categoryId: data['categoryId'] as String?,
      categoryName: data['categoryName'] as String?,
      originalPrice: (data['originalPrice'] as num?)?.toDouble() ?? 0.0,
      menuPrice: (data['menuPrice'] as num?)?.toDouble(),
      isVisible: data['isVisible'] as bool? ?? true,
      displayOrder: (data['displayOrder'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'productName': productName,
        if (productImage != null) 'productImage': productImage,
        if (categoryId != null) 'categoryId': categoryId,
        if (categoryName != null) 'categoryName': categoryName,
        'originalPrice': originalPrice,
        if (menuPrice != null) 'menuPrice': menuPrice,
        'isVisible': isVisible,
        'displayOrder': displayOrder,
      };

  factory MenuProductConfigModel.fromProduct(ProductEntity product, int order) {
    return MenuProductConfigModel(
      productId: product.id,
      productName: product.name,
      productImage: product.imageUrl,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      originalPrice: product.price,
      menuPrice: null,
      isVisible: true,
      displayOrder: order,
    );
  }

  static MenuProductConfigModel fromConfig(MenuProductConfig c) => MenuProductConfigModel(
        productId: c.productId,
        productName: c.productName,
        productImage: c.productImage,
        categoryId: c.categoryId,
        categoryName: c.categoryName,
        originalPrice: c.originalPrice,
        menuPrice: c.menuPrice,
        isVisible: c.isVisible,
        displayOrder: c.displayOrder,
      );
}
