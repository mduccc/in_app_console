import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';
import 'package:in_app_console/src/core/extension/in_app_console_extension_context.dart';
import 'package:in_app_console/src/ui/in_app_console_screen.dart';

/// Implementation of the [InAppConsoleInternal] interface.
///
class InAppConsoleImpl implements InAppConsoleInternal {
  /// Constructor for the [InAppConsoleImpl].
  ///
  InAppConsoleImpl(this.extensionContext);

  /// The extension context instance.
  /// This instance provides access to the console's stream and history for extensions.
  ///
  final InAppConsoleExtensionContext extensionContext;

  /// The map of registered loggers with their hash code.
  ///
  /// This map is used to store the registered loggers with their hash code.
  ///
  final Map<int, InAppLogger> _registeredLoggersWithHashCode = {};

  /// The map of subscriptions of loggers with their hash code.
  ///
  /// This map is used to store the subscriptions of loggers with their hash code.
  ///
  final Map<int, StreamSubscription<InAppLoggerData>>
      _subscriptionsLoggersWithHashCode = {};

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

  /// The map of registered extensions with their ID.
  ///
  /// This map is used to store the registered extensions with their ID.
  ///
  final Map<String, InAppConsoleExtension> _registeredExtensionsWithID = {};

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
  /// If the [kEnableConsole] flag is false, it will not be emit and store the data to the history.
  ///
  @override
  void addLogger(InAppLogger logger) {
    if (_registeredLoggersWithHashCode.containsKey(logger.hashCode)) {
      return;
    }

    _registeredLoggersWithHashCode[logger.hashCode] = logger;
    final subscription = logger.stream.listen((data) {
      if (!InAppConsole.kEnableConsole) {
        return;
      }

      _streamController.add(data);
      _history.add(data);

      // Log to the console of the IDE
      _logToConsole(data);
    });
    _subscriptionsLoggersWithHashCode[logger.hashCode] = subscription;
  }

  /// If the in app logger is not registered, it will not be removed.
  ///
  /// Otherwise, it will be removed and the subscription will be cancelled.
  ///
  @override
  void removeLogger(InAppLogger logger) {
    if (!_registeredLoggersWithHashCode.containsKey(logger.hashCode)) {
      return;
    }
    _registeredLoggersWithHashCode.remove(logger.hashCode);
    final subscription =
        _subscriptionsLoggersWithHashCode.remove(logger.hashCode);
    subscription?.cancel();
  }

  /// Open the in app console screen.
  ///
  /// Ensures the console is enabled by checking the [kEnableConsole] flag before opening the console.
  ///
  @override
  Future<void> openConsole(BuildContext context) {
    if (!InAppConsole.kEnableConsole) {
      return Future.value();
    }
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InAppConsoleScreen(),
      ),
    );
  }

  /// Close the in app console screen.
  ///
  /// Closes the in app console screen by popping the navigator.
  ///
  @override
  void closeConsole(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  void clearLogs() {
    _history.clear();
  }

  /// Register an extension with the console.
  ///
  /// If an extension with the same ID is already registered, registration is skipped.
  ///
  @override
  void registerExtension(InAppConsoleExtension extension) {
    if (_registeredExtensionsWithID.containsKey(extension.id)) {
      return;
    }

    _registeredExtensionsWithID[extension.id] = extension;

    // Initialize the extension
    extension.onInit(extensionContext);
  }

  /// Unregister an extension from the console.
  ///
  /// Calls the extension's onDispose method to allow cleanup.
  ///
  @override
  void unregisterExtension(InAppConsoleExtension extension) {
    final removed = _registeredExtensionsWithID.remove(extension.id);

    if (removed != null) {
      removed.onDispose();
    }
  }

  /// Get all registered extensions.
  @override
  List<InAppConsoleExtension> getExtensions() {
    return _registeredExtensionsWithID.values.toList();
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
