import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iac_device_info_ext_method_channel.dart';

abstract class IacDeviceInfoExtPlatform extends PlatformInterface {
  /// Constructs a IacDeviceInfoExtPlatform.
  IacDeviceInfoExtPlatform() : super(token: _token);

  static final Object _token = Object();

  static IacDeviceInfoExtPlatform _instance = MethodChannelIacDeviceInfoExt();

  /// The default instance of [IacDeviceInfoExtPlatform] to use.
  ///
  /// Defaults to [MethodChannelIacDeviceInfoExt].
  static IacDeviceInfoExtPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IacDeviceInfoExtPlatform] when
  /// they register themselves.
  static set instance(IacDeviceInfoExtPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
