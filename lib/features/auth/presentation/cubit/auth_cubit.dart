import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/firebase/analytics_service.dart';
import '../../../../core/firebase/error_reporter.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/admin_login_usecase.dart';
import '../../domain/usecases/admin_logout_usecase.dart';
import '../../domain/usecases/get_admin_current_user_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _login;
  final LogoutUseCase _logout;
  final GetCurrentUserUseCase _getCurrentUser;
  final GetAdminCurrentUserUseCase _getAdminCurrentUser;
  final AdminLoginUseCase _adminLogin;
  final AdminLogoutUseCase _adminLogout;
  final SecureStorage _storage;
  final LocalStorage _localStorage;
  final AuthRemoteDataSource _authDs;

  AuthCubit({
    required LoginUseCase login,
    required LogoutUseCase logout,
    required GetCurrentUserUseCase getCurrentUser,
    required GetAdminCurrentUserUseCase getAdminCurrentUser,
    required AdminLoginUseCase adminLogin,
    required AdminLogoutUseCase adminLogout,
    required SecureStorage storage,
    required LocalStorage localStorage,
    required AuthRemoteDataSource authDs,
  })  : _login = login,
        _logout = logout,
        _getCurrentUser = getCurrentUser,
        _getAdminCurrentUser = getAdminCurrentUser,
        _adminLogin = adminLogin,
        _adminLogout = adminLogout,
        _storage = storage,
        _localStorage = localStorage,
        _authDs = authDs,
        super(const AuthInitial());

  Future<void> checkAuth() async {
    final token = await _storage.getToken();
    if (token == null) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Determine whether this token belongs to an admin by reading the local cache.
    final cachedJson = _localStorage.getCachedUserJson();
    final cachedIsAdmin = cachedJson?['is_admin'] as bool? ?? false;

    emit(const AuthLoading());

    final result = cachedIsAdmin
        ? await _getAdminCurrentUser()
        : await _getCurrentUser();

    UserEntity? onlineUser;
    result.fold(
      (failure) {
        if (failure is UnauthorizedFailure) {
          _storage.clearAll();
          _localStorage.clearUser();
          emit(const AuthUnauthenticated());
        } else {
          // Network error — restore from local cache immediately
          if (cachedJson != null) {
            emit(AuthAuthenticated(_userFromJson(cachedJson)));
          } else {
            emit(const AuthUnauthenticated());
          }
        }
      },
      (user) {
        _localStorage.cacheUserJson(_userToJson(user));
        onlineUser = user;
      },
    );
    if (onlineUser != null) {
      await _saveCurrencyFrom(onlineUser!);
      if (!cachedIsAdmin) {
        // Store-settings endpoint is vendor-only — skip for admins
        await _syncStoreSettings();
      }
      emit(AuthAuthenticated(onlineUser!));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());
    final result = await _login(LoginParams(email: email, password: password));

    Failure? failure;
    UserEntity? authedUser;
    result.fold((f) => failure = f, (u) => authedUser = u);

    if (failure != null) {
      if (failure is UseAdminLoginFailure) {
        // Backend explicitly said this is an admin account — try admin endpoint
        await _adminLoginFallback(email: email, password: password);
      } else {
        emit(AuthError(failure!.message));
      }
      return;
    }

    if (authedUser != null) {
      _localStorage.cacheUserJson(_userToJson(authedUser!));
      await _saveCurrencyFrom(authedUser!);
      await _syncStoreSettings();
      emit(AuthAuthenticated(authedUser!));
      AppAnalytics.instance.logLogin(method: 'email');
      AppAnalytics.instance.setUser(authedUser!.id, email: authedUser!.email);
      AppErrorReporter.instance.setUser(authedUser!.id, email: authedUser!.email);
    }
  }

  Future<void> _adminLoginFallback({
    required String email,
    required String password,
  }) async {
    final result = await _adminLogin(LoginParams(email: email, password: password));
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        _localStorage.cacheUserJson(_userToJson(user));
        emit(AuthAuthenticated(user));
      },
    );
  }

  /// Saves the currency symbol + code derived from the user's currencyCode field.
  /// The backend returns the currency code (e.g. 'SAR', 'EGP', 'USD') in the
  /// login/me response. We derive the display symbol via intl.
  Future<void> _saveCurrencyFrom(UserEntity user) async {
    try {
      final code = user.currencyCode?.isNotEmpty == true
          ? user.currencyCode!
          : null;
      if (code == null) return;
      final symbol =
          NumberFormat.simpleCurrency(name: code).currencySymbol;
      await _localStorage.saveCurrency(symbol: symbol, code: code);
    } catch (_) {}
  }

  /// Syncs branding / store-level settings (currency as fallback if user
  /// object lacked it, plus any other fields the store-settings endpoint provides).
  Future<void> _syncStoreSettings() async {
    try {
      final settings = await _authDs.fetchStoreSettings();

      // Currency: prefer what we already saved from the user object, but if
      // localStorage still has the default '$' fall back to the store-settings.
      final currentCode = _localStorage.currencyCode;
      // Sync POS default order status
      final posStatus = settings['default_order_status'] as String? ??
          settings['pos_default_status'] as String?;
      if (posStatus != null && posStatus.isNotEmpty) {
        await _localStorage.savePosDefaultStatus(posStatus);
      }

      // Tracking slug
      final slug = settings['tracking_slug'] as String? ??
          settings['slug'] as String? ??
          settings['store_slug'] as String? ??
          settings['tracking_key'] as String?;
      if (slug != null && slug.isNotEmpty) {
        await _localStorage.saveTrackingSlug(slug);
      }

      if (currentCode == 'USD' && _localStorage.currencySymbol == '\$') {
        final symbol = settings['currency_symbol'] as String? ??
            settings['currency']?['symbol'] as String? ??
            settings['symbol'] as String?;
        final code = settings['currency_code'] as String? ??
            settings['currency']?['code'] as String? ??
            settings['code'] as String?;

        final resolvedCode =
            code?.isNotEmpty == true ? code! : currentCode;
        final resolvedSymbol = symbol?.isNotEmpty == true
            ? symbol!
            : NumberFormat.simpleCurrency(name: resolvedCode).currencySymbol;

        await _localStorage.saveCurrency(
            symbol: resolvedSymbol, code: resolvedCode);
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await _logout();
    _localStorage.clearUser();
    AppAnalytics.instance.logLogout();
    AppAnalytics.instance.setUser(null);
    AppErrorReporter.instance.setUser(null);
    emit(const AuthUnauthenticated());
  }

  Future<void> adminLogin({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    final result = await _adminLogin(
      LoginParams(email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        _localStorage.cacheUserJson(_userToJson(user));
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> adminLogout() async {
    await _adminLogout();
    _localStorage.clearUser();
    emit(const AuthUnauthenticated());
  }

  static Map<String, dynamic> _userToJson(UserEntity user) => {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'is_admin': user.isAdmin,
        'currency': user.currencyCode,
      };

  static UserEntity _userFromJson(Map<String, dynamic> json) => UserEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String?,
        isAdmin: json['is_admin'] as bool? ?? false,
        currencyCode: json['currency'] as String?,
      );
}
