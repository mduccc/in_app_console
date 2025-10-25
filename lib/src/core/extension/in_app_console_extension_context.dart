import 'package:in_app_console/in_app_console.dart';

/// The abstract class define the context of the [InAppConsole] to the extensions.
///
/// It's purpose is to provide access to the data of the console, such as the stream and the history,
///
abstract class InAppConsoleExtensionContext {
  /// Provides access to the stream of in app logger data.
  ///
  Stream<InAppLoggerData> get stream;

  /// Provides access to the history of in app logger data.
  ///
  List<InAppLoggerData> get history;
}
