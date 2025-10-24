import 'package:flutter/widgets.dart';
import 'package:in_app_console/src/core/extension/in_app_console_extension.dart';
import 'package:in_app_console/src/core/logger/in_app_logger.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_data.dart';
import 'package:in_app_console/src/impl/console/in_app_console_impl.dart';

/// Interface for a in app console.
///
/// This class is used to combine multiple [InAppLogger] into a single stream.
///
abstract class InAppConsole {
  
  /// Whether to enable the in app console.
  /// 
  /// If your app is in production, you can set this to false to disable the in app console.
  ///
  /// Default is false.
  /// 
  static bool kEnableConsole = false;

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
  /// Ensures the console is enabled by checking the [kEnableConsole] flag before opening the console.
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

  /// Register an extension with the console.
  ///
  /// [extension] is the extension to register.
  ///
  /// Extensions allow you to add custom functionality to the console
  /// without modifying the core package.
  ///
  /// Example:
  /// ```dart
  /// final logExportExtension = LogExportExtension();
  /// InAppConsole.instance.registerExtension(logExportExtension);
  /// ```
  ///
  /// If an extension with the same ID is already registered, registration is skipped.
  ///
  void registerExtension(InAppConsoleExtension extension);

  /// Unregister an extension from the console.
  ///
  /// [extension] is the extension to unregister.
  ///
  /// This will call the extension's [InAppConsoleExtension.onDispose] method
  /// to allow it to clean up resources.
  ///
  void unregisterExtension(InAppConsoleExtension extension);

  /// Get all registered extensions.
  ///
  /// Returns a list of all currently registered extensions.
  ///
  List<InAppConsoleExtension> getExtensions();
}
