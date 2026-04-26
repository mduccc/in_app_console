import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iac_performance_overlay_ext_method_channel.dart';

abstract class IacPerformanceOverlayExtPlatform extends PlatformInterface {
  IacPerformanceOverlayExtPlatform() : super(token: _token);

  static final Object _token = Object();

  static IacPerformanceOverlayExtPlatform _instance =
      MethodChannelIacPerformanceOverlayExt();

  static IacPerformanceOverlayExtPlatform get instance => _instance;

  static set instance(IacPerformanceOverlayExtPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns current CPU usage as a percentage (0–100).
  Future<double?> getCpuUsage() {
    throw UnimplementedError('getCpuUsage() has not been implemented.');
  }

  /// Returns memory info with keys `usedMem` and `totalMem` in bytes.
  Future<Map<String, int>?> getMemoryInfo() {
    throw UnimplementedError('getMemoryInfo() has not been implemented.');
  }
}
