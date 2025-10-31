import 'package:flutter_test/flutter_test.dart';
import 'package:iac_device_info_ext/iac_device_info_ext.dart';
import 'package:iac_device_info_ext/iac_device_info_ext_platform_interface.dart';
import 'package:iac_device_info_ext/iac_device_info_ext_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIacDeviceInfoExtPlatform
    with MockPlatformInterfaceMixin
    implements IacDeviceInfoExtPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IacDeviceInfoExtPlatform initialPlatform = IacDeviceInfoExtPlatform.instance;

  test('$MethodChannelIacDeviceInfoExt is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIacDeviceInfoExt>());
  });

  test('getPlatformVersion', () async {
    IacDeviceInfoExt iacDeviceInfoExtPlugin = IacDeviceInfoExt();
    MockIacDeviceInfoExtPlatform fakePlatform = MockIacDeviceInfoExtPlatform();
    IacDeviceInfoExtPlatform.instance = fakePlatform;

    expect(await iacDeviceInfoExtPlugin.getPlatformVersion(), '42');
  });
}
