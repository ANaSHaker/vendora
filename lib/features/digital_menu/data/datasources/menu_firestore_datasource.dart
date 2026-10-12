import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/menu_models.dart';

abstract class MenuFirestoreDataSource {
  Future<MenuSettingsModel?> getSettings(String vendorId);
  Future<List<MenuProductConfigModel>> getProductConfigs(String vendorId);
  Future<void> saveSettings(MenuSettingsModel settings);
  Future<void> saveProductConfigs(String vendorId, List<MenuProductConfigModel> configs);
  Future<MenuSettingsModel?> getMenuBySlug(String slug);
  Future<List<MenuProductConfigModel>> getMenuProductsBySlug(String slug);
  Future<String> uploadLogo(String vendorId, Uint8List bytes, String ext);
}

class MenuFirestoreDataSourceImpl implements MenuFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  MenuFirestoreDataSourceImpl()
      : _firestore = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _menus =>
      _firestore.collection('menus');

  CollectionReference<Map<String, dynamic>> get _slugIndex =>
      _firestore.collection('slugIndex');

  @override
  Future<MenuSettingsModel?> getSettings(String vendorId) async {
    final doc = await _menus.doc(vendorId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MenuSettingsModel.fromFirestore(doc.data()!, vendorId);
  }

  @override
  Future<List<MenuProductConfigModel>> getProductConfigs(String vendorId) async {
    final snap = await _menus.doc(vendorId).collection('products').get();
    final configs = snap.docs
        .map((d) => MenuProductConfigModel.fromFirestore(d.id, d.data()))
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return configs;
  }

  @override
  Future<void> saveSettings(MenuSettingsModel settings) async {
    final batch = _firestore.batch();
    batch.set(
      _menus.doc(settings.vendorId),
      settings.toFirestore(),
      SetOptions(merge: true),
    );
    batch.set(
      _slugIndex.doc(settings.slug),
      {'vendorId': settings.vendorId, 'updatedAt': FieldValue.serverTimestamp()},
    );
    await batch.commit();
  }

  @override
  Future<void> saveProductConfigs(
    String vendorId,
    List<MenuProductConfigModel> configs,
  ) async {
    final col = _menus.doc(vendorId).collection('products');
    // Firestore batch limit is 500 — chunk if needed
    const chunkSize = 400;
    for (var i = 0; i < configs.length; i += chunkSize) {
      final chunk = configs.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();
      for (final config in chunk) {
        batch.set(col.doc(config.productId), config.toFirestore());
      }
      await batch.commit();
    }
  }

  @override
  Future<MenuSettingsModel?> getMenuBySlug(String slug) async {
    final indexDoc = await _slugIndex.doc(slug).get();
    if (!indexDoc.exists) return null;
    final vendorId = indexDoc.data()?['vendorId'] as String?;
    if (vendorId == null) return null;
    return getSettings(vendorId);
  }

  @override
  Future<List<MenuProductConfigModel>> getMenuProductsBySlug(String slug) async {
    final indexDoc = await _slugIndex.doc(slug).get();
    if (!indexDoc.exists) return [];
    final vendorId = indexDoc.data()?['vendorId'] as String?;
    if (vendorId == null) return [];
    return getProductConfigs(vendorId);
  }

  @override
  Future<String> uploadLogo(String vendorId, Uint8List bytes, String ext) async {
    final ref = _storage.ref('menu_logos/$vendorId/logo.$ext');
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$ext'),
    );
    return ref.getDownloadURL();
  }
}
