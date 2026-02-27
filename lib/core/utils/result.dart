/// Result type for handling success and failure states
/// Similar to Either<L, R> but more explicit for Flutter
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create a success result
  factory Result.success(T data) {
    return Result._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create a failure result
  factory Result.failure(String error) {
    return Result._(
      error: error,
      isSuccess: false,
    );
  }

  /// Check if result is success
  bool get isFailure => !isSuccess;

  /// Get data or throw if failure
  T get dataOrThrow {
    if (isSuccess && data != null) {
      return data!;
    }
    throw Exception(error ?? 'No data available');
  }

  /// Get data or return default
  T getOrElse(T defaultValue) {
    return data ?? defaultValue;
  }

  /// Transform success data
  Result<R> map<R>(R Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return Result.success(transform(data!));
      } catch (e) {
        return Result.failure(e.toString());
      }
    }
    return Result.failure(error ?? 'Unknown error');
  }

  /// Execute function based on result state
  R fold<R>({
    required R Function(String error) onFailure,
    required R Function(T data) onSuccess,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data!);
    }
    return onFailure(error ?? 'Unknown error');
  }
}
