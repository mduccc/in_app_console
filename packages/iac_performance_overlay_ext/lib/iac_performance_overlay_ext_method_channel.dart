import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iac_performance_overlay_ext_platform_interface.dart';

class MethodChannelIacPerformanceOverlayExt
    extends IacPerformanceOverlayExtPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('iac_performance_overlay_ext');

  @override
  Future<double?> getCpuUsage() async {
    final value = await methodChannel.invokeMethod<double>('getCpuUsage');
    return value;
  }

  @override
  Future<Map<String, int>?> getMemoryInfo() async {
    final raw =
        await methodChannel.invokeMapMethod<String, int>('getMemoryInfo');
    return raw;
  }
}
