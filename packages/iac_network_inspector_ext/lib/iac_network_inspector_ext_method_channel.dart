import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iac_network_inspector_ext_platform_interface.dart';

/// An implementation of [IacNetworkInspectorExtPlatform] that uses method channels.
class MethodChannelIacNetworkInspectorExt extends IacNetworkInspectorExtPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('iac_network_inspector_ext');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
