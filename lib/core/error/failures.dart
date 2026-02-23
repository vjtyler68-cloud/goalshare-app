/// Base class for all failures in the app
/// Use sealed class pattern for exhaustive handling
abstract class Failure {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Get user-friendly message for display
  String get userMessage => message;
}

/// Network related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.statusCode,
    super.originalError,
  });

  factory NetworkFailure.noInternet() {
    return const NetworkFailure(
      message: 'No internet connection. Please check your network.',
    );
  }

  factory NetworkFailure.timeout() {
    return const NetworkFailure(
      message: 'Request timeout. Please try again.',
    );
  }

  factory NetworkFailure.requestCancelled() {
    return const NetworkFailure(
      message: 'Request was cancelled.',
    );
  }
}

/// Server related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
    super.originalError,
  });

  factory ServerFailure.internal() {
    return const ServerFailure(
      message: 'Internal server error. Please try again later.',
      statusCode: 500,
    );
  }

  factory ServerFailure.badRequest(String? serverMessage) {
    return ServerFailure(
      message: serverMessage ?? 'Bad request. Please check your input.',
      statusCode: 400,
    );
  }

  factory ServerFailure.unauthorized() {
    return const ServerFailure(
      message: 'Session expired. Please login again.',
      statusCode: 401,
    );
  }

  factory ServerFailure.forbidden() {
    return const ServerFailure(
      message: 'Access forbidden. You don\'t have permission.',
      statusCode: 403,
    );
  }

  factory ServerFailure.notFound() {
    return const ServerFailure(
      message: 'Resource not found.',
      statusCode: 404,
    );
  }

  factory ServerFailure.conflict(String? serverMessage) {
    return ServerFailure(
      message: serverMessage ?? 'Conflict detected. Resource already exists.',
      statusCode: 409,
    );
  }
}

/// Cache/Local storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.originalError,
  });

  factory CacheFailure.notFound() {
    return const CacheFailure(
      message: 'Cached data not found.',
    );
  }

  factory CacheFailure.saveFailed() {
    return const CacheFailure(
      message: 'Failed to save data locally.',
    );
  }
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
  });

  factory ValidationFailure.invalidEmail() {
    return const ValidationFailure(
      message: 'Please enter a valid email address.',
    );
  }

  factory ValidationFailure.invalidPassword() {
    return const ValidationFailure(
      message: 'Password must be at least 8 characters.',
    );
  }

  factory ValidationFailure.emptyField(String fieldName) {
    return ValidationFailure(
      message: '$fieldName cannot be empty.',
    );
  }
}

/// Unknown/Unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.originalError,
  });

  factory UnexpectedFailure.generic() {
    return const UnexpectedFailure(
      message: 'An unexpected error occurred. Please try again.',
    );
  }
}
