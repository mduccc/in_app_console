import 'package:flutter/widgets.dart';
import 'package:in_app_console/src/core/logger/in_app_logger.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_data.dart';
import 'package:in_app_console/src/impl/console/in_app_console_impl.dart';

/// Interface for a in app console.
///
/// This class is used to combine multiple [InAppLogger] into a single stream.
///
abstract class InAppConsole {
  /// Default instance of the [InAppConsole].
  static final InAppConsole _instance = InAppConsoleImpl();

  /// Default instance of the [InAppConsole].
  ///
  static InAppConsole get instance => _instance;

  /// The stream of in app logger data.
  ///
  /// This stream is used to listen to the in app logger data.
  ///
  /// Every [InAppLogger] will emit a new [InAppLoggerData] object, which will be combined into a single stream.
  ///
  Stream<InAppLoggerData> get stream;

  /// The history of in app logger data.
  ///
  /// This history is used to store the in app logger data.
  ///
  List<InAppLoggerData> get history;

  /// Add a in app logger to the console.
  ///
  /// [logger] is the in app logger to add.
  ///
  void addLogger(InAppLogger logger);

  /// Remove a in app logger from the console.
  ///
  /// [logger] is the in app logger to remove.
  ///
  void removeLogger(InAppLogger logger);

  /// Open in app console screen.
  ///
  Future<void> openConsole(BuildContext context);

  /// Close in app console screen.
  ///
  void closeConsole(BuildContext context);

  /// Clear the history of the in app console.
  ///
  /// This method is used to clear the history of the in app console.
  ///
  void clearHistory();
}
