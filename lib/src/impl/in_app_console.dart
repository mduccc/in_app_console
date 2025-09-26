import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/in_app_logger_type.dart';
import 'package:in_app_console/src/ui/in_app_console_screen.dart';

/// Implementation of the [InAppConsole] interface.
///
class InAppConsoleImpl implements InAppConsole {
  final Map<int, InAppLogger> _registeredLoggersWithHashCode = {};

  /// The stream controller for the in app console.
  ///
  /// This stream controller is used to emit the data to the [stream].
  ///
  final StreamController<InAppLoggerData> _streamController =
      StreamController<InAppLoggerData>.broadcast();

  /// The history of in app logger data.
  ///
  /// This history is used to store the in app logger data.
  ///
  final List<InAppLoggerData> _history = [];

  @override
  Stream<InAppLoggerData> get stream => _streamController.stream;

  @override
  List<InAppLoggerData> get history => _history;

  /// If the in app logger is already registered, it will not be registered again.
  ///
  /// Otherwise, it will be registered and the data will be emitted to the stream and the history will be updated.
  ///
  /// Also log to the console of the IDE
  ///
  @override
  void addLogger(InAppLogger logger) {
    if (_registeredLoggersWithHashCode.containsKey(logger.hashCode)) {
      return;
    }

    _registeredLoggersWithHashCode[logger.hashCode] = logger;
    logger.stream.listen((data) {
      _streamController.add(data);
      _history.add(data);

      // Log to the console of the IDE
      _logToConsole(data);
    });
  }

  /// If the in app logger is not registered, it will not be removed.
  ///
  /// Otherwise, it will be removed and the data will be drained from the stream.
  ///
  @override
  void removeLogger(InAppLogger logger) {
    if (!_registeredLoggersWithHashCode.containsKey(logger.hashCode)) {
      return;
    }
    _registeredLoggersWithHashCode.remove(logger.hashCode);
    logger.stream.drain();
  }

  @override
  Future<void> openConsole(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InAppConsoleScreen(),
      ),
    );
  }

  @override
  void closeConsole(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void clearHistory() {
    _history.clear();
  }

  /// Get the appropriate error prefix based on the InAppLoggerType
  String _getErrorPrefix(InAppLoggerType type) {
    switch (type) {
      case InAppLoggerType.error:
        return 'Error';
      case InAppLoggerType.warning:
        return 'Warning';
      case InAppLoggerType.info:
        return '';
    }
  }

  /// Based on the InAppLoggerType, log to the console of the IDE with the corresponding color
  ///
  /// Logs full data including timestamp, label, message, error, and stack trace.
  /// [InAppLoggerType.info] will be logged in a green color.
  /// [InAppLoggerType.error] will be logged in a red color.
  /// [InAppLoggerType.warning] will be logged in a orange color.
  ///
  void _logToConsole(InAppLoggerData data) {
    final buffer = StringBuffer();

    String colorPrefix = '';
    const String colorSuffix = '\x1B[0m';

    switch (data.type) {
      case InAppLoggerType.info:
        colorPrefix = '\x1B[32m';
        break;
      case InAppLoggerType.error:
        colorPrefix = '\x1B[31m';
        break;
      case InAppLoggerType.warning:
        colorPrefix = '\x1B[38;5;208m';
        break;
    }

    // Format timestamp
    final timestamp = data.timestamp;
    final formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';

    // Build log message with full data
    buffer.write('$colorPrefix[$formattedTime]$colorSuffix');

    if (data.label != null) {
      buffer.write(' $colorPrefix[${data.label}]$colorSuffix');
    }

    buffer.write(' $colorPrefix${data.message}$colorSuffix');

    if (data.error != null) {
      buffer.write(
          '\n$colorPrefix  ${_getErrorPrefix(data.type)}: $colorPrefix${data.error}$colorSuffix');
    }

    if (data.stackTrace != null) {
      //buffer.write('\n$colorPrefix  Stack Trace:\n$colorPrefix${data.stackTrace}$colorSuffix');
      final stackTraceLines = data.stackTrace.toString().split('\n');
      for (final line in stackTraceLines) {
        buffer.write('\n$colorPrefix    $line$colorSuffix');
      }
    }

    final logMessage = buffer.toString();

    log(logMessage);
  }
}
