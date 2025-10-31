
import 'iac_device_info_ext_platform_interface.dart';

class IacDeviceInfoExt {
  Future<String?> getPlatformVersion() {
    return IacDeviceInfoExtPlatform.instance.getPlatformVersion();
  }
}
