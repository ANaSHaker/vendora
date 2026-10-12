import 'package:flutter/material.dart';
import '../../domain/entities/sf_entities.dart';

// ── Vendor / Config ───────────────────────────────────────────────────────────

class SfVendorInfoModel extends SfVendorInfo {
  const SfVendorInfoModel({
    required super.slug, required super.name, super.displayName,
    super.logoUrl, required super.currency, required super.storeTheme,
    required super.darkMode, super.primaryOverride,
    super.isActive, super.reservationsEnabled,
    super.aboutTitle, super.aboutContent,
    super.contactPhone, super.contactEmail, super.contactAddress,
    super.instagramUrl, super.twitterUrl, super.facebookUrl,
  });

  factory SfVendorInfoModel.fromJson(Map<String, dynamic> j) {
    Color? primaryOverride;
    final pc = j['primary_color'] as String?;
    if (pc != null && pc.isNotEmpty && pc != '#000000') {
      try {
        final hex = pc.replaceFirst('#', '');
        final value = int.parse(
          hex.length == 6 ? 'FF$hex' : hex,
          radix: 16,
        );
        primaryOverride = Color(value);
      } catch (_) {}
    }

    return SfVendorInfoModel(
      slug:                j['slug']          as String? ?? '',
      name:                j['name']          as String? ?? '',
      displayName:         j['display_name']  as String?,
      logoUrl:             j['logo_url']      as String?,
      currency:            j['currency']      as String? ?? 'USD',
      storeTheme:          j['store_theme']   as String? ?? 'breeze',
      darkMode:            (j['theme_mode']   as String?) == 'dark',
      primaryOverride:     primaryOverride,
      isActive:            j['is_active']     as bool? ?? true,
      reservationsEnabled: j['reservations_enabled'] as bool? ?? false,
      aboutTitle:          j['about_title']   as String?,
      aboutContent:        j['about_content'] as String?,
      contactPhone:        j['contact_phone'] as String?,
      contactEmail:        j['contact_email'] as String?,
      contactAddress:      j['contact_address'] as String?,
      instagramUrl:        j['instagram_url'] as String?,
      twitterUrl:          j['twitter_url']   as String?,
      facebookUrl:         j['facebook_url']  as String?,
    );
  }

  Map<String, dynamic> toUpdatePayload() => {
    'store_theme':           storeTheme,
    'theme_mode':            darkMode ? 'dark' : 'light',
    'is_active':             isActive,
    'reservations_enabled':  reservationsEnabled,
    if (primaryOverride != null)
      'primary_color': '#${primaryOverride!.toARGB32().toRadixString(16).substring(2)}',
    if (aboutTitle    != null) 'about_title':    aboutTitle,
    if (aboutContent  != null) 'about_content':  aboutContent,
    if (contactPhone  != null) 'contact_phone':  contactPhone,
    if (contactEmail  != null) 'contact_email':  contactEmail,
    if (contactAddress!= null) 'contact_address':contactAddress,
    if (instagramUrl  != null) 'instagram_url':  instagramUrl,
    if (twitterUrl    != null) 'twitter_url':    twitterUrl,
    if (facebookUrl   != null) 'facebook_url':   facebookUrl,
  };
}

class SfHomepageSectionModel extends SfHomepageSection {
  const SfHomepageSectionModel({
    required super.id, required super.type, required super.settings,
  });

  factory SfHomepageSectionModel.fromJson(Map<String, dynamic> j) =>
      SfHomepageSectionModel(
        id:       j['id']       as String? ?? '',
        type:     j['type']     as String? ?? '',
        settings: (j['settings'] as Map<String, dynamic>?) ?? {},
      );
}

// ── Category ──────────────────────────────────────────────────────────────────

class SfCategoryModel extends SfCategory {
  const SfCategoryModel({
    required super.id, required super.name,
    super.imageUrl, super.productCount,
  });

  factory SfCategoryModel.fromJson(Map<String, dynamic> j) => SfCategoryModel(
    id:           j['id'].toString(),
    name:         j['name']          as String? ?? '',
    imageUrl:     j['image_url']     as String?,
    productCount: j['product_count'] as int? ?? 0,
  );
}

// ── Product ───────────────────────────────────────────────────────────────────

class SfProductModel extends SfProduct {
  const SfProductModel({
    required super.id, required super.name, super.description,
    required super.price, super.oldPrice, super.image,
    super.images, super.unit, super.category,
    super.isFeatured, super.stock,
  });

  factory SfProductModel.fromJson(Map<String, dynamic> j) {
    final rawImages = j['images'] as List<dynamic>? ?? [];
    final images = rawImages.map((i) => SfProductImage(
      id:  i['id'].toString(),
      url: i['url'] as String? ?? '',
      alt: i['alt'] as String?,
    )).toList();

    SfCategory? cat;
    if (j['category'] is Map<String, dynamic>) {
      final c = j['category'] as Map<String, dynamic>;
      cat = SfCategory(id: c['id'].toString(), name: c['name'] as String? ?? '');
    }

    return SfProductModel(
      id:          j['id'].toString(),
      name:        j['name']        as String? ?? '',
      description: j['description'] as String?,
      price:       (j['price']      as num?)?.toDouble()     ?? 0,
      oldPrice:    (j['old_price']  as num?)?.toDouble(),
      image:       j['image']       as String?,
      images:      images,
      unit:        j['unit']        as String?,
      category:    cat,
      isFeatured:  j['is_featured'] as bool? ?? false,
      stock:       j['stock']       as int? ?? 0,
    );
  }
}

// ── Order ─────────────────────────────────────────────────────────────────────

class SfOrderResultModel extends SfOrderResult {
  const SfOrderResultModel({
    required super.reference, required super.trackingToken,
    required super.total, required super.status,
  });

  factory SfOrderResultModel.fromJson(Map<String, dynamic> j) => SfOrderResultModel(
    reference:     j['reference']      as String? ?? '',
    trackingToken: j['tracking_token'] as String? ?? '',
    total:         (j['total']         as num?)?.toDouble() ?? 0,
    status:        j['status']         as String? ?? 'pending',
  );
}

class SfOrderStatusModel extends SfOrderStatus {
  const SfOrderStatusModel({
    required super.reference, required super.status, required super.total,
    required super.customerName, super.deliveryAddress,
    required super.createdAt, required super.items,
  });

  factory SfOrderStatusModel.fromJson(Map<String, dynamic> j) {
    final rawItems = j['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((i) => SfOrderStatusItem(
      name:     i['name']     as String? ?? '',
      quantity: i['quantity'] as int?    ?? 1,
      price:    (i['price']   as num?)?.toDouble() ?? 0,
    )).toList();

    return SfOrderStatusModel(
      reference:       j['reference']       as String? ?? '',
      status:          j['status']          as String? ?? 'pending',
      total:           (j['total']          as num?)?.toDouble() ?? 0,
      customerName:    j['customer_name']   as String? ?? '',
      deliveryAddress: j['delivery_address']as String?,
      createdAt:       DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      items:           items,
    );
  }
}
