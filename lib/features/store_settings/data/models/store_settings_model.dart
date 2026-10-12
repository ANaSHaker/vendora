import '../../domain/entities/store_settings_entity.dart';

class StoreSettingsModel extends StoreSettingsEntity {
  const StoreSettingsModel({
    super.storeName,
    super.storeEmail,
    super.storePhone,
    super.storeAddress,
    super.currency,
    super.taxRate,
    super.logoUrl,
    super.website,
    super.instagramHandle,
    super.whatsappNumber,
  });

  factory StoreSettingsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return StoreSettingsModel(
      storeName: data['name'] as String? ??
          data['store_name'] as String?,
      storeEmail: data['email'] as String?,
      storePhone: data['phone'] as String?,
      storeAddress: data['address'] as String?,
      currency: data['currency'] as String?,
      taxRate: (data['tax_rate'] as num?)?.toDouble(),
      logoUrl: data['logo'] as String? ?? data['logo_url'] as String?,
      website: data['website'] as String?,
      instagramHandle: data['instagram'] as String?,
      whatsappNumber: data['whatsapp'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (storeName != null) 'name': storeName,
        if (storeEmail != null) 'email': storeEmail,
        if (storePhone != null) 'phone': storePhone,
        if (storeAddress != null) 'address': storeAddress,
        if (currency != null) 'currency': currency,
        if (taxRate != null) 'tax_rate': taxRate,
        if (website != null) 'website': website,
        if (instagramHandle != null) 'instagram': instagramHandle,
        if (whatsappNumber != null) 'whatsapp': whatsappNumber,
      };
}
