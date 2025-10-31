
import 'iac_network_inspector_ext_platform_interface.dart';

class IacNetworkInspectorExt {
  Future<String?> getPlatformVersion() {
    return IacNetworkInspectorExtPlatform.instance.getPlatformVersion();
  }
}
