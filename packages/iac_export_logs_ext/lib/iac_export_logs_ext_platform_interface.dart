import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'iac_export_logs_ext_method_channel.dart';

abstract class IacExportLogsExtPlatform extends PlatformInterface {
  /// Constructs a IacExportLogsExtPlatform.
  IacExportLogsExtPlatform() : super(token: _token);

  static final Object _token = Object();

  static IacExportLogsExtPlatform _instance = MethodChannelIacExportLogsExt();

  /// The default instance of [IacExportLogsExtPlatform] to use.
  ///
  /// Defaults to [MethodChannelIacExportLogsExt].
  static IacExportLogsExtPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [IacExportLogsExtPlatform] when
  /// they register themselves.
  static set instance(IacExportLogsExtPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Share a file using native share sheet (iOS uses LinkPresentation)
  /// [filePath] - absolute path to the file to share
  /// Returns true if share was successful or completed, false otherwise
  Future<bool> shareFile({
    required String filePath,
  }) {
    throw UnimplementedError('shareFile() has not been implemented.');
  }
}
