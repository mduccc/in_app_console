import 'package:in_app_console/in_app_console.dart';

/// Internal interface for a in app console.
/// /// This class extends [InAppConsole] to provide additional internal functionalities.
/// 
abstract class InAppConsoleInternal extends InAppConsole {
  /// Get all registered extensions.
  ///
  /// Returns a list of all currently registered extensions.
  ///
  ///
  List<InAppConsoleExtension> getExtensions();
}