import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/sf_entities.dart';
import '../../domain/usecases/sf_usecases.dart';

// ── Prefs keys ────────────────────────────────────────────────────────────────

const _kTheme        = 'sf_store_theme';
const _kDarkMode     = 'sf_dark_mode';
const _kIsActive     = 'sf_is_active';
const _kReservations = 'sf_reservations_enabled';

// ── States ────────────────────────────────────────────────────────────────────

sealed class SfSettingsState extends Equatable {
  const SfSettingsState();
  @override List<Object?> get props => [];
}

class SfSettingsInitial extends SfSettingsState { const SfSettingsInitial(); }
class SfSettingsLoading extends SfSettingsState { const SfSettingsLoading(); }
class SfSettingsError extends SfSettingsState {
  final String message;
  const SfSettingsError(this.message);
  @override List<Object?> get props => [message];
}

class SfSettingsLoaded extends SfSettingsState {
  final SfVendorInfo vendor;
  final bool isSaving;
  final bool saveSuccess;
  final String? errorMessage;

  const SfSettingsLoaded({
    required this.vendor,
    this.isSaving    = false,
    this.saveSuccess = false,
    this.errorMessage,
  });

  SfSettingsLoaded copyWith({
    SfVendorInfo? vendor,
    bool? isSaving, bool? saveSuccess, String? errorMessage,
    bool clearError = false,
  }) => SfSettingsLoaded(
    vendor:       vendor       ?? this.vendor,
    isSaving:     isSaving     ?? this.isSaving,
    saveSuccess:  saveSuccess  ?? this.saveSuccess,
    errorMessage: clearError   ? null : (errorMessage ?? this.errorMessage),
  );

