import 'package:flutter_test/flutter_test.dart';
import 'package:iac_performance_overlay_ext/iac_performance_overlay_ext.dart';
import 'package:iac_performance_overlay_ext/iac_performance_overlay_ext_platform_interface.dart';
import 'package:iac_performance_overlay_ext/iac_performance_overlay_ext_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIacPerformanceOverlayExtPlatform
    with MockPlatformInterfaceMixin
    implements IacPerformanceOverlayExtPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IacPerformanceOverlayExtPlatform initialPlatform = IacPerformanceOverlayExtPlatform.instance;

  test('$MethodChannelIacPerformanceOverlayExt is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIacPerformanceOverlayExt>());
  });

  test('getPlatformVersion', () async {
    IacPerformanceOverlayExt iacPerformanceOverlayExtPlugin = IacPerformanceOverlayExt();
    MockIacPerformanceOverlayExtPlatform fakePlatform = MockIacPerformanceOverlayExtPlatform();
    IacPerformanceOverlayExtPlatform.instance = fakePlatform;

    expect(await iacPerformanceOverlayExtPlugin.getPlatformVersion(), '42');
  });
}
