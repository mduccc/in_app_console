import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iac_device_info_ext_method_channel.dart';

abstract class IacDeviceInfoExtPlatform extends PlatformInterface {
  IacDeviceInfoExtPlatform() : super(token: _token);

  static final Object _token = Object();

  static IacDeviceInfoExtPlatform _instance = MethodChannelIacDeviceInfoExt();

  static IacDeviceInfoExtPlatform get instance => _instance;

  static set instance(IacDeviceInfoExtPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<int?> getTotalRam() {
    throw UnimplementedError('getTotalRam() has not been implemented.');
  }
}
