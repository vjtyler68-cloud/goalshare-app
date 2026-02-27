/// Custom exceptions for network layer
class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'NetworkException: $message (statusCode: $statusCode)';
}

class NoInternetException extends NetworkException {
  NoInternetException()
      : super(
          message: 'No internet connection',
        );
}

class TimeoutException extends NetworkException {
  TimeoutException()
      : super(
          message: 'Request timeout',
        );
}

class ServerException extends NetworkException {
  ServerException({
    required String message,
    required int statusCode,
    dynamic originalError,
  }) : super(
          message: message,
          statusCode: statusCode,
          originalError: originalError,
        );
}

class UnauthorizedException extends ServerException {
  UnauthorizedException([String? message])
      : super(
          message: message ?? 'Unauthorized access',
          statusCode: 401,
        );
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}
