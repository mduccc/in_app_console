import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iac_device_info_ext_platform_interface.dart';

/// An implementation of [IacDeviceInfoExtPlatform] that uses method channels.
class MethodChannelIacDeviceInfoExt extends IacDeviceInfoExtPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('iac_device_info_ext');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
