import 'package:in_app_console/in_app_console.dart';

/// Internal interface for a in app console.
/// This class extends [InAppConsole] to provide additional internal functionalities.
///
/// In the internal package, using this interface allows access to more detailed
///
abstract class InAppConsoleInternal extends InAppConsole {
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

  /// Get all registered extensions.
  ///
  /// Returns a list of all currently registered extensions.
  ///
  ///
  List<InAppConsoleExtension> getExtensions();
}
