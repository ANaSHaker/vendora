import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/sf_entities.dart';
import '../../domain/usecases/sf_usecases.dart';

// Shared prefs keys (same as sf_settings_cubit)
const _kTheme        = 'sf_store_theme';
const _kDarkMode     = 'sf_dark_mode';
const _kIsActive     = 'sf_is_active';
const _kReservations = 'sf_reservations_enabled';

// ── States ────────────────────────────────────────────────────────────────────

sealed class StorefrontState extends Equatable {
  const StorefrontState();
  @override List<Object?> get props => [];
}

class StorefrontInitial extends StorefrontState { const StorefrontInitial(); }
class StorefrontLoading extends StorefrontState { const StorefrontLoading(); }
class StorefrontError   extends StorefrontState {
  final String message;
  const StorefrontError(this.message);
  @override List<Object?> get props => [message];
}

class StorefrontLoaded extends StorefrontState {
  final SfVendorInfo            vendor;
  final List<SfHomepageSection> sections;
  final List<SfCartItem>        cart;

  const StorefrontLoaded({
    required this.vendor,
    required this.sections,
    this.cart = const [],
  });

  int    get cartItemCount => cart.fold(0, (s, i) => s + i.quantity);
  double get cartTotal     => cart.fold(0.0, (s, i) => s + i.total);

  StorefrontLoaded copyWith({
    SfVendorInfo?            vendor,
    List<SfHomepageSection>? sections,
    List<SfCartItem>?        cart,
  }) => StorefrontLoaded(
    vendor:   vendor   ?? this.vendor,
    sections: sections ?? this.sections,
    cart:     cart     ?? this.cart,
  );

  @override List<Object?> get props => [vendor, sections, cart];
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class StorefrontCubit extends Cubit<StorefrontState> {
  final GetStorefrontUseCase _getStorefront;

  StorefrontCubit({required GetStorefrontUseCase getStorefront})
      : _getStorefront = getStorefront,
        super(const StorefrontInitial());

  Future<void> load(String slug) async {
    emit(const StorefrontLoading());

    final res = await _getStorefront(slug);
    res.fold(
      (f) async {
        // Backend failed — check if vendor activated the store locally
        final fallback = await _localFallback(slug);
        if (fallback != null && !isClosed) {
          emit(StorefrontLoaded(vendor: fallback, sections: const []));
        } else if (!isClosed) {
          emit(StorefrontError(f.message));
        }
      },
      (pair) {
        if (!isClosed) {
          final (vendor, sections) = pair;
          emit(StorefrontLoaded(vendor: vendor, sections: sections));
        }
      },
    );
  }

  // Returns a vendor built from SharedPreferences if isActive=true, else null.
  Future<SfVendorInfo?> _localFallback(String slug) async {
    final prefs    = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_kIsActive) ?? false;
    if (!isActive) return null;

    return SfVendorInfo(
      slug:                slug,
      name:                'My Store',
      currency:            'USD',
      storeTheme:          prefs.getString(_kTheme)        ?? 'breeze',
      darkMode:            prefs.getBool(_kDarkMode)       ?? false,
      isActive:            true,
      reservationsEnabled: prefs.getBool(_kReservations)   ?? false,
    );
  }

  // ── Cart operations ───────────────────────────────────────────────────────

  void addToCart(SfProduct product, {int quantity = 1}) {
    final loaded = _loaded; if (loaded == null) return;
    final cart   = List<SfCartItem>.from(loaded.cart);
    final idx    = cart.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      cart[idx] = cart[idx].copyWith(quantity: cart[idx].quantity + quantity);
    } else {
      cart.add(SfCartItem(product: product, quantity: quantity));
    }
    emit(loaded.copyWith(cart: cart));
  }

  void removeFromCart(String productId) {
    final loaded = _loaded; if (loaded == null) return;
    emit(loaded.copyWith(
      cart: loaded.cart.where((i) => i.product.id != productId).toList(),
    ));
  }

  void updateCartQty(String productId, int qty) {
    final loaded = _loaded; if (loaded == null) return;
    if (qty <= 0) { removeFromCart(productId); return; }
    final cart = loaded.cart.map((i) =>
      i.product.id == productId ? i.copyWith(quantity: qty) : i,
    ).toList();
    emit(loaded.copyWith(cart: cart));
  }

  void clearCart() {
    final loaded = _loaded; if (loaded == null) return;
    emit(loaded.copyWith(cart: const []));
  }

  StorefrontLoaded? get _loaded =>
      state is StorefrontLoaded ? state as StorefrontLoaded : null;
}
