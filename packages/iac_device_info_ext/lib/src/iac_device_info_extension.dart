import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';

import '../iac_device_info_ext_platform_interface.dart';
import 'iac_device_info_model.dart';
import 'iac_device_info_widget.dart';

class IacDeviceInfoExtension extends InAppConsoleExtension {
  late Future<IacDeviceInfoModel> _deviceInfoFuture;

  @override
  String get id => 'iac_device_info_ext';

  @override
  String get name => 'Device Info';

  @override
  String get version => '2.0.0';

  @override
  String get description => 'Display device information and system specs';

  @override
  Widget get icon => const Icon(Icons.phone_android, color: Colors.black);

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    _deviceInfoFuture = _fetchDeviceInfo();
  }

  Future<IacDeviceInfoModel> _fetchDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final rawRamBytes = await IacDeviceInfoExtPlatform.instance.getTotalRam();
    final totalRam = _formatBytes(rawRamBytes);

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return IacDeviceInfoModel(
        platform: 'Android',
        osVersion: info.version.release,
        model: info.model,
        manufacturer: info.manufacturer,
        architecture: info.supportedAbis.join(', '),
        totalRam: totalRam,
        additionalInfo: info.board.isNotEmpty ? info.board : null,
      );
    }

    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return IacDeviceInfoModel(
        platform: 'iOS',
        osVersion: info.systemVersion,
        model: info.model,
        manufacturer: '',
        architecture: info.utsname.machine,
        totalRam: totalRam,
        additionalInfo: info.utsname.sysname,
      );
    }

    throw UnsupportedError('Platform not supported');
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'Unknown';
    final gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return '${gb.toStringAsFixed(1)} GB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget buildWidget(BuildContext context) {
    return IacDeviceInfoWidget(deviceInfoFuture: _deviceInfoFuture);
  }

  @override
  void onDispose() {}
}
