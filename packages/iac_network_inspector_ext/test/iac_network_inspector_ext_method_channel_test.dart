import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIacNetworkInspectorExt platform = MethodChannelIacNetworkInspectorExt();
  const MethodChannel channel = MethodChannel('iac_network_inspector_ext');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
