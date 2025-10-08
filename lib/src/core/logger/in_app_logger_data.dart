import 'package:in_app_console/src/core/logger/in_app_logger_type.dart';

/// Data class for holding in app logger data.
///
class InAppLoggerData {
  /// The message to log in the in app logger.
  final String message;

  /// The timestamp of the log.
  final DateTime timestamp;

  /// The in app logger type of logger.
  final InAppLoggerType type;

  /// Optional label for categorizing or tagging the log entry.
  final String? label;

  /// The error to log in the in app logger.
  final Error? error;

  /// The stack trace of the in app logger.
  final StackTrace? stackTrace;

  const InAppLoggerData({
    required this.message,
    required this.timestamp,
    required this.type,
    this.label,
    this.error,
    this.stackTrace,
  });
}
