import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';

abstract class SfRemoteDataSource {
  Future<Map<String, dynamic>> getStorefront(String slug);
  Future<List<Map<String, dynamic>>> getCategories(String slug);
  Future<List<Map<String, dynamic>>> getProducts(String slug,
      {String? search, String? categoryId, int page});
  Future<Map<String, dynamic>> getProduct(String slug, String productId);
  Future<Map<String, dynamic>> placeOrder(
      String slug, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> getOrderStatus(String slug, String reference);
  Future<void> placeReservation(String slug, Map<String, dynamic> payload);
  Future<Map<String, dynamic>> getStorefrontSettings();
  Future<void> updateStorefrontSettings(Map<String, dynamic> payload);
}

class SfRemoteDataSourceImpl implements SfRemoteDataSource {
  final ApiClient _api;
  SfRemoteDataSourceImpl(this._api);

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Extracts a Map from a response, handling both:
  ///   {data: {...}}  →  returns data
  ///   {...}          →  returns body directly
  /// Throws a descriptive error if the response is not JSON (e.g. HTML).
  Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['data'] as Map<String, dynamic>?) ?? data;
    }
    if (data is String && (data.contains('<!DOCTYPE') || data.contains('<html'))) {
      throw Exception('API endpoint not found (server returned HTML)');
    }
    throw Exception('Unexpected response format: ${data.runtimeType}');
  }

  /// Same but returns the raw Map without unwrapping 'data'.
  Map<String, dynamic> _rawMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String && (data.contains('<!DOCTYPE') || data.contains('<html'))) {
      throw Exception('API endpoint not found (server returned HTML)');
    }
    throw Exception('Unexpected response format: ${data.runtimeType}');
  }

  List<Map<String, dynamic>> _toList(dynamic data) {
    final m = _rawMap(data);
    final list = m['data'] as List<dynamic>? ?? (data is List<dynamic> ? data : <dynamic>[]);
    return list.map((e) {
      if (e is Map<String, dynamic>) return e;
      return <String, dynamic>{};
    }).toList();
  }

  // ── Public storefront API ─────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getStorefront(String slug) async {
    final res = await _api.get(ApiEndpoints.storefrontVendor(slug));
    return _toMap(res.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories(String slug) async {
    final res = await _api.get(ApiEndpoints.storefrontCategories(slug));
    return _toList(res.data);
  }

  @override
  Future<List<Map<String, dynamic>>> getProducts(
    String slug, {String? search, String? categoryId, int page = 1}
  ) async {
    final res = await _api.get(
      ApiEndpoints.storefrontProducts(slug),
      queryParameters: {
        if (search     != null) 'search':      search,
        if (categoryId != null) 'category_id': categoryId,
        'page': page,
        'per_page': 24,
      },
    );
    return _toList(res.data);
  }

  @override
  Future<Map<String, dynamic>> getProduct(String slug, String productId) async {
    final res = await _api.get(ApiEndpoints.storefrontProduct(slug, productId));
    return _toMap(res.data);
  }

  @override
  Future<Map<String, dynamic>> placeOrder(
      String slug, Map<String, dynamic> payload) async {
    final res = await _api.post(ApiEndpoints.storefrontOrders(slug), data: payload);
    return _toMap(res.data);
  }

  @override
  Future<Map<String, dynamic>> getOrderStatus(
      String slug, String reference) async {
    final res = await _api.get(ApiEndpoints.storefrontOrderStatus(slug, reference));
    return _toMap(res.data);
  }

  @override
  Future<void> placeReservation(String slug, Map<String, dynamic> payload) async {
    await _api.post(ApiEndpoints.storefrontReservations(slug), data: payload);
  }

  // ── Dashboard settings API (auth required) ────────────────────────────────

  @override
  Future<Map<String, dynamic>> getStorefrontSettings() async {
    final res = await _api.get(ApiEndpoints.storeSettings);
    return _toMap(res.data);
  }

  @override
  Future<void> updateStorefrontSettings(Map<String, dynamic> payload) async {
    await _api.put(ApiEndpoints.storeSettings, data: payload);
  }
}
