import 'package:equatable/equatable.dart';

class MenuSettings extends Equatable {
  final String vendorId;
  final String slug;
  final String menuName;
  final String? logoUrl;
  final String primaryColor;
  final String backgroundColor;
  final String textColor;
  final int themeId;
  final List<String> phones;
  final String? address;
  final String? description;
  final String? instagramUrl;
  final String? whatsappNumber;
  final String? facebookUrl;
  final String? snapchatUrl;
  final String? websiteUrl;
  final bool showPrices;
  final String currency;
  final bool isActive;

  const MenuSettings({
    required this.vendorId,
    required this.slug,
    required this.menuName,
    this.logoUrl,
    this.primaryColor = '#0C2461',
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#1A1A1A',
    this.themeId = 1,
    this.phones = const [],
    this.address,
    this.description,
    this.instagramUrl,
    this.whatsappNumber,
    this.facebookUrl,
    this.snapchatUrl,
    this.websiteUrl,
    this.showPrices = true,
    this.currency = 'EGP',
    this.isActive = true,
  });

  MenuSettings copyWith({
    String? slug,
    String? menuName,
    String? logoUrl,
    String? primaryColor,
    String? backgroundColor,
    String? textColor,
    int? themeId,
    List<String>? phones,
    String? address,
    String? description,
    String? instagramUrl,
    String? whatsappNumber,
    String? facebookUrl,
    String? snapchatUrl,
    String? websiteUrl,
    bool? showPrices,
    String? currency,
    bool? isActive,
    bool clearLogo = false,
    bool clearInstagram = false,
    bool clearWhatsapp = false,
    bool clearFacebook = false,
    bool clearSnapchat = false,
    bool clearWebsite = false,
    bool clearAddress = false,
    bool clearDescription = false,
  }) {
    return MenuSettings(
      vendorId: vendorId,
      slug: slug ?? this.slug,
      menuName: menuName ?? this.menuName,
      logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      themeId: themeId ?? this.themeId,
      phones: phones ?? this.phones,
      address: clearAddress ? null : (address ?? this.address),
      description: clearDescription ? null : (description ?? this.description),
      instagramUrl: clearInstagram ? null : (instagramUrl ?? this.instagramUrl),
      whatsappNumber: clearWhatsapp ? null : (whatsappNumber ?? this.whatsappNumber),
      facebookUrl: clearFacebook ? null : (facebookUrl ?? this.facebookUrl),
      snapchatUrl: clearSnapchat ? null : (snapchatUrl ?? this.snapchatUrl),
      websiteUrl: clearWebsite ? null : (websiteUrl ?? this.websiteUrl),
      showPrices: showPrices ?? this.showPrices,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        vendorId, slug, menuName, logoUrl, primaryColor, backgroundColor,
        textColor, themeId, phones, address, description, instagramUrl,
        whatsappNumber, facebookUrl, snapchatUrl, websiteUrl,
        showPrices, currency, isActive,
      ];
}

class MenuProductConfig extends Equatable {
  final String productId;
  final String productName;
  final String? productImage;
  final String? categoryId;
  final String? categoryName;
  final double originalPrice;
  final double? menuPrice;
  final bool isVisible;
  final int displayOrder;

  const MenuProductConfig({
    required this.productId,
    required this.productName,
    this.productImage,
    this.categoryId,
    this.categoryName,
    required this.originalPrice,
    this.menuPrice,
    this.isVisible = true,
    this.displayOrder = 0,
  });

  double get effectivePrice => menuPrice ?? originalPrice;

  MenuProductConfig copyWith({
    String? productName,
    String? productImage,
    String? categoryId,
    String? categoryName,
    double? originalPrice,
    double? menuPrice,
    bool? isVisible,
    int? displayOrder,
    bool clearMenuPrice = false,
  }) {
    return MenuProductConfig(
      productId: productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      originalPrice: originalPrice ?? this.originalPrice,
      menuPrice: clearMenuPrice ? null : (menuPrice ?? this.menuPrice),
      isVisible: isVisible ?? this.isVisible,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  List<Object?> get props => [
        productId, productName, productImage, categoryId, categoryName,
        originalPrice, menuPrice, isVisible, displayOrder,
      ];
}
