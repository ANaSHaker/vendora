import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class LocalStorage {
  static const _themeKey         = 'theme_mode';
  static const _localeKey        = 'locale';
  static const _userKey          = 'cached_user';
  static const _colorPresetKey   = 'color_preset';
  static const _posStatusKey     = 'pos_default_status';
  static const _currencySymbolKey = 'currency_symbol';
  static const _currencyCodeKey   = 'currency_code';
  static const _autoPrintKey      = 'pos_auto_print';
  static const _trackingSlugKey   = 'tracking_slug';

  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  // Theme
  String get themeMode => _prefs.getString(_themeKey) ?? 'system';
  Future<void> saveThemeMode(String mode) =>
      _prefs.setString(_themeKey, mode);

  // Locale — default Arabic
  String get locale => _prefs.getString(_localeKey) ?? 'ar';
  Future<void> saveLocale(String locale) =>
      _prefs.setString(_localeKey, locale);

  // Color preset
  String get colorPreset => _prefs.getString(_colorPresetKey) ?? 'navy';
  Future<void> saveColorPreset(String preset) =>
      _prefs.setString(_colorPresetKey, preset);

  // POS default order status
  String get posDefaultStatus => _prefs.getString(_posStatusKey) ?? 'completed';
  Future<void> savePosDefaultStatus(String status) =>
      _prefs.setString(_posStatusKey, status);

  // Currency
  String get currencySymbol => _prefs.getString(_currencySymbolKey) ?? '\$';
  String get currencyCode   => _prefs.getString(_currencyCodeKey) ?? 'USD';
  Future<void> saveCurrency({required String symbol, required String code}) async {
    await _prefs.setString(_currencySymbolKey, symbol);
    await _prefs.setString(_currencyCodeKey, code);
  }

  // POS auto-print
  bool get autoPrint => _prefs.getBool(_autoPrintKey) ?? false;
  Future<void> saveAutoPrint(bool value) =>
      _prefs.setBool(_autoPrintKey, value);

  // Store tracking slug (e.g. "demo-coffee")
  String? get trackingSlug => _prefs.getString(_trackingSlugKey);
  Future<void> saveTrackingSlug(String slug) =>
      _prefs.setString(_trackingSlugKey, slug);

  // User cache — sync read, async write
  Map<String, dynamic>? getCachedUserJson() {
    final s = _prefs.getString(_userKey);
    if (s == null) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheUserJson(Map<String, dynamic> json) =>
      _prefs.setString(_userKey, jsonEncode(json));

  Future<void> clearUser() => _prefs.remove(_userKey);
}
