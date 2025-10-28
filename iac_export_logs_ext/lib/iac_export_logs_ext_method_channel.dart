import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'iac_export_logs_ext_platform_interface.dart';

/// An implementation of [IacExportLogsExtPlatform] that uses method channels.
class MethodChannelIacExportLogsExt extends IacExportLogsExtPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('iac_export_logs_ext');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> shareFile({
    required String filePath,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'shareFile',
        {
          'filePath': filePath,
        },
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error sharing file: $e');
      return false;
    }
  }
}
