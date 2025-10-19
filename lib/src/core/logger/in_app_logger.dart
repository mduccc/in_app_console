import 'package:in_app_console/src/core/logger/in_app_logger_data.dart';
import 'package:in_app_console/src/impl/logger/in_app_logger_impl.dart';

/// Interface for a in app logger.
///
/// This class is used to log messages to the console.
///
abstract class InAppLogger {
  /// Default factory constructor for the [InAppLogger].
  ///
  factory InAppLogger() => InAppLoggerImpl();

  /// The stream of in app logger data.
  ///
  /// This stream is used to listen to the in app logger data.
  ///
  /// Every methods [logInfo], [logError], [logWarning] will emit a new [InAppLoggerData] object to the stream.
  ///
  Stream<InAppLoggerData> get stream;

  /// The label of the in app logger.
  ///
  /// This label is used to identify the in app logger.
  ///
  String get label;

  /// Log an info message.
  ///
  /// This method is used to log an info message to the console.
  ///
  /// [message] is the message to log.
  ///
  void logInfo(String message);

  /// Log an error message.
  ///
  /// This method is used to log an error message to the console.
  ///
  /// [message] is the message to log.
  /// [error] is the error to log.
  /// [stackTrace] is the stack trace to log.
  ///
  /// Also emit a new [InAppLoggerData] object to the [stream].
  ///
  void logError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
  });

  /// Log a warning message.
  ///
  /// This method is used to log a warning message to the console.
  ///
  /// [message] is the message to log.
  /// [error] is the error to log.
  /// [stackTrace] is the stack trace to log.
  ///
  /// Also emit a new [InAppLoggerData] object to the [stream].
  ///
  void logWarning({
    required String message,
    Error? error,
    StackTrace? stackTrace,
  });

  /// Set the label of the in app logger.
  ///
  /// This method is used to set the label of the in app logger.
  ///
  /// [label] is the label to set.
  ///
  void setLabel(String label);
}
