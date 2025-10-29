import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iac_export_logs_ext/iac_export_logs_ext_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelIacExportLogsExt platform = MethodChannelIacExportLogsExt();
  const MethodChannel channel = MethodChannel('iac_export_logs_ext');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getPlatformVersion') {
          return '42';
        } else if (methodCall.method == 'shareFile') {
          return true;
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('shareFile', () async {
    final result = await platform.shareFile(
      filePath: '/path/to/test_logs.txt',
    );
    expect(result, true);
  });
}