  @override List<Object?> get props => [vendor, isSaving, saveSuccess, errorMessage];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class SfSettingsCubit extends Cubit<SfSettingsState> {
  final GetStorefrontSettingsUseCase    _getSettings;
  final UpdateStorefrontSettingsUseCase _updateSettings;

  SfSettingsCubit({
    required GetStorefrontSettingsUseCase getSettings,
    required UpdateStorefrontSettingsUseCase updateSettings,
  })  : _getSettings    = getSettings,
        _updateSettings = updateSettings,
        super(const SfSettingsInitial());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(const SfSettingsLoading());

    // Try backend
    final res = await _getSettings();

    SfVendorInfo vendor   = _defaultVendor;
    String?      errorMessage;

    res.fold(
      (f) {
        vendor       = _defaultVendor;
        errorMessage = _cleanMessage(f.message);
      },
      (v) => vendor = v,
    );

    // Always overlay with cached local values for the fields the backend
    // may not persist yet (theme, dark mode, is_active, reservations).
    vendor = await _overlayPrefs(vendor);

    if (!isClosed) {
      emit(SfSettingsLoaded(vendor: vendor, errorMessage: errorMessage));
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> save({
    String?  theme,
    bool?    darkMode,
    bool?    isActive,
    Color?   primaryOverride,
    bool?    reservationsEnabled,
    String?  aboutTitle,
    String?  aboutContent,
    String?  contactPhone,
    String?  contactEmail,
    String?  contactAddress,
    String?  instagramUrl,
    String?  twitterUrl,
    String?  facebookUrl,
  }) async {
    final loaded = _loaded; if (loaded == null) return;
    if (loaded.isSaving) return;

    final updatedVendor = _applyChanges(
      loaded.vendor,
      theme: theme, darkMode: darkMode, isActive: isActive,
      primaryOverride: primaryOverride,
      reservationsEnabled: reservationsEnabled,
      aboutTitle: aboutTitle, aboutContent: aboutContent,
      contactPhone: contactPhone, contactEmail: contactEmail,
      contactAddress: contactAddress,
      instagramUrl: instagramUrl, twitterUrl: twitterUrl,
      facebookUrl: facebookUrl,
    );

    // 1. Optimistic UI update immediately
    emit(loaded.copyWith(
      vendor: updatedVendor,
      isSaving: true,
      saveSuccess: false,
      clearError: true,
    ));

    // 2. Persist to SharedPreferences immediately so it survives reload
    await _savePrefs(updatedVendor);

    // 3. Try to persist to backend
    final payload = _buildPayload(
      theme: theme, darkMode: darkMode, isActive: isActive,
      primaryOverride: primaryOverride,
      reservationsEnabled: reservationsEnabled,
      aboutTitle: aboutTitle, aboutContent: aboutContent,
      contactPhone: contactPhone, contactEmail: contactEmail,
      contactAddress: contactAddress,
      instagramUrl: instagramUrl, twitterUrl: twitterUrl,
      facebookUrl: facebookUrl,
    );

    final res = await _updateSettings(payload);
    if (!isClosed) {
      res.fold(
        (f) {
          // Backend failed — but prefs are saved, so UI stays correct.
          // Show a soft warning (not reverting).
          final current = _loaded;
          if (current != null) {
            emit(current.copyWith(
              isSaving: false,
              errorMessage: _cleanMessage(f.message),
            ));
          }
        },
        (_) {
          final current = _loaded;
          if (current != null) {
            emit(current.copyWith(isSaving: false, saveSuccess: true, clearError: true));
          }
        },
      );
    }
  }

  // ── SharedPreferences helpers ─────────────────────────────────────────────

  Future<void> _savePrefs(SfVendorInfo v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTheme,        v.storeTheme);
    await prefs.setBool  (_kDarkMode,     v.darkMode);
    await prefs.setBool  (_kIsActive,     v.isActive);
    await prefs.setBool  (_kReservations, v.reservationsEnabled);
  }

  Future<SfVendorInfo> _overlayPrefs(SfVendorInfo v) async {
    final prefs = await SharedPreferences.getInstance();
    return SfVendorInfo(
      slug:                v.slug,
      name:                v.name,
      displayName:         v.displayName,
      logoUrl:             v.logoUrl,
      currency:            v.currency,
      storeTheme:          prefs.getString(_kTheme)        ?? v.storeTheme,
      darkMode:            prefs.getBool  (_kDarkMode)     ?? v.darkMode,
      isActive:            prefs.getBool  (_kIsActive)     ?? v.isActive,
      primaryOverride:     v.primaryOverride,
      reservationsEnabled: prefs.getBool  (_kReservations) ?? v.reservationsEnabled,
      aboutTitle:          v.aboutTitle,
      aboutContent:        v.aboutContent,
      contactPhone:        v.contactPhone,
      contactEmail:        v.contactEmail,
      contactAddress:      v.contactAddress,
      instagramUrl:        v.instagramUrl,
      twitterUrl:          v.twitterUrl,
      facebookUrl:         v.facebookUrl,
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static SfVendorInfo get _defaultVendor => const SfVendorInfo(
    slug: '', name: 'My Store', currency: 'USD',
    storeTheme: 'breeze', darkMode: false,
    isActive: false, reservationsEnabled: false,
  );

  SfVendorInfo _applyChanges(
    SfVendorInfo v, {
    String?  theme,
    bool?    darkMode,
    bool?    isActive,
    Color?   primaryOverride,
    bool?    reservationsEnabled,
    String?  aboutTitle,
    String?  aboutContent,
    String?  contactPhone,
    String?  contactEmail,
    String?  contactAddress,
    String?  instagramUrl,
    String?  twitterUrl,
    String?  facebookUrl,
  }) => SfVendorInfo(
    slug:                v.slug,
    name:                v.name,
    displayName:         v.displayName,
    logoUrl:             v.logoUrl,
    currency:            v.currency,
    storeTheme:          theme               ?? v.storeTheme,
    darkMode:            darkMode            ?? v.darkMode,
    isActive:            isActive            ?? v.isActive,
    primaryOverride:     primaryOverride     ?? v.primaryOverride,
    reservationsEnabled: reservationsEnabled ?? v.reservationsEnabled,
    aboutTitle:          aboutTitle          ?? v.aboutTitle,
    aboutContent:        aboutContent        ?? v.aboutContent,
    contactPhone:        contactPhone        ?? v.contactPhone,
    contactEmail:        contactEmail        ?? v.contactEmail,
    contactAddress:      contactAddress      ?? v.contactAddress,
    instagramUrl:        instagramUrl        ?? v.instagramUrl,
    twitterUrl:          twitterUrl          ?? v.twitterUrl,
    facebookUrl:         facebookUrl         ?? v.facebookUrl,
  );

  Map<String, dynamic> _buildPayload({
    String?  theme,
    bool?    darkMode,
    bool?    isActive,
    Color?   primaryOverride,
    bool?    reservationsEnabled,
    String?  aboutTitle,
    String?  aboutContent,
    String?  contactPhone,
    String?  contactEmail,
    String?  contactAddress,
    String?  instagramUrl,
    String?  twitterUrl,
    String?  facebookUrl,
  }) => {
    if (theme              != null) 'store_theme':           theme,
    if (darkMode           != null) 'theme_mode':            darkMode ? 'dark' : 'light',
    if (isActive           != null) 'is_active':             isActive,
    if (primaryOverride    != null) 'primary_color':
        '#${primaryOverride.toARGB32().toRadixString(16).padLeft(8,'0').substring(2)}',
    if (reservationsEnabled != null) 'reservations_enabled': reservationsEnabled,
    if (aboutTitle         != null) 'about_title':           aboutTitle,
    if (aboutContent       != null) 'about_content':         aboutContent,
    if (contactPhone       != null) 'contact_phone':         contactPhone,
    if (contactEmail       != null) 'contact_email':         contactEmail,
    if (contactAddress     != null) 'contact_address':       contactAddress,
    if (instagramUrl       != null) 'instagram_url':         instagramUrl,
    if (twitterUrl         != null) 'twitter_url':           twitterUrl,
    if (facebookUrl        != null) 'facebook_url':          facebookUrl,
  };

  static String _cleanMessage(String msg) {
    if (msg.contains('<!DOCTYPE') || msg.contains('<html')) {
      return 'Server error. Please try again.';
    }
    if (msg.length > 120) return '${msg.substring(0, 120)}…';
    return msg;
  }

  SfSettingsLoaded? get _loaded =>
      state is SfSettingsLoaded ? state as SfSettingsLoaded : null;
}
