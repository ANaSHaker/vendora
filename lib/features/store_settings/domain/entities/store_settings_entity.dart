import 'package:equatable/equatable.dart';

class StoreSettingsEntity extends Equatable {
  final String? storeName;
  final String? storeEmail;
  final String? storePhone;
  final String? storeAddress;
  final String? currency;
  final double? taxRate;
  final String? logoUrl;
  final String? website;
  final String? instagramHandle;
  final String? whatsappNumber;

  const StoreSettingsEntity({
    this.storeName,
    this.storeEmail,
    this.storePhone,
    this.storeAddress,
    this.currency,
    this.taxRate,
    this.logoUrl,
    this.website,
    this.instagramHandle,
    this.whatsappNumber,
  });

  StoreSettingsEntity copyWith({
    String? storeName,
    String? storeEmail,
    String? storePhone,
    String? storeAddress,
    String? currency,
    double? taxRate,
    String? logoUrl,
    String? website,
    String? instagramHandle,
    String? whatsappNumber,
  }) =>
      StoreSettingsEntity(
        storeName: storeName ?? this.storeName,
        storeEmail: storeEmail ?? this.storeEmail,
        storePhone: storePhone ?? this.storePhone,
        storeAddress: storeAddress ?? this.storeAddress,
        currency: currency ?? this.currency,
        taxRate: taxRate ?? this.taxRate,
        logoUrl: logoUrl ?? this.logoUrl,
        website: website ?? this.website,
        instagramHandle: instagramHandle ?? this.instagramHandle,
        whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      );

  @override
  List<Object?> get props => [
        storeName,
        storeEmail,
        storePhone,
        storeAddress,
        currency,
        taxRate,
        logoUrl,
        website,
        instagramHandle,
        whatsappNumber,
      ];
}
