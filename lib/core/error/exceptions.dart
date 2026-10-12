class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class ForbiddenException implements Exception {
  const ForbiddenException();
}

class SubscriptionException implements Exception {
  const SubscriptionException();
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;
  const ValidationException(this.message, {this.errors});
}

class UseAdminLoginException implements Exception {
  const UseAdminLoginException();
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);
}
