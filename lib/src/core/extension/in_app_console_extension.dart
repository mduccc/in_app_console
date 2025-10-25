import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_console/src/core/extension/in_app_console_extension_context.dart';

/// Abstract interface for In-App Console extensions.
///
/// Extensions allow you to add custom functionality to the console without
/// modifying the core package. Examples include:
/// - Log export functionality
/// - Network traffic inspector
/// - Database viewer
/// - Custom log renderers
/// - Additional toolbars and actions
///
/// Extensions are displayed in sequence based on their registration order.
/// Each extension provides a single widget that will be rendered in the
/// extension area of the console UI.
///
/// Example:
/// ```dart
/// class LogExportExtension extends InAppConsoleExtension {
///   @override
///   String get id => 'log_export';
///
///   @override
///   String get name => 'Log Export';
///
///   @override
///   String get version => '1.0.0';
///
///   @override
///   Widget get icon => Icon(Icons.download);
///
///   @override
///   void onInit(InAppConsoleExtensionContext extensionContext) {
///     print('Extension initialized');
///   }
///
///   @override
///   Widget buildWidget(BuildContext context) {
///     return ElevatedButton(
///       onPressed: () => _exportLogs(),
///       child: Text('Export Logs'),
///     );
///   }
/// }
/// ```
abstract class InAppConsoleExtension {
  /// Unique identifier for this extension.
  ///
  /// Must be unique across all extensions. Use reverse domain notation
  /// for best practices (e.g., 'com.example.log_export').
  String get id;

  /// Human-readable name of the extension.
  String get name;

  /// Version of the extension (e.g., '1.0.0').
  String get version;

  /// Optional description of what this extension does.
  String get description => '';

  /// Optional icon widget for the extension.
  ///
  /// This icon will be displayed in the extension list and details.
  /// Can be an Icon, Image, or any custom widget.
  /// If not provided, a default extension icon will be used.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget get icon => Icon(Icons.analytics);
  /// ```
  ///
  /// Or with a custom image:
  /// ```dart
  /// @override
  /// Widget get icon => Image.asset('assets/my_icon.png', width: 24, height: 24);
  /// ```
  Widget get icon => const Icon(Icons.extension);

  /// Called when the extension is registered with the console.
  ///
  /// Use this to initialize resources, set up listeners, or perform
  /// any setup logic needed for your extension.
  void onInit(InAppConsoleExtensionContext extensionContext) {}

  /// Called when the extension is unregistered from the console.
  ///
  /// Use this to clean up resources, cancel subscriptions, or perform
  /// any cleanup logic.
  void onDispose() {}

  /// Build the extension widget.
  ///
  /// The [context] parameter provides the BuildContext for building the widget.
  ///
  /// Return a widget that will be rendered in the extension area of the
  /// console UI. Extensions are displayed in sequence based on their
  /// registration order.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget buildWidget(BuildContext context) {
  ///   return Card(
  ///     child: Padding(
  ///       padding: EdgeInsets.all(8),
  ///       child: Row(
  ///         children: [
  ///           Text('Extension Widget'),
  ///           SizedBox(width: 16),
  ///           ElevatedButton(
  ///             onPressed: () => _doAction(),
  ///             child: Text('Action'),
  ///           ),
  ///         ],
  ///       ),
  ///     ),
  ///   );
  /// }
  /// ```
  Widget buildWidget(BuildContext context);
}
