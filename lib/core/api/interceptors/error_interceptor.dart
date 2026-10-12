import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../error/exceptions.dart';
import '../../firebase/error_reporter.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;
    final method = err.requestOptions.method;

    // Report to Firestore (skip 401/422 — those are expected flows)
    if (statusCode == null || (statusCode != 401 && statusCode != 422)) {
      AppErrorReporter.instance.reportApiError(
        endpoint: path,
        method: method,
        statusCode: statusCode,
        error: err.message ?? err.error?.toString(),
      );
    }

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      debugPrint('[Network] type=${err.type} | error=${err.error} | msg=${err.message}');
      final detail = err.error?.toString() ?? err.message ?? 'connection failed';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: NetworkException(detail),
          type: err.type,
        ),
      );
      return;
    }

    switch (statusCode) {
      case 401:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const UnauthorizedException(),
            response: err.response,
          ),
        );
      case 402:
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: const SubscriptionException(),
            response: err.response,
          ),
        );
      case 403:
        final rawData403 = err.response?.data;
        final data403 = rawData403 is Map<String, dynamic> ? rawData403 : null;
        final code403 = data403?['code'] as String?;
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: code403 == 'use_admin_login'
                ? const UseAdminLoginException()
                : const ForbiddenException(),
            response: err.response,
          ),
        );
      case 422:
        final rawData422 = err.response?.data;
        final data = rawData422 is Map<String, dynamic> ? rawData422 : null;
        final message = data?['message'] as String? ?? 'Validation error';
        final rawErrors = data?['errors'] as Map<String, dynamic>?;
        final errors = rawErrors?.map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        );
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ValidationException(message, errors: errors),
            response: err.response,
          ),
        );
      default:
        final rawData = err.response?.data;
        final data = rawData is Map<String, dynamic> ? rawData : null;
        final message = data?['message'] as String? ??
            'An unexpected error occurred';
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ServerException(message, statusCode: statusCode),
            response: err.response,
          ),
        );
    }
  }
}
