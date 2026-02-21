import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iac_device_info_ext_platform_interface.dart';

class MethodChannelIacDeviceInfoExt extends IacDeviceInfoExtPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('iac_device_info_ext');

  @override
  Future<String?> getPlatformVersion() async {
    return await methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<int?> getTotalRam() async {
    return await methodChannel.invokeMethod<int>('getTotalRam');
  }
}
