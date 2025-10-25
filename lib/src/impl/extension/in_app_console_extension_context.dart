import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';
import 'package:in_app_console/src/core/extension/in_app_console_extension_context.dart';
import 'package:in_app_console/src/impl/console/in_app_console_impl.dart';

class InAppConsoleExtensionContextImpl implements InAppConsoleExtensionContext {
  InAppConsoleExtensionContextImpl();

  /// Must using late to avoid circular dependency
  /// Explanation:
  /// - [InAppConsoleExtensionContextImpl] needs to access [InAppConsole.instance]
  /// - [InAppConsole.instance] is an instance of [InAppConsoleImpl]
  /// - [InAppConsoleImpl] requires [InAppConsoleExtensionContext] in its constructor
  /// - This creates a circular dependency if we try to initialize them directly
  ///
  /// By using late final, we defer the initialization of _console until it's first accessed,
  /// breaking the circular dependency chain.
  ///
  late final InAppConsoleInternal _console =
      InAppConsole.instance as InAppConsoleInternal;

  @override
  Stream<InAppLoggerData> get stream => _console.stream;

  @override
  List<InAppLoggerData> get history => _console.history;
}
