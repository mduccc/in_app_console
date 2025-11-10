import 'package:iac_network_inspector_ext/src/core/iac_network_inspector_core.dart';
import 'package:iac_network_inspector_ext/src/impl/iac_network_inspector_extension.dart';
import 'package:iac_network_inspector_ext/src/impl/iac_network_interceptor_impl.dart';

abstract class IacNetworkInspectorExt implements IacNetworkInspectorExtCore {
  factory IacNetworkInspectorExt() =>
      IacNetworkInspectorExtImpl(IacNetworkInterceptorImpl());
}
