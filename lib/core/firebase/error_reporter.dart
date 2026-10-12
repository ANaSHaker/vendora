import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'analytics_service.dart';

/// Logs every error (UI, API, logic, Dart) to Firestore `app_errors` collection.
class AppErrorReporter {
  AppErrorReporter._();
  static final AppErrorReporter instance = AppErrorReporter._();

  FirebaseFirestore? _firestore;
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _deviceInfo;
  String _currentScreen = 'unknown';
  String? _userId;
  String? _userEmail;

  Future<void> init() async {
    try {
      _firestore = FirebaseFirestore.instance;
      _packageInfo = await PackageInfo.fromPlatform();
      _deviceInfo = await _gatherDeviceInfo();

      // Capture Flutter widget errors
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        originalOnError?.call(details);
        _report(
          type: 'ui',
          severity: 'high',
          message: details.exceptionAsString(),
          stackTrace: details.stack,
          context: {'library': details.library ?? 'unknown'},
        );
      };

      // Capture uncaught Dart errors
      PlatformDispatcher.instance.onError = (error, stack) {
        _report(
          type: 'dart',
          severity: 'critical',
          message: error.toString(),
          stackTrace: stack,
        );
        return true;
      };

      debugPrint('[ErrorReporter] initialized');
    } catch (e) {
      debugPrint('[ErrorReporter] init failed: $e');
    }
  }

  void setUser(String? userId, {String? email}) {
    _userId = userId;
    _userEmail = email;
  }

  void setScreen(String screen) => _currentScreen = screen;

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> reportApiError({
    required String endpoint,
    required String method,
    int? statusCode,
    dynamic error,
    Map<String, dynamic>? context,
  }) {
    AppAnalytics.instance.logApiError(
      endpoint: endpoint,
      method: method,
      statusCode: statusCode,
    );
    return _report(
      type: 'api',
      severity: statusCode != null && statusCode >= 500 ? 'high' : 'medium',
      message: 'API $method $endpoint → $statusCode: $error',
      context: {
        'endpoint': endpoint,
        'method': method,
        if (statusCode != null) 'status_code': statusCode,
        ...?context,
      },
    );
  }

  Future<void> reportLogicError({
    required String message,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String severity = 'medium',
  }) =>
      _report(
        type: 'logic',
        severity: severity,
        message: message,
        stackTrace: stackTrace,
        context: context,
      );

  // ── Core ───────────────────────────────────────────────────────────────────

  Future<void> _report({
    required String type,
    required String severity,
    required String message,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      final db = _firestore;
      if (db == null) return;

      await db.collection('app_errors').add({
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        'severity': severity,
        'message': message.length > 2000
            ? message.substring(0, 2000)
            : message,
        'stack_trace': stackTrace != null
            ? stackTrace.toString().length > 3000
                ? stackTrace.toString().substring(0, 3000)
                : stackTrace.toString()
            : null,
        'screen': _currentScreen,
        'user': {
          'id': _userId ?? 'guest',
          if (_userEmail != null) 'email': _userEmail,
        },
        'platform': _currentPlatform(),
        'platform_details': _deviceInfo ?? {},
        'app_version': _packageInfo?.version ?? 'unknown',
        'build_number': _packageInfo?.buildNumber ?? 'unknown',
        'context': context ?? {},
        'resolved': false,
      });
    } catch (e) {
      debugPrint('[ErrorReporter] failed to log: $e');
    }
  }

  String _currentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  Future<Map<String, dynamic>> _gatherDeviceInfo() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final w = await plugin.webBrowserInfo;
        return {
          'type': 'web',
          'browser': w.browserName.name,
          'browser_version': w.appVersion ?? '',
          'user_agent': w.userAgent ?? '',
          'platform': w.platform ?? '',
        };
      }
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        return {
          'type': 'android',
          'model': a.model,
          'brand': a.brand,
          'manufacturer': a.manufacturer,
          'android_version': a.version.release,
          'sdk_int': a.version.sdkInt,
          'is_physical': a.isPhysicalDevice,
        };
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        return {
          'type': 'ios',
          'model': i.model,
          'name': i.name,
          'system_version': i.systemVersion,
          'is_physical': i.isPhysicalDevice,
          'identifier': i.identifierForVendor ?? '',
        };
      }
      if (Platform.isWindows) {
        final w = await plugin.windowsInfo;
        return {
          'type': 'windows',
          'computer_name': w.computerName,
          'major_version': w.majorVersion,
          'minor_version': w.minorVersion,
          'edition_id': w.editionId,
          'product_name': w.productName,
        };
      }
      if (Platform.isMacOS) {
        final m = await plugin.macOsInfo;
        return {
          'type': 'macos',
          'model': m.model,
          'arch': m.arch,
          'kernel_version': m.kernelVersion,
          'os_release': m.osRelease,
          'computer_name': m.computerName,
        };
      }
      if (Platform.isLinux) {
        final l = await plugin.linuxInfo;
        return {
          'type': 'linux',
          'name': l.name,
          'version': l.version ?? '',
          'id': l.id,
          'machine_id': l.machineId ?? '',
        };
      }
    } catch (_) {}
    return {'type': 'unknown'};
  }
}
