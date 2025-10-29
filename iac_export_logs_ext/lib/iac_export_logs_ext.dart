import 'iac_export_logs_ext_platform_interface.dart';

export 'src/in_app_console_export_logs_extension.dart';

class IacExportLogsExt {
  Future<String?> getPlatformVersion() {
    return IacExportLogsExtPlatform.instance.getPlatformVersion();
  }

  Future<bool> shareFile({
    required String filePath,
  }) {
    return IacExportLogsExtPlatform.instance.shareFile(
      filePath: filePath,
    );
  }
}
