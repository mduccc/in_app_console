import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iac_network_inspector_ext_method_channel.dart';

abstract class IacNetworkInspectorExtPlatform extends PlatformInterface {
  /// Constructs a IacNetworkInspectorExtPlatform.
  IacNetworkInspectorExtPlatform() : super(token: _token);

  static final Object _token = Object();

  static IacNetworkInspectorExtPlatform _instance = MethodChannelIacNetworkInspectorExt();

  /// The default instance of [IacNetworkInspectorExtPlatform] to use.
  ///
  /// Defaults to [MethodChannelIacNetworkInspectorExt].
  static IacNetworkInspectorExtPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IacNetworkInspectorExtPlatform] when
  /// they register themselves.
  static set instance(IacNetworkInspectorExtPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
