import 'package:flutter_test/flutter_test.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext_platform_interface.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIacNetworkInspectorExtPlatform
    with MockPlatformInterfaceMixin
    implements IacNetworkInspectorExtPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final IacNetworkInspectorExtPlatform initialPlatform = IacNetworkInspectorExtPlatform.instance;

  test('$MethodChannelIacNetworkInspectorExt is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIacNetworkInspectorExt>());
  });

  test('getPlatformVersion', () async {
    IacNetworkInspectorExt iacNetworkInspectorExtPlugin = IacNetworkInspectorExt();
    MockIacNetworkInspectorExtPlatform fakePlatform = MockIacNetworkInspectorExtPlatform();
    IacNetworkInspectorExtPlatform.instance = fakePlatform;

    expect(await iacNetworkInspectorExtPlugin.getPlatformVersion(), '42');
  });
}
