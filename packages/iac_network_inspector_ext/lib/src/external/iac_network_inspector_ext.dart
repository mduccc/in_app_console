import 'package:iac_network_inspector_ext/src/core/iac_network_inspector_workflow.dart';
import 'package:iac_network_inspector_ext/src/impl/iac_network_inspector_extension.dart';
import 'package:iac_network_inspector_ext/src/impl/iac_network_interceptor_impl.dart';
import 'package:in_app_console/in_app_console.dart';

abstract class IacNetworkInspectorExt
    implements InAppConsoleExtension, IacNetworkInspectorExtWorkflow {
  factory IacNetworkInspectorExt() =>
      IacNetworkInspectorExtImpl(IacNetworkInterceptorImpl());
}
