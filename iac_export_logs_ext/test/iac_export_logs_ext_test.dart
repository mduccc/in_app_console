import 'package:flutter_test/flutter_test.dart';
import 'package:iac_export_logs_ext/iac_export_logs_ext.dart';
import 'package:iac_export_logs_ext/iac_export_logs_ext_platform_interface.dart';
import 'package:iac_export_logs_ext/iac_export_logs_ext_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockIacExportLogsExtPlatform
    with MockPlatformInterfaceMixin
    implements IacExportLogsExtPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> shareFile({
    required String filePath,
  }) => Future.value(true);
}

void main() {
  final IacExportLogsExtPlatform initialPlatform = IacExportLogsExtPlatform.instance;

  test('$MethodChannelIacExportLogsExt is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelIacExportLogsExt>());
  });

  test('getPlatformVersion', () async {
    IacExportLogsExt iacExportLogsExtPlugin = IacExportLogsExt();
    MockIacExportLogsExtPlatform fakePlatform = MockIacExportLogsExtPlatform();
    IacExportLogsExtPlatform.instance = fakePlatform;

    expect(await iacExportLogsExtPlugin.getPlatformVersion(), '42');
  });
}
