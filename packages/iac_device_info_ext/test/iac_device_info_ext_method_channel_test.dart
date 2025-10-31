import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iac_device_info_ext/iac_device_info_ext_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIacDeviceInfoExt platform = MethodChannelIacDeviceInfoExt();
  const MethodChannel channel = MethodChannel('iac_device_info_ext');

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
