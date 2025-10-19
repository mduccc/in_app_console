import 'dart:async';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_type.dart';

/// Implementation of the [InAppLogger] interface.
///
class InAppLoggerImpl implements InAppLogger {
  String _label = '';
  final StreamController<InAppLoggerData> _streamController =
      StreamController<InAppLoggerData>.broadcast();

  @override
  Stream<InAppLoggerData> get stream => _streamController.stream;

  @override
  String get label => _label;

  @override
  void logInfo(String message) {
    _streamController.add(InAppLoggerData(
        message: message,
        timestamp: DateTime.now(),
        type: InAppLoggerType.info,
        label: _label.isNotEmpty ? _label : null));
  }

  @override
  void logError(
      {required String message, Object? error, StackTrace? stackTrace}) {
    _streamController.add(InAppLoggerData(
        message: message,
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
        type: InAppLoggerType.error,
        label: _label.isNotEmpty ? _label : null));
  }

  @override
  void logWarning(
      {required String message, Error? error, StackTrace? stackTrace}) {
    _streamController.add(InAppLoggerData(
        message: message,
        timestamp: DateTime.now(),
        error: error,
        stackTrace: stackTrace,
        type: InAppLoggerType.warning,
        label: _label.isNotEmpty ? _label : null));
  }

  @override
  void setLabel(String label) {
    _label = label;
  }
}
