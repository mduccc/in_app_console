/// Holder for network error data.
///
final class IacNetworkError {
  const IacNetworkError({
    required this.message,
    this.code,
    this.error,
    this.stackTrace,
  });

  /// The error message.
  final String message;

  /// The error code, if available.
  final int? code;

  /// The error object, if available.
  final Object? error;

  /// The stack trace associated with the error, if available.
  final StackTrace? stackTrace;
}
